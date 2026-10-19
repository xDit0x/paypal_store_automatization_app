import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/domain/services/order_builder.dart';

Product _product({
  required String uid,
  required double price,
  bool active = true,
}) {
  return Product(
    id: 'id-$uid',
    uid: uid,
    supplierId: 'sup-1',
    name: 'Producto $uid',
    price: price,
    stock: 10,
    lowStockThreshold: 2,
    active: active,
  );
}

void main() {
  final products = [
    _product(uid: 'AAA', price: 10),
    _product(uid: 'BBB', price: 2.5),
  ];

  group('OrderBuilder.buildItems', () {
    test('construye líneas y calcula totales', () {
      final result = OrderBuilder.buildItems(
        lines: const [
          DraftOrderLine(productUid: 'AAA', qty: 2),
          DraftOrderLine(productUid: 'BBB', qty: 4),
        ],
        products: products,
      );

      final items = result.getOrElse(() => []);
      expect(items, hasLength(2));
      expect(items.first.lineTotal, 20);
      expect(OrderBuilder.total(items), 30);
    });

    test('falla si no hay líneas', () {
      final result = OrderBuilder.buildItems(lines: const [], products: products);
      expect(result.isLeft(), isTrue);
    });

    test('falla con cantidad inválida', () {
      final result = OrderBuilder.buildItems(
        lines: const [DraftOrderLine(productUid: 'AAA', qty: 0)],
        products: products,
      );
      expect(result.isLeft(), isTrue);
    });

    test('falla con UID desconocido', () {
      final result = OrderBuilder.buildItems(
        lines: const [DraftOrderLine(productUid: 'ZZZ', qty: 1)],
        products: products,
      );
      expect(result.isLeft(), isTrue);
    });

    test('falla con producto inactivo', () {
      final result = OrderBuilder.buildItems(
        lines: const [DraftOrderLine(productUid: 'AAA', qty: 1)],
        products: [_product(uid: 'AAA', price: 10, active: false)],
      );
      expect(result.isLeft(), isTrue);
    });
  });
}
