import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/presentation/widgets/restock/carousel_nav_bar.dart';

/// Color de la píldora azul del dock.
Color _pillColor(WidgetTester tester) {
  final pill = find
      .descendant(
        of: find
            .descendant(
              of: find.byType(CarouselNavBar),
              matching: find.byType(Positioned),
            )
            .first,
        matching: find.byType(DecoratedBox),
      )
      .first;
  final box = tester.widget<DecoratedBox>(pill);
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  testWidgets('arrastrar el dock cambia la pestaña seleccionada', (tester) async {
    final controller = PageController();
    final dragged = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: CarouselNavBar(
                controller: controller,
                items: const [
                  NavItem('Inicio', Icons.home),
                  NavItem('Stock', Icons.inventory_2),
                  NavItem('Pedidos', Icons.receipt_long),
                  NavItem('Reglas', Icons.tune),
                  NavItem('Asistente', Icons.chat_bubble),
                ],
                onSelect: (_) {},
                onDragSelect: dragged.add,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(CarouselNavBar), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(dragged, isNotEmpty);
    expect(dragged.last, greaterThan(0));
  });

  testWidgets('al pulsar una pestaña se notifica la selección', (tester) async {
    final controller = PageController();
    int? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: CarouselNavBar(
                controller: controller,
                items: const [
                  NavItem('Inicio', Icons.home),
                  NavItem('Stock', Icons.inventory_2),
                  NavItem('Pedidos', Icons.receipt_long),
                ],
                onSelect: (index) => tapped = index,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Stock'));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('la píldora se aclara durante el trayecto y vuelve al azul',
      (tester) async {
    final controller = PageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: controller,
                  children: const [
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                  ],
                ),
              ),
              CarouselNavBar(
                controller: controller,
                items: const [
                  NavItem('Inicio', Icons.home),
                  NavItem('Stock', Icons.inventory_2),
                  NavItem('Pedidos', Icons.receipt_long),
                ],
                onSelect: (index) => controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.linear,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final palette = tester.element(find.byType(CarouselNavBar)).rp;
    final resting = _pillColor(tester);
    // Reposada es el azul de la app.
    expect(resting, palette.accent);

    await tester.tap(find.text('Stock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    final moving = _pillColor(tester);
    // Durante el camino la píldora se aclara un poco.
    expect(moving, isNot(resting));
    expect(moving.r, greaterThan(resting.r));

    await tester.pumpAndSettle();
    // Al posarse vuelve al azul de la app.
    expect(_pillColor(tester), resting);
  });
}
