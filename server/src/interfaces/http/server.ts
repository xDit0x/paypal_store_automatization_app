import cors from '@fastify/cors';
import Fastify, { type FastifyInstance } from 'fastify';

import { agentRoutes } from './routes/agent.js';
import { healthRoutes } from './routes/health.js';
import { orderRoutes } from './routes/orders.js';

export function buildServer(): FastifyInstance {
  const app = Fastify({
    logger: {
      level: process.env.LOG_LEVEL ?? 'info',
    },
  });

  app.register(cors, { origin: true });

  app.register(healthRoutes);
  app.register(agentRoutes);
  app.register(orderRoutes);

  return app;
}
