import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/common/helpers/restock_markdown.dart';

void main() {
  const base = TextStyle(fontSize: 16, color: Color(0xFF000000));

  group('buildInlineMarkdown', () {
    test('convierte **negrita** en un span con w700', () {
      final spans = buildInlineMarkdown('Pedido a **Café Global**', base);

      expect(spans.length, 2);
      expect(spans.first.text, 'Pedido a ');
      expect(spans.last.text, 'Café Global');
      expect(spans.last.style?.fontWeight, FontWeight.w700);
    });

    test('convierte *cursiva* y `código`', () {
      final spans = buildInlineMarkdown('*rápido* `uid`', base);

      expect(spans[0].style?.fontStyle, FontStyle.italic);
      expect(spans[0].text, 'rápido');
      expect(spans.last.style?.fontFamily, 'monospace');
      expect(spans.last.text, 'uid');
    });

    test('deja los marcadores sin pareja tal cual', () {
      final spans = buildInlineMarkdown('2 ** 3', base);

      expect(spans.length, 1);
      expect(spans.first.text, '2 ** 3');
    });
  });

  group('stripInlineMarkdown', () {
    test('quita los marcadores y deja el texto', () {
      expect(
        stripInlineMarkdown('Pedido a **Café Global** para *8* unidades'),
        'Pedido a Café Global para 8 unidades',
      );
    });
  });
}
