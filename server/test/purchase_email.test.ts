import assert from 'node:assert/strict';
import test from 'node:test';

import {
  buildHtml,
  buildText,
  type PurchaseEmailInput,
} from '../src/infrastructure/email/purchase_order_email.js';

const input: PurchaseEmailInput = {
  orderNumber: 'RS-ABCD1234',
  supplierName: 'Andina',
  storeName: 'Cafetería Centro',
  currency: 'EUR',
  total: 27.2,
  payoutId: 'PAYOUT-123',
  payoutStatus: 'SUCCESS',
  lines: [
    { name: 'Café en grano 1 kg', qty: 2, unitPrice: 12.5, lineTotal: 25 },
    { name: 'Agua mineral 1.5L', qty: 4, unitPrice: 0.55, lineTotal: 2.2 },
  ],
  supplierEmail: 'proveedor@example.com',
  ownerEmail: 'dueno@example.com',
};

test('el email de compra incluye pedido, productos, total y pago', () => {
  const text = buildText(input);

  assert.match(text, /RS-ABCD1234/);
  assert.match(text, /Andina/);
  assert.match(text, /Café en grano 1 kg: 2 ×/);
  assert.match(text, /Agua mineral 1\.5L: 4 ×/);
  assert.match(text, /27,20/);
  assert.match(text, /PAYOUT-123/);
});

test('el HTML escapa el nombre del proveedor', () => {
  const html = buildHtml({ ...input, supplierName: '<script>alert(1)</script>' });

  assert.doesNotMatch(html, /<script>alert\(1\)<\/script>/);
  assert.match(html, /&lt;script&gt;/);
});
