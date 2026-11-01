import { sendEmail } from './resend_client.js';

export interface PurchaseEmailLine {
  name: string;
  qty: number;
  unitPrice: number;
  lineTotal: number;
}

export interface PurchaseEmailInput {
  orderNumber: string;
  supplierName: string;
  storeName: string;
  currency: string;
  total: number;
  payoutId: string;
  payoutStatus: string;
  lines: PurchaseEmailLine[];
  supplierEmail: string | null;
  ownerEmail: string | null;
}

function money(currency: string, value: number): string {
  return new Intl.NumberFormat('es-ES', {
    style: 'currency',
    currency: currency || 'EUR',
  }).format(value);
}

function linesToText(lines: PurchaseEmailLine[], currency: string): string {
  return lines
    .map(
      (line) =>
        `- ${line.name}: ${line.qty} × ${money(currency, line.unitPrice)} = ${money(currency, line.lineTotal)}`,
    )
    .join('\n');
}

function linesToHtml(lines: PurchaseEmailLine[], currency: string): string {
  return lines
    .map(
      (line) => `
        <tr>
          <td style="padding:8px 12px;border-bottom:1px solid #eee">${line.name}</td>
          <td style="padding:8px 12px;border-bottom:1px solid #eee;text-align:right">${line.qty}</td>
          <td style="padding:8px 12px;border-bottom:1px solid #eee;text-align:right">${money(currency, line.unitPrice)}</td>
          <td style="padding:8px 12px;border-bottom:1px solid #eee;text-align:right">${money(currency, line.lineTotal)}</td>
        </tr>`,
    )
    .join('');
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildText(input: PurchaseEmailInput): string {
  return [
    `Pedido de compra ${input.orderNumber}`,
    '',
    `Proveedor: ${input.supplierName}`,
    `Tienda: ${input.storeName}`,
    '',
    'Productos:',
    linesToText(input.lines, input.currency),
    '',
    `Total: ${money(input.currency, input.total)}`,
    `Pago PayPal: ${input.payoutId} (${input.payoutStatus})`,
    '',
    'Este email se ha generado automáticamente tras confirmarse el pago.',
  ].join('\n');
}

function buildHtml(input: PurchaseEmailInput): string {
  return `<!doctype html>
<html lang="es">
  <body style="margin:0;padding:24px;background:#f6f7f9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#111">
    <div style="max-width:640px;margin:0 auto;background:#fff;border-radius:12px;padding:24px">
      <h1 style="margin:0 0 4px;font-size:20px">Pedido de compra ${escapeHtml(input.orderNumber)}</h1>
      <p style="margin:0 0 16px;color:#666">${escapeHtml(input.supplierName)} · ${escapeHtml(input.storeName)}</p>

      <table style="width:100%;border-collapse:collapse;font-size:14px">
        <thead>
          <tr style="text-align:left;color:#666">
            <th style="padding:8px 12px;border-bottom:2px solid #eee">Producto</th>
            <th style="padding:8px 12px;border-bottom:2px solid #eee;text-align:right">Cantidad</th>
            <th style="padding:8px 12px;border-bottom:2px solid #eee;text-align:right">Precio</th>
            <th style="padding:8px 12px;border-bottom:2px solid #eee;text-align:right">Importe</th>
          </tr>
        </thead>
        <tbody>${linesToHtml(input.lines, input.currency)}</tbody>
      </table>

      <p style="margin:16px 0 0;font-size:18px;font-weight:700;text-align:right">
        Total: ${money(input.currency, input.total)}
      </p>

      <div style="margin-top:16px;padding:12px;background:#f0f4ff;border-radius:8px;font-size:13px">
        <strong>Pago PayPal:</strong> ${escapeHtml(input.payoutId)} (${escapeHtml(input.payoutStatus)})
      </div>

      <p style="margin:16px 0 0;font-size:12px;color:#888">
        Este email se ha generado automáticamente tras confirmarse el pago.
      </p>
    </div>
  </body>
</html>`;
}

export async function sendPurchaseOrderEmail(
  input: PurchaseEmailInput,
): Promise<{ supplierSent: boolean; ownerSent: boolean }> {
  const subject = `Pedido de compra ${input.orderNumber} — ${input.storeName}`;
  const html = buildHtml(input);
  const text = buildText(input);

  let supplierSent = false;
  let ownerSent = false;

  if (input.supplierEmail) {
    await sendEmail({
      to: [input.supplierEmail],
      subject,
      html,
      text,
    });
    supplierSent = true;
  }

  if (input.ownerEmail) {
    await sendEmail({
      to: [input.ownerEmail],
      subject: `Copia: ${subject}`,
      html,
      text,
    });
    ownerSent = true;
  }

  return { supplierSent, ownerSent };
}

export async function sendPaymentFailedEmail(input: {
  orderNumber: string;
  supplierName: string;
  storeName: string;
  reason: string;
  ownerEmail: string | null;
}): Promise<boolean> {
  if (!input.ownerEmail) return false;

  await sendEmail({
    to: [input.ownerEmail],
    subject: `Pago fallido del pedido ${input.orderNumber}`,
    text: [
      `No se pudo pagar el pedido ${input.orderNumber} a ${input.supplierName}.`,
      '',
      `Motivo: ${input.reason}`,
      '',
      'El proveedor no ha recibido ningún aviso de compra.',
    ].join('\n'),
    html: `<!doctype html>
<html lang="es">
  <body style="margin:0;padding:24px;background:#f6f7f9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#111">
    <div style="max-width:560px;margin:0 auto;background:#fff;border-radius:12px;padding:24px">
      <h1 style="margin:0 0 8px;font-size:20px">Pago fallido</h1>
      <p style="margin:0 0 16px;color:#666">
        No se pudo pagar el pedido <strong>${input.orderNumber}</strong>
        a <strong>${input.supplierName}</strong>.
      </p>
      <div style="padding:12px;background:#fff4f4;border-radius:8px;font-size:13px">
        <strong>Motivo:</strong> ${input.reason}
      </div>
      <p style="margin:16px 0 0;font-size:12px;color:#888">
        El proveedor no ha recibido ningún aviso de compra.
      </p>
    </div>
  </body>
</html>`,
  });

  return true;
}
