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

function buildTools(productKeys: string[]): AiToolDefinition[] {
  return [
  {
    type: 'function',
    function: {
      name: 'ask_user',
      description:
        'Haz UNA pregunta corta al dueño cuando falte un dato, con 2-4 respuestas rápidas que pueda tocar.',
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
      description:
        'Compara distribuidores de varios países para un producto nuevo y devuelve los 3 más asequibles con el coste real (precio, envío, aranceles, cambio de moneda). La app muestra las tarjetas sola.',
      parameters: {
        type: 'object',
        properties: {
          product: { type: 'string', description: 'Producto tal como lo describe el dueño.' },
          product_key: {
            type: 'string',
            description: 'Clave del catálogo que corresponde al producto. Omitir si ninguna encaja.',
            ...(productKeys.length > 0 ? { enum: productKeys } : {}),
          },
          region: { type: 'string', enum: ['spain', 'europe', 'world'] },
          monthly_quantity: { type: 'number', description: 'Unidades al mes. Omitir si no lo sabe.' },
          max_unit_price_eur: { type: 'number', description: 'Precio máximo por unidad. Omitir si no hay.' },
        },
        required: ['product', 'region'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'get_store_summary',
      description: 'Estado de la tienda: productos con stock bajo, gasto del mes y reglas de gasto.',
      parameters: { type: 'object', properties: {} },
    },
  },
  {
    type: 'function',
    function: {
      name: 'adjust_budget',
      description:
        'Ajusta el presupuesto de la tienda cuando el dueño lo pide: límite mensual total, máximo por pedido o umbral de aprobación automática.',
      parameters: {
        type: 'object',
        properties: {
          monthly_limit: {
            type: 'number',
            description:
              'Límite mensual del presupuesto: lo máximo que se puede gastar en el mes. Omitir si no se cambia.',
          },
          max_per_order: {
            type: 'number',
            description:
              'Máximo por pedido: lo máximo que puede costar una sola compra. Omitir si no se cambia.',
          },
          require_approval_above: {
            type: 'number',
            description:
              'Importe a partir del cual el agente pide aprobación. 0 para pedirla siempre.',
          },
        },
        required: [],
      },
    },
  },
  ];
}

function systemPrompt(store: StoreContext, products: { key: string; name: string }[]): string {
  const catalogue = products.length
    ? products.map((p) => `- ${p.key}: ${p.name}`).join('\n')
    : '(vacío)';
  return [
    `Eres el asistente de compras de "${store.name}", una tienda pequeña. Moneda: ${store.currency}.`,
    'Hablas con el dueño, a menudo por voz: respuestas cortas (2-3 frases), naturales, sin tablas ni listas largas.',
    'Responde en el idioma del dueño (español por defecto).',
    '',
    'Cuando el dueño quiera vender o comprar un producto nuevo:',
    '1. Si no sabes dónde buscar, pregunta con ask_user: opciones "Solo España", "Europa", "Todo el mundo".',
    '2. Si no sabes cuántas unidades necesita al mes, pregúntalo con ask_user (ofrece 3 cantidades razonables y "No lo sé").',
    '3. El precio máximo es opcional: pregúntalo solo si el dueño habló de presupuesto.',
    '4. Llama a market_research. Luego resume en 2-3 frases: el más barato, cuánto cuesta por unidad puesto en la tienda y qué lo diferencia de los otros (plazo, mínimo de pedido, aranceles). La app ya muestra las tarjetas: no repitas todos los datos.',
    '5. Si el producto no está en el catálogo, NO llames a market_research varias veces ni inventes: dilo con sinceridad, di que de momento no tienes distribuidores verificados para eso y menciona 3-4 productos parecidos del catálogo que sí puedes comparar.',
    '6. Si el resultado trae outside_region (países fuera de la región elegida que sí lo venden) y no hay ofertas, ofrece ampliar la búsqueda con ask_user.',
    '',
    'Catálogo de productos que puedes comparar (clave: nombre). Si lo que pide el dueño encaja con uno, aunque lo diga con otras palabras o marca, pasa su clave en product_key:',
    catalogue,
    '',
    'Si el dueño da detalles (marca, tamaño) de un producto del catálogo, no vuelvas a preguntarlos: busca directamente.',
    'Si el dueño quiere cambiar el presupuesto, llama a `adjust_budget`: "presupuesto del mes", "tope mensual" o "cuánto puedo gastar al mes" es `monthly_limit`; "máximo por pedido" o "tope por compra" es `max_per_order`; "pedirme aprobación" es `require_approval_above`. Si la frase es ambigua (por ejemplo "presupuesto máximo"), pregunta con `ask_user` si es el del mes o el de cada pedido.',
    'Haz una sola pregunta cada vez. No inventes precios ni distribuidores: usa solo lo que devuelven las herramientas.',
    'Para preguntas sobre el stock o el gasto usa get_store_summary.',
    'Usa **negrita** solo para nombres de distribuidor e importes.',
  ].join('\n');
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
}): Promise<AssistantReply> {
  const provider = params.provider ?? new GroqProvider();
  const products = params.products ?? (await listMarketProducts());
  const tools = buildTools(products.map((p) => p.key));
  const messages: AiMessage[] = [
    { role: 'system', content: systemPrompt(params.store, products) },
    ...sanitize(params.history),
  ];

  let market: MarketResearchResult | null = null;

  for (let step = 0; step < MAX_STEPS; step++) {
    const result = await provider.chat(messages, tools);

    if (result.toolCalls.length === 0) {
      return { reply: (result.content ?? '').trim() || '¿En qué te ayudo?', quickReplies: [], market };
    }

    messages.push({ role: 'assistant', content: result.content ?? '', toolCalls: result.toolCalls });

    for (const call of result.toolCalls) {
      const args = parseArgs(call.function.arguments);

      if (call.function.name === 'ask_user') {
        const options = Array.isArray(args.options)
          ? args.options.map(String).filter(Boolean).slice(0, 4)
          : [];
        return {
          reply: String(args.question ?? result.content ?? '').trim() || '¿Me das más detalles?',
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
              ? 'Los importes del presupuesto deben ser números.'
              : maxPerOrder <= 0
                ? 'El máximo por pedido tiene que ser mayor que 0.'
                : monthlyLimit < maxPerOrder
                  ? `El límite mensual no puede ser menor que el máximo por pedido (${maxPerOrder.toFixed(2)}).`
                  : requireApprovalAbove > maxPerOrder
                    ? `El umbral de aprobación no puede superar el máximo por pedido (${maxPerOrder.toFixed(2)}).`
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
          output = { error: `Herramienta desconocida: ${call.function.name}` };
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
    reply: market ? 'Aquí tienes las mejores opciones que he encontrado.' : 'No he podido terminar. ¿Lo intentamos otra vez?',
    quickReplies: [],
    market,
  };
}
