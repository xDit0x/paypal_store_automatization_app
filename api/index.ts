import { buildServer } from '../server/dist/interfaces/http/server.js';
import { requireSupabaseEnv } from '../server/dist/config/env.js';

// Si faltan las claves de Supabase, el backend avisa al arrancar.
requireSupabaseEnv();

const app = buildServer();

export default async (req: any, res: any) => {
  // Vercel sirve esta función en /api y reescribe /api/<ruta> hacia ella.
  // Fastify espera la ruta sin el prefijo: /api/agent/run -> /agent/run
  const original = String(req.url || '/');
  const stripped = original.replace(/^\/api(?=\/|$)/, '');
  const fallback = req.query?.path ? `/${String(req.query.path).replace(/^\//, '')}` : '';
  req.url = stripped && stripped !== '/' ? stripped : fallback || '/';

  await app.ready();
  app.server.emit('request', req, res);
};
