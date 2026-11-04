import { env } from '../../config/env.js';
import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';
import {
  authorizeOrder,
  captureAuthorization,
  createAuthorizationOrder,
  getApprovalUrl,
  refundCapture,
} from '../paypal/escrow.js';
import { paypalConfigured } from '../paypal/paypal_client.js';
import { ReasonError } from '../../domain/reasons.js';
import type { AppLanguage } from '../i18n/messages.js';
import { guardOrderAmount } from './guard_order_amount.js';
import { sendInvoiceForOrder } from './fulfill_order.js';
import {
  sendPaymentFailedEmail,
  sendPurchaseOrderEmail,
} from '../../infrastructure/email/purchase_order_email.js';

interface OrderItemRow {
  product_uid: string;
  name: string;
  qty: number;
  unit_price: number | string;
}

interface EscrowOrderRow {
  id: string;
  store_id: string;
  supplier_id: string;
  status: string;
  total: number | string;
  payment_authorization_id: string | null;
  payment_capture_id: string | null;
  payment_payout_id: string | null;
  order_items: OrderItemRow[] | null;
}

interface EscrowStoreRow {
  name: string;
  currency: string;
  paypal_merchant_email: string | null;
  notification_email: string | null;
}

interface EscrowSupplierRow {
  name: string;
  paypal_email: string | null;
}

export interface DeliveryLine {
  productUid: string;
  qtyReceived: number;
}

export interface StartAuthorizationResult {
  total: number;
  previousTotal: number;
  changed: boolean;
  paypalOrderId: string;
  approveUrl: string | null;
}

export interface CaptureDeliveryResult {
  captureId: string;
  capturedAmount: number;
  orderStatus: string;
  warnings: string[];
}

async function updateOrder(
  orderId: string,
  values: Record<string, unknown>,
): Promise<void> {
  const { error } = await supabaseAdmin
    .from('orders')
    .update(values)
    .eq('id', orderId);
  if (error) {
    throw new Error(`No se pudo actualizar el pedido: ${error.message}`);
  }
}

async function loadEscrowContext(orderId: string): Promise<{
  order: EscrowOrderRow;
  store: EscrowStoreRow;
  supplier: EscrowSupplierRow;
}> {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .select(
      'id, store_id, supplier_id, status, total, payment_authorization_id, payment_capture_id, payment_payout_id, order_items(product_uid, name, qty, unit_price)',
    )
    .eq('id', orderId)
    .maybeSingle();

  if (error) {
    throw new Error(`No se pudo cargar el pedido: ${error.message}`);
  }
  if (!data) {
    throw new ReasonError({ code: 'order_not_found' });
  }

  const order = data as unknown as EscrowOrderRow;

  const [{ data: storeData }, { data: supplierData }] = await Promise.all([
    supabaseAdmin
      .from('stores')
      .select('name, currency, paypal_merchant_email, notification_email')
      .eq('id', order.store_id)
      .maybeSingle(),
    supabaseAdmin
      .from('suppliers')
      .select('name, paypal_email')
      .eq('id', order.supplier_id)
      .maybeSingle(),
  ]);

  if (!storeData) throw new ReasonError({ code: 'store_not_found' });
  if (!supplierData) throw new ReasonError({ code: 'supplier_not_found' });

  return {
    order,
    store: storeData as EscrowStoreRow,
    supplier: supplierData as EscrowSupplierRow,
  };
}

/**
 * Crea la orden de PayPal en modo AUTHORIZE y devuelve el enlace de
 * aprobación. El dinero no se mueve todavía.
 */
export async function startAuthorization(
  orderId: string,
  options: { ownerApproved?: boolean; locale?: 'es' | 'en' } = {},
): Promise<StartAuthorizationResult> {
  const { order } = await loadEscrowContext(orderId);

  if (!['approved', 'draft', 'pending_approval'].includes(order.status)) {
    throw new ReasonError({
      code: 'wrong_status',
      params: { status: order.status },
    });
  }
  if (!paypalConfigured()) {
    throw new ReasonError({ code: 'paypal_not_configured' });
  }

  // El importe se recalcula con el catálogo vigente antes de autorizar.
  const amount = await guardOrderAmount(orderId, options);

  const created = await createAuthorizationOrder({
    amount: amount.total,
    currency: 'EUR',
    referenceId: order.id,
    // El idioma viaja en la URL para que la página de vuelta de PayPal esté
    // en el idioma del dueño.
    returnUrl: `${env.publicBaseUrl}/paypal/return?order_id=${order.id}&locale=${
      options.locale ?? 'es'
    }`,
    cancelUrl: `${env.appUrl}/orders/${order.id}`,
  });

  await updateOrder(order.id, {
    status: 'approved',
    payment_provider: 'paypal',
    payment_status: 'CREATED',
    payment_payout_id: created.orderId,
  });

  return {
    total: amount.total,
    previousTotal: amount.previousTotal,
    changed: amount.changed,
    paypalOrderId: created.orderId,
    approveUrl: created.approveUrl,
  };
}

