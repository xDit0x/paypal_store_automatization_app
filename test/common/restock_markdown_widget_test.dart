import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/common/helpers/restock_markdown.dart';

void main() {
  testWidgets('el markdown del agente se pinta en negrita', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Pedido a '),
                TextSpan(
                  text: 'Café Global',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Café Global'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
  });

  testWidgets('un texto con markdown no deja asteriscos en pantalla',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text.rich(
            TextSpan(
              children: buildInlineMarkdown(
                'He creado un pedido a **Café Global** para **Agua mineral 1.5L**.',
                const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('Café Global'), findsOneWidget);
  });
}
