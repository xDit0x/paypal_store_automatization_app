import assert from 'node:assert/strict';
import test from 'node:test';

import {
  evaluateSpendingRules,
  type SpendingRules,
} from '../src/domain/spending_rules.js';
import { describeSpendingBlock } from '../src/application/orders/describe_spending_block.js';

const rules: SpendingRules = {
  maxPerOrder: 200,
  monthlyLimit: 800,
  requireApprovalAbove: 50,
  allowedSupplierIds: [],
};

const context = {
  orderTotal: 250,
  spentThisMonth: 600,
  currency: 'EUR',
  maxPerOrder: rules.maxPerOrder,
  monthlyLimit: rules.monthlyLimit,
};

test('explica el bloqueo por encima del máximo por pedido con ambos importes', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 250,
    spentThisMonth: 0,
    supplierId: 'sup-1',
  });

  assert.equal(
    describeSpendingBlock(decision, context),
    'supera el máximo por pedido (250.00 EUR de 200.00 EUR)',
  );
});

test('explica el bloqueo mensual sumando lo gastado y el pedido', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 100,
    spentThisMonth: 750,
    supplierId: 'sup-1',
  });

  assert.equal(
    describeSpendingBlock(decision, { ...context, orderTotal: 100, spentThisMonth: 750 }),
    'supera el límite mensual (850.00 EUR de 800.00 EUR)',
  );
});

test('explica un proveedor no permitido', () => {
  const decision = evaluateSpendingRules({
    rules: { ...rules, allowedSupplierIds: ['sup-1'] },
    orderTotal: 10,
    spentThisMonth: 0,
    supplierId: 'sup-9',
  });

  assert.equal(
    describeSpendingBlock(decision, context),
    'el proveedor no está en la lista de proveedores permitidos',
  );
});

test('explica un pedido sin importe', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 0,
    spentThisMonth: 0,
    supplierId: 'sup-1',
  });

  assert.equal(describeSpendingBlock(decision, context), 'el pedido no tiene importe');
});

test('recorta el punto final del motivo de reserva', () => {
  const reason = describeSpendingBlock(
    { status: 'blocked', reason: 'lo bloquea una regla antigua.' },
    context,
  );

  assert.equal(reason, 'lo bloquea una regla antigua');
});
