import type { FastifyInstance } from 'fastify';

import {
  assistantChat,
  type ChatTurn,
  type LastMarketContext,
} from '../../../application/assistant/assistant_chat.js';
import {
  elevenLabsConfigured,
  synthesizeSpeech,
  transcribeAudio,
} from '../../../application/voice/voice_io.js';
import { adoptMarketOffer } from '../../../application/market/adopt_offer.js';
import { getStoreForOwner } from '../../../application/stores/store_service.js';
import { authenticate } from '../auth.js';
import { createRateLimiter } from '../rate_limit.js';

interface MessageBody {
  store_id?: string;
  messages?: ChatTurn[];
  last_market?: unknown;
}

interface VoiceBody extends MessageBody {
  /** Audio grabado por la app (WAV 16 kHz mono), en base64. */
  audio_base64?: string;
  mime_type?: string;
  language?: string;
  /** false si la app no quiere audio de vuelta (usa la voz del dispositivo). */
  speak?: boolean;
}

interface SpeakBody {
  text?: string;
}

/** Lee el contexto de opciones que manda la app (se revalida al adoptar). */
function parseLastMarket(value: unknown): LastMarketContext | null {
  if (!value || typeof value !== 'object') return null;
  const raw = value as Record<string, unknown>;
  const options = Array.isArray(raw.options) ? raw.options : [];
  const parsed = options
    .slice(0, 3)
    .map((o) => (o && typeof o === 'object' ? (o as Record<string, unknown>) : {}))
    .filter((o) => typeof o.offerId === 'string')
    .map((o) => ({
      offerId: String(o.offerId),
      distributorName: String(o.distributorName ?? '').slice(0, 80),
      unitLandedEur: Number(o.unitLandedEur) || 0,
      orderQty: Number(o.orderQty) || 0,
      totalEur: Number(o.totalEur) || 0,
    }));
  if (parsed.length === 0) return null;
  const quantity = Number(raw.monthlyQuantity);
  return {
    searchId: typeof raw.searchId === 'string' ? raw.searchId : null,
    monthlyQuantity: Number.isFinite(quantity) && quantity > 0 ? quantity : null,
    options: parsed,
  };
}

interface AdoptBody {
  store_id?: string;
  offer_id?: string;
  search_id?: string | null;
  quantity?: number | null;
  place_order?: boolean;
}

