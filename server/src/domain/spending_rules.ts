export interface SpendingRules {
  maxPerOrder: number;
  monthlyLimit: number;
  requireApprovalAbove: number;
  allowedSupplierIds: string[];
}

export type SpendingStatus = 'auto_approved' | 'requires_approval' | 'blocked';

export interface SpendingDecision {
  status: SpendingStatus;
  reason?: string;
}

export function evaluateSpendingRules(params: {
  rules: SpendingRules;
  orderTotal: number;
  spentThisMonth: number;
  supplierId: string;
}): SpendingDecision {
  const { rules, orderTotal, spentThisMonth, supplierId } = params;

  if (orderTotal <= 0) {
    return { status: 'blocked', reason: 'El pedido no tiene importe.' };
  }

  if (
    rules.allowedSupplierIds.length > 0 &&
    !rules.allowedSupplierIds.includes(supplierId)
  ) {
    return {
      status: 'blocked',
      reason: 'El proveedor no está en la lista de proveedores permitidos.',
    };
  }

  if (orderTotal > rules.maxPerOrder) {
    return {
      status: 'blocked',
      reason: `El pedido supera el máximo por pedido (${rules.maxPerOrder.toFixed(2)}).`,
    };
  }

  if (spentThisMonth + orderTotal > rules.monthlyLimit) {
    return {
      status: 'blocked',
      reason: `El pedido supera el límite mensual (${rules.monthlyLimit.toFixed(2)}).`,
    };
  }

  if (orderTotal > rules.requireApprovalAbove) {
    return {
      status: 'requires_approval',
      reason:
        rules.requireApprovalAbove <= 0
          ? 'Me preguntas por cualquier pedido.'
          : `El pedido supera el umbral de aprobación automática (${rules.requireApprovalAbove.toFixed(2)}).`,
    };
  }

  return { status: 'auto_approved' };
}

export function mapSpendingRules(row: {
  max_per_order?: number | string | null;
  monthly_limit?: number | string | null;
  require_approval_above?: number | string | null;
  allowed_supplier_ids?: string[] | null;
}): SpendingRules {
  return {
    maxPerOrder: Number(row.max_per_order ?? 200),
    monthlyLimit: Number(row.monthly_limit ?? 800),
    requireApprovalAbove: Number(row.require_approval_above ?? 50),
    allowedSupplierIds: row.allowed_supplier_ids ?? [],
  };
}
