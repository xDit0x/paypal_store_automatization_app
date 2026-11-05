import type { FastifyRequest } from 'fastify';

import {
  languageOf,
  type AppLanguage,
} from '../../application/i18n/messages.js';

/**
 * Idioma de la petición.
 *
 * La app lo manda en la cabecera `X-App-Locale` en todas sus llamadas y, en
 * las que llevan cuerpo, también en el campo `locale`. Si no llega ninguno,
 * se responde en español.
 */
export function requestLanguage(request: FastifyRequest): AppLanguage {
  const header = request.headers['x-app-locale'];
  if (typeof header === 'string' && header.trim().length > 0) {
    return languageOf(header);
  }

  const body = request.body as { locale?: unknown } | undefined;
  return languageOf(body?.locale);
}

/**
 * Idioma de una página web (por ejemplo, la vuelta de PayPal): se usa la
 * cabecera `Accept-Language` del navegador.
 */
export function browserLanguage(request: FastifyRequest): AppLanguage {
  const header = request.headers['accept-language'];
  if (typeof header !== 'string' || header.trim().length === 0) return 'es';
  const first = header.split(',')[0] ?? '';
  return languageOf(first);
}
