import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/domain/entities/product.dart';

Product _product({required int stock, required int threshold}) {
  return Product(
    id: 'p1',
    uid: 'PRD-1',
    supplierId: 'sup-1',
    name: 'Producto',
    price: 1,
    stock: stock,
    lowStockThreshold: threshold,
  );
}

void main() {
  group('Product.suggestedReorderQty', () {
    test('pide una unidad extra para salir del umbral', () {
      expect(_product(stock: 3, threshold: 10).suggestedReorderQty, 8);
    });

    test('pide al menos una unidad justo en el umbral', () {
      expect(_product(stock: 10, threshold: 10).suggestedReorderQty, 1);
    });

    test('pide una unidad si el stock es alto', () {
      expect(_product(stock: 20, threshold: 10).suggestedReorderQty, 1);
    });
  });
}
