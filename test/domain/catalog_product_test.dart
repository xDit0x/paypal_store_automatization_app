import 'package:flutter_test/flutter_test.dart';
import 'package:store_automatization_app/domain/entities/catalog_product.dart';

void main() {
  group('CatalogProduct', () {
    test('constructs with supplier info', () {
      const p = CatalogProduct(
        id: 'p1',
        uid: 'UID-1',
        supplierId: 's1',
        supplierName: 'Tostadores Norte',
        name: 'Café',
        price: 12.5,
      );
      expect(p.supplierName, 'Tostadores Norte');
      expect(p.inInventory, false);
    });
  });
}
