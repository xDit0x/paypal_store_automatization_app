import { supabaseAdmin } from '../infrastructure/supabase/supabase_client.js';

interface StoreRow {
  name: string;
}

interface ProductRow {
  uid: string;
  name: string;
}

interface InventoryRow {
  stock: number;
  low_stock_threshold: number;
  stores: StoreRow | StoreRow[] | null;
  products: ProductRow | ProductRow[] | null;
}

const storeId = process.env.STORE_ID;

let query = supabaseAdmin
  .from('store_products')
  .select('stock, low_stock_threshold, stores(name), products(uid, name)');
if (storeId) {
  query = query.eq('store_id', storeId);
}

const { data, error } = await query;

if (error) {
  console.error('No se pudo leer el stock:', error.message);
  process.exit(1);
}

function one<T>(value: T | T[] | null): T | null {
  return Array.isArray(value) ? (value[0] ?? null) : value;
}

const rows = ((data ?? []) as unknown as InventoryRow[])
  .map((row) => ({
    stock: Number(row.stock),
    threshold: Number(row.low_stock_threshold),
    store: one(row.stores),
    product: one(row.products),
  }))
  .filter((row) => row.product !== null)
  .sort((a, b) => {
    const store = (a.store?.name ?? '').localeCompare(b.store?.name ?? '');
    return store !== 0
      ? store
      : (a.product?.uid ?? '').localeCompare(b.product?.uid ?? '');
  });

for (const row of rows) {
  const marker = row.stock <= row.threshold ? 'BAJO' : 'ok';
  console.log(
    `[${row.store?.name ?? 'tienda'}] ${row.product?.uid} ${row.product?.name}: ` +
      `${row.stock}/${row.threshold} [${marker}]`,
  );
}

if (rows.length === 0) {
  console.log(
    storeId
      ? `La tienda ${storeId} no tiene inventario.`
      : 'No hay inventario. Ejecuta supabase/seed.sql.',
  );
}
