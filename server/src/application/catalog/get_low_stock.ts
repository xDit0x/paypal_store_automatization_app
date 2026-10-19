import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';

interface ProductRow {
  uid: string;
  name: string;
  price: number | string;
  currency: string;
  stock: number;
  low_stock_threshold: number;
  unit: string;
  supplier_id: string;
  suppliers:
    | { name: string; paypal_email: string | null }
    | { name: string; paypal_email: string | null }[]
    | null;
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

export async function getLowStockProducts(options?: {
  storeId?: string;
  excludeUids?: Set<string>;
}): Promise<LowStockProduct[]> {
  const excluded =
    options?.excludeUids ??
    (options?.storeId
      ? await getProductsInOpenOrders(options.storeId)
      : new Set<string>());

  const { data, error } = await supabaseAdmin
    .from('products')
    .select(
      'uid, name, price, currency, stock, low_stock_threshold, unit, supplier_id, suppliers(name, paypal_email)',
    )
    .eq('active', true);

  if (error) {
    throw new Error(`No se pudo leer el inventario: ${error.message}`);
  }

  return ((data ?? []) as unknown as ProductRow[])
    .filter((row) => row.stock <= row.low_stock_threshold)
    .filter((row) => !excluded.has(row.uid))
    .map((row) => {
      const supplier = Array.isArray(row.suppliers)
        ? row.suppliers[0]
        : row.suppliers;
      const missing = row.low_stock_threshold - row.stock;
      return {
        uid: row.uid,
        name: row.name,
        price: Number(row.price),
        currency: row.currency,
        stock: row.stock,
        lowStockThreshold: row.low_stock_threshold,
        suggestedQty: missing >= 0 ? missing + 1 : 1,
        unit: row.unit,
        supplierId: row.supplier_id,
        supplierName: supplier?.name ?? 'Proveedor',
        supplierPaypalEmail: supplier?.paypal_email ?? null,
      };
    });
}
