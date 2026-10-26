import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/core/audio/restock_sounds.dart';

/// Todo botón de la app llama a `play`, así que estos casos no son un lujo:
/// sin tarjeta de sonido (tests, navegador, plataforma sin soporte) el motor
/// no está inicializado y aun así la interfaz tiene que responder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sin motor de audio no lanza ni prepara nada', () async {
    await RestockSounds.instance.warmUp();
    RestockSounds.instance.play(RSound.tap);
    RestockSounds.instance.play(RSound.success);
    RestockSounds.instance.stopAll();
  });

  test('el interruptor corta el sonido aunque no haya motor', () {
    RestockSounds.instance.enabled = false;
    expect(RestockSounds.instance.enabled, isFalse);

    RestockSounds.instance.play(RSound.warning);

    RestockSounds.instance.enabled = true;
    expect(RestockSounds.instance.enabled, isTrue);
  });

  group('WAV generado', () {
    /// Muestras PCM 16 bits del buffer, sin la cabecera.
    List<int> samples(RSound sound) {
      final bytes = RestockSounds.instance.renderWav(sound);
      final data = ByteData.sublistView(bytes);
      final count = (bytes.length - 44) ~/ 2;
      return [
        for (var i = 0; i < count; i++)
          data.getInt16(44 + i * 2, Endian.little),
      ];
    }

    test('es un WAV PCM 16 bits mono a 44,1 kHz', () {
      final bytes = RestockSounds.instance.renderWav(RSound.tap);
      final data = ByteData.sublistView(bytes);
      String text(int offset) =>
          String.fromCharCodes(bytes.sublist(offset, offset + 4));

      expect(text(0), 'RIFF');
      expect(text(8), 'WAVE');
      expect(text(12), 'fmt ');
      expect(data.getUint16(20, Endian.little), 1, reason: 'PCM sin comprimir');
      expect(data.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(data.getUint32(24, Endian.little), 44100);
      expect(data.getUint16(34, Endian.little), 16);
      expect(data.getUint32(40, Endian.little), bytes.length - 44);
    });

    test('no es silencio, pero empieza y acaba en cero', () {
      for (final sound in RSound.values) {
        final pcm = samples(sound);
        final peak = pcm.map((s) => s.abs()).reduce(math.max);

        expect(
          pcm.length,
          greaterThan(4000),
          reason: '$sound es demasiado corto',
        );
        expect(peak, greaterThan(3000), reason: '$sound sale mudo');
        expect(peak, lessThan(32767), reason: '$sound satura');
        // Sin esto el altavoz chasquea al empezar y al cortar.
        expect(
          pcm.first.abs(),
          lessThanOrEqualTo(1),
          reason: '$sound chasquea al empezar',
        );
        expect(
          pcm.last.abs(),
          lessThanOrEqualTo(1),
          reason: '$sound chasquea al acabar',
        );
      }
    });

    test('cada sonido se queda en su volumen, sin saturar al sumar notas', () {
      // Los picos de los presets. El acorde de "success" suma tres notas y aun
      // así tiene que caber en el mismo margen.
      const expected = {
        RSound.tap: 0.22,
        RSound.message: 0.22,
        RSound.success: 0.24,
        RSound.warning: 0.20,
      };

      for (final MapEntry(key: sound, value: peak) in expected.entries) {
        final pcm = samples(sound);
        final amplitude = pcm.map((s) => s.abs()).reduce(math.max) / 32767;
        expect(
          amplitude,
          closeTo(peak, 0.01),
          reason: '$sound debería quedarse en $peak',
        );
      }
    });
  });
}
