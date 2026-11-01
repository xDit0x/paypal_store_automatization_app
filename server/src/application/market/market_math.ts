/**
 * Cálculos del estudio de mercado. Todo es puro (sin red ni base de datos)
 * para poder probarlo con tests.
 */

export type MarketRegion = 'spain' | 'europe' | 'world';

/** Países de la UE más el resto de Europa que se considera "Europa". */
const EUROPE = new Set([
  'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU',
  'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES',
  'SE', 'GB', 'CH', 'NO', 'IS',
]);

export function isInRegion(country: string, region: MarketRegion): boolean {
  const code = country.toUpperCase();
  if (region === 'spain') return code === 'ES';
  if (region === 'europe') return EUROPE.has(code);
  return true;
}

export function parseRegion(value: unknown): MarketRegion {
  const text = String(value ?? '').toLowerCase();
  if (text.includes('spain') || text.includes('españa') || text.includes('espana')) return 'spain';
  if (text.includes('europ')) return 'europe';
  return 'world';
}

export interface MarketDistributor {
  id: string;
  code: string;
  name: string;
  country: string;
  city: string | null;
  currency: string;
  paypalEmail: string | null;
  website: string | null;
  rating: number;
  leadDays: number;
  shippingBase: number;
  shippingPerUnit: number;
  freeShippingOver: number | null;
  dutyRate: number;
  description: string | null;
}

export interface MarketOffer {
  id: string;
  distributorId: string;
  sku: string;
  productKey: string;
  name: string;
  keywords: string[];
  unit: string;
  price: number;
  minQty: number;
  packSize: number;
  notes: string | null;
}

/** Unidades de cada moneda por 1 EUR (como las publica el BCE). */
export type EurRates = Record<string, number>;

export function toEur(amount: number, currency: string, rates: EurRates): number {
  const code = currency.toUpperCase();
  if (code === 'EUR') return amount;
  const rate = rates[code];
  if (!rate || rate <= 0) {
    throw new Error(`No hay tipo de cambio para ${code}.`);
  }
  return amount / rate;
}

const round2 = (value: number): number => Math.round(value * 100) / 100;

export function normalizeText(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9 ]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Singular aproximado: "gominolas" -> "gominola", "patatas" -> "patata". */
function stem(word: string): string {
  return word.length > 3 && word.endsWith('s') ? word.slice(0, -1) : word;
}

function stemPhrase(value: string): string {
  return normalizeText(value).split(' ').filter(Boolean).map(stem).join(' ');
}

/**
 * Elige qué producto del directorio corresponde a lo que pide el dueño
 * ("leche de avena para café" -> "oat-barista"). Devuelve null si nada encaja.
 */
export function matchProductKey(query: string, offers: MarketOffer[]): string | null {
  const text = ` ${stemPhrase(query)} `;
  const words = new Set(text.trim().split(' ').filter((word) => word.length >= 3));
  const scores = new Map<string, number>();

  for (const offer of offers) {
    if (scores.has(offer.productKey)) continue;
    let score = 0;
    const terms = [...new Set(offer.keywords.map(stemPhrase).filter(Boolean))];
    for (const term of terms) {
      if (term.includes(' ')) {
        if (text.includes(` ${term} `)) score += 3;
      } else if (words.has(term)) {
        score += 2;
      }
    }
    for (const word of stemPhrase(offer.name).split(' ')) {
      if (word.length >= 4 && words.has(word)) score += 1;
    }
    scores.set(offer.productKey, score);
  }

  let best: string | null = null;
  let bestScore = 0;
  for (const [key, score] of scores) {
    if (score > bestScore) {
      best = key;
      bestScore = score;
    }
  }
  return bestScore >= 2 ? best : null;
}

/** Productos distintos del directorio (para que la IA sepa qué puede comparar). */
export function listProducts(offers: MarketOffer[]): { key: string; name: string }[] {
  const seen = new Map<string, string>();
  for (const offer of offers) {
    if (!seen.has(offer.productKey)) seen.set(offer.productKey, offer.name);
  }
  return [...seen].map(([key, name]) => ({ key, name })).sort((a, b) => a.name.localeCompare(b.name));
}

