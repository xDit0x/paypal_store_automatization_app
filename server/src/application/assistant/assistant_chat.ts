import { GroqProvider } from '../../infrastructure/ai/groq_provider.js';
import type { AiMessage, AiProvider, AiToolDefinition } from '../../infrastructure/ai/provider.js';
import { getLowStockProducts } from '../catalog/get_low_stock.js';
import {
  listMarketProducts,
  runMarketResearch,
  type MarketResearchResult,
} from '../market/market_research.js';
import { adoptMarketOffer, type AdoptOfferResult } from '../market/adopt_offer.js';
import { parseRegion } from '../market/market_math.js';
import { getSpentThisMonth } from '../orders/spent_this_month.js';
import type { StoreContext } from '../stores/store_service.js';
import type { SpendingRules } from '../../domain/spending_rules.js';
import {
  assistantPrompt,
  copy,
  fill,
  toolTexts,
  type AppLanguage,
} from '../i18n/messages.js';
import { updateStoreRules } from '../stores/update_store_rules.js';

export interface ChatTurn {
  role: 'user' | 'assistant';
  content: string;
}

export interface AssistantReply {
  reply: string;
  quickReplies: string[];
  market: MarketResearchResult | null;
  /** Si el dueño eligió un distribuidor en la conversación. */
  adopted: AdoptOfferResult | null;
}

/** Las opciones que el dueño tiene delante (para "me quedo con el primero"). */
export interface LastMarketContext {
  searchId: string | null;
  monthlyQuantity: number | null;
  options: { offerId: string; distributorName: string; unitLandedEur: number; orderQty: number; totalEur: number }[];
}

const MAX_TURNS = 20;
const MAX_CHARS = 2000;
const MAX_STEPS = 5;

const ADOPT_TOOL: AiToolDefinition = {
  type: 'function',
  function: {
    name: 'adopt_offer',
    description:
      'Añade a la tienda el distribuidor que el dueño eligió de las opciones que tiene delante y, si lo pide, hace el primer pedido pagado con PayPal (respetando sus reglas de gasto). Solo después de que el dueño lo confirme de forma explícita.',
    parameters: {
      type: 'object',
      properties: {
        option_number: { type: 'integer', minimum: 1, maximum: 3, description: 'Número de la opción (1, 2 o 3).' },
        place_order: { type: 'boolean', description: 'true si el dueño quiere hacer ya el primer pedido.' },
        quantity: { type: 'number', description: 'Unidades al mes, si el dueño lo dijo.' },
        owner_confirmed: { type: 'boolean', description: 'true solo si el dueño acaba de confirmar con un sí claro.' },
      },
      required: ['option_number', 'place_order', 'owner_confirmed'],
    },
  },
};

