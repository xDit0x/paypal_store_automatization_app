import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:store_automatization_app/core/configs/l10n/l10n.dart';

/// Idioma de la app.
///
/// El estado es el [Locale] elegido por el usuario, o `null` cuando está en
/// "Auto": en ese caso se usa el [Locale] del dispositivo. Se guarda con
/// hydrated_bloc, igual que el tema.
class LocaleCubit extends HydratedCubit<Locale?> {
  LocaleCubit() : super(null);

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

  @override
  Locale? fromJson(Map<String, dynamic> json) {
    final code = json['locale'];
    if (code is! String) return null;
    for (final locale in selectable) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(Locale? state) =>
      state == null ? null : <String, dynamic>{'locale': state.languageCode};
}
