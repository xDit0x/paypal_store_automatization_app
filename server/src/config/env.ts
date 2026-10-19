import 'dotenv/config';

function readNumber(value: string | undefined, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: readNumber(process.env.PORT, 3000),

  supabaseUrl: process.env.SUPABASE_URL ?? '',
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? '',

  groqApiKey: process.env.GROQ_API_KEY ?? '',
  aiProvider: process.env.AI_PROVIDER ?? 'groq',
  aiModel: process.env.AI_MODEL ?? 'openai/gpt-oss-120b',

  paypalClientId: process.env.PAYPAL_CLIENT_ID ?? '',
  paypalClientSecret: process.env.PAYPAL_CLIENT_SECRET ?? '',
  paypalBaseUrl:
    process.env.PAYPAL_BASE_URL ?? 'https://api-m.sandbox.paypal.com',
} as const;

export function requireSupabaseEnv(): void {
  if (!env.supabaseUrl || !env.supabaseServiceRoleKey) {
    throw new Error('Faltan SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY');
  }
}

export function requireGroqEnv(): void {
  if (!env.groqApiKey) {
    throw new Error('Falta GROQ_API_KEY');
  }
}
