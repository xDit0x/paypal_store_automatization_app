import 'package:store_automatization_app/domain/entities/order_item.dart';

enum OrderStatus {
  draft('draft'),
  pendingApproval('pending_approval'),
  approved('approved'),
  paying('paying'),
  paid('paid'),
  invoiced('invoiced'),
  completed('completed'),
  rejected('rejected'),
  paymentFailed('payment_failed');

  final String value;
  const OrderStatus(this.value);

  static OrderStatus fromValue(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.draft,
    );
  }
}

enum OrderCreatorType {
  user('user'),
  agent('agent');

  final String value;
  const OrderCreatorType(this.value);

  static OrderCreatorType fromValue(String value) {
    return OrderCreatorType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => OrderCreatorType.user,
    );
  }
}

class Order {
  final String id;
  final String storeId;
  final String supplierId;
  final OrderCreatorType createdByType;
  final String? createdById;
  final List<OrderItem> items;
  final double subtotal;
  final double total;
  final OrderStatus status;
  final String? approvalBy;
  final DateTime? approvalAt;
  final String? paymentProvider;
  final String? paymentPayoutId;
  final String? paymentStatus;
  final DateTime? paymentAt;
  final String? invoiceId;
  final String? agentRunId;
  final String idempotencyKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.storeId,
    required this.supplierId,
    this.createdByType = OrderCreatorType.user,
    this.createdById,
    required this.items,
    required this.subtotal,
    required this.total,
    this.status = OrderStatus.draft,
    this.approvalBy,
    this.approvalAt,
    this.paymentProvider,
    this.paymentPayoutId,
    this.paymentStatus,
    this.paymentAt,
    this.invoiceId,
    this.agentRunId,
    required this.idempotencyKey,
    this.createdAt,
    this.updatedAt,
  });

  bool get canBeApproved =>
      status == OrderStatus.pendingApproval || status == OrderStatus.draft;

  bool get isFinal =>
      status == OrderStatus.completed ||
      status == OrderStatus.rejected ||
      status == OrderStatus.paymentFailed;

  Order copyWith({
    String? id,
    String? supplierId,
    List<OrderItem>? items,
    double? subtotal,
    double? total,
    OrderStatus? status,
    String? approvalBy,
    DateTime? approvalAt,
    String? paymentProvider,
    String? paymentPayoutId,
    String? paymentStatus,
    DateTime? paymentAt,
    String? invoiceId,
    String? agentRunId,
    String? idempotencyKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      storeId: storeId,
      supplierId: supplierId ?? this.supplierId,
      createdByType: createdByType,
      createdById: createdById,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      status: status ?? this.status,
      approvalBy: approvalBy ?? this.approvalBy,
      approvalAt: approvalAt ?? this.approvalAt,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      paymentPayoutId: paymentPayoutId ?? this.paymentPayoutId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentAt: paymentAt ?? this.paymentAt,
      invoiceId: invoiceId ?? this.invoiceId,
      agentRunId: agentRunId ?? this.agentRunId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
