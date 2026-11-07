import type { FastifyInstance } from 'fastify';

import {
  DeliveryLine,
  approvalUrlForOrder,
  captureDelivery,
  confirmAuthorization,
  refundOrder,
  startAuthorization,
} from '../../../application/orders/escrow_flow.js';
import { previewOrderAmount } from '../../../application/orders/guard_order_amount.js';
import { errorCopy } from '../../../application/i18n/errors.js';
import { describeReason } from '../../../application/i18n/reasons.js';
import { env } from '../../../config/env.js';
import { ReasonError } from '../../../domain/reasons.js';
import { supabaseAdmin } from '../../../infrastructure/supabase/supabase_client.js';
import { authenticate } from '../auth.js';
import { browserLanguage, requestLanguage } from '../language.js';
import { createRateLimiter } from '../rate_limit.js';

interface OrderRow {
  id: string;
  store_id: string;
  status: string;
  stores:
    | { owner_id: string }
    | { owner_id: string }[]
    | null;
}

async function loadOwnedOrder(
  orderId: string,
  userId: string,
): Promise<OrderRow | null> {
  const { data, error } = await supabaseAdmin
    .from('orders')
    .select('id, store_id, status, stores!inner(owner_id)')
    .eq('id', orderId)
    .maybeSingle();

  if (error) {
    throw new Error(`No se pudo cargar el pedido: ${error.message}`);
  }
  if (!data) return null;

  const row = data as unknown as OrderRow;
  const store = Array.isArray(row.stores) ? row.stores[0] : row.stores;
  if (!store || store.owner_id !== userId) return null;

  return row;
}

interface OrderStatusRow {
  id: string;
  status: string;
  total: number | string;
  payment_provider: string | null;
  payment_payout_id: string | null;
  payment_status: string | null;
  payment_at: string | null;
  invoice_id: string | null;
  invoices:
    | {
        number: string;
        status: string;
        sent_to: string | null;
        sent_at: string | null;
      }[]
    | null;
}

/**
 * Texto de un error del dominio, en el idioma de la app.
 *
 * Si el error no trae motivo estructurado (es un fallo técnico), se devuelve
 * `fallback` para no enseñar un volcado de excepción.
 */
function reasonText(
  error: unknown,
  language: 'es' | 'en',
  fallback: string,
): string {
  if (error instanceof ReasonError) {
    return describeReason(error.reason, language);
  }
  return fallback;
}

