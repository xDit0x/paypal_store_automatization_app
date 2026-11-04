import assert from 'node:assert/strict';
import test from 'node:test';

import {
  evaluateSpendingRules,
  type SpendingRules,
} from '../src/domain/spending_rules.js';
import { describeReason } from '../src/application/i18n/reasons.js';
import { languageOf } from '../src/application/i18n/messages.js';

const rules: SpendingRules = {
  maxPerOrder: 200,
  monthlyLimit: 800,
  requireApprovalAbove: 50,
  allowedSupplierIds: [],
};

test('explica el bloqueo por encima del máximo por pedido con ambos importes', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 250,
    spentThisMonth: 0,
    supplierId: 'sup-1',
    currency: 'EUR',
  });

  assert.equal(
    describeReason(decision.reason!),
    'supera el máximo por pedido (250.00 EUR de 200.00 EUR)',
  );
});

test('explica el bloqueo mensual sumando lo gastado y el pedido', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 100,
    spentThisMonth: 750,
    supplierId: 'sup-1',
    currency: 'EUR',
  });

  assert.equal(
    describeReason(decision.reason!),
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
    describeReason(decision.reason!),
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

  assert.equal(describeReason(decision.reason!), 'el pedido no tiene importe');
});

test('explica el bloqueo en inglés cuando la app va en inglés', () => {
  const decision = evaluateSpendingRules({
    rules,
    orderTotal: 100,
    spentThisMonth: 750,
    supplierId: 'sup-1',
    currency: 'EUR',
  });

  assert.equal(
    describeReason(decision.reason!, 'en'),
    'it exceeds the monthly limit (850.00 EUR of 800.00 EUR)',
  );
});

test('el mismo motivo se explica en los dos idiomas', () => {
  const reason = { code: 'wrong_status', params: { status: 'approved' } } as const;

  assert.equal(
    describeReason(reason, 'es'),
    'el pedido está en estado "approved"',
  );
  assert.equal(
    describeReason(reason, 'en'),
    'the order is in status "approved"',
  );
});

test('el idioma se detecta a partir del que manda la app', () => {
  assert.equal(languageOf('en'), 'en');
  assert.equal(languageOf('en-US'), 'en');
  assert.equal(languageOf('es'), 'es');
  assert.equal(languageOf(null), 'es');
  assert.equal(languageOf(7), 'es');
});