/**
 * Autoriza la orden cuando el pagador vuelve de PayPal. A partir de aquí el
 * dinero está retenido y se puede capturar (total o parcialmente).
 */
export async function confirmAuthorization(
  orderId: string,
  paypalOrderId?: string | null,
): Promise<{ authorizationId: string; status: string }> {
  const { order } = await loadEscrowContext(orderId);

  if (order.status !== 'approved') {
    throw new ReasonError({
      code: 'wrong_status',
      params: { status: order.status },
    });
  }

  const paypalOrder = paypalOrderId ?? order.payment_payout_id;
  if (!paypalOrder) {
    throw new ReasonError({ code: 'no_paypal_order' });
  }

  const authorization = await authorizeOrder(paypalOrder);

  await updateOrder(order.id, {
    status: 'authorized',
    payment_authorization_id: authorization.authorizationId,
    payment_status: authorization.status,
    authorized_at: new Date().toISOString(),
  });

  return authorization;
}

/**
 * Enlace de aprobación de PayPal para un pedido pendiente de autorizar.
 * Sirve cuando la app se ha reiniciado y ya no tiene el enlace en memoria.
 */
export async function approvalUrlForOrder(
  orderId: string,
): Promise<string | null> {
  const { order } = await loadEscrowContext(orderId);

  if (order.status !== 'approved') {
    throw new ReasonError({
      code: 'wrong_status',
      params: { status: order.status },
    });
  }
  if (!order.payment_payout_id) return null;

  return getApprovalUrl(order.payment_payout_id);
}

/**
 * Confirma qué ha llegado y captura solo lo recibido. Si falta algo, la
 * autorización se captura por el importe de las líneas recibidas.
 */
