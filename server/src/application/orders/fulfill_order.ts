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
    | { name: string; qty: number; unit_price: number | string }[]
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

export async function fulfillOrder(
  orderId: string,
): Promise<FulfillmentResult> {
  const { data: orderData, error } = await supabaseAdmin
    .from('orders')
    .select(
      'id, store_id, supplier_id, status, total, order_items(name, qty, unit_price)',
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
  if (order.status !== 'approved') {
    throw new Error(`El pedido está en estado "${order.status}".`);
  }

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

  const store = storeData as StoreRow;
  const supplier = supplierData as SupplierRow;
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

  const invoicerEmail = store.paypal_merchant_email;

  if (paypalConfigured() && supplier.paypal_email && invoicerEmail) {
    try {
      const number = `RS-${order.id.slice(0, 8).toUpperCase()}-${Date.now()
        .toString()
        .slice(-6)}`;

      const result = await createAndSendInvoice({
        invoiceNumber: number,
        currency: store.currency,
        recipientEmail: supplier.paypal_email,
        merchantEmail: invoicerEmail,
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
        warnings.push(
          `Factura creada en PayPal pero no registrada: ${invoiceError.message}`,
        );
      }

      await updateOrder(order.id, {
        invoice_id: invoiceRow?.id ?? null,
        status: 'completed',
      });

      invoice = { invoiceId: result.invoiceId, number };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      warnings.push(`No se pudo emitir la factura: ${message}`);
    }
  } else {
    warnings.push(
      'Factura omitida: configura paypal_merchant_email en la tienda o el proveedor no tiene email.',
    );
  }

  return {
    payment,
    invoice,
    warnings,
    orderStatus: invoice ? 'completed' : payment ? 'paid' : 'approved',
  };
}
