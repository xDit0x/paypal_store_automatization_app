/**
 * Motivos de error con clave estable.
 *
 * El dominio no redacta mensajes: solo dice qué pasó. Así el mismo motivo se
 * puede explicar en español o en inglés (ver `describeReason` en la capa de
 * aplicación) sin tocar la lógica.
 */
export type ReasonCode =
  // Reglas de gasto.
  | 'no_amount'
  | 'supplier_not_allowed'
  | 'over_max_per_order'
  | 'over_monthly_limit'
  | 'needs_approval'
  | 'approval_threshold'
  // Comprobación del importe del pedido.
  | 'no_lines'
  | 'product_not_in_catalog'
  | 'product_not_active'
  | 'invalid_qty'
  | 'product_wrong_supplier'
  | 'blocked_by_rules'
  | 'amount_check_failed'
  // Pago y entrega.
  | 'order_not_found'
  | 'store_not_found'
  | 'supplier_not_found'
  | 'wrong_status'
  | 'paypal_not_configured'
  | 'no_paypal_order'
  | 'no_paypal_authorization'
  | 'product_not_in_order'
  | 'invalid_received_qty'
  | 'nothing_received'
  | 'no_capture_to_refund';

export interface Reason {
  code: ReasonCode;
  /** Datos del motivo (importes, nombres, estados...). */
  params?: Record<string, string>;
}

/** Error de dominio que lleva su motivo estructurado. */
export class ReasonError extends Error {
  readonly reason: Reason;

  constructor(reason: Reason) {
    super(reason.code);
    this.name = 'ReasonError';
    this.reason = reason;
  }
}
