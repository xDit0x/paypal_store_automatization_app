import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:store_automatization_app/core/voice/voice_activity.dart';

/// Audio del asistente:
/// - Escucha: graba con el micrófono y corta sola cuando el dueño se calla.
///   El audio se transcribe en el servidor con Whisper (Groq).
/// - Voz: reproduce el MP3 de ElevenLabs que manda el servidor o, si no hay,
///   usa la mejor voz del dispositivo.
///
/// Todo va en try/catch: sin micrófono la app sigue funcionando por texto.
class VoiceService {
  VoiceService._();

  static final VoiceService instance = VoiceService._();

  static const _sampleRate = 16000;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  StreamSubscription<Uint8List>? _micSub;
  Completer<Uint8List?>? _listening;
  void Function()? _finishNow;
  Completer<void>? _playing;
  bool _ttsReady = false;

  bool get isListening => _listening != null;

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (error) {
      debugPrint('[voice] permiso: $error');
      return false;
    }
  }

  /// Graba hasta que el dueño termina de hablar. Devuelve un WAV, o null si
  /// no habló (o se canceló). [onLevel] recibe el volumen (0..1) para animar.
  Future<Uint8List?> listen({
    void Function(double level)? onLevel,
    void Function()? onSpeech,
  }) async {
    await stopSpeaking();
    if (_listening != null) return _listening!.future;

    final done = Completer<Uint8List?>();
    _listening = done;
    final vad = VoiceActivity(sampleRate: _sampleRate);
    final audio = BytesBuilder(copy: false);
    var speechStart = 0;

    Future<void> finish({required bool keep}) async {
      if (done.isCompleted) return;
      _finishNow = null;
      await _micSub?.cancel();
      _micSub = null;
      try {
        await _recorder.stop();
      } catch (_) {}
      final bytes = audio.toBytes();
      final hadSpeech = keep && vad.hadSpeech;
      // Se guardan ~0,3 s antes de la primera palabra.
      final preRoll = speechStart - _sampleRate * 2 * 3 ~/ 10;
      final from = preRoll < 0 ? 0 : (preRoll > bytes.length ? bytes.length : preRoll);
      _listening = null;
      done.complete(hadSpeech ? buildWav(Uint8List.sublistView(bytes, from), sampleRate: _sampleRate) : null);
    }

    _finishNow = () => finish(keep: true);

    try {
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ));
      _micSub = stream.listen(
        (chunk) {
          audio.add(chunk);
          onLevel?.call((rms(chunk) / 3500).clamp(0.0, 1.0).toDouble());
          switch (vad.feed(chunk)) {
            case VadEvent.speechStarted:
              speechStart = audio.length - chunk.length;
              onSpeech?.call();
            case VadEvent.endOfUtterance:
            case VadEvent.maxLength:
              finish(keep: true);
            case VadEvent.noSpeechTimeout:
              debugPrint('[voice] sin voz: pico=${vad.peakLevel.round()} umbral=${vad.threshold.round()}');
              finish(keep: false);
            case VadEvent.none:
              break;
          }
        },
        onError: (Object error) {
          debugPrint('[voice] micro: $error');
          finish(keep: false);
        },
        onDone: () => finish(keep: true),
      );
    } catch (error) {
      debugPrint('[voice] no se pudo grabar: $error');
      _listening = null;
      if (!done.isCompleted) done.complete(null);
    }
    return done.future;
  }

  /// Corta la escucha y envía lo grabado (el dueño tocó "enviar ya").
  void finishListening() => _finishNow?.call();

  /// Corta la escucha sin enviar nada.
  Future<void> cancelListening() async {
    final pending = _listening;
    if (pending == null) return;
    _finishNow = null;
    await _micSub?.cancel();
    _micSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    _listening = null;
    if (!pending.isCompleted) pending.complete(null);
  }

  /// Reproduce el MP3 de ElevenLabs. Termina cuando acaba o se interrumpe.
  /// Devuelve false si no se pudo reproducir.
  Future<bool> playMp3(Uint8List bytes) async {
    await stopSpeaking();
    final done = Completer<void>();
    _playing = done;
    var failed = false;
    File? file;
    final sub = _player.onPlayerComplete.listen(
      (_) {
        if (!done.isCompleted) done.complete();
      },
      onError: (Object error) {
        debugPrint('[voice] reproductor: $error');
        failed = true;
        if (!done.isCompleted) done.complete();
      },
    );
    try {
      // Tras grabar, iOS puede dejar el audio en el auricular: se fuerza
      // el altavoz.
      await _player.setAudioContext(
        AudioContextConfig(route: AudioContextConfigRoute.speaker).build(),
      );
    } catch (_) {}
    try {
      final Source source;
      if (kIsWeb) {
        source = UrlSource('data:audio/mpeg;base64,${base64Encode(bytes)}');
      } else {
        // iOS necesita la extensión para reconocer el formato del archivo.
        final dir = await getTemporaryDirectory();
        final stamp = DateTime.now().microsecondsSinceEpoch;
        file = File('${dir.path}/stocky_voice_$stamp.mp3');
        await file.writeAsBytes(bytes, flush: true);
        source = DeviceFileSource(file.path, mimeType: 'audio/mpeg');
      }
      await _player.play(source);
      await done.future;
    } catch (error) {
      debugPrint('[voice] reproducir: $error');
      // Si el dueño lo interrumpió, no cuenta como fallo.
      if (identical(_playing, done)) failed = true;
    } finally {
      await sub.cancel();
      if (identical(_playing, done)) _playing = null;
      try {
        await file?.delete();
      } catch (_) {}
    }
    return !failed;
  }

  /// Voz del dispositivo (la mejor que tenga instalada).
  Future<void> speakDevice(String text, String languageCode) async {
    final clean = text.replaceAll('**', '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return;
    await stopSpeaking();
    final done = Completer<void>();
    _playing = done;
    try {
      await _prepareTts(languageCode);
      await _tts.speak(clean);
    } catch (error) {
      debugPrint('[voice] tts: $error');
    } finally {
      if (!done.isCompleted) done.complete();
      if (identical(_playing, done)) _playing = null;
    }
  }

  Future<void> _prepareTts(String languageCode) async {
    final locale = languageCode == 'en' ? 'en-US' : 'es-ES';
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);
    if (_ttsReady) return;
    _ttsReady = true;
    // Busca una voz "mejorada" o "premium" si el dispositivo la tiene.
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        Map<String, String>? best;
        var bestScore = -1;
        for (final raw in voices) {
          if (raw is! Map) continue;
          final name = '${raw['name'] ?? ''}';
          final voiceLocale = '${raw['locale'] ?? ''}';
          if (!voiceLocale.toLowerCase().startsWith(languageCode)) continue;
          final quality = '${raw['quality'] ?? ''}'.toLowerCase();
          var score = 0;
          if (quality.contains('premium') || name.contains('Premium')) score = 3;
          if (quality.contains('enhanced') || name.contains('Mejorada') || name.contains('Enhanced')) {
            score = score > 2 ? score : 2;
          }
          if (voiceLocale.replaceAll('_', '-') == locale) score += 1;
          if (score > bestScore) {
            bestScore = score;
            best = {'name': name, 'locale': voiceLocale};
          }
        }
        if (best != null && bestScore >= 2) await _tts.setVoice(best);
      }
    } catch (_) {}
  }

  Future<void> stopSpeaking() async {
    final pending = _playing;
    _playing = null;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  /// Para todo (al salir del modo conversación).
  Future<void> stopAll() async {
    await cancelListening();
    await stopSpeaking();
  }
}
