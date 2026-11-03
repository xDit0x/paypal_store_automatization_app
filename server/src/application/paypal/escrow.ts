import { paypalRequest } from './paypal_client.js';

export interface AuthorizationOrder {
  orderId: string;
  approveUrl: string | null;
  status: string;
}

export interface AuthorizationResult {
  authorizationId: string;
  status: string;
}

export interface CaptureResult {
  captureId: string;
  status: string;
  amount: number;
}

/**
 * Crea una orden de PayPal con intención AUTHORIZE: el dinero queda
 * retenido, no cobrado. Devuelve el enlace para que el pagador apruebe.
 */
export async function createAuthorizationOrder(params: {
  amount: number;
  currency: string;
  referenceId: string;
  returnUrl: string;
  cancelUrl: string;
}): Promise<AuthorizationOrder> {
  const body = {
    intent: 'AUTHORIZE',
    purchase_units: [
      {
        reference_id: params.referenceId,
        amount: {
          currency_code: params.currency,
          value: params.amount.toFixed(2),
        },
      },
    ],
    payment_source: {
      paypal: {
        experience_context: {
          return_url: params.returnUrl,
          cancel_url: params.cancelUrl,
          user_action: 'PAY_NOW',
        },
      },
    },
  };

  const result = await paypalRequest<{
    id: string;
    status: string;
    links?: { rel: string; href: string }[];
  }>('/v2/checkout/orders', { method: 'POST', body });

  const approveUrl =
    result.links?.find((link) => link.rel === 'payer-action')?.href ??
    result.links?.find((link) => link.rel === 'approve')?.href ??
    null;

  return {
    orderId: result.id,
    approveUrl,
    status: result.status,
  };
}

/** Devuelve el enlace de aprobación de una orden de PayPal ya creada. */
export async function getApprovalUrl(
  orderId: string,
): Promise<string | null> {
  const result = await paypalRequest<{
    links?: { rel: string; href: string }[];
  }>(`/v2/checkout/orders/${orderId}`, { method: 'GET' });

  return (
    result.links?.find((link) => link.rel === 'payer-action')?.href ??
    result.links?.find((link) => link.rel === 'approve')?.href ??
    null
  );
}

/** Autoriza la orden creada (el pagador ya aprobó en PayPal). */
export async function authorizeOrder(
  orderId: string,
): Promise<AuthorizationResult> {
  const result = await paypalRequest<{
    status: string;
    purchase_units?: {
      payments?: {
        authorizations?: { id: string; status: string }[];
      };
    }[];
  }>(`/v2/checkout/orders/${orderId}/authorize`, { method: 'POST' });

  const authorization = result.purchase_units?.[0]?.payments?.authorizations?.[0];
  if (!authorization?.id) {
    throw new Error('PayPal no devolvió la autorización del pago.');
  }

  return {
    authorizationId: authorization.id,
    status: authorization.status,
  };
}

/**
 * Cobra todo o parte de una autorización. Para una captura parcial hay que
 * marcar `final_capture` (PayPal no permite capturar dos veces parcialmente
 * una misma autorización).
 */
export async function captureAuthorization(params: {
  authorizationId: string;
  amount?: number;
  currency?: string;
}): Promise<CaptureResult> {
  const body = params.amount
    ? {
        amount: {
          currency_code: params.currency ?? 'EUR',
          value: params.amount.toFixed(2),
        },
        final_capture: true,
      }
    : { final_capture: true };

  const result = await paypalRequest<{
    id: string;
    status: string;
    amount?: { value: string; currency_code: string };
  }>(`/v2/payments/authorizations/${params.authorizationId}/capture`, {
    method: 'POST',
    body,
  });

  return {
    captureId: result.id,
    status: result.status,
    amount: Number(result.amount?.value ?? params.amount ?? 0),
  };
}

/** Reembolsa una captura ya cobrada. */
export async function refundCapture(params: {
  captureId: string;
  amount?: number;
  currency?: string;
}): Promise<{ refundId: string; status: string }> {
  const body = params.amount
    ? {
        amount: {
          currency_code: params.currency ?? 'EUR',
          value: params.amount.toFixed(2),
        },
      }
    : {};

  const result = await paypalRequest<{ id: string; status: string }>(
    `/v2/payments/captures/${params.captureId}/refund`,
    { method: 'POST', body },
  );

  return { refundId: result.id, status: result.status };
}
