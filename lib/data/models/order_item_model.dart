import 'package:store_automatization_app/data/models/model_utils.dart';
import 'package:store_automatization_app/domain/entities/order_item.dart';

class OrderItemModel {
  const OrderItemModel._();

  static OrderItem fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productUid: map['product_uid'] as String,
      name: map['name'] as String? ?? '',
      qty: asInt(map['qty']),
      unitPrice: asDouble(map['unit_price']),
    );
  }

  static Map<String, dynamic> toMap({
    required String orderId,
    required OrderItem item,
  }) {
    return {
      'order_id': orderId,
      'product_uid': item.productUid,
      'name': item.name,
      'qty': item.qty,
      'unit_price': item.unitPrice,
      'line_total': item.lineTotal,
    };
  }
}
