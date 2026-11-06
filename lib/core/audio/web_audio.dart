// Helper de audio para web. En plataformas nativas este archivo no se importa.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Reproduce bytes WAV en el navegador usando el elemento <audio>.
Future<void> playWavBytesWeb(Uint8List bytes, double volume) async {
  final blob = html.Blob([bytes], 'audio/wav');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final audio = html.AudioElement(url);
  audio.volume = volume.clamp(0.0, 1.0);
  try {
    await audio.play();
  } finally {
    audio.onEnded.listen((_) => html.Url.revokeObjectUrl(url));
  }
}
