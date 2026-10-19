import { env } from '../../config/env.js';
import { GroqProvider } from './groq_provider.js';
import type { AiProvider } from './provider.js';

export function createAiProvider(): AiProvider {
  switch (env.aiProvider) {
    case 'groq':
      return new GroqProvider();
    default:
      throw new Error(`AI_PROVIDER no soportado: ${env.aiProvider}`);
  }
}