function buildTools(
  productKeys: string[],
  language: AppLanguage,
  canAdopt: boolean,
): AiToolDefinition[] {
  const text = toolTexts[language];
  return [
    ...(canAdopt ? [ADOPT_TOOL] : []),
    {
      type: 'function',
      function: {
        name: 'ask_user',
        description: text.askUser,
        parameters: {
          type: 'object',
          properties: {
            question: { type: 'string' },
            options: { type: 'array', items: { type: 'string' }, maxItems: 4 },
          },
          required: ['question', 'options'],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'market_research',
        description: text.marketResearch,
        parameters: {
          type: 'object',
          properties: {
            product: { type: 'string', description: text.marketResearchProduct },
            product_key: {
              type: 'string',
              description: text.marketResearchProductKey,
              ...(productKeys.length > 0 ? { enum: productKeys } : {}),
            },
            region: { type: 'string', enum: ['spain', 'europe', 'world'] },
            monthly_quantity: {
              type: 'number',
              description: text.marketResearchQuantity,
            },
            max_unit_price_eur: {
              type: 'number',
              description: text.marketResearchMaxPrice,
            },
          },
          required: ['product', 'region'],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'get_store_summary',
        description: text.storeSummary,
        parameters: { type: 'object', properties: {} },
      },
    },
    {
      type: 'function',
      function: {
        name: 'adjust_budget',
        description: text.adjustBudget,
        parameters: {
          type: 'object',
          properties: {
            monthly_limit: {
              type: 'number',
              description: text.adjustMonthly,
            },
            max_per_order: {
              type: 'number',
              description: text.adjustMaxPerOrder,
            },
            require_approval_above: {
              type: 'number',
              description: text.adjustApprovalAbove,
            },
          },
          required: [],
        },
      },
    },
  ];
}

function systemPrompt(
  store: StoreContext,
  products: { key: string; name: string }[],
  language: AppLanguage,
  options: { voice: boolean; lastMarket: LastMarketContext | null },
): string {
  return [
    baseSystemPrompt(store, products, language),
    ...(options.lastMarket && options.lastMarket.options.length > 0
      ? [
          '',
          'Opciones que el dueño tiene ahora en pantalla:',
          ...options.lastMarket.options.map(
            (o, i) =>
              `${i + 1}. ${o.distributorName}: ${o.unitLandedEur.toFixed(2)} EUR por unidad, pedido de ${o.orderQty} uds, total ${o.totalEur.toFixed(2)} EUR`,
          ),
          'Si el dueño elige una ("el primero", "el de Valencia", "el más rápido"): resume en una frase qué vas a hacer (distribuidor, unidades e importe aproximado, y si se paga ya con PayPal) y pide confirmación con ask_user (opciones "Sí, hazlo" y "No"). Solo cuando diga que sí, llama a adopt_offer con owner_confirmed=true.',
          'Tras adopt_offer, cuenta el resultado en una frase. Si el pedido quedó bloqueado por las reglas, explica el motivo.',
        ]
      : []),
    ...(options.voice
      ? [
          '',
          'MODO CONVERSACIÓN POR VOZ: tu respuesta se leerá en voz alta. Habla como una persona: una o dos frases cortas, sin listas, sin markdown, sin símbolos. Di los importes con palabras naturales ("un euro con cuarenta y cinco"). Tras un estudio de mercado menciona solo la mejor opción y una alternativa, y termina preguntando si la añades.',
        ]
      : []),
  ].join('\n');
}

function baseSystemPrompt(store: StoreContext, products: { key: string; name: string }[], language: AppLanguage): string {
  const catalogue = products.length
    ? products.map((p) => `- ${p.key}: ${p.name}`).join('\n')
    : copy[language].catalogueEmpty;

  return fill(assistantPrompt[language], {
    store: store.name,
    currency: store.currency,
    catalogue,
    languageRule: copy[language].assistantLanguageRule,
  });
}

function sanitize(history: ChatTurn[]): AiMessage[] {
  return history
    .filter((turn) => (turn.role === 'user' || turn.role === 'assistant') && typeof turn.content === 'string')
    .slice(-MAX_TURNS)
    .map((turn) => ({ role: turn.role, content: turn.content.slice(0, MAX_CHARS) }));
}

/** Versión reducida del estudio para el modelo (menos tokens). */
function compact(result: MarketResearchResult): Record<string, unknown> {
  return {
    product: result.productName,
    found: result.productKey !== null,
    compared_offers: result.compared,
    outside_region: result.outsideRegion,
    countries: result.countries,
    top3: result.offers.map((o) => ({
      distributor: o.distributorName,
      country: o.country,
      unit_cost_eur: o.unitLandedEur,
      order_qty: o.orderQty,
      total_eur: o.totalEur,
      shipping_eur: o.shippingEur,
      duties_eur: o.dutiesEur,
      lead_days: o.leadDays,
      rating: o.rating,
      over_budget: o.overBudget,
      tags: o.tags,
    })),
    web_results: result.webResults.map((w) => w.domain),
  };
}

function parseArgs(raw: string): Record<string, unknown> {
  try {
    const value = JSON.parse(raw || '{}') as unknown;
    return value && typeof value === 'object' ? (value as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

const positive = (value: unknown): number | null => {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? n : null;
};

export async function assistantChat(params: {
  store: StoreContext;
  history: ChatTurn[];
  provider?: AiProvider;
  /** Para tests: catálogo sin leer Supabase. */
  products?: { key: string; name: string }[];
  /** Respuesta pensada para leerse en voz alta. */
  voice?: boolean;
  lastMarket?: LastMarketContext | null;
  userId?: string;
  /** Para tests: sustituye el alta real del distribuidor. */
  adopt?: typeof adoptMarketOffer;
  /** Para tests: actualización de reglas sin tocar Supabase. */
  updateRules?: (storeId: string, rules: SpendingRules) => Promise<SpendingRules>;
  /** Idioma en el que contesta el asistente (el que está usando la app). */
  language?: AppLanguage;
}): Promise<AssistantReply> {
  const provider = params.provider ?? new GroqProvider();
  const language = params.language ?? 'es';
  const products = params.products ?? (await listMarketProducts());
  const lastMarket = params.lastMarket?.options.length ? params.lastMarket : null;
  const canAdopt = Boolean(lastMarket && params.userId);
  const tools = buildTools(products.map((p) => p.key), language, canAdopt);
  const messages: AiMessage[] = [
    {
      role: 'system',
      content: systemPrompt(params.store, products, language, { voice: params.voice === true, lastMarket }),
    },
    ...sanitize(params.history),
  ];

  let market: MarketResearchResult | null = null;
  let adopted: AdoptOfferResult | null = null;

  for (let step = 0; step < MAX_STEPS; step++) {
    const result = await provider.chat(messages, tools);

    if (result.toolCalls.length === 0) {
      return {
        reply: (result.content ?? '').trim() || copy[language].assistantFallback,
        quickReplies: [],
        market,
        adopted,
      };
    }

    messages.push({ role: 'assistant', content: result.content ?? '', toolCalls: result.toolCalls });

    for (const call of result.toolCalls) {
      const args = parseArgs(call.function.arguments);

      if (call.function.name === 'ask_user') {
        const options = Array.isArray(args.options)
          ? args.options.map(String).filter(Boolean).slice(0, 4)
          : [];
        return {
          reply:
            String(args.question ?? result.content ?? '').trim() ||
            copy[language].assistantMoreDetails,
          quickReplies: options,
          market,
          adopted,
        };
      }

      let output: Record<string, unknown>;
      try {
        if (call.function.name === 'market_research') {
          market = await runMarketResearch({
            storeId: params.store.id,
            query: String(args.product ?? ''),
            productKey: typeof args.product_key === 'string' ? args.product_key : null,
            region: parseRegion(args.region),
            monthlyQuantity: positive(args.monthly_quantity),
            maxUnitPriceEur: positive(args.max_unit_price_eur),
          });
          output = compact(market);
        } else if (call.function.name === 'adopt_offer') {
          const number = Math.round(Number(args.option_number));
          const option = lastMarket?.options[number - 1];
          if (!canAdopt || !lastMarket || !option) {
            output = { error: 'Esa opción no existe. Pregunta al dueño cuál de las opciones quiere.' };
          } else if (args.owner_confirmed !== true) {
            output = { error: 'Falta la confirmación del dueño. Pregúntale antes con ask_user.' };
          } else if (adopted) {
            output = { error: 'Ya se añadió un distribuidor en este mensaje.' };
          } else {
            adopted = await (params.adopt ?? adoptMarketOffer)({
              store: params.store,
              userId: params.userId!,
              offerId: option.offerId,
              searchId: lastMarket.searchId,
              quantity: positive(args.quantity) ?? lastMarket.monthlyQuantity,
              placeOrder: args.place_order === true,
            });
            output = {
              added: true,
              supplier: adopted.supplierName,
              product: adopted.productName,
              order: adopted.order
                ? {
                    qty: adopted.order.qty,
                    total: adopted.order.total,
                    paid_with_paypal: adopted.order.paid,
                    status: adopted.order.status,
                    reason: adopted.order.reason,
                  }
                : null,
            };
          }
        } else if (call.function.name === 'get_store_summary') {
          const [low, spent] = await Promise.all([
            getLowStockProducts({ storeId: params.store.id }),
            getSpentThisMonth(params.store.id),
          ]);
          output = {
            low_stock: low.map((p) => ({ name: p.name, stock: p.stock, supplier: p.supplierName })),
            spent_this_month: spent,
            rules: params.store.rules,
          };
        } else if (call.function.name === 'adjust_budget') {
          const monthlyLimit =
            args.monthly_limit == null ? params.store.rules.monthlyLimit : Number(args.monthly_limit);
          const maxPerOrder =
            args.max_per_order == null ? params.store.rules.maxPerOrder : Number(args.max_per_order);
          const requireApprovalAbove =
            args.require_approval_above == null
              ? params.store.rules.requireApprovalAbove
              : Number(args.require_approval_above);

          const invalid =
            !Number.isFinite(maxPerOrder) ||
            !Number.isFinite(monthlyLimit) ||
            !Number.isFinite(requireApprovalAbove)
              ? copy[language].assistantBudgetNumbers
              : maxPerOrder <= 0
                ? copy[language].assistantBudgetMaxPerOrder
                : monthlyLimit < maxPerOrder
                  ? fill(copy[language].assistantBudgetMonthlyBelowMax, {
                      max: maxPerOrder.toFixed(2),
                    })
                  : requireApprovalAbove > maxPerOrder
                    ? fill(copy[language].assistantBudgetApprovalAboveMax, {
                        max: maxPerOrder.toFixed(2),
                      })
                    : null;

          if (invalid) {
            output = { ok: false, error: invalid };
          } else {
            const updated = await (
              params.updateRules ?? ((id: string, rules: SpendingRules) => updateStoreRules(id, rules))
            )(params.store.id, {
              maxPerOrder,
              monthlyLimit,
              requireApprovalAbove,
              allowedSupplierIds: params.store.rules.allowedSupplierIds,
            });
            output = {
              ok: true,
              updated: {
                max_per_order: updated.maxPerOrder,
                monthly_limit: updated.monthlyLimit,
                require_approval_above: updated.requireApprovalAbove,
              },
            };
          }
        } else {
          output = {
            error: fill(copy[language].assistantToolUnknown, {
              name: call.function.name,
            }),
          };
        }
      } catch (error) {
        output = { error: error instanceof Error ? error.message : String(error) };
      }

      messages.push({
        role: 'tool',
        toolCallId: call.id,
        name: call.function.name,
        content: JSON.stringify(output),
      });
    }
  }

  return {
    reply: market
      ? copy[language].assistantMarketFound
      : copy[language].assistantCouldNotFinish,
    quickReplies: [],
    market,
    adopted,
  };
}
