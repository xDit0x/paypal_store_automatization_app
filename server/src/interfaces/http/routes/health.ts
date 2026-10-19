import type { FastifyInstance } from 'fastify';

import { env } from '../../../config/env.js';

export async function healthRoutes(app: FastifyInstance): Promise<void> {
  app.get('/health', async () => ({
    status: 'ok',
    service: 'restock-agent',
    environment: env.nodeEnv,
    aiProvider: env.aiProvider,
    aiModel: env.aiModel,
  }));
}
