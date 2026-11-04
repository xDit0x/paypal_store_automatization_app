import type { Reason, ReasonCode } from '../../domain/reasons.js';
import { fill, type AppLanguage } from './messages.js';

type ReasonTexts = Record<ReasonCode, string>;

const es: ReasonTexts = {
  no_amount: 'el pedido no tiene importe',
  supplier_not_allowed:
    'el proveedor no está en la lista de proveedores permitidos',
  over_max_per_order: 'supera el máximo por pedido ({total} de {limit})',
  over_monthly_limit: 'supera el límite mensual ({total} de {limit})',
  needs_approval: 'el pedido necesita tu aprobación antes de pagarlo',
  approval_threshold:
    'el pedido supera el umbral de aprobación automática ({amount})',
  no_lines: 'el pedido no tiene líneas',
  product_not_in_catalog: 'el producto {uid} no está en el catálogo',
  product_not_active: 'el producto {name} no está activo',
  invalid_qty: 'cantidad inválida para {uid}',
  product_wrong_supplier:
    'el producto {name} no pertenece al proveedor del pedido',
  blocked_by_rules: 'lo bloquean las reglas de gasto',
  amount_check_failed: 'el pedido no supera la comprobación de importe',
  order_not_found: 'el pedido no existe',
  store_not_found: 'la tienda del pedido no existe',
  supplier_not_found: 'el proveedor del pedido no existe',
  wrong_status: 'el pedido está en estado "{status}"',
  paypal_not_configured: 'PayPal no está configurado',
  no_paypal_order: 'el pedido no tiene una orden de PayPal pendiente',
  no_paypal_authorization: 'el pedido no tiene autorización de PayPal',
  product_not_in_order: 'el producto {uid} no está en el pedido',
  invalid_received_qty:
    'cantidad recibida no válida para {name}: {qty}',
  nothing_received: 'no se ha recibido ningún producto: no hay nada que cobrar',
  no_capture_to_refund: 'el pedido no tiene una captura que reembolsar',
};

const en: ReasonTexts = {
  no_amount: 'the order has no amount',
  supplier_not_allowed:
    'the supplier is not in the list of allowed suppliers',
  over_max_per_order: 'it exceeds the maximum per order ({total} of {limit})',
  over_monthly_limit: 'it exceeds the monthly limit ({total} of {limit})',
  needs_approval: 'the order needs your approval before paying',
  approval_threshold:
    'the order exceeds the automatic approval threshold ({amount})',
  no_lines: 'the order has no lines',
  product_not_in_catalog: 'the product {uid} is not in the catalogue',
  product_not_active: 'the product {name} is not active',
  invalid_qty: 'invalid quantity for {uid}',
  product_wrong_supplier:
    'the product {name} does not belong to the order supplier',
  blocked_by_rules: 'your spending rules block it',
  amount_check_failed: 'the order does not pass the amount check',
  order_not_found: 'the order does not exist',
  store_not_found: 'the order store does not exist',
  supplier_not_found: 'the order supplier does not exist',
  wrong_status: 'the order is in status "{status}"',
  paypal_not_configured: 'PayPal is not configured',
  no_paypal_order: 'the order has no pending PayPal order',
  no_paypal_authorization: 'the order has no PayPal authorization',
  product_not_in_order: 'the product {uid} is not in the order',
  invalid_received_qty: 'invalid received quantity for {name}: {qty}',
  nothing_received: 'no product was received: there is nothing to charge',
  no_capture_to_refund: 'the order has no capture to refund',
};

const texts: Record<AppLanguage, ReasonTexts> = { es, en };

/**
 * Explica un motivo de error en el idioma de la app.
 *
 * Devuelve una frase en minúscula, sin punto final, para poder encadenarla
 * detrás de "no creé el pedido porque…" o "no pude pedir…".
 */
export function describeReason(
  reason: Reason,
  language: AppLanguage = 'es',
): string {
  const template = texts[language][reason.code];
  if (!template) return reason.code;
  return fill(template, reason.params ?? {});
}
