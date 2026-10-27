import { env, requireSupabaseEnv } from './config/env.js';
import { buildServer } from './interfaces/http/server.js';
import { startRestockScheduler } from './jobs/scheduled_restock.js';

// Falla al arrancar (y no en cada petición) si faltan las claves.
requireSupabaseEnv();

const app = buildServer();

try {
  await app.listen({ port: env.port, host: '0.0.0.0' });
  // Revisión automática de stock (por defecto a las 09:00 y 21:00, hora de Madrid).
  startRestockScheduler(app.log);
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
