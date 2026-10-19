import type { FastifyInstance } from 'fastify';

import { runAgent } from '../../../application/agent/run_agent.js';
import { getStoreForOwner } from '../../../application/stores/store_service.js';
import { authenticate } from '../auth.js';

interface RunBody {
  store_id?: string;
}

export async function agentRoutes(app: FastifyInstance): Promise<void> {
  app.post<{ Body: RunBody }>('/agent/run', async (request, reply) => {
    const user = await authenticate(request);
    if (!user) {
      return reply.code(401).send({ error: 'Sesión no válida.' });
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
      const message =
        error instanceof Error ? error.message : 'Error del agente.';
      return reply.code(500).send({ error: message });
    }
  });
}
