import 'package:flutter/widgets.dart';

import 'package:store_automatization_app/l10n/app_localizations.dart';

// Reexporta la clase generada para no importar dos ficheros cada vez.
export 'package:store_automatization_app/l10n/app_localizations.dart';

/// Acceso corto a los textos traducidos: `context.l10n.reglasTitle`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Resuelve un [Locale] a sus textos.
///
/// Sigue el mismo criterio que Flutter: si el idioma no está soportado se
/// usa el primero de la lista. Sirve para el código que no tiene un
/// [BuildContext] (el cubit, por ejemplo).
AppLocalizations l10nFor(Locale locale) {
  final supported = AppLocalizations.supportedLocales;
  final match = supported.firstWhere(
    (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    orElse: () => supported.first,
  );
  return lookupAppLocalizations(match);
}

/// El [Locale] del dispositivo que la app debe usar cuando el usuario no ha
/// elegido ninguno a mano.
Locale deviceLocale() =>
    WidgetsBinding.instance.platformDispatcher.locale;
