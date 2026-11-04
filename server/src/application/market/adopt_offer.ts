import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';
import { evaluateSpendingRules } from '../../domain/spending_rules.js';
import { copy, type AppLanguage } from '../i18n/messages.js';
import { describeReason } from '../i18n/reasons.js';
import { createOrder } from '../orders/create_order.js';
import { fulfillOrder } from '../orders/fulfill_order.js';
import { getSpentThisMonth } from '../orders/spent_this_month.js';
import type { StoreContext } from '../stores/store_service.js';
import { getEurRates } from './fx_rates.js';
import { landedCost } from './market_math.js';
import { mapDistributor, mapOffer } from './market_research.js';

export interface AdoptOfferInput {
  store: StoreContext;
  userId: string;
  offerId: string;
  searchId?: string | null;
  /** Unidades al mes que necesita la tienda (para el primer pedido). */
  quantity?: number | null;
  placeOrder: boolean;
  /** Idioma de los mensajes (el que está usando la app). */
  language?: AppLanguage;
}

export interface AdoptOfferResult {
  supplierId: string;
  supplierName: string;
  productUid: string;
  productName: string;
  unitPrice: number;
  currency: string;
  order: {
    id: string | null;
    qty: number;
    total: number;
    status: string;
    paid: boolean;
    reason: string | null;
    warnings: string[];
  } | null;
}

const round2 = (value: number): number => Math.round(value * 100) / 100;

/**
 * El dueño elige una oferta del estudio de mercado:
 * 1. el distribuidor pasa a ser un proveedor (código mkt-<código>),
 * 2. el producto se añade al catálogo con su coste real por unidad,
 * 3. la tienda empieza a controlar su stock,
 * 4. opcional: primer pedido pagado con PayPal (respetando las reglas).
 *
 * El precio se recalcula aquí: nunca se fía del que manda la app.
 */
export async function adoptMarketOffer(input: AdoptOfferInput): Promise<AdoptOfferResult> {
  const { data: offerRow, error: offerError } = await supabaseAdmin
    .from('market_offers')
    .select('*')
    .eq('id', input.offerId)
    .maybeSingle();
  if (offerError || !offerRow) throw new Error('La oferta ya no existe.');
  const offer = mapOffer(offerRow);

  const { data: distRow, error: distError } = await supabaseAdmin
    .from('market_distributors')
    .select('*')
    .eq('id', offer.distributorId)
    .maybeSingle();
  if (distError || !distRow) throw new Error('El distribuidor ya no existe.');
  const distributor = mapDistributor(distRow);

  const { rates } = await getEurRates();
  const cost = landedCost({ offer, distributor, quantity: input.quantity ?? null, rates });

  // Precio en la moneda de la tienda (normalmente EUR).
  const storeCurrency = input.store.currency.toUpperCase();
  const storeRate = storeCurrency === 'EUR' ? 1 : rates[storeCurrency];
  if (!storeRate) throw new Error(`No hay tipo de cambio para ${storeCurrency}.`);
  const unitPrice = round2(cost.unitLandedEur * storeRate);

  // 1. Proveedor
  const supplierCode = `mkt-${distributor.code}`.toLowerCase();
  const { data: supplier, error: supplierError } = await supabaseAdmin
    .from('suppliers')
    .upsert(
      {
        code: supplierCode,
        name: distributor.name,
        paypal_email: distributor.paypalEmail,
        category: 'Estudio de mercado',
        active: true,
      },
      { onConflict: 'code' },
    )
    .select('id, name')
    .single();
  if (supplierError || !supplier) {
    throw new Error(`No se pudo dar de alta el proveedor: ${supplierError?.message}`);
  }

  // 2. Producto
  const productUid = `mkt-${distributor.code}-${offer.sku}`.toLowerCase();
  const { error: productError } = await supabaseAdmin.from('products').upsert(
    {
      uid: productUid,
      supplier_id: supplier.id,
      name: offer.name,
      description: [
        `${distributor.city ?? ''} (${distributor.country})`.trim(),
        `Coste real por ${offer.unit} con envío y aranceles`,
        offer.notes ?? '',
      ]
        .filter(Boolean)
        .join(' · '),
      price: unitPrice,
      currency: storeCurrency,
      unit: offer.unit,
      active: true,
    },
    { onConflict: 'uid' },
  );
  if (productError) {
    throw new Error(`No se pudo añadir el producto: ${productError.message}`);
  }

  // 3. Stock de la tienda (si ya existía no se toca)
  const monthly = input.quantity && input.quantity > 0 ? Math.ceil(input.quantity) : cost.orderQty;
  const { error: stockError } = await supabaseAdmin.from('store_products').upsert(
    {
      store_id: input.store.id,
      product_uid: productUid,
      stock: 0,
      // Avisa cuando quede menos de una semana de consumo.
      low_stock_threshold: Math.max(1, Math.ceil(monthly / 4)),
    },
    { onConflict: 'store_id,product_uid', ignoreDuplicates: true },
  );
  if (stockError) {
    throw new Error(`No se pudo añadir el producto a tu tienda: ${stockError.message}`);
  }

  if (input.searchId) {
    await supabaseAdmin
      .from('market_searches')
      .update({ adopted_offer_id: offer.id, adopted_at: new Date().toISOString() })
      .eq('id', input.searchId)
      .eq('store_id', input.store.id);
  }

  const result: AdoptOfferResult = {
    supplierId: supplier.id as string,
    supplierName: supplier.name as string,
    productUid,
    productName: offer.name,
    unitPrice,
    currency: storeCurrency,
    order: null,
  };
  if (!input.placeOrder) return result;

  // 4. Primer pedido
  const qty = cost.orderQty;
  const total = round2(unitPrice * qty);
  const language = input.language ?? 'es';
  const decision = evaluateSpendingRules({
    rules: input.store.rules,
    orderTotal: total,
    spentThisMonth: await getSpentThisMonth(input.store.id),
    supplierId: supplier.id as string,
    currency: storeCurrency,
  });

  if (decision.status === 'blocked') {
    result.order = {
      id: null,
      qty,
      total,
      status: 'blocked',
      paid: false,
      reason:
        describeReason(decision.reason ?? { code: 'blocked_by_rules' }, language) ||
        copy[language].blockNotAllowedFallback,
      warnings: [],
    };
    return result;
  }

  // Elegir la oferta en la app cuenta como aprobación del dueño.
  const order = await createOrder({
    storeId: input.store.id,
    supplierId: supplier.id as string,
    lines: [{ productUid, qty }],
    status: 'approved',
    createdByType: 'user',
    createdById: input.userId,
  });

  try {
    const fulfillment = await fulfillOrder(order.id, { ownerApproved: true });
    result.order = {
      id: order.id,
      qty,
      total: order.total,
      status: fulfillment.orderStatus,
      paid: fulfillment.payment !== null,
      reason: null,
      warnings: fulfillment.warnings,
    };
  } catch (error) {
    result.order = {
      id: order.id,
      qty,
      total: order.total,
      status: 'payment_failed',
      paid: false,
      reason: error instanceof Error ? error.message : String(error),
      warnings: [],
    };
  }
  return result;
}
