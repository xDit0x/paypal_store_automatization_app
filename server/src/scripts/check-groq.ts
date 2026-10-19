import { createAiProvider } from '../infrastructure/ai/index.js';

const provider = createAiProvider();

const result = await provider.chat([
  { role: 'system', content: 'Responde en una sola frase.' },
  { role: 'user', content: 'Di "Groq conectado" y nada más.' },
]);

console.log(`[${provider.name}/${provider.model}] ${result.content}`);

if (result.content === null) {
  process.exit(1);
}
