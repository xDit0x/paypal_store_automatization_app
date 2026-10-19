import { createAndSendInvoice } from '../paypal/invoices.js';
import { paypalConfigured } from '../paypal/paypal_client.js';
import { sendPayout } from '../paypal/payouts.js';
import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';

interface OrderRow {
  id: string;
  store_id: string;
  supplier_id: string;
  status: string;
  total: number | string;
  order_items:
    | { product_uid: string; name: string; qty: number; unit_price: number | string }[]
    | null;
}

interface StoreRow {
  currency: string;
  paypal_merchant_email: string | null;
  notification_email: string | null;
}

interface SupplierRow {
  name: string;
  paypal_email: string | null;
}

interface OrderContext {
  order: OrderRow;
  store: StoreRow;
  supplier: SupplierRow;
}

export interface FulfillmentResult {
  payment: { payoutId: string; status: string } | null;
  invoice: { invoiceId: string; number: string } | null;
  warnings: string[];
  orderStatus: string;
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

async function loadOrderContext(orderId: string): Promise<OrderContext> {
  const { data: orderData, error } = await supabaseAdmin
    .from('orders')
    .select(
      'id, store_id, supplier_id, status, total, order_items(product_uid, name, qty, unit_price)',
    )
    .eq('id', orderId)
    .maybeSingle();

  if (error) {
    throw new Error(`No se pudo cargar el pedido: ${error.message}`);
  }
  if (!orderData) {
    throw new Error('El pedido no existe.');
  }

  const order = orderData as unknown as OrderRow;

  const [{ data: storeData }, { data: supplierData }] = await Promise.all([
    supabaseAdmin
      .from('stores')
      .select('currency, paypal_merchant_email, notification_email')
      .eq('id', order.store_id)
      .maybeSingle(),
    supabaseAdmin
      .from('suppliers')
      .select('name, paypal_email')
      .eq('id', order.supplier_id)
      .maybeSingle(),
  ]);

  if (!storeData) {
    throw new Error('La tienda del pedido no existe.');
  }
  if (!supplierData) {
    throw new Error('El proveedor del pedido no existe.');
  }

  return {
    order,
    store: storeData as StoreRow,
    supplier: supplierData as SupplierRow,
  };
}

async function incrementStock(order: OrderRow): Promise<void> {
  for (const item of order.order_items ?? []) {
    const { data: product, error } = await supabaseAdmin
      .from('products')
      .select('stock')
      .eq('uid', item.product_uid)
      .maybeSingle();

    if (error) {
      throw new Error(
        `No se pudo leer el stock de ${item.product_uid}: ${error.message}`,
      );
    }
    if (!product) continue;

    const { error: updateError } = await supabaseAdmin
      .from('products')
      .update({ stock: Number(product.stock) + item.qty })
      .eq('uid', item.product_uid);

    if (updateError) {
      throw new Error(
        `No se pudo actualizar el stock de ${item.product_uid}: ${updateError.message}`,
      );
    }
  }
}

export async function sendInvoiceForOrder(
  orderId: string,
): Promise<{ invoiceId: string; number: string }> {
  const { order, store, supplier } = await loadOrderContext(orderId);

  if (!paypalConfigured()) {
    throw new Error('PayPal no está configurado.');
  }
  if (!store.paypal_merchant_email) {
    throw new Error('Falta paypal_merchant_email en la tienda.');
  }
  if (!supplier.paypal_email) {
    throw new Error('El proveedor no tiene email de PayPal.');
  }

  const number = `RS-${order.id.slice(0, 8).toUpperCase()}-${Date.now()
    .toString()
    .slice(-6)}`;

  const result = await createAndSendInvoice({
    invoiceNumber: number,
    currency: store.currency,
    recipientEmail: supplier.paypal_email,
    merchantEmail: store.paypal_merchant_email,
    note: `Factura de reposición ${number}`,
    lines: (order.order_items ?? []).map((item) => ({
      name: item.name,
      qty: item.qty,
      unitPrice: Number(item.unit_price),
    })),
  });

  const { data: invoiceRow, error: invoiceError } = await supabaseAdmin
    .from('invoices')
    .upsert(
      {
        order_id: order.id,
        number,
        status: 'sent',
        sent_to: supplier.paypal_email,
        sent_at: new Date().toISOString(),
      },
      { onConflict: 'order_id' },
    )
    .select('id')
    .single();

  if (invoiceError) {
    throw new Error(`No se pudo registrar la factura: ${invoiceError.message}`);
  }

  await updateOrder(order.id, {
    invoice_id: invoiceRow?.id ?? null,
    status: 'completed',
  });

  return { invoiceId: result.invoiceId, number };
}

export async function fulfillOrder(
  orderId: string,
): Promise<FulfillmentResult> {
  const { order, store, supplier } = await loadOrderContext(orderId);

  if (order.status !== 'approved') {
    throw new Error(`El pedido está en estado "${order.status}".`);
  }

  const total = Number(order.total);
  const warnings: string[] = [];

  let payment: FulfillmentResult['payment'] = null;

  if (paypalConfigured() && supplier.paypal_email) {
    try {
      const payout = await sendPayout({
        recipientEmail: supplier.paypal_email,
        amount: total,
        currency: store.currency,
        note: `Reposición a ${supplier.name}`,
        senderBatchId: `restock-${order.id}`,
      });

      await updateOrder(order.id, {
        status: 'paid',
        payment_provider: 'paypal',
        payment_payout_id: payout.batchId,
        payment_status: payout.status,
        payment_at: new Date().toISOString(),
      });

      payment = { payoutId: payout.batchId, status: payout.status };

      try {
        await incrementStock(order);
      } catch (error) {
        warnings.push(
          `Pago realizado pero no se actualizó el stock: ${
            error instanceof Error ? error.message : String(error)
          }`,
        );
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      await updateOrder(order.id, {
        status: 'payment_failed',
        payment_status: message,
      });
      throw error;
    }
  } else {
    warnings.push(
      'Pago omitido: PayPal no está configurado o el proveedor no tiene email.',
    );
  }

  let invoice: FulfillmentResult['invoice'] = null;

  try {
    invoice = await sendInvoiceForOrder(order.id);
  } catch (error) {
    warnings.push(
      `No se pudo emitir la factura: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  }

  return {
    payment,
    invoice,
    warnings,
    orderStatus: invoice ? 'completed' : payment ? 'paid' : 'approved',
  };
}
