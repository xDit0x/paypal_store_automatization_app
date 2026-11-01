import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voz del asistente: dictado (speech_to_text) y lectura (flutter_tts).
///
/// Todo va en try/catch: si el dispositivo no tiene micrófono o el permiso
/// se deniega, la app sigue funcionando por texto.
class VoiceService {
  VoiceService._();

  static final VoiceService instance = VoiceService._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _ready = false;
  void Function()? _onDone;
  void Function(String error)? _onError;

  /// Último error del dictado (por ejemplo "error_permission"), para avisar.
  String? lastError;

  bool get isListening => _stt.isListening;

  Future<bool> _init() async {
    // Si falló antes se reintenta: el usuario pudo conceder el permiso después.
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            final done = _onDone;
            _onDone = null;
            done?.call();
          }
        },
        onError: (error) {
          debugPrint('[voice] ${error.errorMsg}');
          lastError = error.errorMsg;
          final callback = _onError;
          _onError = null;
          callback?.call(error.errorMsg);
        },
      );
    } catch (error) {
      debugPrint('[voice] $error');
      lastError = '$error';
      _ready = false;
    }
    if (!_ready) lastError ??= 'error_permission';
    debugPrint('[voice] initialize -> $_ready (${lastError ?? 'ok'})');
    return _ready;
  }

  /// Empieza a escuchar. [onText] recibe el texto según se reconoce y
  /// `isFinal` = true al terminar la frase. Devuelve false si no hay voz.
  Future<bool> listen({
    required String languageCode,
    required void Function(String text, bool isFinal) onText,
    void Function()? onDone,
    void Function(String error)? onError,
  }) async {
    lastError = null;
    if (!await _init()) return false;
    await stopSpeaking();
    _onDone = onDone;
    _onError = onError;
    try {
      await _stt.listen(
        onResult: (SpeechRecognitionResult result) =>
            onText(result.recognizedWords, result.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: languageCode == 'en' ? 'en_US' : 'es_ES',
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
        ),
      );
      return true;
    } catch (error) {
      debugPrint('[voice] $error');
      lastError = '$error';
      _onDone = null;
      _onError = null;
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
  }

  /// Lee el texto (sin los ** de negrita).
  Future<void> speak(String text, String languageCode) async {
    final clean = text.replaceAll('**', '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(languageCode == 'en' ? 'en-US' : 'es-ES');
      await _tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);
      await _tts.speak(clean);
    } catch (error) {
      debugPrint('[voice] $error');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
