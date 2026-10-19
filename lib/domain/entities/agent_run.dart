class AgentRun {
  final String id;
  final String storeId;
  final String? orderId;
  final String provider;
  final String model;
  final String? decision;
  final double? confidence;
  final DateTime? createdAt;

  const AgentRun({
    required this.id,
    required this.storeId,
    this.orderId,
    required this.provider,
    required this.model,
    this.decision,
    this.confidence,
    this.createdAt,
  });
}
