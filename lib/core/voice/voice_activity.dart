import 'dart:math' as math;
import 'dart:typed_data';

/// Detección de voz para el modo conversación: decide cuándo el dueño
/// empezó a hablar y cuándo terminó (silencio), sin pulsar botones.
///
/// Trabaja con audio PCM de 16 bits mono. Es puro (sin plugins) para poder
/// probarlo con tests.
enum VadEvent { none, speechStarted, endOfUtterance, noSpeechTimeout, maxLength }

class VoiceActivity {
  VoiceActivity({
    this.sampleRate = 16000,
    this.calibration = const Duration(milliseconds: 350),
    this.minSpeech = const Duration(milliseconds: 160),
    this.silenceToEnd = const Duration(milliseconds: 1100),
    this.noSpeechTimeout = const Duration(seconds: 9),
    this.maxUtterance = const Duration(seconds: 30),
    this.minThreshold = 250,
    this.maxNoiseFloor = 700,
  });

  final int sampleRate;
  final Duration calibration;
  final Duration minSpeech;
  final Duration silenceToEnd;
  final Duration noSpeechTimeout;
  final Duration maxUtterance;

  /// Umbral mínimo de volumen (RMS en unidades de 16 bits).
  final double minThreshold;

  /// Tope del ruido medido: si el dueño habla o queda eco de la voz durante
  /// la calibración, el umbral no se dispara.
  final double maxNoiseFloor;

  Duration _elapsed = Duration.zero;
  Duration _voiced = Duration.zero;
  Duration _silence = Duration.zero;
  double _noiseSum = 0;
  int _noiseCount = 0;
  double _floor = 0;
  double _peak = 0;
  bool _speaking = false;

  bool get hadSpeech => _speaking;

  /// Volumen más alto oído en este turno (para diagnóstico).
  double get peakLevel => _peak;

  double get threshold => math.max(minThreshold, _floor * 2.6);

  Duration durationOf(int bytes) =>
      Duration(microseconds: (bytes ~/ 2) * 1000000 ~/ sampleRate);

  VadEvent feed(Uint8List chunk) {
    final length = durationOf(chunk.length);
    final level = rms(chunk);
    _elapsed += length;
    _peak = math.max(_peak, level);

    // Los primeros milisegundos sirven para medir el ruido de fondo.
    if (_elapsed <= calibration && !_speaking) {
      _noiseSum += level;
      _noiseCount++;
      _floor = math.min(_noiseSum / _noiseCount, maxNoiseFloor);
      return VadEvent.none;
    }

    final loud = level > threshold;
    if (!_speaking) {
      // Mientras no habla, el ruido medido puede bajar si era demasiado alto.
      if (!loud && level < _floor) _floor = _floor * 0.9 + level * 0.1;
      // La voz sube y baja: un bajón resta tiempo, pero no reinicia la cuenta.
      if (loud) {
        _voiced += length;
      } else {
        final rest = _voiced - length ~/ 2;
        _voiced = rest.isNegative ? Duration.zero : rest;
      }
      if (_voiced >= minSpeech) {
        _speaking = true;
        _silence = Duration.zero;
        return VadEvent.speechStarted;
      }
      if (_elapsed >= noSpeechTimeout) return VadEvent.noSpeechTimeout;
      return VadEvent.none;
    }

    _silence = loud ? Duration.zero : _silence + length;
    if (_silence >= silenceToEnd) return VadEvent.endOfUtterance;
    if (_elapsed >= maxUtterance) return VadEvent.maxLength;
    return VadEvent.none;
  }
}

/// Volumen medio (RMS) de un trozo PCM de 16 bits little-endian.
double rms(Uint8List chunk) {
  final samples = chunk.length ~/ 2;
  if (samples == 0) return 0;
  final data = ByteData.sublistView(chunk);
  var sum = 0.0;
  for (var i = 0; i < samples; i++) {
    final s = data.getInt16(i * 2, Endian.little).toDouble();
    sum += s * s;
  }
  return math.sqrt(sum / samples);
}

/// Envuelve PCM de 16 bits mono en un WAV (lo que entiende Whisper).
Uint8List buildWav(Uint8List pcm, {int sampleRate = 16000}) {
  final header = ByteData(44);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      header.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);

  return (BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List())
        ..add(pcm))
      .toBytes();
}
