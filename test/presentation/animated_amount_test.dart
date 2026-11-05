import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/presentation/widgets/stocky/animated_amount.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

int _shown(WidgetTester tester) {
  final text = tester.widget<Text>(find.byType(Text));
  return int.parse(text.data!);
}

void main() {
  testWidgets('el importe sube desde 0 hasta su valor', (tester) async {
    await tester.pumpWidget(
      _app(
        AnimatedAmount(
          value: 100,
          builder: (context, value) => Text('${value.round()}'),
        ),
      ),
    );

    // Empieza en cero y va subiendo.
    expect(_shown(tester), 0);
    await tester.pump(const Duration(milliseconds: 300));
    final mid = _shown(tester);
    expect(mid, greaterThan(0));
    expect(mid, lessThan(100));

    await tester.pumpAndSettle();
    expect(_shown(tester), 100);
  });

  testWidgets('al cambiar el valor anima desde el que se veía', (tester) async {
    var value = 40.0;
    late StateSetter setOuter;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return AnimatedAmount(
              value: value,
              builder: (context, v) => Text('${v.round()}'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_shown(tester), 40);

    setOuter(() => value = 120);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Ni se reinicia a 0 ni salta de golpe al nuevo valor.
    final mid = _shown(tester);
    expect(mid, greaterThan(40));
    expect(mid, lessThan(120));

    await tester.pumpAndSettle();
    expect(_shown(tester), 120);
  });

  testWidgets('con las animaciones desactivadas muestra el valor final', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AnimatedAmount(
            value: 250,
            builder: (context, value) => Text('${value.round()}'),
          ),
        ),
      ),
    );

    expect(_shown(tester), 250);
  });
}
