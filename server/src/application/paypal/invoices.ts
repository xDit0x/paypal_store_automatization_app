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

export async function createAndSendInvoice(params: {
  invoiceNumber: string;
  currency: string;
  recipientEmail: string;
  merchantEmail: string;
  note: string;
  lines: InvoiceLine[];
}): Promise<InvoiceResult> {
  const body = {
    detail: {
      invoice_number: params.invoiceNumber,
      currency_code: params.currency,
      note: params.note,
      payment_term: { term_type: 'DUE_ON_RECEIPT' },
    },
    invoicer: { email_address: params.merchantEmail },
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
