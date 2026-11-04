import 'dart:ui' show Locale;

/// Idioma activo de la app, accesible fuera del árbol de widgets.
///
/// El servidor lo necesita en cada petición (para responder en el mismo
/// idioma), y el cliente HTTP se crea antes de que exista el árbol de
/// widgets, así que el idioma se guarda aquí.
class AppLanguage {
  AppLanguage._();

  static Locale _locale = const Locale('en');

  /// El idioma que se está usando ahora mismo.
  static Locale get locale => _locale;

  /// Código del idioma activo ('es' o 'en').
  static String get code => _locale.languageCode;

  /// Actualiza el idioma activo (lo llama el [LocaleCubit]).
  static void update(Locale locale) => _locale = locale;
}
