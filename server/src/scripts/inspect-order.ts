import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

const orderId = process.argv[2];

let query = supabaseAdmin
  .from('orders')
  .select(
    '*, order_items(*), invoices!invoices_order_id_fkey(*), agent_runs!orders_agent_run_id_fkey(*)',
  );

if (orderId) {
  query = query.eq('id', orderId);
} else {
  query = query.order('created_at', { ascending: false }).limit(1);
}

const { data, error } = await query.maybeSingle();

if (error) {
  console.error('No se pudo leer el pedido:', error.message);
  process.exit(1);
}

console.log(JSON.stringify(data, null, 2));
