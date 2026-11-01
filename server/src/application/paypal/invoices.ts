import { paypalRequest } from './paypal_client.js';

export interface InvoiceLine {
  name: string;
  qty: number;
  unitPrice: number;
}

export interface InvoiceResult {
  invoiceId: string;
  status: string;
}

export function buildInvoiceBody(params: {
  invoiceNumber: string;
  currency: string;
  recipientEmail: string;
  invoicerEmail: string;
  note: string;
  lines: InvoiceLine[];
}) {
  return {
    detail: {
      invoice_number: params.invoiceNumber,
      currency_code: params.currency,
      note: params.note,
      payment_term: { term_type: 'DUE_ON_RECEIPT' },
    },
    // El proveedor es quien emite (invoicer); la tienda quien recibe.
    invoicer: { email_address: params.invoicerEmail },
    primary_recipients: [
      { billing_info: { email_address: params.recipientEmail } },
    ],
    items: params.lines.map((line) => ({
      name: line.name,
      quantity: String(line.qty),
      unit_amount: {
        currency_code: params.currency,
        value: line.unitPrice.toFixed(2),
      },
    })),
  };
}

export async function createAndSendInvoice(params: {
  invoiceNumber: string;
  currency: string;
  /** Quien recibe la factura: la tienda. */
  recipientEmail: string;
  /** Quien emite la factura: el proveedor. */
  invoicerEmail: string;
  note: string;
  lines: InvoiceLine[];
}): Promise<InvoiceResult> {
  const body = buildInvoiceBody(params);

  const created = await paypalRequest<{
    id?: string;
    status?: string;
    href?: string;
  }>('/v2/invoicing/invoices', { method: 'POST', body });

  const invoiceId = created.id ?? created.href?.split('/').pop();
  if (!invoiceId) {
    throw new Error('PayPal no devolvió el ID de la factura.');
  }

  await paypalRequest(`/v2/invoicing/invoices/${invoiceId}/send`, {
    method: 'POST',
    body: { send_to_recipient: true, send_to_invoicer: false },
  });

  return { invoiceId, status: 'sent' };
}
