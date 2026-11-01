import { env, requireSupabaseEnv } from './config/env.js';
import { buildServer } from './interfaces/http/server.js';
import { startStockyScheduler } from './jobs/scheduled_stocky.js';
import { startCatalogSyncScheduler } from './jobs/scheduled_catalog_sync.js';

// Falla al arrancar (y no en cada petición) si faltan las claves.
requireSupabaseEnv();

const app = buildServer();

try {
  await app.listen({ port: env.port, host: '0.0.0.0' });
  // Revisión automática de stock (por defecto a las 09:00 y 21:00, hora de Madrid).
  startStockyScheduler(app.log);
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
