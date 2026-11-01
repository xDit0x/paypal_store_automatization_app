import type { EurRates } from './market_math.js';

/**
 * Tipos de cambio del Banco Central Europeo (vía frankfurter.app, gratis y sin
 * clave). Se guardan 6 horas. Si no hay conexión se usan unos aproximados.
 */
const FALLBACK: EurRates = {
  USD: 1.08,
  GBP: 0.85,
  PLN: 4.3,
  JPY: 165,
  CHF: 0.95,
  SEK: 11.4,
  NOK: 11.6,
  DKK: 7.46,
  CZK: 25.2,
  HUF: 395,
};

let cache: { rates: EurRates; source: 'live' | 'fallback'; at: number } | null = null;
const TTL_MS = 6 * 60 * 60 * 1000;

export async function getEurRates(): Promise<{ rates: EurRates; source: 'live' | 'fallback' }> {
  if (cache && Date.now() - cache.at < TTL_MS) {
    return { rates: cache.rates, source: cache.source };
  }

  try {
    const response = await fetch('https://api.frankfurter.app/latest?from=EUR', {
      signal: AbortSignal.timeout(4000),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const body = (await response.json()) as { rates?: Record<string, number> };
    const rates = { ...FALLBACK, ...(body.rates ?? {}) };
    cache = { rates, source: 'live', at: Date.now() };
  } catch {
    cache = { rates: FALLBACK, source: 'fallback', at: Date.now() };
  }
  return { rates: cache.rates, source: cache.source };
}
