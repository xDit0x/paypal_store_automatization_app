import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Sonidos de interfaz de Restock.
///
/// No hay ficheros de audio: cada sonido se sintetiza al arrancar y se carga en
/// memoria como WAV. El instrumento es un timbal, y suena a timbal por tres
/// cosas que un tono con caída no tiene:
///
///  * modos inarmónicos (1, 1'5, 2, 2'44…), no solo la fundamental;
///  * la afinación cae unos céntimos justo después del golpe;
///  * un golpe de maza corto y filtrado, que es el "toc" del parche.
///
/// El sobre va **dentro de las muestras** a propósito. SoLoud tiene un único
/// fader de volumen por voz: si se programa el ataque con `fadeScheduled` y
/// después la caída, la segunda llamada reemplaza a la primera y el sonido se
/// queda mudo. Generar el sobre en el buffer evita ese problema y permite una
/// caída exponencial por parcial.
enum RSound {
  /// Toque de un botón o de una pestaña.
  tap,

  /// Aviso neutro: mensaje del agente, dato guardado.
  message,

  /// Algo salió bien.
  success,

  /// Algo no salió: suena grave y descendente, nunca estridente.
  warning,
}

/// Un golpe de maza: nota base del parche y cuándo entra.
class _Hit {
  const _Hit(this.freq, {this.at = Duration.zero, this.gain = 1});

  final double freq;
  final Duration at;
  final double gain;
}

/// Receta de un sonido.
class _Preset {
  const _Preset({
    required this.hits,
    required this.peak,
    required this.attack,
    required this.length,
    this.decay = 3.4,
    this.bend = 0.02,
    this.strike = 0.14,
  });

  final List<_Hit> hits;

  /// Volumen máximo del sonido ya renderizado, antes del volumen maestro.
  final double peak;

  /// Entrada en rampa: sin esto, la onda empieza de golpe y chasquea.
  final Duration attack;

  /// Cuánto aguanta la fundamental.
  final Duration length;

  /// Cuántas constantes de tiempo caben en [length]. Más alto = más seco.
  final double decay;

  /// Cuánto cae la afinación tras el golpe, en tanto por uno. Es lo que da la
  /// sensación de parche y no de nota fija.
  final double bend;

  /// Peso del golpe de maza respecto a la fundamental.
  final double strike;
}

class RestockSounds {
  RestockSounds._();

  static final RestockSounds instance = RestockSounds._();

  static const int _sampleRate = 44100;

  /// Volumen general. Los picos de cada sonido ya son bajos de por sí.
  static const double _master = 0.9;

  /// Sin esto, dos toques muy seguidos se solapan y suena a traba.
  static const Duration _tapGap = Duration(milliseconds: 70);

  /// La caída final dura esto y llega a cero exacto: así no hay chasquido.
  static const double _tail = 0.012;

  /// Cómo cae la afinación tras el golpe: rápido al principio y luego estable.
  static const double _bendTime = 0.025;

  /// Modos del parche, como (ratio de frecuencia, peso, factor de caída). Los
  /// agudos se apagan antes que la fundamental, igual que en un timbal real.
  static const List<(double, double, double)> _partials = [
    (1.00, 1.00, 1.00),
    (1.50, 0.55, 0.72),
    (2.00, 0.42, 0.58),
    (2.44, 0.24, 0.44),
    (3.00, 0.14, 0.34),
    (4.00, 0.07, 0.26),
  ];

  static const Map<RSound, _Preset> _presets = {
    // Un golpe solo en sol grave (98 Hz): el "tok" de un botón.
    RSound.tap: _Preset(
      hits: [_Hit(98.00)],
      peak: 0.26,
      attack: Duration(milliseconds: 6),
      length: Duration(milliseconds: 170),
      decay: 4.4,
    ),
    // Sol y su quinta: dos golpes suaves, sin urgencia.
    RSound.message: _Preset(
      hits: [
        _Hit(98.00),
        _Hit(146.83, at: Duration(milliseconds: 110), gain: 0.85),
      ],
      peak: 0.26,
      attack: Duration(milliseconds: 8),
      length: Duration(milliseconds: 300),
      decay: 3.6,
    ),
    // Sol, si y re: el acorde mayor que sube, redondo y corto.
    RSound.success: _Preset(
      hits: [
        _Hit(98.00),
        _Hit(123.47, at: Duration(milliseconds: 95)),
        _Hit(146.83, at: Duration(milliseconds: 190)),
      ],
      peak: 0.28,
      attack: Duration(milliseconds: 10),
      length: Duration(milliseconds: 420),
      decay: 3.4,
    ),
    // Sol que cae a re grave: "no ha podido ser", sin alarma.
    RSound.warning: _Preset(
      hits: [
        _Hit(98.00),
        _Hit(73.42, at: Duration(milliseconds: 140)),
      ],
      peak: 0.24,
      attack: Duration(milliseconds: 12),
      length: Duration(milliseconds: 460),
      decay: 3.0,
      // Más maza y una caída de afinación mayor: así suena a "se acabó".
      bend: 0.028,
      strike: 0.18,
    ),
  };

