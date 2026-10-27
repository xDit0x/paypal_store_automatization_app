import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

Widget _app({required VoidCallback onAction}) => MaterialApp(
  theme: ThemeData.light(),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showRestockSnack(
          context,
          'No se pudo reenviar el correo.',
          tone: RSnackTone.warning,
          actionLabel: 'Reenviar correo',
          onAction: onAction,
        ),
        child: const Text('Mostrar aviso'),
      ),
    ),
  ),
);

void main() {
  testWidgets('un aviso de advertencia también muestra su acción', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(_app(onAction: () => tapped = true));

    await tester.tap(find.text('Mostrar aviso'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('No se pudo reenviar el correo.'), findsOneWidget);
    expect(find.text('Reenviar correo'), findsOneWidget);

    await tester.tap(find.text('Reenviar correo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tapped, isTrue);
  });
}
