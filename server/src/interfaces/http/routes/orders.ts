import type { FastifyInstance } from 'fastify';

import {
  captureDelivery,
  confirmAuthorization,
  refundOrder,
  startAuthorization,
} from '../../../application/orders/escrow_flow.js';
import { previewOrderAmount } from '../../../application/orders/guard_order_amount.js';
import { supabaseAdmin } from '../../../infrastructure/supabase/supabase_client.js';
import { authenticate } from '../auth.js';
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

export async function orderRoutes(app: FastifyInstance): Promise<void> {
  // Aprobar mueve dinero: se limita por usuario.
  const paymentLimiter = createRateLimiter({ windowMs: 60_000, max: 20 });
  app.get<{ Params: { id: string } }>(
    '/orders/:id/status',
    async (request, reply) => {
      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: 'Sesión no válida.' });
      }

      try {
        const owned = await loadOwnedOrder(request.params.id, user.id);
        if (!owned) {
          return reply.code(404).send({ error: 'Pedido no encontrado.' });
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
        return reply.code(500).send({ error: 'No se pudo consultar el pedido.' });
      }
    },
  );

  app.get<{ Params: { id: string } }>(
    '/orders/:id/amount',
    async (request, reply) => {
      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: 'Sesión no válida.' });
      }

      try {
        const owned = await loadOwnedOrder(request.params.id, user.id);
        if (!owned) {
          return reply.code(404).send({ error: 'Pedido no encontrado.' });
        }

        // Importe que se pagaría ahora, con el catálogo vigente.
        const review = await previewOrderAmount(owned.id);
        return reply.send({
          order_id: owned.id,
          total: review.total,
          previous_total: review.previousTotal,
          changed: review.changed,
        });
      } catch (error) {
        return reply.code(409).send({
          error:
            error instanceof Error
              ? error.message
              : 'No se pudo calcular el importe del pedido.',
        });
      }
    },
  );

  app.post<{ Params: { id: string } }>(
    '/orders/:id/approve',
    async (request, reply) => {
      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: 'Sesión no válida.' });
      }

      const { allowed, retryAfterSeconds } = paymentLimiter.check(user.id);
      if (!allowed) {
        reply.header('Retry-After', String(retryAfterSeconds));
        return reply
          .code(429)
          .send({ error: 'Demasiadas aprobaciones seguidas. Espera un momento.' });
      }

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) {
          return reply.code(404).send({ error: 'Pedido no encontrado.' });
        }
        if (!['draft', 'pending_approval'].includes(order.status)) {
          return reply
            .code(409)
            .send({ error: `El pedido está en estado "${order.status}".` });
        }

        // Al aprobar no se cobra: se crea una autorización de PayPal y se
        // devuelve el enlace para que el dueño la apruebe. El dinero queda
        // retenido hasta que confirme la entrega.
        let auth;
        try {
          auth = await startAuthorization(order.id, { ownerApproved: true });
        } catch (error) {
          return reply.code(409).send({
            error:
              error instanceof Error
                ? error.message
                : 'El pedido no supera la comprobación de importe.',
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
          error: 'No se pudo completar el pago del pedido.',
        });
      }
    },
  );

  app.post<{ Params: { id: string }; Body: { paypal_order_id: string } }>(
    '/orders/:id/confirm-auth',
    async (request, reply) => {
      const user = await authenticate(request);
      if (!user) return reply.code(401).send({ error: 'Sesión no válida.' });

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) return reply.code(404).send({ error: 'Pedido no encontrado.' });
        if (order.status !== 'approved') {
          return reply.code(409).send({ error: `El pedido está en estado "${order.status}".` });
        }

        const auth = await confirmAuthorization(order.id, request.body.paypal_order_id);
        return reply.send({ order_id: order.id, ...auth });
      } catch (error) {
        request.log.error(error);
        return reply.code(502).send({ error: 'No se pudo confirmar la autorización.' });
      }
    },
  );

  app.post<{ Params: { id: string }; Body: { lines: DeliveryLine[] } }>(
    '/orders/:id/capture',
    async (request, reply) => {
      const user = await authenticate(request);
      if (!user) return reply.code(401).send({ error: 'Sesión no válida.' });

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) return reply.code(404).send({ error: 'Pedido no encontrado.' });
        
        const capture = await captureDelivery(order.id, request.body.lines);
        return reply.send({ order_id: order.id, ...capture });
      } catch (error) {
        request.log.error(error);
        return reply.code(502).send({ 
          error: error instanceof Error ? error.message : 'No se pudo capturar el pago.' 
        });
      }
    },
  );

  app.post<{ Params: { id: string }; Body: { amount?: number } }>(
    '/orders/:id/refund',
    async (request, reply) => {
      const user = await authenticate(request);
      if (!user) return reply.code(401).send({ error: 'Sesión no válida.' });

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) return reply.code(404).send({ error: 'Pedido no encontrado.' });
        
        const refund = await refundOrder(order.id, request.body.amount);
        return reply.send({ order_id: order.id, ...refund });
      } catch (error) {
        request.log.error(error);
        return reply.code(502).send({ error: 'No se pudo reembolsar el pago.' });
      }
    },
  );
      const user = await authenticate(request);
      if (!user) {
        return reply.code(401).send({ error: 'Sesión no válida.' });
      }

      try {
        const order = await loadOwnedOrder(request.params.id, user.id);
        if (!order) {
          return reply.code(404).send({ error: 'Pedido no encontrado.' });
        }
        if (!['draft', 'pending_approval'].includes(order.status)) {
          return reply
            .code(409)
            .send({ error: `El pedido está en estado "${order.status}".` });
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
        return reply.code(500).send({ error: 'No se pudo rechazar el pedido.' });
      }
    },
  );
}