export interface LandedCost {
  offerId: string;
  distributorId: string;
  distributorName: string;
  country: string;
  city: string | null;
  currency: string;
  website: string | null;
  rating: number;
  leadDays: number;
  productName: string;
  unit: string;
  notes: string | null;
  /** Precio unitario en la moneda del distribuidor. */
  unitPrice: number;
  minQty: number;
  packSize: number;
  /** Unidades que habría que pedir (mínimo y cajas completas). */
  orderQty: number;
  /** Unidades de más respecto a lo que necesita la tienda. */
  extraUnits: number;
  goodsEur: number;
  shippingEur: number;
  dutiesEur: number;
  totalEur: number;
  /** Coste real por unidad puesta en la tienda. */
  unitLandedEur: number;
  outsideEu: boolean;
}

const EU = new Set([
  'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU',
  'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE',
]);

export function landedCost(params: {
  offer: MarketOffer;
  distributor: MarketDistributor;
  /** Lo que necesita la tienda. Sin él se calcula el pedido mínimo. */
  quantity?: number | null;
  rates: EurRates;
}): LandedCost {
  const { offer, distributor, rates } = params;
  const wanted = params.quantity && params.quantity > 0 ? Math.ceil(params.quantity) : 0;
  const base = Math.max(wanted, offer.minQty);
  const pack = Math.max(1, offer.packSize);
  const orderQty = Math.ceil(base / pack) * pack;

  const goodsLocal = offer.price * orderQty;
  const freeShipping =
    distributor.freeShippingOver !== null && goodsLocal >= distributor.freeShippingOver;
  const shippingLocal = freeShipping
    ? 0
    : distributor.shippingBase + distributor.shippingPerUnit * orderQty;

  const goodsEur = toEur(goodsLocal, distributor.currency, rates);
  const shippingEur = toEur(shippingLocal, distributor.currency, rates);
  const dutiesEur = distributor.dutyRate * (goodsEur + shippingEur);
  const totalEur = goodsEur + shippingEur + dutiesEur;

  return {
    offerId: offer.id,
    distributorId: distributor.id,
    distributorName: distributor.name,
    country: distributor.country,
    city: distributor.city,
    currency: distributor.currency,
    website: distributor.website,
    rating: distributor.rating,
    leadDays: distributor.leadDays,
    productName: offer.name,
    unit: offer.unit,
    notes: offer.notes,
    unitPrice: offer.price,
    minQty: offer.minQty,
    packSize: pack,
    orderQty,
    extraUnits: wanted > 0 ? orderQty - wanted : 0,
    goodsEur: round2(goodsEur),
    shippingEur: round2(shippingEur),
    dutiesEur: round2(dutiesEur),
    totalEur: round2(totalEur),
    unitLandedEur: round2(totalEur / orderQty),
    outsideEu: !EU.has(distributor.country.toUpperCase()),
  };
}

export interface RankedOffer extends LandedCost {
  tags: ('cheapest' | 'fastest' | 'best_rated')[];
  overBudget: boolean;
}

/**
 * Ordena por coste real por unidad (a igualdad, el que llega antes) y
 * devuelve los mejores. Si hay precio máximo, primero los que lo cumplen.
 */
export function rankOffers(
  costs: LandedCost[],
  options: { maxUnitPriceEur?: number | null; limit?: number } = {},
): RankedOffer[] {
  const limit = options.limit ?? 3;
  const max = options.maxUnitPriceEur && options.maxUnitPriceEur > 0 ? options.maxUnitPriceEur : null;

  const sorted = [...costs].sort(
    (a, b) => a.unitLandedEur - b.unitLandedEur || a.leadDays - b.leadDays || b.rating - a.rating,
  );
  const withinBudget = max === null ? sorted : sorted.filter((c) => c.unitLandedEur <= max);
  const pool = withinBudget.length > 0 ? withinBudget : sorted;
  const top = pool.slice(0, limit);
  if (top.length === 0) return [];

  const minLead = Math.min(...top.map((c) => c.leadDays));
  const maxRating = Math.max(...top.map((c) => c.rating));

  return top.map((cost, index) => {
    const tags: RankedOffer['tags'] = [];
    if (index === 0) tags.push('cheapest');
    if (cost.leadDays === minLead) tags.push('fastest');
    if (cost.rating === maxRating) tags.push('best_rated');
    return { ...cost, tags, overBudget: max !== null && cost.unitLandedEur > max };
  });
}
