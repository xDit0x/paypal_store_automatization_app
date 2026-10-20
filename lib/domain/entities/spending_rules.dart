enum SpendingDecisionStatus { autoApproved, requiresApproval, blocked }

/// Motivo de la decisión, sin texto: la frase se compone en presentación con
/// el importe del idioma activo.
enum SpendingReason {
  noAmount,
  supplierNotAllowed,
  overMaxPerOrder,
  overMonthlyLimit,
  anyOrderNeedsApproval,
  overApprovalThreshold,
}

class SpendingDecision {
  final SpendingDecisionStatus status;
  final SpendingReason? reason;

  const SpendingDecision._(this.status, [this.reason]);

  factory SpendingDecision.autoApproved() =>
      const SpendingDecision._(SpendingDecisionStatus.autoApproved);

  factory SpendingDecision.requiresApproval(SpendingReason reason) =>
      SpendingDecision._(SpendingDecisionStatus.requiresApproval, reason);

  factory SpendingDecision.blocked(SpendingReason reason) =>
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
      return SpendingDecision.blocked(SpendingReason.noAmount);
    }

    if (allowedSupplierIds.isNotEmpty &&
        !allowedSupplierIds.contains(supplierId)) {
      return SpendingDecision.blocked(SpendingReason.supplierNotAllowed);
    }

    if (orderTotal > maxPerOrder) {
      return SpendingDecision.blocked(SpendingReason.overMaxPerOrder);
    }

    if (spentThisMonth + orderTotal > monthlyLimit) {
      return SpendingDecision.blocked(SpendingReason.overMonthlyLimit);
    }

    if (orderTotal > requireApprovalAbove) {
      if (requireApprovalAbove <= 0) {
        return SpendingDecision.requiresApproval(
          SpendingReason.anyOrderNeedsApproval,
        );
      }
      return SpendingDecision.requiresApproval(
        SpendingReason.overApprovalThreshold,
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