export async function orderRoutes(app: FastifyInstance): Promise<void> {
  // Página a la que PayPal redirige al pagador tras aprobar. Confirma la
  // autorización para que el pedido quede listo para la entrega.
  app.get<{ Querystring: { order_id?: string; token?: string; locale?: string } }>(
    '/paypal/return',
    async (request, reply) => {
      const language =
        request.query.locale === 'en' || request.query.locale === 'es'
          ? request.query.locale
          : browserLanguage(request);
      const orderId = request.query.order_id;

      const page = {
        es: {
          missingTitle: 'Faltan datos',
          missingMessage: 'No hemos podido identificar el pedido.',
          notFoundTitle: 'Pedido no encontrado',
          notFoundMessage: 'Vuelve a la app y revisa el pedido.',
          okTitle: 'Pago autorizado',
          okMessage:
            'El importe queda retenido y se cobrará al confirmar la entrega.',
          errorTitle: 'No se pudo confirmar',
          errorMessage:
            'Vuelve a Stocky y pulsa «Ya he autorizado el pago».',
          back: 'Ya puedes volver a Stocky.',
        },
        en: {
          missingTitle: 'Missing data',
          missingMessage: 'We could not identify the order.',
          notFoundTitle: 'Order not found',
          notFoundMessage: 'Go back to the app and check the order.',
          okTitle: 'Payment authorized',
          okMessage:
            'The amount is held and will be charged when the delivery is confirmed.',
          errorTitle: 'Could not confirm',
          errorMessage:
            'Go back to Stocky and tap "I have authorized the payment".',
          back: 'You can go back to Stocky now.',
        },
      }[language];

      const appReturnUrl =
        env.appUrl || env.publicBaseUrl || 'https://stocky-app-theta.vercel.app';
      const buttonLabel = language === 'es' ? 'Volver a Stocky' : 'Back to Stocky';
      const redirectNote =
        language === 'es'
          ? 'Volviendo a Stocky en unos segundos...'
          : 'Returning to Stocky in a few seconds...';

      const html = (
        title: string,
        message: string,
        ok: boolean,
        redirect = false,
      ) => {
        const auto =
          redirect && ok
            ? `<meta http-equiv="refresh" content="3;url=${appReturnUrl}">` +
              `<script>setTimeout(function(){window.location.href=${JSON.stringify(appReturnUrl)};},3000);</script>`
            : '';
        const note =
          redirect && ok
            ? `<p style="color:#888;font-size:13px">${redirectNote}</p>`
            : `<p style="color:#888;font-size:13px">${page.back}</p>`;
        return (
          `<!doctype html><html lang="${language}"><head><meta charset="utf-8">` +
          `<meta name="viewport" content="width=device-width,initial-scale=1">` +
          auto +
          `<title>${title}</title></head>` +
          `<body style="font-family:-apple-system,system-ui,sans-serif;text-align:center;padding:48px 24px;background:#f6f6f8">` +
          `<div style="font-size:48px">${ok ? '✅' : '⚠️'}</div>` +
          `<h1 style="font-size:22px">${title}</h1>` +
          `<p style="color:#555;line-height:1.5">${message}</p>` +
          `<p style="margin:24px 0"><a href="${appReturnUrl}" style="display:inline-block;background:#111827;color:#fff;text-decoration:none;padding:12px 18px;border-radius:10px;font-weight:600">${buttonLabel}</a></p>` +
          note +
          `</body></html>`
        );
      };

      if (!orderId) {
        return reply
          .code(400)
          .type('text/html; charset=utf-8')
          .send(html(page.missingTitle, page.missingMessage, false));
      }

      try {
        const { data } = await supabaseAdmin
          .from('orders')
          .select('id, status')
          .eq('id', orderId)
          .maybeSingle();

        if (!data) {
          return reply
            .code(404)
            .type('text/html; charset=utf-8')
            .send(html(page.notFoundTitle, page.notFoundMessage, false));
        }

        if (data.status === 'approved') {
          await confirmAuthorization(orderId, request.query.token ?? null);
        }

        return reply
          .type('text/html; charset=utf-8')
          .send(html(page.okTitle, page.okMessage, true, true));
      } catch (error) {
        request.log.error(error);
        return reply
          .code(502)
          .type('text/html; charset=utf-8')
          .send(html(page.errorTitle, page.errorMessage, false));
      }
    },
  );

  // Aprobar mueve dinero: se limita por usuario.
  const paymentLimiter = createRateLimiter({ windowMs: 60_000, max: 20 });
  app.get<{ Params: { id: string } }>(
    '/orders/:id/status',
    async (request, reply) => {
      const language = requestLanguage(request);
      const text = errorCopy[language];

      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: text.sessionInvalid });
      }

      try {
        const owned = await loadOwnedOrder(request.params.id, user.id);
        if (!owned) {
          return reply.code(404).send({ error: text.orderNotFound });
        }

        const { data, error } = await supabaseAdmin
          .from('orders')
          .select(
            'id, status, total, payment_provider, payment_payout_id, payment_status, payment_at, invoice_id, invoices!invoices_order_id_fkey(number, status, sent_to, sent_at)',
          )
          .eq('id', owned.id)
          .maybeSingle();

        if (error) {
          throw new Error(`No se pudo leer el pedido: ${error.message}`);
        }

        const order = data as unknown as OrderStatusRow;
        const invoice = order.invoices?.[0] ?? null;

        return reply.send({
          order_id: order.id,
          status: order.status,
          total: Number(order.total),
          payment: order.payment_payout_id
            ? {
                provider: order.payment_provider,
                payout_id: order.payment_payout_id,
                status: order.payment_status,
                paid_at: order.payment_at,
              }
            : null,
          invoice: invoice
            ? {
                id: order.invoice_id,
                number: invoice.number,
                status: invoice.status,
                sent_to: invoice.sent_to,
                sent_at: invoice.sent_at,
              }
            : null,
        });
      } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ error: text.orderLoadFailed });
      }
    },
  );

  app.get<{ Params: { id: string } }>(
    '/orders/:id/amount',
    async (request, reply) => {
      const language = requestLanguage(request);
      const text = errorCopy[language];

      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: text.sessionInvalid });
      }

      try {
        const owned = await loadOwnedOrder(request.params.id, user.id);
        if (!owned) {
          return reply.code(404).send({ error: text.orderNotFound });
        }

        // Importe que se pagaría ahora, con el catálogo vigente.
        const review = await previewOrderAmount(owned.id);
        return reply.send({
          order_id: owned.id,
          total: review.total,
          previous_total: review.previousTotal,
          changed: review.changed,
          blockedReason: review.blockedReason
            ? describeReason(review.blockedReason, language)
            : null,
        });
      } catch (error) {
        return reply.code(409).send({
          error: reasonText(error, language, text.orderAmountFailed),
        });
      }
    },
  );

  app.post<{ Params: { id: string } }>(
    '/orders/:id/approve',
    async (request, reply) => {
      const language = requestLanguage(request);
      const text = errorCopy[language];

      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: text.sessionInvalid });
      }

      const { allowed, retryAfterSeconds } = paymentLimiter.check(user.id);
      if (!allowed) {
        reply.header('Retry-After', String(retryAfterSeconds));
        return reply
          .code(429)
          .send({ error: text.approvalsRateLimited });
      }

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) {
          return reply.code(404).send({ error: text.orderNotFound });
        }
        if (!['draft', 'pending_approval'].includes(order.status)) {
          return reply.code(409).send({
            error: describeReason(
              { code: 'wrong_status', params: { status: order.status } },
              language,
            ),
          });
        }

        // Al aprobar no se cobra: se crea una autorización de PayPal y se
        // devuelve el enlace para que el dueño la apruebe. El dinero queda
        // retenido hasta que confirme la entrega.
        let auth;
        try {
          auth = await startAuthorization(order.id, {
            ownerApproved: true,
            locale: language,
          });
        } catch (error) {
          return reply.code(409).send({
            error: reasonText(error, language, text.orderAmountMismatch),
          });
        }

        const { error } = await supabaseAdmin
          .from('orders')
          .update({
            approval_by: user.id,
            approval_at: new Date().toISOString(),
          })
          .eq('id', order.id);

        if (error) {
          throw new Error(`No se pudo aprobar el pedido: ${error.message}`);
        }

        return reply.send({
          order_id: order.id,
          total: auth.total,
          previous_total: auth.previousTotal,
          total_changed: auth.changed,
          paypal_order_id: auth.paypalOrderId,
          approve_url: auth.approveUrl,
          payment_status: 'CREATED',
          orderStatus: 'approved',
          warnings: [],
        });
      } catch (error) {
        request.log.error(error);
        return reply.code(502).send({
          error: text.paymentFailed,
        });
      }
    },
  );

  app.get<{ Params: { id: string } }>(
    '/orders/:id/approve-url',
    async (request, reply) => {
      const language = requestLanguage(request);
      const text = errorCopy[language];

      const user = await authenticate(request);
      if (!user) return reply.code(401).send({ error: text.sessionInvalid });

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) return reply.code(404).send({ error: text.orderNotFound });
        if (order.status !== 'approved') {
          return reply.code(409).send({
            error: describeReason(
              { code: 'wrong_status', params: { status: order.status } },
              language,
            ),
          });
        }

        const approveUrl = await approvalUrlForOrder(order.id);
        return reply.send({ order_id: order.id, approve_url: approveUrl });
      } catch (error) {
        request.log.error(error);
        return reply.code(502).send({ error: text.paypalLinkFailed });
      }
    },
  );

  app.post<{ Params: { id: string }; Body: { paypal_order_id?: string } | null }>(
    '/orders/:id/confirm-auth',
    async (request, reply) => {
      const language = requestLanguage(request);
      const text = errorCopy[language];

      const user = await authenticate(request);
      if (!user) return reply.code(401).send({ error: text.sessionInvalid });

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) return reply.code(404).send({ error: text.orderNotFound });
        if (order.status !== 'approved') {
          return reply.code(409).send({
            error: describeReason(
              { code: 'wrong_status', params: { status: order.status } },
              language,
            ),
          });
        }

        const auth = await confirmAuthorization(
          order.id,
          request.body?.paypal_order_id ?? null,
        );
        return reply.send({ order_id: order.id, ...auth });
      } catch (error) {
        request.log.error(error);
        return reply.code(502).send({ error: text.authConfirmFailed });
      }
    },
  );

  app.post<{ Params: { id: string }; Body: { lines: DeliveryLine[] } }>(
    '/orders/:id/capture',
    async (request, reply) => {
      const language = requestLanguage(request);
      const text = errorCopy[language];

      const user = await authenticate(request);
      if (!user) return reply.code(401).send({ error: text.sessionInvalid });

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) return reply.code(404).send({ error: text.orderNotFound });

        const capture = await captureDelivery(order.id, request.body.lines, {
          locale: language,
        });
        return reply.send({ order_id: order.id, ...capture });
      } catch (error) {
        request.log.error(error);
        return reply.code(502).send({
          error: reasonText(error, language, text.captureFailed),
        });
      }
    },
  );

  app.post<{ Params: { id: string }; Body: { amount?: number } }>(
    '/orders/:id/refund',
    async (request, reply) => {
      const language = requestLanguage(request);
      const text = errorCopy[language];

      const user = await authenticate(request);
      if (!user) return reply.code(401).send({ error: text.sessionInvalid });

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) return reply.code(404).send({ error: text.orderNotFound });

        const refund = await refundOrder(order.id, request.body.amount);
        return reply.send({ order_id: order.id, ...refund });
      } catch (error) {
        request.log.error(error);
        return reply.code(502).send({ error: text.refundFailed });
      }
    },
  );
  app.post<{ Params: { id: string } }>(
    '/orders/:id/reject',
    async (request, reply) => {
      const language = requestLanguage(request);
      const text = errorCopy[language];

      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: text.sessionInvalid });
      }

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) {
          return reply.code(404).send({ error: text.orderNotFound });
        }
        if (!['draft', 'pending_approval'].includes(order.status)) {
          return reply.code(409).send({
            error: describeReason(
              { code: 'wrong_status', params: { status: order.status } },
              language,
            ),
          });
        }

        const { error } = await supabaseAdmin
          .from('orders')
          .update({
            status: 'rejected',
            approval_by: user.id,
            approval_at: new Date().toISOString(),
          })
          .eq('id', order.id);

        if (error) {
          throw new Error(`No se pudo rechazar el pedido: ${error.message}`);
        }

        return reply.send({ order_id: order.id, status: 'rejected' });
      } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ error: text.rejectFailed });
      }
    },
  );
}
