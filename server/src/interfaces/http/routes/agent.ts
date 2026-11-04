import type { FastifyInstance } from 'fastify';

import { runAgent } from '../../../application/agent/run_agent.js';
import { errorCopy } from '../../../application/i18n/errors.js';
import { getStoreForOwner } from '../../../application/stores/store_service.js';
import { authenticate } from '../auth.js';
import { requestLanguage } from '../language.js';
import { createRateLimiter } from '../rate_limit.js';

interface RunBody {
  store_id?: string;
  /** Idioma de la app: 'es' o 'en'. */
  locale?: string;
}

export async function agentRoutes(app: FastifyInstance): Promise<void> {
  // El agente llama a la IA: cada ejecución cuesta dinero, así que se limita.
  const limiter = createRateLimiter({ windowMs: 60_000, max: 10 });

  app.post<{ Body: RunBody }>('/agent/run', async (request, reply) => {
    const language = requestLanguage(request);
    const text = errorCopy[language];

    const user = await authenticate(request);
    if (!user) {
      return reply.code(401).send({ error: text.sessionInvalid });
    }

    const { allowed, retryAfterSeconds } = limiter.check(user.id);
    if (!allowed) {
      reply.header('Retry-After', String(retryAfterSeconds));
      return reply.code(429).send({ error: text.agentRateLimited });
    }

    const storeId = request.body?.store_id;
    if (!storeId) {
      return reply.code(400).send({ error: text.storeIdMissing });
    }

    try {
      const store = await getStoreForOwner(storeId, user.id);
      const result = await runAgent({ store, userId: user.id, language });
      return reply.send(result);
    } catch (error) {
      request.log.error(error);
      return reply.code(500).send({ error: text.reviewFailed });
    }
  });
}
