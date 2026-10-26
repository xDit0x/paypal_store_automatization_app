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
}
