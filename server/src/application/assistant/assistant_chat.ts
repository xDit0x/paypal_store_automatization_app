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

function buildTools(productKeys: string[], canAdopt: boolean): AiToolDefinition[] {
  return [
  ...(canAdopt ? [ADOPT_TOOL] : []),
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
  ];
}

function systemPrompt(
  store: StoreContext,
  products: { key: string; name: string }[],
  options: { voice: boolean; lastMarket: LastMarketContext | null },
): string {
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
    'Haz una sola pregunta cada vez. No inventes precios ni distribuidores: usa solo lo que devuelven las herramientas.',
    'Para preguntas sobre el stock o el gasto usa get_store_summary.',
    'Usa **negrita** solo para nombres de distribuidor e importes.',
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
}): Promise<AssistantReply> {
  const provider = params.provider ?? new GroqProvider();
  const products = params.products ?? (await listMarketProducts());
  const lastMarket = params.lastMarket?.options.length ? params.lastMarket : null;
  const canAdopt = Boolean(lastMarket && params.userId);
  const tools = buildTools(products.map((p) => p.key), canAdopt);
  const messages: AiMessage[] = [
    {
      role: 'system',
      content: systemPrompt(params.store, products, { voice: params.voice === true, lastMarket }),
    },
    ...sanitize(params.history),
  ];

  let market: MarketResearchResult | null = null;
  let adopted: AdoptOfferResult | null = null;

  for (let step = 0; step < MAX_STEPS; step++) {
    const result = await provider.chat(messages, tools);

    if (result.toolCalls.length === 0) {
      return { reply: (result.content ?? '').trim() || '¿En qué te ayudo?', quickReplies: [], market, adopted };
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
    adopted,
  };
}
