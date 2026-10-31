import type { FastifyInstance } from 'fastify';

import { importCatalog } from '../../../application/catalog/import_catalog.js';
import { createRateLimiter } from '../rate_limit.js';

interface SyncBody {
  catalog?: unknown;
  products?: unknown;
  items?: unknown;
  currency?: unknown;
  supplier?: unknown;
}

export async function catalogSyncRoutes(app: FastifyInstance): Promise<void> {
  const syncLimiter = createRateLimiter({ windowMs: 60_000, max: 20 });

  app.post<{ Params: { supplierCode: string }; Body: SyncBody }>(
    '/catalog/sync/:supplierCode',
    async (request, reply) => {
      const { allowed, retryAfterSeconds } = syncLimiter.check(request.ip);
      if (!allowed) {
        reply.header('Retry-After', String(retryAfterSeconds));
        return reply.code(429).send({ error: 'Demasiadas peticiones. Espera un momento.' });
      }

      // Autenticación por token estático en cabecera x-catalog-token o Bearer
      const tokenHeader =
        request.headers['x-catalog-token'] ??
        (request.headers['authorization']?.startsWith('Bearer ')
          ? request.headers['authorization'].slice(7)
          : null);

      const expectedToken = process.env.CATALOG_SYNC_TOKEN;
      if (!expectedToken || tokenHeader !== expectedToken) {
        return reply.code(401).send({ error: 'Token de sincronización no válido o no configurado.' });
      }

      const supplierCode = request.params.supplierCode.trim().toLowerCase();
      const rawBody = request.body;
      if (!rawBody || typeof rawBody !== 'object') {
        return reply.code(400).send({ error: 'Payload JSON no válido.' });
      }

      try {
        const result = await importCatalog({
          supplierCode,
          type: 'json',
          content: JSON.stringify(rawBody),
        });

        if (result.errors.length > 0) {
          return reply.code(422).send({
            error: 'Errores al procesar el catálogo.',
            details: result.errors,
            result,
          });
        }

        request.log.info({ supplierCode, ...result }, 'Catálogo sincronizado por API');
        return reply.send({ success: true, ...result });
      } catch (error) {
        request.log.error(error);
        return reply.code(500).send({
          error: error instanceof Error ? error.message : 'Error interno al sincronizar el catálogo.',
        });
      }
    },
  );
}
