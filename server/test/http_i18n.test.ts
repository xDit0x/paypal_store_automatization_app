import assert from 'node:assert/strict';
import test from 'node:test';

import { buildServer } from '../src/interfaces/http/server.js';

/**
 * El servidor responde en el idioma que indica la app con la cabecera
 * `X-App-Locale`.
 */
test('los errores del servidor llegan en inglés si la app va en inglés', async () => {
  const app = buildServer();
  const response = await app.inject({
    method: 'POST',
    url: '/agent/run',
    headers: { 'x-app-locale': 'en' },
    payload: { store_id: 'store-1' },
  });

  assert.equal(response.statusCode, 401);
  assert.deepEqual(response.json(), { error: 'Invalid session.' });

  await app.close();
});

test('sin cabecera los errores llegan en español', async () => {
  const app = buildServer();
  const response = await app.inject({
    method: 'POST',
    url: '/agent/run',
    payload: { store_id: 'store-1' },
  });

  assert.equal(response.statusCode, 401);
  assert.deepEqual(response.json(), { error: 'Sesión no válida.' });

  await app.close();
});

test('el idioma también se puede mandar en el cuerpo', async () => {
  const app = buildServer();
  const response = await app.inject({
    method: 'POST',
    url: '/agent/run',
    payload: { store_id: 'store-1', locale: 'en' },
  });

  assert.equal(response.statusCode, 401);
  assert.deepEqual(response.json(), { error: 'Invalid session.' });

  await app.close();
});
