/// Formato de importes y fechas en español, sin depender de la
/// inicialización de locales de `intl`.
library;

/// 145.0 -> "145,00 €"
String euros(double value, [String currency = 'EUR']) =>
    '${value.toStringAsFixed(2).replaceAll('.', ',')} ${_symbol(currency)}';

/// 212.0 -> "212 €"; 38.4 -> "38,40 €"
String eurosShort(double value, [String currency = 'EUR']) {
  if (value == value.roundToDouble()) {
    return '${value.round()} ${_symbol(currency)}';
  }
  return euros(value, currency);
}

String _symbol(String currency) => switch (currency.toUpperCase()) {
      'EUR' => '€',
      'USD' => r'$',
      'GBP' => '£',
      _ => currency,
    };

const _weekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// "Lunes 19 oct"
String shortDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "15:40"
String clock(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "Hoy 07:02", "Ayer 18:10" o "12 oct".
String relativeDate(DateTime? value) {
  if (value == null) return '';
  final d = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoy ${clock(d)}';
  if (diff == 1) return 'Ayer ${clock(d)}';
  return '${d.day} ${_months[d.month - 1]}';
}

/// Nombre del mes en curso: "octubre".
String currentMonthName() {
  const names = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return names[DateTime.now().month - 1];
}
