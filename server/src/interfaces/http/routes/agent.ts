import type { FastifyInstance } from 'fastify';

import { runAgent } from '../../../application/agent/run_agent.js';
import { getStoreForOwner } from '../../../application/stores/store_service.js';
import { authenticate } from '../auth.js';
import { createRateLimiter } from '../rate_limit.js';

interface RunBody {
  store_id?: string;
}

export async function agentRoutes(app: FastifyInstance): Promise<void> {
  // El agente llama a la IA: cada ejecución cuesta dinero, así que se limita.
  const limiter = createRateLimiter({ windowMs: 60_000, max: 10 });

  app.post<{ Body: RunBody }>('/agent/run', async (request, reply) => {
    const user = await authenticate(request);
    if (!user) {
      return reply.code(401).send({ error: 'Sesión no válida.' });
    }

    const { allowed, retryAfterSeconds } = limiter.check(user.id);
    if (!allowed) {
      reply.header('Retry-After', String(retryAfterSeconds));
      return reply
        .code(429)
        .send({ error: 'Has pedido demasiadas revisiones seguidas. Espera un momento.' });
    }

    const storeId = request.body?.store_id;
    if (!storeId) {
      return reply.code(400).send({ error: 'Falta store_id.' });
    }

    try {
      const store = await getStoreForOwner(storeId, user.id);
      const result = await runAgent({ store, userId: user.id });
      return reply.send(result);
    } catch (error) {
      request.log.error(error);
      return reply.code(500).send({
        error: 'No se pudo completar la revisión de stock.',
      });
    }
  });
}
