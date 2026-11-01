import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';
import { getEurRates } from './fx_rates.js';
import {
  isInRegion,
  landedCost,
  listProducts,
  matchProductKey,
  rankOffers,
  type MarketDistributor,
  type MarketOffer,
  type MarketRegion,
  type RankedOffer,
} from './market_math.js';
import { searchDistributorsOnWeb, type WebResult } from './web_search.js';

export interface MarketResearchInput {
  storeId: string;
  query: string;
  /** Producto del directorio elegido por la IA (si no, se busca por palabras). */
  productKey?: string | null;
  region: MarketRegion;
  monthlyQuantity?: number | null;
  maxUnitPriceEur?: number | null;
}

export interface MarketResearchResult {
  searchId: string | null;
  query: string;
  region: MarketRegion;
  monthlyQuantity: number | null;
  productKey: string | null;
  productName: string | null;
  /** Cuántas ofertas se compararon dentro de la región. */
  compared: number;
  /** Países que venden el producto pero quedan fuera de la región elegida. */
  outsideRegion: string[];
  countries: string[];
  offers: RankedOffer[];
  webResults: WebResult[];
  fxSource: 'live' | 'fallback';
}

type DistributorRow = {
  id: string;
  code: string;
  name: string;
  country: string;
  city: string | null;
  currency: string;
  paypal_email: string | null;
  website: string | null;
  rating: number | string;
  lead_days: number;
  shipping_base: number | string;
  shipping_per_unit: number | string;
  free_shipping_over: number | string | null;
  duty_rate: number | string;
  description: string | null;
};

type OfferRow = {
  id: string;
  distributor_id: string;
  sku: string;
  product_key: string;
  name: string;
  keywords: string[] | null;
  unit: string;
  price: number | string;
  min_qty: number;
  pack_size: number;
  notes: string | null;
};

export function mapDistributor(row: DistributorRow): MarketDistributor {
  return {
    id: row.id,
    code: row.code,
    name: row.name,
    country: row.country,
    city: row.city,
    currency: row.currency,
    paypalEmail: row.paypal_email,
    website: row.website,
    rating: Number(row.rating),
    leadDays: row.lead_days,
    shippingBase: Number(row.shipping_base),
    shippingPerUnit: Number(row.shipping_per_unit),
    freeShippingOver: row.free_shipping_over === null ? null : Number(row.free_shipping_over),
    dutyRate: Number(row.duty_rate),
    description: row.description,
  };
}

export function mapOffer(row: OfferRow): MarketOffer {
  return {
    id: row.id,
    distributorId: row.distributor_id,
    sku: row.sku,
    productKey: row.product_key,
    name: row.name,
    keywords: row.keywords ?? [],
    unit: row.unit,
    price: Number(row.price),
    minQty: row.min_qty,
    packSize: row.pack_size,
    notes: row.notes,
  };
}

export async function loadMarketDirectory(): Promise<{
  distributors: Map<string, MarketDistributor>;
  offers: MarketOffer[];
}> {
  const [dist, off] = await Promise.all([
    supabaseAdmin.from('market_distributors').select('*'),
    supabaseAdmin.from('market_offers').select('*'),
  ]);
  if (dist.error) throw new Error(`No se pudo leer el directorio: ${dist.error.message}`);
  if (off.error) throw new Error(`No se pudieron leer las ofertas: ${off.error.message}`);

  const distributors = new Map<string, MarketDistributor>();
  for (const row of (dist.data ?? []) as DistributorRow[]) {
    distributors.set(row.id, mapDistributor(row));
  }
  return { distributors, offers: ((off.data ?? []) as OfferRow[]).map(mapOffer) };
}

/** Catálogo de productos que se pueden comparar. */
export async function listMarketProducts(): Promise<{ key: string; name: string }[]> {
  const { data, error } = await supabaseAdmin.from('market_offers').select('product_key, name');
  if (error) return [];
  return listProducts(
    ((data ?? []) as { product_key: string; name: string }[]).map((row) => ({
      id: '', distributorId: '', sku: row.product_key, productKey: row.product_key, name: row.name,
      keywords: [], unit: '', price: 0, minQty: 1, packSize: 1, notes: null,
    })),
  );
}

export async function runMarketResearch(input: MarketResearchInput): Promise<MarketResearchResult> {
  const [{ distributors, offers }, fx] = await Promise.all([loadMarketDirectory(), getEurRates()]);

  const known = new Set(offers.map((offer) => offer.productKey));
  const productKey =
    input.productKey && known.has(input.productKey)
      ? input.productKey
      : matchProductKey(input.query, offers);
  const candidates = productKey ? offers.filter((offer) => offer.productKey === productKey) : [];

  const costs = [];
  const outside = new Set<string>();
  for (const offer of candidates) {
    const distributor = distributors.get(offer.distributorId);
    if (!distributor) continue;
    if (!isInRegion(distributor.country, input.region)) {
      outside.add(distributor.country);
      continue;
    }
    try {
      costs.push(
        landedCost({ offer, distributor, quantity: input.monthlyQuantity ?? null, rates: fx.rates }),
      );
    } catch {
      // Moneda sin tipo de cambio: se ignora esa oferta.
    }
  }

  const ranked = rankOffers(costs, { maxUnitPriceEur: input.maxUnitPriceEur ?? null, limit: 3 });
  const webResults = await searchDistributorsOnWeb(input.query, input.region);

  const result: MarketResearchResult = {
    searchId: null,
    query: input.query,
    region: input.region,
    monthlyQuantity: input.monthlyQuantity ?? null,
    productKey,
    productName: candidates[0]?.name ?? null,
    compared: costs.length,
    outsideRegion: [...outside].sort(),
    countries: [...new Set(costs.map((c) => c.country))].sort(),
    offers: ranked,
    webResults,
    fxSource: fx.source,
  };

  const { data, error } = await supabaseAdmin
    .from('market_searches')
    .insert({
      store_id: input.storeId,
      query: input.query,
      region: input.region,
      monthly_quantity: input.monthlyQuantity ?? null,
      results: ranked,
      web_results: webResults,
    })
    .select('id')
    .single();
  if (!error && data) result.searchId = (data as { id: string }).id;

  return result;
}
