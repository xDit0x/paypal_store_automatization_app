import type { Reason } from './reasons.js';

export interface SpendingRules {
  maxPerOrder: number;
  monthlyLimit: number;
  requireApprovalAbove: number;
  allowedSupplierIds: string[];
}

export type SpendingStatus = 'auto_approved' | 'requires_approval' | 'blocked';

export type SpendingBlockCode =
  | 'no_amount'
  | 'supplier_not_allowed'
  | 'over_max_per_order'
  | 'over_monthly_limit';

export interface SpendingDecision {
  status: SpendingStatus;
  /** Motivo estructurado: se redacta en el idioma de la app. */
  reason?: Reason;
  /** Código estable del motivo, para poder redactarlo con el importe. */
  code?: SpendingBlockCode;
}

export function evaluateSpendingRules(params: {
  rules: SpendingRules;
  orderTotal: number;
  spentThisMonth: number;
  supplierId: string;
  /** Divisa de la tienda, para poder escribir los importes con ella. */
  currency?: string;
}): SpendingDecision {
  const { rules, orderTotal, spentThisMonth, supplierId } = params;
  const money = (value: number): string =>
    params.currency
      ? `${value.toFixed(2)} ${params.currency}`
      : value.toFixed(2);

  if (orderTotal <= 0) {
    return {
      status: 'blocked',
      code: 'no_amount',
      reason: { code: 'no_amount' },
    };
  }

  if (
    rules.allowedSupplierIds.length > 0 &&
    !rules.allowedSupplierIds.includes(supplierId)
  ) {
    return {
      status: 'blocked',
      code: 'supplier_not_allowed',
      reason: { code: 'supplier_not_allowed' },
    };
  }

  if (orderTotal > rules.maxPerOrder) {
    return {
      status: 'blocked',
      code: 'over_max_per_order',
      reason: {
        code: 'over_max_per_order',
        params: {
          total: money(orderTotal),
          limit: money(rules.maxPerOrder),
        },
      },
    };
  }

  if (spentThisMonth + orderTotal > rules.monthlyLimit) {
    return {
      status: 'blocked',
      code: 'over_monthly_limit',
      reason: {
        code: 'over_monthly_limit',
        params: {
          total: money(spentThisMonth + orderTotal),
          limit: money(rules.monthlyLimit),
        },
      },
    };
  }

  if (orderTotal > rules.requireApprovalAbove) {
    return {
      status: 'requires_approval',
      reason:
        rules.requireApprovalAbove <= 0
          ? { code: 'needs_approval' }
          : {
              code: 'approval_threshold',
              params: { amount: money(rules.requireApprovalAbove) },
            },
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
