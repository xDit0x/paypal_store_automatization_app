class AgentRun {
  final String id;
  final String storeId;
  final String? orderId;
  final String provider;
  final String model;
  final String? decision;
  final double? confidence;
  final DateTime? createdAt;

  /// Resultado de cada herramienta que ejecutó el agente. De aquí sale el
  /// motivo concreto cuando un pedido quedó bloqueado por las reglas.
  final List<Map<String, dynamic>> toolCalls;

  const AgentRun({
    required this.id,
    required this.storeId,
    this.orderId,
    required this.provider,
    required this.model,
    this.decision,
    this.confidence,
    this.createdAt,
    this.toolCalls = const [],
  });

  /// Motivos de los pedidos que el agente no pudo crear.
  List<String> get blockedReasons => [
    for (final call in toolCalls)
      if (call['blocked'] == true && call['reason'] is String)
        call['reason'] as String,
  ];

  /// Primer motivo concreto del bloqueo, si lo hay.
  String? get blockedReason =>
      blockedReasons.isEmpty ? null : blockedReasons.first;
}
