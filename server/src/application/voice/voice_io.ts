import Groq, { toFile } from 'groq-sdk';

import { env } from '../../config/env.js';

/**
 * Oído y voz del modo conversación.
 * - Oído: Whisper en Groq (misma GROQ_API_KEY que el agente).
 * - Voz: ElevenLabs (opcional). Sin ELEVENLABS_API_KEY la app usa la voz
 *   del dispositivo.
 */

const WHISPER_MODEL = process.env.WHISPER_MODEL ?? 'whisper-large-v3-turbo';

/** Pistas para que Whisper escriba bien las palabras del negocio. */
const WHISPER_PROMPT =
  'Conversación con el asistente de compras de una tienda: proveedores, distribuidores, stock, pedido, PayPal, kombucha, matcha, Haribo, gominolas, euros.';

export async function transcribeAudio(params: {
  audio: Buffer;
  mimeType: string;
  language?: string;
}): Promise<string> {
  const extension = params.mimeType.includes('wav')
    ? 'wav'
    : params.mimeType.includes('mp4') || params.mimeType.includes('m4a')
      ? 'm4a'
      : params.mimeType.includes('webm')
        ? 'webm'
        : 'wav';

  const client = new Groq({ apiKey: env.groqApiKey });
  const file = await toFile(params.audio, `voz.${extension}`, { type: params.mimeType });
  const result = await client.audio.transcriptions.create({
    file,
    model: WHISPER_MODEL,
    language: params.language === 'en' ? 'en' : 'es',
    prompt: WHISPER_PROMPT,
    temperature: 0,
    response_format: 'json',
  });
  return cleanTranscript(result.text ?? '');
}

/**
 * Whisper a veces "oye" frases típicas de vídeos cuando solo hay silencio o
 * ruido. Se descartan para que el asistente no conteste a nada.
 */
const HALLUCINATIONS = [
  'subtitulos realizados por la comunidad de amara.org',
  'subtitulado por la comunidad de amara.org',
  'gracias por ver el video',
  'gracias por ver',
  'suscribete',
  'thank you for watching',
  'thanks for watching',
  'gracias.',
  'gracias',
];

export function cleanTranscript(text: string): string {
  const clean = text.replace(/\s+/g, ' ').trim();
  const plain = clean
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[¡!¿?.,]+$/g, '')
    .replace(/^[¡!¿?.,\s]+/g, '');
  if (plain.length < 2) return '';
  if (HALLUCINATIONS.some((h) => plain === h.replace(/\.$/, ''))) return '';
  return clean;
}

/** Texto listo para leer en voz alta: sin markdown ni símbolos raros. */
export function speakableText(text: string): string {
  return text
    .replace(/\*\*/g, '')
    .replace(/[*_`#>]/g, '')
    .replace(/\[(.*?)\]\(.*?\)/g, '$1')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 900);
}

export function elevenLabsConfigured(): boolean {
  return Boolean(process.env.ELEVENLABS_API_KEY);
}

/** Devuelve MP3 o null si ElevenLabs no está configurado o falla. */
export async function synthesizeSpeech(text: string, language = 'es'): Promise<Buffer | null> {
  const apiKey = process.env.ELEVENLABS_API_KEY;
  const clean = speakableText(text);
  if (!apiKey || !clean) return null;

  // "Sarah": voz multilingüe de la biblioteca básica. Se puede cambiar por
  // cualquier voz en español de la Voice Library (ELEVENLABS_VOICE_ID).
  const voiceId = process.env.ELEVENLABS_VOICE_ID || 'EXAVITQu4vr4xnSDxMaL';
  const model = process.env.ELEVENLABS_MODEL || 'eleven_flash_v2_5';

  try {
    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voiceId)}?output_format=mp3_44100_128`,
      {
        method: 'POST',
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          Accept: 'audio/mpeg',
        },
        body: JSON.stringify({
          text: clean,
          model_id: model,
          // Pronunciación nativa en el idioma del dueño (no acento inglés).
          language_code: language === 'en' ? 'en' : 'es',
          voice_settings: { stability: 0.45, similarity_boost: 0.8, style: 0.15, use_speaker_boost: true },
        }),
        signal: AbortSignal.timeout(15_000),
      },
    );
    if (!response.ok) {
      console.warn(`[voz] ElevenLabs respondió ${response.status}: ${(await response.text()).slice(0, 200)}`);
      return null;
    }
    return Buffer.from(await response.arrayBuffer());
  } catch (error) {
    console.warn(`[voz] ElevenLabs no disponible: ${error instanceof Error ? error.message : error}`);
    return null;
  }
}
