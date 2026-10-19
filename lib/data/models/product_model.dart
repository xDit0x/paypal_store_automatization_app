import 'package:store_automatization_app/data/models/model_utils.dart';
import 'package:store_automatization_app/domain/entities/product.dart';

class ProductModel {
  const ProductModel._();

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      uid: map['uid'] as String,
      supplierId: map['supplier_id'] as String,
      name: map['name'] as String? ?? 'Producto',
      description: map['description'] as String?,
      price: asDouble(map['price']),
      currency: map['currency'] as String? ?? 'EUR',
      stock: asInt(map['stock']),
      lowStockThreshold: asInt(map['low_stock_threshold']),
      unit: map['unit'] as String? ?? 'unidad',
      imageUrl: map['image_url'] as String?,
      active: asBool(map['active'], fallback: true),
    );
  }
}
