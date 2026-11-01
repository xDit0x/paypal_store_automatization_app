import assert from 'node:assert/strict';
import test from 'node:test';

import { buildInvoiceBody } from '../src/application/paypal/invoices.js';

test('el proveedor emite la factura y la tienda la recibe', () => {
  const body = buildInvoiceBody({
    invoiceNumber: 'RS-ABCD1234',
    currency: 'EUR',
    recipientEmail: 'tienda@example.com',
    invoicerEmail: 'proveedor@example.com',
    note: 'Factura de reposición',
    lines: [{ name: 'Café en grano 1 kg', qty: 2, unitPrice: 12.5 }],
  });

  assert.equal(body.invoicer.email_address, 'proveedor@example.com');
  assert.equal(
    body.primary_recipients[0]?.billing_info.email_address,
    'tienda@example.com',
  );
});

test('la factura lleva las líneas con precio y cantidad', () => {
  const body = buildInvoiceBody({
    invoiceNumber: 'RS-1',
    currency: 'EUR',
    recipientEmail: 'tienda@example.com',
    invoicerEmail: 'proveedor@example.com',
    note: 'Factura',
    lines: [{ name: 'Agua', qty: 4, unitPrice: 0.55 }],
  });

  assert.equal(body.items[0]?.name, 'Agua');
  assert.equal(body.items[0]?.quantity, '4');
  assert.equal(body.items[0]?.unit_amount.value, '0.55');
});
