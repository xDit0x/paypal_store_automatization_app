import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/core/voice/voice_activity.dart';

/// 100 ms de audio a 16 kHz: silencio (amplitud 0) o "voz" (tono).
Uint8List _chunk(int amplitude) {
  final data = ByteData(1600 * 2);
  for (var i = 0; i < 1600; i++) {
    data.setInt16(i * 2, (amplitude * math.sin(i / 8)).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  test('detecta cuándo empiezas a hablar y cuándo te callas', () {
    final vad = VoiceActivity();
    final events = <VadEvent>[];
    for (var i = 0; i < 4; i++) {
      events.add(vad.feed(_chunk(30))); // ruido de fondo (calibración)
    }
    for (var i = 0; i < 10; i++) {
      events.add(vad.feed(_chunk(6000))); // 1 s hablando
    }
    for (var i = 0; i < 12; i++) {
      events.add(vad.feed(_chunk(30))); // 1,2 s callado
    }
    expect(events, contains(VadEvent.speechStarted));
    expect(events.last, VadEvent.endOfUtterance);
    expect(vad.hadSpeech, isTrue);
  });

  test('si no hablas en un rato, deja de escuchar', () {
    final vad = VoiceActivity(noSpeechTimeout: const Duration(seconds: 2));
    VadEvent last = VadEvent.none;
    for (var i = 0; i < 25 && last == VadEvent.none; i++) {
      last = vad.feed(_chunk(20));
    }
    expect(last, VadEvent.noSpeechTimeout);
    expect(vad.hadSpeech, isFalse);
  });

  test('un golpe corto no cuenta como voz', () {
    final vad = VoiceActivity();
    for (var i = 0; i < 4; i++) {
      vad.feed(_chunk(30));
    }
    expect(vad.feed(_chunk(8000)), VadEvent.none); // 100 ms
    expect(vad.feed(_chunk(30)), VadEvent.none);
    expect(vad.hadSpeech, isFalse);
  });

  test('WAV válido para Whisper', () {
    final wav = buildWav(Uint8List(3200));
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(wav.length, 44 + 3200);
    expect(ByteData.sublistView(wav).getUint32(24, Endian.little), 16000);
  });
}
