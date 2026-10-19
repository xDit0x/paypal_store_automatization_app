import 'package:store_automatization_app/data/models/model_utils.dart';
import 'package:store_automatization_app/domain/entities/supplier.dart';

class SupplierModel {
  const SupplierModel._();

  static Supplier fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Proveedor',
      paypalEmail: map['paypal_email'] as String?,
      category: map['category'] as String?,
      logoUrl: map['logo_url'] as String?,
      active: asBool(map['active'], fallback: true),
    );
  }
}
