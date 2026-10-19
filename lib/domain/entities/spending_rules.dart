enum SpendingDecisionStatus { autoApproved, requiresApproval, blocked }

class SpendingDecision {
  final SpendingDecisionStatus status;
  final String? reason;

  const SpendingDecision._(this.status, [this.reason]);

  factory SpendingDecision.autoApproved() =>
      const SpendingDecision._(SpendingDecisionStatus.autoApproved);

  factory SpendingDecision.requiresApproval(String reason) =>
      SpendingDecision._(SpendingDecisionStatus.requiresApproval, reason);

  factory SpendingDecision.blocked(String reason) =>
      SpendingDecision._(SpendingDecisionStatus.blocked, reason);

  bool get isBlocked => status == SpendingDecisionStatus.blocked;
  bool get canProceed => !isBlocked;
  bool get needsApproval =>
      status == SpendingDecisionStatus.requiresApproval;
}

class SpendingRules {
  final double maxPerOrder;
  final double monthlyLimit;
  final double requireApprovalAbove;
  final List<String> allowedSupplierIds;

  const SpendingRules({
    this.maxPerOrder = 200,
    this.monthlyLimit = 800,
    this.requireApprovalAbove = 50,
    this.allowedSupplierIds = const [],
  });

  SpendingDecision evaluate({
    required double orderTotal,
    required double spentThisMonth,
    required String supplierId,
  }) {
    if (orderTotal <= 0) {
      return SpendingDecision.blocked('El pedido no tiene importe.');
    }

    if (allowedSupplierIds.isNotEmpty &&
        !allowedSupplierIds.contains(supplierId)) {
      return SpendingDecision.blocked(
        'El proveedor no está en la lista de proveedores permitidos.',
      );
    }

    if (orderTotal > maxPerOrder) {
      return SpendingDecision.blocked(
        'El pedido supera el máximo por pedido '
        '(${maxPerOrder.toStringAsFixed(2)}).',
      );
    }

    if (spentThisMonth + orderTotal > monthlyLimit) {
      return SpendingDecision.blocked(
        'El pedido supera el límite mensual '
        '(${monthlyLimit.toStringAsFixed(2)}).',
      );
    }

    if (orderTotal > requireApprovalAbove) {
      if (requireApprovalAbove <= 0) {
        return SpendingDecision.requiresApproval(
          'Me preguntas por cualquier pedido.',
        );
      }
      return SpendingDecision.requiresApproval(
        'El pedido supera el umbral de aprobación automática '
        '(${requireApprovalAbove.toStringAsFixed(2)}).',
      );
    }

    return SpendingDecision.autoApproved();
  }

  SpendingRules copyWith({
    double? maxPerOrder,
    double? monthlyLimit,
    double? requireApprovalAbove,
    List<String>? allowedSupplierIds,
  }) {
    return SpendingRules(
      maxPerOrder: maxPerOrder ?? this.maxPerOrder,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      requireApprovalAbove: requireApprovalAbove ?? this.requireApprovalAbove,
      allowedSupplierIds: allowedSupplierIds ?? this.allowedSupplierIds,
    );
  }
}
