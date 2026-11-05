import assert from 'node:assert/strict';
import test from 'node:test';

import type { LowStockProduct } from '../src/application/catalog/get_low_stock.js';

// Valores falsos: el test no llega a llamar a Supabase.
process.env.SUPABASE_URL ??= 'https://example.supabase.co';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'test';

async function selectLowStockProducts(
  ...args: Parameters<
    typeof import('../src/application/catalog/get_low_stock.js').selectLowStockProducts
  >
) {
  const module = await import('../src/application/catalog/get_low_stock.js');
  return module.selectLowStockProducts(...args);
}

function row(
  uid: string,
  options: {
    active?: boolean;
    stock?: number;
    threshold?: number;
    supplierId?: string;
  } = {},
) {
  return {
    stock: options.stock ?? 0,
    low_stock_threshold: options.threshold ?? 5,
    products: {
      uid,
      name: `Producto ${uid}`,
      price: 3,
      currency: 'EUR',
      unit: 'ud',
      supplier_id: options.supplierId ?? 'sup-1',
      active: options.active ?? true,
      suppliers: { name: 'Proveedor Uno', paypal_email: null },
    },
  };
}

test('propone reponer los productos que están bajo de stock', async () => {
  const products: LowStockProduct[] = await selectLowStockProducts(
    [row('p1'), row('p2', { stock: 3, threshold: 5 })],
    new Set(),
  );

  assert.deepEqual(
    products.map((p) => p.uid),
    ['p1', 'p2'],
  );
  assert.equal(products[0]?.suggestedQty, 6);
  assert.equal(products[0]?.supplierName, 'Proveedor Uno');
});

test('ignora los productos eliminados aunque estén bajo de stock', async () => {
  const products: LowStockProduct[] = await selectLowStockProducts(
    [row('activo'), row('eliminado', { active: false })],
    new Set(),
  );

  assert.deepEqual(
    products.map((p) => p.uid),
    ['activo'],
  );
});

test('ignora los productos que ya están en un pedido abierto', async () => {
  const products: LowStockProduct[] = await selectLowStockProducts(
    [row('p1'), row('p2')],
    new Set(['p1']),
  );

  assert.deepEqual(
    products.map((p) => p.uid),
    ['p2'],
  );
});

test('no propone productos con stock por encima del mínimo', async () => {
  const products: LowStockProduct[] = await selectLowStockProducts(
    [row('p1', { stock: 9, threshold: 5 })],
    new Set(),
  );

  assert.deepEqual(products, []);
});
