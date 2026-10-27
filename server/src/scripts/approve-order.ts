import { fulfillOrder } from '../application/orders/fulfill_order.js';
import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

let orderId = process.argv[2];

if (!orderId) {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .select('id')
    .in('status', ['draft', 'pending_approval'])
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error('No se pudo buscar el pedido:', error.message);
    process.exit(1);
  }
  if (!data) {
    console.error('No hay pedidos pendientes de aprobación.');
    process.exit(1);
  }

  orderId = data.id as string;
}

const { error } = await supabaseAdmin
  .from('orders')
  .update({
    status: 'approved',
    approval_at: new Date().toISOString(),
  })
  .eq('id', orderId)
  .in('status', ['draft', 'pending_approval']);

if (error) {
  console.error('No se pudo aprobar el pedido:', error.message);
  process.exit(1);
}

const result = await fulfillOrder(orderId, { ownerApproved: true });
console.log(JSON.stringify({ order_id: orderId, ...result }, null, 2));
