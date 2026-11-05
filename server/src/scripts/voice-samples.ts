// Genera un MP3 de prueba por cada voz gratuita de ElevenLabs, en español y
// con el mismo modelo que usa Stocky.
//   npm run voice:samples                 -> todas
//   npm run voice:samples -- <voice_id>   -> solo esa voz
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

import '../config/env.js';

const VOICES: Record<string, string> = {
  sarah: 'EXAVITQu4vr4xnSDxMaL',
  laura: 'FGY2WhTYpPnrIDTdsKH5',
  charlotte: 'XB0fDUnXU5powFXDhCwa',
  alice: 'Xb7hH8MSUJpSbSDYk0k2',
  roger: 'CwhRBWXzGAHq8TQ4Fs17',
  george: 'JBFqnCBsd6RMkjVDRZzb',
  brian: 'nPczCjzI2devNBz1zQrb',
  daniel: 'onwK4e9ZLuTAKqWW03F9',
  jessica: 'cgSgspJ2msm6clMCkdW9',
};

// Si se pasa un ID, solo se prueba esa voz.
const only = process.argv.slice(2).filter(Boolean);
const selected: Record<string, string> = only.length
  ? Object.fromEntries(only.map((id) => [Object.keys(VOICES).find((k) => VOICES[k] === id) ?? id, id]))
  : VOICES;

const TEXT =
  'Hola, soy tu asistente de Stocky. El distribuidor más barato es Horta Verda, en Valencia: un euro con cuarenta y cinco por litro, con envío gratis. ¿Lo añado a tu tienda?';

const apiKey = process.env.ELEVENLABS_API_KEY;
if (!apiKey) {
  console.error('Falta ELEVENLABS_API_KEY en server/.env');
  process.exit(1);
}

const model = process.env.ELEVENLABS_MODEL || 'eleven_flash_v2_5';
const outDir = join(process.cwd(), 'voice-samples');
mkdirSync(outDir, { recursive: true });

for (const [name, id] of Object.entries(selected)) {
  const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${id}?output_format=mp3_44100_128`, {
    method: 'POST',
    headers: { 'xi-api-key': apiKey, 'Content-Type': 'application/json', Accept: 'audio/mpeg' },
    body: JSON.stringify({ text: TEXT, model_id: model, language_code: 'es' }),
  });
  if (!response.ok) {
    console.log(`✗ ${name.padEnd(10)} ${response.status} ${(await response.text()).slice(0, 400)}`);
    continue;
  }
  const file = join(outDir, `${name}.mp3`);
  writeFileSync(file, Buffer.from(await response.arrayBuffer()));
  console.log(`✓ ${name.padEnd(10)} ID ${id}  ->  voice-samples/${name}.mp3`);
}
console.log('\nÁbrelos con: open voice-samples');
