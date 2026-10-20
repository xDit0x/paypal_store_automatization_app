import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/core/configs/l10n/app_error_l10n.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/l10n/app_localizations.dart';

/// Evita que un código nuevo se quede sin texto en algún idioma: si falta la
/// clave, el ARB no lo genera y este test no compila; si el texto está vacío o
/// sin traducir, falla aquí.
void main() {
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('cada código de error tiene texto en español y en inglés', () {
    for (final code in AppErrorCode.values) {
      final error = AppError(code, subject: 'PRD-1');
      final esText = es.describe(error);
      final enText = en.describe(error);

      expect(esText.trim(), isNotEmpty, reason: '${code.name} (es)');
      expect(enText.trim(), isNotEmpty, reason: '${code.name} (en)');
    }
  });

  test('el detalle del servidor manda en el cuerpo del aviso', () {
    const withDetail = AppError(
      AppErrorCode.orderApproveFailed,
      detail: 'El pedido supera el máximo por pedido.',
    );
    const withoutDetail = AppError(AppErrorCode.orderApproveFailed);

    expect(
      es.describeDetail(withDetail),
      'El pedido supera el máximo por pedido.',
    );
    expect(es.describeDetail(withoutDetail), es.errorOrderApproveFailed);
    expect(
      en.describeDetail(withDetail),
      'El pedido supera el máximo por pedido.',
    );
  });

  test('los códigos con dato interpolan el sujeto', () {
    expect(
      en.describe(AppError(AppErrorCode.productNotFound, subject: 'PRD-9')),
      contains('PRD-9'),
    );
  });
}
