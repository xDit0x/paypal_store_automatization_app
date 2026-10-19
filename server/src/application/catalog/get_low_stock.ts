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

export async function getLowStockProducts(): Promise<LowStockProduct[]> {
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
