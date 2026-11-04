import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/app_language.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';

/// Idioma de la app.
///
/// El estado es el [Locale] elegido por el usuario, o `null` cuando está en
/// "Auto": en ese caso se usa el [Locale] del dispositivo. Se guarda con
/// hydrated_bloc, igual que el tema.
class LocaleCubit extends HydratedCubit<Locale?> {
  /// Idioma por defecto: inglés. El dueño puede cambiarlo a español desde
  /// el login o desde la pestaña Reglas.
  static const Locale defaultLocale = Locale('en');

  LocaleCubit() : super(defaultLocale) {
    // El idioma se publica al arrancar y también cada vez que cambia (al
    // restaurar el idioma guardado, por ejemplo).
    AppLanguage.update(effectiveLocale);
  }

  /// Idiomas que se pueden elegir a mano (además de "Auto").
  static const List<Locale> selectable = <Locale>[
    Locale('es'),
    Locale('en'),
  ];

  /// El idioma que se está usando ahora mismo.
  Locale get effectiveLocale => state ?? deviceLocale();

  /// Los textos del idioma activo.
  AppLocalizations get l10n => l10nFor(effectiveLocale);

  void updateLocale(Locale? locale) => emit(locale);

  /// Publica el idioma activo para el cliente HTTP (el servidor lo necesita
  /// en cada petición para responder en el mismo idioma).
  ///
  /// Se hace al emitir el estado para que también recoja el idioma guardado
  /// al arrancar.
  @override
  void emit(Locale? locale) {
    super.emit(locale);
    AppLanguage.update(effectiveLocale);
  }

  @override
  Locale? fromJson(Map<String, dynamic> json) {
    final code = json['locale'];
    if (code is! String) return defaultLocale;
    // "Auto" se guarda como tal: el idioma lo pone el dispositivo.
    if (code == 'auto') return null;
    for (final locale in selectable) {
      if (locale.languageCode == code) return locale;
    }
    return defaultLocale;
  }

  @override
  Map<String, dynamic>? toJson(Locale? state) => <String, dynamic>{
    'locale': state?.languageCode ?? 'auto',
  };
}
