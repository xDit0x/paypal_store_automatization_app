import { sendInvoiceForOrder } from '../application/orders/fulfill_order.js';
import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

let orderId = process.argv[2];

if (!orderId) {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .select('id')
    .in('status', ['paid', 'approved'])
    .is('invoice_id', null)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error('No se pudo buscar el pedido:', error.message);
    process.exit(1);
  }
  if (!data) {
    console.error('No hay pedidos pagados sin factura.');
    process.exit(1);
  }

  orderId = data.id as string;
}

const result = await sendInvoiceForOrder(orderId);
console.log(
  `Factura ${result.number} enviada (PayPal invoice ${result.invoiceId}).`,
);
