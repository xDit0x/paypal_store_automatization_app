import type { FastifyInstance } from 'fastify';

import { assistantChat, type ChatTurn } from '../../../application/assistant/assistant_chat.js';
import { errorCopy } from '../../../application/i18n/errors.js';
import { adoptMarketOffer } from '../../../application/market/adopt_offer.js';
import { getStoreForOwner } from '../../../application/stores/store_service.js';
import { authenticate } from '../auth.js';
import { requestLanguage } from '../language.js';
import { createRateLimiter } from '../rate_limit.js';

interface MessageBody {
  store_id?: string;
  messages?: ChatTurn[];
  /** Idioma de la app: 'es' o 'en'. */
  locale?: string;
}

interface AdoptBody {
  store_id?: string;
  offer_id?: string;
  search_id?: string | null;
  quantity?: number | null;
  place_order?: boolean;
  /** Idioma de la app: 'es' o 'en'. */
  locale?: string;
}

export async function assistantRoutes(app: FastifyInstance): Promise<void> {
  // Cada mensaje llama a la IA (y quizá a la búsqueda web): se limita.
  const chatLimiter = createRateLimiter({ windowMs: 60_000, max: 20 });
  const adoptLimiter = createRateLimiter({ windowMs: 60_000, max: 5 });

  app.post<{ Body: MessageBody }>('/assistant/message', async (request, reply) => {
    const language = requestLanguage(request);
    const text = errorCopy[language];

    const user = await authenticate(request);
    if (!user) return reply.code(401).send({ error: text.sessionInvalid });

    const limit = chatLimiter.check(user.id);
    if (!limit.allowed) {
      reply.header('Retry-After', String(limit.retryAfterSeconds));
      return reply.code(429).send({ error: text.assistantRateLimited });
    }

    const storeId = request.body?.store_id;
    const messages = request.body?.messages;
    if (!storeId) return reply.code(400).send({ error: text.storeIdMissing });
    if (!Array.isArray(messages) || messages.length === 0) {
      return reply.code(400).send({ error: text.messageMissing });
    }

    try {
      const store = await getStoreForOwner(storeId, user.id);
      const result = await assistantChat({ store, history: messages, language });
      return reply.send({
        reply: result.reply,
        quick_replies: result.quickReplies,
        market: result.market,
      });
    } catch (error) {
      request.log.error(error);
      return reply.code(500).send({ error: text.assistantFailed });
    }
  });

  app.post<{ Body: AdoptBody }>('/assistant/adopt', async (request, reply) => {
    const language = requestLanguage(request);
    const text = errorCopy[language];

    const user = await authenticate(request);
    if (!user) return reply.code(401).send({ error: text.sessionInvalid });

    const limit = adoptLimiter.check(user.id);
    if (!limit.allowed) {
      reply.header('Retry-After', String(limit.retryAfterSeconds));
      return reply.code(429).send({ error: text.assistantRetryLater });
    }

    const { store_id: storeId, offer_id: offerId } = request.body ?? {};
    if (!storeId || !offerId) {
      return reply.code(400).send({ error: text.offerIdsMissing });
    }

    try {
      const store = await getStoreForOwner(storeId, user.id);
      const result = await adoptMarketOffer({
        store,
        userId: user.id,
        offerId,
        searchId: request.body.search_id ?? null,
        quantity: typeof request.body.quantity === 'number' ? request.body.quantity : null,
        placeOrder: request.body.place_order === true,
        language,
      });
      return reply.send(result);
    } catch (error) {
      request.log.error(error);
      return reply.code(500).send({
        error: error instanceof Error ? error.message : text.catalogErrors,
      });
    }
  });
}
