/// Formato de importes y fechas según el idioma activo.
///
/// Se usa como extensión de [AppLocalizations] para que el formato siga al
/// Locale que el usuario ha elegido: `l10n.euros(12.5)` da "12,50 €" en
/// español y "€12.50" en inglés.
library;

import 'package:intl/intl.dart';

import 'package:store_automatization_app/l10n/app_localizations.dart';

extension RestockFormat on AppLocalizations {
  /// "145,00 €" (es) / "€145.00" (en).
  String euros(double value, [String currency = 'EUR']) =>
      NumberFormat.currency(
        locale: localeName,
        symbol: _symbol(currency),
        decimalDigits: 2,
      ).format(value);

  /// "212 €" (es) / "€212" (en); con decimales, el importe completo.
  String eurosShort(double value, [String currency = 'EUR']) {
    if (value == value.roundToDouble()) {
      return NumberFormat.currency(
        locale: localeName,
        symbol: _symbol(currency),
        decimalDigits: 0,
      ).format(value);
    }
    return euros(value, currency);
  }

  /// Solo el símbolo: "€".
  String currencySymbol([String currency = 'EUR']) => _symbol(currency);

  String _symbol(String currency) => switch (currency.toUpperCase()) {
        'EUR' => '€',
        'USD' => r'$',
        'GBP' => '£',
        _ => currency,
      };

  /// "lun, 19 oct" (es) / "Mon, Oct 19" (en).
  String shortDate(DateTime d) => DateFormat.MMMEd(localeName).format(d);

  /// "Hoy 07:02", "Ayer 18:10" o "12 oct".
  String relativeDate(DateTime? value) {
    if (value == null) return '';
    final d = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return dateToday(clock(d));
    if (diff == 1) return dateYesterday(clock(d));
    return DateFormat('d MMM', localeName).format(d);
  }

  /// "15:40".
  String clock(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Nombre del mes en curso: "octubre" / "October".
  String currentMonthName() =>
      DateFormat.MMMM(localeName).format(DateTime.now());
}
