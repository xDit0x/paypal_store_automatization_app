import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/presentation/widgets/restock/carousel_nav_bar.dart';

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
}
