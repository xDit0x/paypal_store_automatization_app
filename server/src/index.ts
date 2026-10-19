import { env, requireSupabaseEnv } from './config/env.js';
import { buildServer } from './interfaces/http/server.js';

// Falla al arrancar (y no en cada petición) si faltan las claves.
requireSupabaseEnv();

const app = buildServer();

try {
  await app.listen({ port: env.port, host: '0.0.0.0' });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
