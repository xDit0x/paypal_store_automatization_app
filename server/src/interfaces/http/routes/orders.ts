import type { FastifyInstance } from 'fastify';

import { fulfillOrder } from '../../../application/orders/fulfill_order.js';
import { supabaseAdmin } from '../../../infrastructure/supabase/supabase_client.js';
import { authenticate } from '../auth.js';

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

export async function orderRoutes(app: FastifyInstance): Promise<void> {
  app.post<{ Params: { id: string } }>(
    '/orders/:id/approve',
    async (request, reply) => {
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
            status: 'approved',
            approval_by: user.id,
            approval_at: new Date().toISOString(),
          })
          .eq('id', order.id);

        if (error) {
          throw new Error(`No se pudo aprobar el pedido: ${error.message}`);
        }

        const fulfillment = await fulfillOrder(order.id);
        return reply.send({ order_id: order.id, ...fulfillment });
      } catch (error) {
        request.log.error(error);
        const message =
          error instanceof Error ? error.message : 'Error al aprobar el pedido.';
        return reply.code(502).send({ error: message });
      }
    },
  );

  app.post<{ Params: { id: string } }>(
    '/orders/:id/reject',
    async (request, reply) => {
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
        const message =
          error instanceof Error
            ? error.message
            : 'Error al rechazar el pedido.';
        return reply.code(500).send({ error: message });
      }
    },
  );
}
