import assert from 'node:assert/strict';
import test from 'node:test';

import {
  evaluateSpendingRules,
  mapSpendingRules,
  type SpendingRules,
} from '../src/domain/spending_rules.js';

const rules: SpendingRules = {
  maxPerOrder: 200,
  monthlyLimit: 800,
  requireApprovalAbove: 50,
  allowedSupplierIds: [],
};

test('auto aprueba pedidos pequeños', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 30,
    spentThisMonth: 0,
    supplierId: 'sup-1',
  });

  assert.equal(decision.status, 'auto_approved');
});

test('requiere aprobación por encima del umbral', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 120,
    spentThisMonth: 0,
    supplierId: 'sup-1',
  });

  assert.equal(decision.status, 'requires_approval');
});

test('bloquea pedidos sin importe', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 0,
    spentThisMonth: 0,
    supplierId: 'sup-1',
  });

  assert.equal(decision.status, 'blocked');
});

test('bloquea por encima del máximo por pedido', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 250,
    spentThisMonth: 0,
    supplierId: 'sup-1',
  });

  assert.equal(decision.status, 'blocked');
});

test('bloquea si supera el límite mensual', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 100,
    spentThisMonth: 750,
    supplierId: 'sup-1',
  });

  assert.equal(decision.status, 'blocked');
});

test('bloquea proveedores no permitidos', () => {
  const decision = evaluateSpendingRules({
    rules: { ...rules, allowedSupplierIds: ['sup-1'] },
    orderTotal: 10,
    spentThisMonth: 0,
    supplierId: 'sup-9',
  });

  assert.equal(decision.status, 'blocked');
});

test('mapea reglas de Supabase con valores por defecto', () => {
  const mapped = mapSpendingRules({
    max_per_order: '150.50',
    monthly_limit: null,
    require_approval_above: 25,
    allowed_supplier_ids: ['sup-1'],
  });

  assert.equal(mapped.maxPerOrder, 150.5);
  assert.equal(mapped.monthlyLimit, 800);
  assert.equal(mapped.requireApprovalAbove, 25);
  assert.deepEqual(mapped.allowedSupplierIds, ['sup-1']);
});
