import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

const SEED_STOCK: Record<string, number> = {
  'PRD-000001': 6,
  'PRD-000002': 18,
  'PRD-000003': 4,
  'PRD-000004': 22,
  'PRD-000005': 3,
  'PRD-000006': 40,
  'PRD-000007': 7,
  'PRD-000008': 25,
  'PRD-000009': 12,
  'PRD-000010': 9,
};

const confirmed =
  process.argv.includes('--yes') || process.env.RESET_DEMO_CONFIRM === 'yes';

if (!confirmed) {
  console.error(
    'Esto borra pedidos, facturas y ejecuciones del agente, y restaura el stock del seed.\n' +
      'Ejecuta: npx tsx src/scripts/reset-demo.ts --yes',
  );
  process.exit(1);
}

const storeId = process.env.STORE_ID;

function fail(message: string, error: { message: string }): never {
  console.error(`${message}: ${error.message}`);
  process.exit(1);
}

let orderQuery = supabaseAdmin.from('orders').select('id');
if (storeId) {
  orderQuery = orderQuery.eq('store_id', storeId);
}

const { data: orders, error: ordersError } = await orderQuery;
if (ordersError) {
  fail('No se pudieron leer los pedidos', ordersError);
}

const orderIds = (orders ?? []).map((order) => order.id as string);

let invoiceDelete = supabaseAdmin.from('invoices').delete();
if (storeId && orderIds.length > 0) {
  invoiceDelete = invoiceDelete.in('order_id', orderIds);
} else if (storeId) {
  invoiceDelete = invoiceDelete.in('order_id', []);
} else {
  invoiceDelete = invoiceDelete.not('id', 'is', null);
}

if (!storeId || orderIds.length > 0) {
  const { error } = await invoiceDelete;
  if (error) {
    fail('No se pudieron borrar las facturas', error);
  }
}

if (orderIds.length > 0) {
  const { error } = await supabaseAdmin.from('orders').delete().in('id', orderIds);
  if (error) {
    fail('No se pudieron borrar los pedidos', error);
  }
}

let runDelete = supabaseAdmin.from('agent_runs').delete();
if (storeId) {
  runDelete = runDelete.eq('store_id', storeId);
} else {
  runDelete = runDelete.not('id', 'is', null);
}

const { error: runsError } = await runDelete;
if (runsError) {
  fail('No se pudieron borrar las ejecuciones del agente', runsError);
}

for (const [uid, stock] of Object.entries(SEED_STOCK)) {
  const { error } = await supabaseAdmin
    .from('products')
    .update({ stock })
    .eq('uid', uid);

  if (error) {
    fail(`No se pudo restaurar el stock de ${uid}`, error);
  }
}

console.log(
  JSON.stringify(
    {
      store_id: storeId ?? 'todas',
      orders_deleted: orderIds.length,
      stock_restored: Object.keys(SEED_STOCK).length,
    },
    null,
    2,
  ),
);
