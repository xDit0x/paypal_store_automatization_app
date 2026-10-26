import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Sonidos de interfaz de Restock.
///
/// No hay ficheros de audio: cada sonido es una sinusoide generada por SoLoud
/// a la que se le pinta un sobre (ataque corto, cuerpo y caída larga). Eso es
/// lo que los hace "cómodos": tonos graves, volumen bajo y sin cortes secos,
/// que es lo que convierte un pitido en un golpe de madera.
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

/// Una nota del acorde: frecuencia y cuándo entra respecto al inicio.
class _Note {
  const _Note(this.freq, {this.at = Duration.zero});

  final double freq;
  final Duration at;
}

/// Receta de un sonido.
class _Preset {
  const _Preset(
    this.notes, {
    required this.peak,
    this.attack = const Duration(milliseconds: 10),
    this.hold = const Duration(milliseconds: 70),
    this.release = const Duration(milliseconds: 180),
  });

  final List<_Note> notes;

  /// Volumen máximo de cada nota, antes del volumen maestro.
  final double peak;
  final Duration attack;
  final Duration hold;
  final Duration release;

  Duration get length => attack + hold + release;
}

class RestockSounds {
  RestockSounds._();

  static final RestockSounds instance = RestockSounds._();

  /// Volumen general. Los picos de cada sonido son deliberadamente bajos.
  static const double _master = 0.7;

  /// Sin esto, dos toques muy seguidos se solapan y suena a traba.
  static const Duration _tapGap = Duration(milliseconds: 70);

  static const Map<RSound, _Preset> _presets = {
    // Do agudo muy corto: el "tok" de un botón.
    RSound.tap: _Preset(
      [_Note(523.25)],
      peak: 0.09,
      attack: Duration(milliseconds: 5),
      hold: Duration(milliseconds: 18),
      release: Duration(milliseconds: 65),
    ),
    // Sol y re: una campanita suave, sin urgencia.
    RSound.message: _Preset(
      [_Note(392.00), _Note(587.33, at: Duration(milliseconds: 90))],
      peak: 0.11,
      hold: Duration(milliseconds: 60),
      release: Duration(milliseconds: 170),
    ),
    // Do, mi, sol ascendente: acorde mayor, alegre pero corto.
    RSound.success: _Preset(
      [
        _Note(523.25),
        _Note(659.25, at: Duration(milliseconds: 85)),
        _Note(783.99, at: Duration(milliseconds: 170)),
      ],
      peak: 0.10,
      attack: Duration(milliseconds: 12),
      hold: Duration(milliseconds: 90),
      release: Duration(milliseconds: 230),
    ),
    // Fa y re descendente, más lento: "no ha podido ser", sin alarma.
    RSound.warning: _Preset(
      [_Note(349.23), _Note(293.66, at: Duration(milliseconds: 110))],
      peak: 0.10,
      attack: Duration(milliseconds: 16),
      hold: Duration(milliseconds: 110),
      release: Duration(milliseconds: 250),
    ),
  };

  /// Una fuente por frecuencia: SoLoud afina la onda, no la reproducción, así
  /// que cada nota necesita su propia fuente y se reutiliza entre sonidos.
  final Map<double, AudioSource> _sources = {};

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

  /// Carga las ondas. Se llama una vez al arrancar: generar cuatro o seis
  /// notas es instantáneo, pero hacerlo en el primer toque añadiría retraso.
  Future<void> warmUp() async {
    if (_ready || !SoLoud.instance.isInitialized) return;
    _ready = true;

    try {
      for (final freq in _frequencies) {
        final source = await SoLoud.instance.loadWaveform(
          WaveForm.sin, // la onda más limpia: sin armónicos ásperos
          false, // superWave: no hace falta, sería un coro tembloroso
          1.0,
          0.0,
        );
        SoLoud.instance.setWaveformFreq(source, freq);
        _sources[freq] = source;
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

    final preset = _presets[sound];
    if (preset == null) return;

    try {
      final start = SoLoud.instance.getEngineTime();
      for (final note in preset.notes) {
        final source = _sources[note.freq];
        if (source == null) continue;

        final at = start + note.at;
        final handle = SoLoud.instance.playScheduled(
          source,
          at,
          volume: 0, // entra en silencio y se sube con el ataque
          duration: preset.length,
        );

        // Ataque: de 0 al pico en unos milisegundos, sin chasquido.
        SoLoud.instance.fadeScheduled(
          handle,
          at,
          preset.peak * _master,
          preset.attack,
        );
        // Caída y parada: el final se apaga en vez de cortarse.
        SoLoud.instance.fadeScheduled(
          handle,
          at + preset.attack + preset.hold,
          0,
          preset.release,
          thenStop: true,
        );
      }
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

  /// Libera las ondas generadas.
  Future<void> dispose() async {
    stopAll();
    for (final source in _sources.values) {
      try {
        await SoLoud.instance.disposeSource(source);
      } catch (error) {
        debugPrint('No se pudo liberar una onda: $error');
      }
    }
    _sources.clear();
    _ready = false;
  }

  Iterable<double> get _frequencies sync* {
    final seen = <double>{};
    for (final preset in _presets.values) {
      for (final note in preset.notes) {
        if (seen.add(note.freq)) yield note.freq;
      }
    }
  }
}
