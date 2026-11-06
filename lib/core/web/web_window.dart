// Helper para abrir URLs en el navegador de forma sincrona (evita el bloqueo
// de popups del navegador cuando la apertura se hace tras un await).
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Abre una ventana en blanco de forma sincrona y devuelve una referencia
/// para navegarla después. Solo funciona en web.
html.WindowBase? openBlankWindowSync() {
  return html.window.open('', '_blank');
}

/// Navega una ventana previamente abierta a la URL indicada.
void navigateWindow(html.WindowBase? window, String url) {
  if (window == null) return;
  try {
    window.location.href = url;
  } catch (_) {
    // Si la ventana se cerró, abrir en la misma pestaña.
    html.window.location.href = url;
  }
}

/// Cierra una ventana previamente abierta.
void closeWindow(html.WindowBase? window) {
  try {
    window?.close();
  } catch (_) {}
}
