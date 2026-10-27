import assert from 'node:assert/strict';
import test from 'node:test';

import {
  computeOrderTotal,
  verifyOrderAmount,
  type CatalogPrice,
} from '../src/application/orders/guard_order_amount.js';
import type { SpendingRules } from '../src/domain/spending_rules.js';

const rules: SpendingRules = {
  maxPerOrder: 200,
  monthlyLimit: 800,
  requireApprovalAbove: 50,
  allowedSupplierIds: [],
};

const products: CatalogPrice[] = [
  { uid: 'PRD-001', name: 'Café en grano 1 kg', price: 12.5, active: true, supplierId: 'sup-1' },
  { uid: 'PRD-002', name: 'Agua mineral 1.5L', price: 0.55, active: true, supplierId: 'sup-1' },
  { uid: 'PRD-003', name: 'Producto retirado', price: 10, active: false, supplierId: 'sup-1' },
];

const lines = [
  { productUid: 'PRD-001', qty: 2 },
  { productUid: 'PRD-002', qty: 4 },
];

test('el importe se calcula con los precios del catálogo', () => {
  const result = computeOrderTotal(lines, products);

  assert.equal(result.reason, undefined);
  assert.equal(result.total, 27.2); // 12,50 * 2 + 0,55 * 4
});

test('un producto que no está en el catálogo invalida el pedido', () => {
  const result = computeOrderTotal(
    [{ productUid: 'PRD-999', qty: 1 }],
    products,
  );

  assert.match(result.reason ?? '', /no está en el catálogo/);
});

test('un producto inactivo invalida el pedido', () => {
  const result = computeOrderTotal(
    [{ productUid: 'PRD-003', qty: 1 }],
    products,
  );

  assert.match(result.reason ?? '', /no está activo/);
});

test('una cantidad inválida invalida el pedido', () => {
  const result = computeOrderTotal(
    [{ productUid: 'PRD-001', qty: 0 }],
    products,
  );

  assert.match(result.reason ?? '', /Cantidad inválida/);
});

test('un importe manipulado no pasa la comprobación', () => {
  const check = verifyOrderAmount({
    orderTotal: 0.01,
    orderSupplierId: 'sup-1',
    lines,
    products,
    rules,
    spentThisMonth: 0,
  });

  assert.equal(check.ok, false);
  assert.match(check.reason ?? '', /no coincide con el catálogo/);
});

test('un importe correcto y dentro de las reglas pasa la comprobación', () => {
  const check = verifyOrderAmount({
    orderTotal: 27.2,
    orderSupplierId: 'sup-1',
    lines,
    products,
    rules,
    spentThisMonth: 0,
  });

  assert.equal(check.ok, true);
  assert.equal(check.total, 27.2);
});

test('un pedido por encima del máximo por pedido no se paga', () => {
  const check = verifyOrderAmount({
    orderTotal: 300,
    orderSupplierId: 'sup-1',
    lines: [{ productUid: 'PRD-001', qty: 24 }],
    products,
    rules,
    spentThisMonth: 0,
  });

  assert.equal(check.ok, false);
  assert.match(check.reason ?? '', /máximo por pedido/);
});

test('un pedido que necesita aprobación no se paga automáticamente', () => {
  const check = verifyOrderAmount({
    orderTotal: 75,
    orderSupplierId: 'sup-1',
    lines: [{ productUid: 'PRD-001', qty: 6 }],
    products,
    rules,
    spentThisMonth: 0,
  });

  assert.equal(check.ok, false);
  assert.match(check.reason ?? '', /aprobación/);
});

test('un pedido que necesita aprobación se paga cuando el dueño lo aprueba', () => {
  const check = verifyOrderAmount({
    orderTotal: 75,
    orderSupplierId: 'sup-1',
    lines: [{ productUid: 'PRD-001', qty: 6 }],
    products,
    rules,
    spentThisMonth: 0,
    ownerApproved: true,
  });

  assert.equal(check.ok, true);
  assert.equal(check.total, 75);
});

test('un producto de otro proveedor invalida el pedido', () => {
  const check = verifyOrderAmount({
    orderTotal: 12.5,
    orderSupplierId: 'sup-2',
    lines: [{ productUid: 'PRD-001', qty: 1 }],
    products,
    rules,
    spentThisMonth: 0,
  });

  assert.equal(check.ok, false);
  assert.match(check.reason ?? '', /no pertenece al proveedor/);
});
