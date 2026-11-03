import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';

interface ProductRow {
  uid: string;
  name: string;
  price: number | string;
  currency: string;
  unit: string;
  supplier_id: string;
  active: boolean;
  suppliers:
    | { name: string; paypal_email: string | null }
    | { name: string; paypal_email: string | null }[]
    | null;
}

interface InventoryRow {
  stock: number;
  low_stock_threshold: number;
  products: ProductRow | ProductRow[] | null;
}

export interface LowStockProduct {
  uid: string;
  name: string;
  price: number;
  currency: string;
  stock: number;
  lowStockThreshold: number;
  suggestedQty: number;
  unit: string;
  supplierId: string;
  supplierName: string;
  supplierPaypalEmail: string | null;
}

// Estados en los que el pedido sigue "abierto" y todavía no ha repuesto stock.
// Se excluyen completed/rejected/payment_failed para permitir reintentos.
const OPEN_ORDER_STATUSES = [
  'draft',
  'pending_approval',
  'approved',
  'paying',
  'paid',
];

interface OrderItemsRow {
  order_items: { product_uid: string }[] | null;
}

/** UIDs de productos que ya están en un pedido abierto de la tienda. */
export async function getProductsInOpenOrders(
  storeId: string,
): Promise<Set<string>> {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .select('order_items(product_uid)')
    .eq('store_id', storeId)
    .in('status', OPEN_ORDER_STATUSES);

  if (error) {
    throw new Error(
      `No se pudieron leer los pedidos abiertos: ${error.message}`,
    );
  }

  const uids = new Set<string>();
  for (const row of (data ?? []) as unknown as OrderItemsRow[]) {
    for (const item of row.order_items ?? []) {
      uids.add(item.product_uid);
    }
  }
  return uids;
}

/**
 * UIDs de productos que existen pero están eliminados (`active = false`).
 *
 * El agente nunca los propone (la lista de stock bajo ya los excluye), pero
 * sirve para explicar con claridad por qué se rechaza una línea en vez de
 * dejar un error genérico.
 */
export async function getInactiveProductUids(
  uids: string[],
): Promise<Set<string>> {
  if (uids.length === 0) return new Set();

  const { data, error } = await supabaseAdmin
    .from('products')
    .select('uid, active')
    .in('uid', uids);

  if (error) {
    throw new Error(`No se pudieron leer los productos: ${error.message}`);
  }

  const rows = (data ?? []) as unknown as { uid: string; active: boolean }[];
  return new Set(rows.filter((row) => !row.active).map((row) => row.uid));
}

/**
 * Convierte las filas de inventario en la lista de productos a reponer.
 *
 * Es pura (sin base de datos) para poder probarla: aquí se descarta lo que
 * el agente no debe tocar.
 */
export function selectLowStockProducts(
  rows: InventoryRow[],
  excluded: Set<string>,
): LowStockProduct[] {
  const products: LowStockProduct[] = [];

  for (const row of rows) {
    const product = Array.isArray(row.products)
      ? row.products[0]
      : row.products;
    if (!product) continue;
    // Un producto eliminado (`active = false`) no se repone, aunque su stock
    // esté por debajo del mínimo.
    if (!product.active) continue;
    if (row.stock > row.low_stock_threshold) continue;
    if (excluded.has(product.uid)) continue;

    const supplier = Array.isArray(product.suppliers)
      ? product.suppliers[0]
      : product.suppliers;
    const missing = row.low_stock_threshold - row.stock;
    products.push({
      uid: product.uid,
      name: product.name,
      price: Number(product.price),
      currency: product.currency,
      stock: row.stock,
      lowStockThreshold: row.low_stock_threshold,
      suggestedQty: missing >= 0 ? missing + 1 : 1,
      unit: product.unit,
      supplierId: product.supplier_id,
      supplierName: supplier?.name ?? 'Proveedor',
      supplierPaypalEmail: supplier?.paypal_email ?? null,
    });
  }

  return products;
}

export async function getLowStockProducts(options: {
  storeId: string;
  excludeUids?: Set<string>;
}): Promise<LowStockProduct[]> {
  const excluded =
    options.excludeUids ?? (await getProductsInOpenOrders(options.storeId));

  const { data, error } = await supabaseAdmin
    .from('store_products')
    .select(
      'stock, low_stock_threshold, products!inner(uid, name, price, currency, unit, supplier_id, active, suppliers(name, paypal_email))',
    )
    .eq('store_id', options.storeId)
    // Los productos eliminados (`active = false`) no se reponen: ni se le
    // ofrecen a la IA ni pueden entrar en un pedido.
    .eq('products.active', true);

  if (error) {
    throw new Error(`No se pudo leer el inventario: ${error.message}`);
  }

  return selectLowStockProducts(
    (data ?? []) as unknown as InventoryRow[],
    excluded,
  );
}
