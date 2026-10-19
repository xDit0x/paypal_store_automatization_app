import 'package:store_automatization_app/data/models/model_utils.dart';
import 'package:store_automatization_app/data/models/order_item_model.dart';
import 'package:store_automatization_app/domain/entities/order.dart';

class OrderModel {
  const OrderModel._();

  static Order fromMap(Map<String, dynamic> map) {
    final items = asMapList(map['order_items'])
        .map(OrderItemModel.fromMap)
        .toList();

    return Order(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      supplierId: map['supplier_id'] as String,
      createdByType: OrderCreatorType.fromValue(
        map['created_by_type'] as String? ?? 'user',
      ),
      createdById: map['created_by_id'] as String?,
      items: items,
      subtotal: asDouble(map['subtotal']),
      total: asDouble(map['total']),
      status: OrderStatus.fromValue(map['status'] as String? ?? 'draft'),
      approvalBy: map['approval_by'] as String?,
      approvalAt: asDateTime(map['approval_at']),
      paymentProvider: map['payment_provider'] as String?,
      paymentPayoutId: map['payment_payout_id'] as String?,
      paymentStatus: map['payment_status'] as String?,
      paymentAt: asDateTime(map['payment_at']),
      invoiceId: map['invoice_id'] as String?,
      agentRunId: map['agent_run_id'] as String?,
      idempotencyKey: map['idempotency_key'] as String? ?? '',
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }
}
