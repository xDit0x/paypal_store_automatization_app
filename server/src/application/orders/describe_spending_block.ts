import type { SpendingDecision } from '../../domain/spending_rules.js';

export interface SpendingBlockContext {
  orderTotal: number;
  spentThisMonth: number;
  currency: string;
  maxPerOrder: number;
  monthlyLimit: number;
}

/** Importe con dos decimales y la divisa de la tienda. */
function money(value: number, currency: string): string {
  return `${value.toFixed(2)} ${currency}`;
}

/**
 * Explica en una cláusula por qué las reglas de gasto bloquean un pedido.
 *
 * Devuelve texto en minúscula para poder encadenarlo detrás de "no creé el
 * pedido porque…" o "no pude pedir…". El importe siempre acompaña al límite
 * para que el dueño sepa cuánto se pasó.
 */
export function describeSpendingBlock(
  decision: SpendingDecision,
  context: SpendingBlockContext,
): string {
  switch (decision.code) {
    case 'no_amount':
      return 'el pedido no tiene importe';
    case 'supplier_not_allowed':
      return 'el proveedor no está en la lista de proveedores permitidos';
    case 'over_max_per_order':
      return `supera el máximo por pedido (${money(context.orderTotal, context.currency)} de ${money(context.maxPerOrder, context.currency)})`;
    case 'over_monthly_limit':
      return `supera el límite mensual (${money(context.spentThisMonth + context.orderTotal, context.currency)} de ${money(context.monthlyLimit, context.currency)})`;
    default:
      return (
        decision.reason?.replace(/\.\s*$/, '') ??
        'lo bloquean las reglas de gasto'
      );
  }
}