export async function assistantRoutes(app: FastifyInstance): Promise<void> {
  // Cada mensaje llama a la IA (y quizá a la búsqueda web): se limita.
  const chatLimiter = createRateLimiter({ windowMs: 60_000, max: 20 });
  const adoptLimiter = createRateLimiter({ windowMs: 60_000, max: 5 });
  const voiceLimiter = createRateLimiter({ windowMs: 60_000, max: 30 });

  app.post<{ Body: MessageBody }>('/assistant/message', async (request, reply) => {
    const user = await authenticate(request);
    if (!user) return reply.code(401).send({ error: 'Sesión no válida.' });

    const limit = chatLimiter.check(user.id);
    if (!limit.allowed) {
      reply.header('Retry-After', String(limit.retryAfterSeconds));
      return reply.code(429).send({ error: 'Vas muy rápido. Espera un momento.' });
    }

    const storeId = request.body?.store_id;
    const messages = request.body?.messages;
    if (!storeId) return reply.code(400).send({ error: 'Falta store_id.' });
    if (!Array.isArray(messages) || messages.length === 0) {
      return reply.code(400).send({ error: 'Falta el mensaje.' });
    }

    try {
      const store = await getStoreForOwner(storeId, user.id);
      const result = await assistantChat({
        store,
        history: messages,
        userId: user.id,
        lastMarket: parseLastMarket(request.body.last_market),
      });
      return reply.send({
        reply: result.reply,
        quick_replies: result.quickReplies,
        market: result.market,
        adopted: result.adopted,
      });
    } catch (error) {
      request.log.error(error);
      return reply.code(500).send({ error: 'El asistente no pudo responder.' });
    }
  });

  // Modo conversación: audio -> Whisper -> asistente -> voz, en una sola
  // petición para que la respuesta llegue lo antes posible.
  app.post<{ Body: VoiceBody }>(
    '/assistant/voice',
    { bodyLimit: 12 * 1024 * 1024 },
    async (request, reply) => {
      const user = await authenticate(request);
      if (!user) return reply.code(401).send({ error: 'Sesión no válida.' });

      const limit = voiceLimiter.check(user.id);
      if (!limit.allowed) {
        reply.header('Retry-After', String(limit.retryAfterSeconds));
        return reply.code(429).send({ error: 'Vas muy rápido. Espera un momento.' });
      }

      const body = request.body ?? {};
      if (!body.store_id) return reply.code(400).send({ error: 'Falta store_id.' });
      if (!body.audio_base64) return reply.code(400).send({ error: 'Falta el audio.' });

      try {
        const store = await getStoreForOwner(body.store_id, user.id);
        const audio = Buffer.from(body.audio_base64, 'base64');
        if (audio.length < 2000) {
          return reply.send({ transcript: '', reply: '', quick_replies: [], market: null, adopted: null, audio_base64: null });
        }

        const transcript = await transcribeAudio({
          audio,
          mimeType: body.mime_type ?? 'audio/wav',
          language: body.language,
        });
        // Silencio o ruido: la app vuelve a escuchar sin contestar.
        if (!transcript) {
          return reply.send({ transcript: '', reply: '', quick_replies: [], market: null, adopted: null, audio_base64: null });
        }

        const history = [
          ...(Array.isArray(body.messages) ? body.messages : []),
          { role: 'user' as const, content: transcript },
        ];
        const result = await assistantChat({
          store,
          history,
          voice: true,
          userId: user.id,
          lastMarket: parseLastMarket(body.last_market),
        });
        const speech = body.speak === false ? null : await synthesizeSpeech(result.reply, body.language);

        return reply.send({
          transcript,
          reply: result.reply,
          quick_replies: result.quickReplies,
          market: result.market,
          adopted: result.adopted,
          audio_base64: speech ? speech.toString('base64') : null,
          audio_mime: speech ? 'audio/mpeg' : null,
        });
      } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ error: 'No pude entenderte. Inténtalo otra vez.' });
      }
    },
  );

  // Lee un texto con la voz de ElevenLabs (avisos, resumen tras añadir...).
  app.post<{ Body: SpeakBody }>('/assistant/speak', async (request, reply) => {
    const user = await authenticate(request);
    if (!user) return reply.code(401).send({ error: 'Sesión no válida.' });
    const limit = voiceLimiter.check(user.id);
    if (!limit.allowed) return reply.code(429).send({ error: 'Vas muy rápido.' });

    const text = String(request.body?.text ?? '').slice(0, 900);
    if (!text || !elevenLabsConfigured()) return reply.send({ audio_base64: null });
    const speech = await synthesizeSpeech(text);
    return reply.send({
      audio_base64: speech ? speech.toString('base64') : null,
      audio_mime: speech ? 'audio/mpeg' : null,
    });
  });

  app.post<{ Body: AdoptBody }>('/assistant/adopt', async (request, reply) => {
    const user = await authenticate(request);
    if (!user) return reply.code(401).send({ error: 'Sesión no válida.' });

    const limit = adoptLimiter.check(user.id);
    if (!limit.allowed) {
      reply.header('Retry-After', String(limit.retryAfterSeconds));
      return reply.code(429).send({ error: 'Espera un momento antes de repetir.' });
    }

    const { store_id: storeId, offer_id: offerId } = request.body ?? {};
    if (!storeId || !offerId) return reply.code(400).send({ error: 'Faltan store_id u offer_id.' });

    try {
      const store = await getStoreForOwner(storeId, user.id);
      const result = await adoptMarketOffer({
        store,
        userId: user.id,
        offerId,
        searchId: request.body.search_id ?? null,
        quantity: typeof request.body.quantity === 'number' ? request.body.quantity : null,
        placeOrder: request.body.place_order === true,
      });
      return reply.send(result);
    } catch (error) {
      request.log.error(error);
      return reply.code(500).send({
        error: error instanceof Error ? error.message : 'No se pudo añadir el producto.',
      });
    }
  });
}
