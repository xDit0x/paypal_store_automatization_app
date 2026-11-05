import assert from 'node:assert/strict';
import test from 'node:test';

process.env.SUPABASE_URL ??= 'https://example.supabase.co';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'test';

async function sumSpent(
  ...args: Parameters<
    typeof import('../src/application/orders/spent_this_month.js').sumSpent
  >
) {
  const module = await import('../src/application/orders/spent_this_month.js');
  return module.sumSpent(...args);
}

const november = new Date('2026-11-01T00:00:00Z');

test('cuenta autorizados, cobrados y pagados del mes actual', async () => {
  const rows = [
    // Autorizado: el dinero está retenido y comprometido.
    { total: 100, authorized_at: '2026-11-02T10:00:00Z' },
    // Cobrado: entra por payment_at.
    { total: 50, payment_at: '2026-11-03T10:00:00Z' },
    // Sin fechas de pago: se usa la de creación.
    { total: 70, created_at: '2026-11-04T00:00:00Z' },
  ];

  assert.equal(await sumSpent(rows, november), 220);
});

test('en una entrega parcial cuenta solo lo cobrado', async () => {
  const rows = [
    {
      total: 80,
      received_total: 25,
      payment_at: '2026-11-05T10:00:00Z',
    },
  ];

  assert.equal(await sumSpent(rows, november), 25);
});

test('un pedido cobrado este mes cuenta aunque se creara antes', async () => {
  const rows = [
    {
      total: 40,
      created_at: '2026-09-15T10:00:00Z',
      payment_at: '2026-11-06T10:00:00Z',
    },
  ];

  assert.equal(await sumSpent(rows, november), 40);
});

test('no cuenta pedidos cobrados en un mes anterior', async () => {
  const rows = [
    { total: 90, payment_at: '2026-10-31T23:59:00Z' },
    { total: 10, payment_at: '2026-11-01T00:00:00Z' },
  ];

  assert.equal(await sumSpent(rows, november), 10);
});

test('un pedido aprobado cuenta solo si ya existe la orden de PayPal', async () => {
  const rows = [
    // Aprobado y con orden de PayPal creada: importe comprometido.
    {
      status: 'approved',
      total: 60,
      payment_payout_id: 'PAYPAL-ORDER-1',
      approval_at: '2026-11-02T10:00:00Z',
    },
    // Aprobado sin orden de PayPal: aún no hay nada comprometido.
    {
      status: 'approved',
      total: 999,
      approval_at: '2026-11-02T10:00:00Z',
    },
  ];

  assert.equal(await sumSpent(rows, november), 60);
});

test('un pedido aprobado usa approval_at para el mes', async () => {
  const rows = [
    {
      status: 'approved',
      total: 30,
      payment_payout_id: 'PAYPAL-ORDER-2',
      created_at: '2026-10-01T10:00:00Z',
      approval_at: '2026-11-02T10:00:00Z',
    },
  ];

  assert.equal(await sumSpent(rows, november), 30);
});

test('una lista vacía no gasta nada', async () => {
  assert.equal(await sumSpent([], november), 0);
});
