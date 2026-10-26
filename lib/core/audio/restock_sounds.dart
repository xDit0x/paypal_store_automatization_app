import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Sonidos de interfaz de Restock.
///
/// No hay ficheros de audio: cada sonido se sintetiza al arrancar (sinusoides
/// con armónicos y un sobre de ataque/caída) y se carga en memoria como WAV.
///
/// El sobre va **dentro de las muestras** a propósito. SoLoud tiene un único
/// fader de volumen por voz: si se programa el ataque con `fadeScheduled` y
/// después la caída, la segunda llamada reemplaza a la primera y el sonido se
/// queda mudo. Generar el sobre en el buffer evita ese problema y da una caída
/// exponencial, que es lo que hace que suene a campana y no a pitido.
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

/// Una nota del acorde: frecuencia y cuándo entra.
class _Note {
  const _Note(this.freq, {this.at = Duration.zero});

  final double freq;
  final Duration at;
}

/// Receta de un sonido.
class _Preset {
  const _Preset({
    required this.notes,
    required this.peak,
    required this.attack,
    required this.length,
    this.decay = 3.2,
  });

  final List<_Note> notes;

  /// Volumen máximo del sonido ya renderizado, antes del volumen maestro.
  final double peak;

  /// Entrada en rampa: sin esto, la onda empieza de golpe y chasquea.
  final Duration attack;

  /// Duración de cada nota que no defina la suya.
  final Duration length;

  /// Cuántas constantes de tiempo caben en [length]. Más alto = caída más
  /// rápida, más seco.
  final double decay;
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

  static const Map<RSound, _Preset> _presets = {
    // Do agudo y muy corto: el "tok" de un botón.
    RSound.tap: _Preset(
      notes: [_Note(523.25)],
      peak: 0.22,
      attack: Duration(milliseconds: 4),
      length: Duration(milliseconds: 110),
      decay: 4.5,
    ),
    // Sol y re: una campanita suave, sin urgencia.
    RSound.message: _Preset(
      notes: [
        _Note(392.00),
        _Note(587.33, at: Duration(milliseconds: 95)),
      ],
      peak: 0.22,
      attack: Duration(milliseconds: 8),
      length: Duration(milliseconds: 280),
    ),
    // Do, mi, sol ascendente: acorde mayor, alegre pero corto.
    RSound.success: _Preset(
      notes: [
        _Note(523.25),
        _Note(659.25, at: Duration(milliseconds: 80)),
        _Note(783.99, at: Duration(milliseconds: 160)),
      ],
      peak: 0.24,
      attack: Duration(milliseconds: 10),
      length: Duration(milliseconds: 340),
    ),
    // Fa y re descendente, más lento: "no ha podido ser", sin alarma.
    RSound.warning: _Preset(
      notes: [
        _Note(349.23),
        _Note(293.66, at: Duration(milliseconds: 120)),
      ],
      peak: 0.20,
      attack: Duration(milliseconds: 14),
      length: Duration(milliseconds: 380),
      decay: 2.6,
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

  /// Mezcla las notas y devuelve un WAV PCM 16 bits mono listo para SoLoud.
  Uint8List _render(_Preset preset) {
    final attack = _samples(preset.attack);
    final length = _samples(preset.length);
    final total = preset.notes.fold<int>(0, (max, note) {
      final end = _samples(note.at) + length;
      return end > max ? end : max;
    });

    final mix = Float64List(total);
    for (final note in preset.notes) {
      final start = _samples(note.at);
      final tau = (length / _sampleRate) / preset.decay;

      for (var i = 0; i < length && start + i < total; i++) {
        final t = i / _sampleRate;
        final phase = 2 * math.pi * note.freq * t;
        // Fundamental dominante y dos armónicos suaves: da cuerpo de campana
        // sin volverse metálico.
        final wave =
            math.sin(phase) +
            0.18 * math.sin(2 * phase) +
            0.05 * math.sin(3 * phase);
        mix[start + i] += _envelope(i, length, attack, tau) * wave;
      }
    }

    // Normalizar al pico pedido: así el volumen de cada sonido es predecible
    // aunque el acorde sume varias notas.
    var maxAbs = 0.0;
    for (final sample in mix) {
      final abs = sample.abs();
      if (abs > maxAbs) maxAbs = abs;
    }
    final scale = maxAbs == 0 ? 0.0 : preset.peak / maxAbs;

    return _wav(mix, scale);
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