  final Map<RSound, AudioSource> _sources = {};

  bool _enabled = true;
  bool _ready = false;
  bool _warming = false;
  DateTime? _lastTap;

  bool get enabled => _enabled;

  /// Se apaga en los ajustes. Corta lo que esté sonando para que el silencio
  /// sea inmediato.
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    if (!value) stopAll();
  }

  /// Sintetiza y carga los sonidos. Se llama una vez al arrancar: son cuatro
  /// buffers diminutos y así el primer toque no paga la síntesis.
  Future<void> warmUp() async {
    if (_ready || !SoLoud.instance.isInitialized) return;
    _ready = true;

    try {
      for (final MapEntry(key: sound, value: preset) in _presets.entries) {
        final source = await SoLoud.instance.loadMem(
          '${sound.name}.wav',
          _render(preset),
        );
        _sources[sound] = source;
      }
    } catch (error) {
      // Sin audio la app tiene que seguir funcionando.
      debugPrint('No se pudieron preparar los sonidos: $error');
      _ready = false;
    }
  }

  /// Reproduce [sound] si los ajustes lo permiten.
  ///
  /// Nunca lanza: un fallo de audio no puede tumbar la pulsación de un botón.
  void play(RSound sound) {
    if (!_enabled) return;

    // En web el motor puede arrancar antes de que el navegador deje sonar
    // (política de autoplay). El primer toque del usuario es el permiso: se
    // aprovecha para reintentar y, a partir del segundo, ya suena.
    if (!_ready || !SoLoud.instance.isInitialized) {
      if (kIsWeb) unawaited(_retryWarmUp());
      return;
    }

    if (sound == RSound.tap) {
      final now = DateTime.now();
      final last = _lastTap;
      if (last != null && now.difference(last) < _tapGap) return;
      _lastTap = now;
    }

    final source = _sources[sound];
    if (source == null) return;

    try {
      SoLoud.instance.play(source, volume: _master);
    } catch (error) {
      debugPrint('No se pudo reproducir $sound: $error');
    }
  }

  Future<void> _retryWarmUp() async {
    if (_warming) return;
    _warming = true;
    try {
      if (!SoLoud.instance.isInitialized) await SoLoud.instance.init();
      await warmUp();
    } catch (error) {
      debugPrint('No se pudo arrancar el audio: $error');
    } finally {
      _warming = false;
    }
  }

  /// Corta todo lo que esté sonando (al desactivar los sonidos o al salir).
  void stopAll() {
    if (!SoLoud.instance.isInitialized) return;
    try {
      SoLoud.instance.stopAll();
    } catch (error) {
      debugPrint('No se pudieron parar los sonidos: $error');
    }
  }

  /// Libera los buffers generados.
  Future<void> dispose() async {
    stopAll();
    for (final source in _sources.values) {
      try {
        await SoLoud.instance.disposeSource(source);
      } catch (error) {
        debugPrint('No se pudo liberar un sonido: $error');
      }
    }
    _sources.clear();
    _ready = false;
  }

  /// El WAV que se carga en SoLoud para [sound].
  ///
  /// Solo para tests: comprobar que el buffer no es silencio y que empieza y
  /// acaba en cero no se puede hacer a oído.
  @visibleForTesting
  Uint8List renderWav(RSound sound) => _render(_presets[sound]!);

  /// Mezcla los golpes y devuelve un WAV PCM 16 bits mono listo para SoLoud.
  Uint8List _render(_Preset preset) {
    final attack = _samples(preset.attack);
    final length = _samples(preset.length);
    final total = preset.hits.fold<int>(0, (max, hit) {
      final end = _samples(hit.at) + length;
      return end > max ? end : max;
    });

    final mix = Float64List(total);
    // Semilla fija: el golpe de maza suena igual en cada arranque.
    final random = math.Random(7);

    for (final hit in preset.hits) {
      final start = _samples(hit.at);

      for (final (ratio, weight, falloff) in _partials) {
        final tau = (length / _sampleRate) / preset.decay * falloff;
        final freq = hit.freq * ratio;
        var phase = 0.0;

        for (var i = 0; i < length && start + i < total; i++) {
          final t = i / _sampleRate;
          // La afinación cae tras el golpe y se asienta en unos milisegundos.
          final glide = 1 - preset.bend * (1 - math.exp(-t / _bendTime));
          phase += 2 * math.pi * freq * glide / _sampleRate;
          mix[start + i] +=
              hit.gain *
              weight *
              _envelope(i, length, attack, tau) *
              math.sin(phase);
        }
      }

      if (preset.strike > 0) {
        _addStrike(mix, start, hit.gain * preset.strike, random);
      }
    }

    // Normalizar al pico pedido: así el volumen de cada sonido es predecible
    // aunque el acorde sume varios golpes.
    var maxAbs = 0.0;
    for (final sample in mix) {
      final abs = sample.abs();
      if (abs > maxAbs) maxAbs = abs;
    }
    final scale = maxAbs == 0 ? 0.0 : preset.peak / maxAbs;

    return _wav(mix, scale);
  }

  /// Golpe de maza: ruido muy corto y pasado por un filtro grave. Es lo que
  /// hace que se oiga "golpe" y no solo tono, sin aportar agudos ásperos.
  void _addStrike(Float64List mix, int start, double gain, math.Random random) {
    const duration = 0.030;
    final count = (duration * _sampleRate).round();
    final smoothing = 1 - math.exp(-2 * math.pi * 900 / _sampleRate);
    // Entrada de 2 ms: una maza real no golpea instantáneamente, y sin esto
    // la primera muestra salta y se oye un chasquido.
    final attack = math.max(1, (0.002 * _sampleRate).round());

    final burst = Float64List(count);
    var low = 0.0;
    var peak = 0.0;
    for (var i = 0; i < count; i++) {
      final white = random.nextDouble() * 2 - 1;
      low += smoothing * (white - low);
      final ramp = i >= attack
          ? 1.0
          : 0.5 - 0.5 * math.cos(math.pi * i / attack);
      burst[i] = low * ramp * math.exp(-(i / _sampleRate) / 0.007);
      final abs = burst[i].abs();
      if (abs > peak) peak = abs;
    }
    if (peak == 0) return;

    for (var i = 0; i < count && start + i < mix.length; i++) {
      mix[start + i] += burst[i] / peak * gain;
    }
  }

  /// Ataque en rampa, caída exponencial y cierre a cero exacto.
  double _envelope(int i, int length, int attack, double tau) {
    final t = i / _sampleRate;

    final attackPart = i >= attack
        ? 1.0
        : 0.5 - 0.5 * math.cos(math.pi * i / attack);

    final decayPart = math.exp(-t / tau);

    final tailSamples = math.max(1, (_tail * _sampleRate).round());
    final remaining = length - 1 - i;
    final tailPart = remaining >= tailSamples
        ? 1.0
        : 0.5 - 0.5 * math.cos(math.pi * remaining / tailSamples);

    return attackPart * decayPart * tailPart;
  }

  Uint8List _wav(Float64List samples, double scale) {
    const header = 44;
    const channels = 1;
    const bitsPerSample = 16;
    const bytesPerSample = bitsPerSample ~/ 8;

    final dataLength = samples.length * bytesPerSample;
    final data = ByteData(header + dataLength);

    void ascii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        data.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, header - 8 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little); // tamaño del bloque fmt
    data.setUint16(20, 1, Endian.little); // PCM sin comprimir
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, _sampleRate, Endian.little);
    data.setUint32(28, _sampleRate * channels * bytesPerSample, Endian.little);
    data.setUint16(32, channels * bytesPerSample, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, dataLength, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      final value = (samples[i] * scale * 32767).clamp(-32768.0, 32767.0);
      data.setInt16(header + i * bytesPerSample, value.round(), Endian.little);
    }

    return data.buffer.asUint8List();
  }

  int _samples(Duration duration) =>
      (duration.inMicroseconds * _sampleRate / 1000000).round();
}
