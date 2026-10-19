import cors from '@fastify/cors';
import Fastify, { type FastifyInstance } from 'fastify';

import { env } from '../../config/env.js';
import { agentRoutes } from './routes/agent.js';
import { catalogRoutes } from './routes/catalog.js';
import { healthRoutes } from './routes/health.js';
import { orderRoutes } from './routes/orders.js';
import { createRateLimiter } from './rate_limit.js';

/**
 * Orígenes admitidos: los de ALLOWED_ORIGINS y, en desarrollo, cualquier
 * localhost (Flutter web abre un puerto aleatorio).
 */
function isAllowedOrigin(origin: string): boolean {
  const allowed = (process.env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);

  if (allowed.includes(origin)) return true;
  if (env.nodeEnv === 'production') return false;
  return /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
}

export function buildServer(): FastifyInstance {
  const app = Fastify({
    logger: {
      level: process.env.LOG_LEVEL ?? 'info',
    },
  });

  app.register(cors, {
    origin: (origin, callback) => {
      callback(null, !origin || isAllowedOrigin(origin));
    },
    credentials: false,
  });

  // Cortafuegos global por IP (protege también de bots sin sesión).
  const globalLimiter = createRateLimiter({ windowMs: 60_000, max: 300 });

  app.addHook('onRequest', async (request, reply) => {
    const { allowed, retryAfterSeconds } = globalLimiter.check(request.ip);
    if (!allowed) {
      reply.header('Retry-After', String(retryAfterSeconds));
      return reply.code(429).send({ error: 'Demasiadas peticiones. Espera un momento.' });
    }
  });

  app.register(healthRoutes);
  app.register(agentRoutes);
  app.register(orderRoutes);
  app.register(catalogRoutes);

  return app;
}