export async function captureDelivery(
  orderId: string,
  lines: DeliveryLine[],
  options: { locale?: AppLanguage } = {},
): Promise<CaptureDeliveryResult> {
  const { order, store, supplier } = await loadEscrowContext(orderId);
  const warnings: string[] = [];

  if (order.status !== 'authorized') {
    throw new ReasonError({
      code: 'wrong_status',
      params: { status: order.status },
    });
  }
  if (!order.payment_authorization_id) {
    throw new ReasonError({ code: 'no_paypal_authorization' });
  }

  const items = order.order_items ?? [];
  const byUid = new Map(items.map((item) => [item.product_uid, item]));

  for (const line of lines) {
    const item = byUid.get(line.productUid);
    if (!item) {
      throw new ReasonError({
        code: 'product_not_in_order',
        params: { uid: line.productUid },
      });
    }
    if (line.qtyReceived < 0 || line.qtyReceived > item.qty) {
      throw new ReasonError({
        code: 'invalid_received_qty',
        params: { name: item.name, qty: String(line.qtyReceived) },
      });
    }
  }

  // Las líneas no enviadas se consideran no recibidas.
  const received = new Map(lines.map((line) => [line.productUid, line.qtyReceived]));
  const receivedTotal = items.reduce((sum, item) => {
    const qty = received.get(item.product_uid) ?? 0;
    return sum + qty * Number(item.unit_price);
  }, 0);
  const capturedAmount = Number(receivedTotal.toFixed(2));
  const complete = items.every(
    (item) => (received.get(item.product_uid) ?? 0) >= item.qty,
  );

  if (capturedAmount <= 0) {
    throw new ReasonError({ code: 'nothing_received' });
  }

  let capture;
  try {
    capture = await captureAuthorization({
      authorizationId: order.payment_authorization_id,
      amount: capturedAmount,
      currency: store.currency,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    await updateOrder(order.id, { payment_status: 'CAPTURE_FAILED' });
    try {
      await sendPaymentFailedEmail({
        orderNumber: `RS-${order.id.slice(0, 8).toUpperCase()}`,
        supplierName: supplier.name,
        storeName: store.name,
        reason:
          options.locale === 'en'
            ? `The payment capture failed: ${message}`
            : `La captura del pago falló: ${message}`,
        ownerEmail: store.notification_email,
        locale: options.locale,
      });
    } catch (notifyError) {
      warnings.push(
        `No se pudo avisar del fallo de captura: ${
          notifyError instanceof Error ? notifyError.message : String(notifyError)
        }`,
      );
    }
    throw error;
  }

  const now = new Date().toISOString();
  const orderStatus = complete ? 'delivered' : 'partially_delivered';

  await updateOrder(order.id, {
    status: orderStatus,
    payment_capture_id: capture.captureId,
    payment_status: capture.status,
    payment_at: now,
    delivered_at: now,
    received_total: capturedAmount,
  });

  // Stock solo de lo que realmente ha llegado.
  for (const item of items) {
    const qty = received.get(item.product_uid) ?? 0;
    if (qty <= 0) continue;
    try {
      await incrementStockLine(order.store_id, item.product_uid, qty);
    } catch (error) {
      warnings.push(
        `No se actualizó el stock de ${item.product_uid}: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  // Registro de entrega para auditoría.
  const { error: deliveryError } = await supabaseAdmin
    .from('order_delivery_items')
    .upsert(
      items.map((item) => ({
        order_id: order.id,
        product_uid: item.product_uid,
        qty_ordered: item.qty,
        qty_received: received.get(item.product_uid) ?? 0,
      })),
      { onConflict: 'order_id,product_uid' },
    );

  if (deliveryError) {
    warnings.push(`No se guardó el detalle de entrega: ${deliveryError.message}`);
  }

  // Factura y email al proveedor con lo realmente cobrado.
  try {
    const notified = await sendPurchaseOrderEmail({
      orderNumber: `RS-${order.id.slice(0, 8).toUpperCase()}`,
      supplierName: supplier.name,
      storeName: store.name,
      currency: store.currency,
      total: capturedAmount,
      payoutId: capture.captureId,
      payoutStatus: capture.status,
      lines: items
        .filter((item) => (received.get(item.product_uid) ?? 0) > 0)
        .map((item) => {
          const qty = received.get(item.product_uid) ?? 0;
          return {
            name: item.name,
            qty,
            unitPrice: Number(item.unit_price),
            lineTotal: qty * Number(item.unit_price),
          };
        }),
      supplierEmail: supplier.paypal_email,
      ownerEmail: store.notification_email,
    });
    if (!notified.supplierSent) {
      warnings.push('El proveedor no tiene email de contacto.');
    }
  } catch (error) {
    warnings.push(
      `No se pudo enviar el email de compra: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  }

  try {
    await sendInvoiceForOrder(order.id);
  } catch (error) {
    warnings.push(
      `No se pudo emitir la factura: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  }

  return {
    captureId: capture.captureId,
    capturedAmount,
    orderStatus,
    warnings,
  };
}

/** Reembolsa una entrega ya cobrada (total o parcial). */
export async function refundOrder(
  orderId: string,
  amount?: number,
): Promise<{ refundId: string; status: string }> {
  const { order, store } = await loadEscrowContext(orderId);

  if (!order.payment_capture_id) {
    throw new ReasonError({ code: 'no_capture_to_refund' });
  }

  const refund = await refundCapture({
    captureId: order.payment_capture_id,
    amount,
    currency: store.currency,
  });

  await updateOrder(order.id, {
    status: 'refunded',
    payment_status: refund.status,
  });

  return refund;
}

async function incrementStockLine(
  storeId: string,
  productUid: string,
  qty: number,
): Promise<void> {
  const { data: current, error } = await supabaseAdmin
    .from('store_products')
    .select('stock')
    .eq('store_id', storeId)
    .eq('product_uid', productUid)
    .maybeSingle();

  if (error) {
    throw new Error(`No se pudo leer el stock: ${error.message}`);
  }

  if (current) {
    const { error: updateError } = await supabaseAdmin
      .from('store_products')
      .update({ stock: Number(current.stock) + qty })
      .eq('store_id', storeId)
      .eq('product_uid', productUid);
    if (updateError) {
      throw new Error(`No se pudo actualizar el stock: ${updateError.message}`);
    }
    return;
  }

  const { data: product } = await supabaseAdmin
    .from('products')
    .select('low_stock_threshold')
    .eq('uid', productUid)
    .maybeSingle();

  const { error: insertError } = await supabaseAdmin
    .from('store_products')
    .insert({
      store_id: storeId,
      product_uid: productUid,
      stock: qty,
      low_stock_threshold: Number(product?.low_stock_threshold ?? 0),
    });

  if (insertError) {
    throw new Error(`No se pudo crear el stock: ${insertError.message}`);
  }
}
