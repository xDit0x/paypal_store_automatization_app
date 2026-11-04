import assert from 'node:assert/strict';
import test from 'node:test';

import { deliveryPaymentMode } from '../src/application/orders/escrow_flow.js';

// El pedido con el dinero retenido en PayPal cobra lo que llega.
test('un pedido autorizado captura el pago al confirmar la entrega', () => {
  assert.equal(deliveryPaymentMode('authorized'), 'capture');
});

// El agente paga solo: al confirmar la entrega no se cobra nada más.
test('un pedido ya pagado no se vuelve a cobrar', () => {
  assert.equal(deliveryPaymentMode('paid'), 'already_paid');
  assert.equal(deliveryPaymentMode('invoiced'), 'already_paid');
});

// Los pedidos que no están listos no se pueden confirmar.
test('los demás estados no permiten confirmar la entrega', () => {
  for (const status of ['draft', 'pending_approval', 'approved', 'delivered', 'rejected']) {
    assert.equal(deliveryPaymentMode(status), null, status);
  }
});
