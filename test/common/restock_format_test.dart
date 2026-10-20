import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:store_automatization_app/common/helpers/restock_format.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('importes en español', () {
    expect(es.euros(145), contains('145,00'));
    expect(es.euros(145), contains('€'));
    expect(es.eurosShort(212), contains('212'));
    expect(es.eurosShort(12.5), contains('12,50'));
    expect(es.currencySymbol(), '€');
    expect(es.currencySymbol('USD'), r'$');
  });

  test('importes en inglés', () {
    expect(en.euros(145), '€145.00');
    expect(en.eurosShort(212), '€212');
    expect(en.eurosShort(12.5), '€12.50');
  });

  test('fechas y meses según el idioma', () {
    final d = DateTime(2026, 10, 19, 7, 2);

    expect(es.shortDate(d), 'lun, 19 oct');
    expect(en.shortDate(d), 'Mon, Oct 19');

    expect(es.currentMonthName(), 'octubre');
    expect(en.currentMonthName(), 'October');
  });

  test('"Hoy" y "Ayer" se traducen', () {
    final now = DateTime.now();
    expect(es.relativeDate(now), startsWith('Hoy '));
    expect(en.relativeDate(now), startsWith('Today '));

    final yesterday = now.subtract(const Duration(days: 1));
    expect(es.relativeDate(yesterday), startsWith('Ayer '));
    expect(en.relativeDate(yesterday), startsWith('Yesterday '));

    expect(es.relativeDate(null), '');
  });
}
