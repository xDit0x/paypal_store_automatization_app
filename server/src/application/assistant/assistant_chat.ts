import { GroqProvider } from '../../infrastructure/ai/groq_provider.js';
import type { AiMessage, AiProvider, AiToolDefinition } from '../../infrastructure/ai/provider.js';
import { getLowStockProducts } from '../catalog/get_low_stock.js';
import {
  listMarketProducts,
  runMarketResearch,
  type MarketResearchResult,
} from '../market/market_research.js';
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
}

const MAX_TURNS = 20;
const MAX_CHARS = 2000;
const MAX_STEPS = 5;

function buildTools(
  productKeys: string[],
  language: AppLanguage,
): AiToolDefinition[] {
  const text = toolTexts[language];
  return [
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

function systemPrompt(store: StoreContext, products: { key: string; name: string }[], language: AppLanguage): string {
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
  /** Para tests: actualización de reglas sin tocar Supabase. */
  updateRules?: (storeId: string, rules: SpendingRules) => Promise<SpendingRules>;
  /** Idioma en el que contesta el asistente (el que está usando la app). */
  language?: AppLanguage;
}): Promise<AssistantReply> {
  const provider = params.provider ?? new GroqProvider();
  const language = params.language ?? 'es';
  const products = params.products ?? (await listMarketProducts());
  const tools = buildTools(products.map((p) => p.key), language);
  const messages: AiMessage[] = [
    { role: 'system', content: systemPrompt(params.store, products, language) },
    ...sanitize(params.history),
  ];

  let market: MarketResearchResult | null = null;

  for (let step = 0; step < MAX_STEPS; step++) {
    const result = await provider.chat(messages, tools);

    if (result.toolCalls.length === 0) {
      return {
        reply: (result.content ?? '').trim() || copy[language].assistantFallback,
        quickReplies: [],
        market,
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
  };
}
