// Helper para navegación en web. Usa dart:html directamente para máxima
// compatibilidad con el navegador.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Navega el navegador a la URL indicada (misma pestaña).
void navigateToUrl(String url) {
  html.window.location.href = url;
}
