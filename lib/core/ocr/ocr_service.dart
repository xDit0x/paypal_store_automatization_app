import 'dart:io';

import 'package:flutter/services.dart';

/// OCR local del albarán.
///
/// Usa Apple Vision en iOS y ML Kit en Android a través de un canal nativo.
/// Todo el procesamiento ocurre en el dispositivo: la foto nunca se sube.
class OcrService {
  const OcrService();

  static const MethodChannel _channel = MethodChannel(
    'store_automatization_app/ocr',
  );

  /// Devuelve el texto detectado en la imagen indicada.
  ///
  /// Lanza una [PlatformException] si el reconocimiento falla.
  Future<String> recognizeText(String imagePath) async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      throw UnsupportedError(
        'El OCR solo está disponible en iOS y Android.',
      );
    }

    final text = await _channel.invokeMethod<String>('recognizeText', {
      'path': imagePath,
    });

    return text ?? '';
  }
}
