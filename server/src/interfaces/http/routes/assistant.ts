import type { FastifyInstance } from 'fastify';

import { assistantChat, type ChatTurn } from '../../../application/assistant/assistant_chat.js';
import { adoptMarketOffer } from '../../../application/market/adopt_offer.js';
import { getStoreForOwner } from '../../../application/stores/store_service.js';
import { authenticate } from '../auth.js';
import { createRateLimiter } from '../rate_limit.js';

interface MessageBody {
  store_id?: string;
  messages?: ChatTurn[];
}

interface AdoptBody {
  store_id?: string;
  offer_id?: string;
  search_id?: string | null;
  quantity?: number | null;
  place_order?: boolean;
}

export async function assistantRoutes(app: FastifyInstance): Promise<void> {
  // Cada mensaje llama a la IA (y quizá a la búsqueda web): se limita.
  const chatLimiter = createRateLimiter({ windowMs: 60_000, max: 20 });
  const adoptLimiter = createRateLimiter({ windowMs: 60_000, max: 5 });

  app.post<{ Body: MessageBody }>('/assistant/message', async (request, reply) => {
    const user = await authenticate(request);
    if (!user) return reply.code(401).send({ error: 'Sesión no válida.' });

    const limit = chatLimiter.check(user.id);
    if (!limit.allowed) {
      reply.header('Retry-After', String(limit.retryAfterSeconds));
      return reply.code(429).send({ error: 'Vas muy rápido. Espera un momento.' });
    }

    const storeId = request.body?.store_id;
    const messages = request.body?.messages;
    if (!storeId) return reply.code(400).send({ error: 'Falta store_id.' });
    if (!Array.isArray(messages) || messages.length === 0) {
      return reply.code(400).send({ error: 'Falta el mensaje.' });
    }

    try {
      const store = await getStoreForOwner(storeId, user.id);
      const result = await assistantChat({ store, history: messages });
      return reply.send({
        reply: result.reply,
        quick_replies: result.quickReplies,
        market: result.market,
      });
    } catch (error) {
      request.log.error(error);
      return reply.code(500).send({ error: 'El asistente no pudo responder.' });
    }
  });

  app.post<{ Body: AdoptBody }>('/assistant/adopt', async (request, reply) => {
    const user = await authenticate(request);
    if (!user) return reply.code(401).send({ error: 'Sesión no válida.' });

    const limit = adoptLimiter.check(user.id);
    if (!limit.allowed) {
      reply.header('Retry-After', String(limit.retryAfterSeconds));
      return reply.code(429).send({ error: 'Espera un momento antes de repetir.' });
    }

    const { store_id: storeId, offer_id: offerId } = request.body ?? {};
    if (!storeId || !offerId) return reply.code(400).send({ error: 'Faltan store_id u offer_id.' });

    try {
      const store = await getStoreForOwner(storeId, user.id);
      const result = await adoptMarketOffer({
        store,
        userId: user.id,
        offerId,
        searchId: request.body.search_id ?? null,
        quantity: typeof request.body.quantity === 'number' ? request.body.quantity : null,
        placeOrder: request.body.place_order === true,
      });
      return reply.send(result);
    } catch (error) {
      request.log.error(error);
      return reply.code(500).send({
        error: error instanceof Error ? error.message : 'No se pudo añadir el producto.',
      });
    }
  });
}
