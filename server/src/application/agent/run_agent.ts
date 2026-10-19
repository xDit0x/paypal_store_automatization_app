import { GroqProvider } from '../../infrastructure/ai/groq_provider.js';
import type {
  AiMessage,
  AiToolCall,
  AiToolDefinition,
} from '../../infrastructure/ai/provider.js';
import { supabaseAdmin } from '../../infrastructure/supabase/supabase_client.js';
import {
  evaluateSpendingRules,
  type SpendingDecision,
} from '../../domain/spending_rules.js';
import { getLowStockProducts } from '../catalog/get_low_stock.js';
import {
  createOrder,
  quoteOrder,
  type OrderQuote,
} from '../orders/create_order.js';
import { fulfillOrder } from '../orders/fulfill_order.js';
import { getSpentThisMonth } from '../orders/spent_this_month.js';
import type { StoreContext } from '../stores/store_service.js';

const tools: AiToolDefinition[] = [
  {
    type: 'function',
    function: {
      name: 'create_restock_order',
      description:
        'Crea un pedido de reposición a un proveedor con productos que están por debajo de su stock mínimo.',
      parameters: {
        type: 'object',
        properties: {
          supplier_id: {
            type: 'string',
            description: 'UUID del proveedor del pedido.',
          },
          items: {
            type: 'array',
            description: 'Productos a reponer.',
            items: {
              type: 'object',
              properties: {
                product_uid: { type: 'string' },
                qty: { type: 'integer', minimum: 1 },
              },
              required: ['product_uid', 'qty'],
            },
          },
          reasoning: {
            type: 'string',
            description: 'Motivo breve de la reposición.',
          },
        },
        required: ['supplier_id', 'items'],
      },
    },
  },
];

export interface AgentRunResult {
  orderId: string | null;
  decision: string;
  message: string;
}

interface RestockArgs {
  supplier_id?: unknown;
  items?: unknown;
  reasoning?: unknown;
}

async function handleToolCall(
  call: AiToolCall,
  store: StoreContext,
  agentRunId: string,
): Promise<Record<string, unknown>> {
  if (call.function.name !== 'create_restock_order') {
    return { ok: false, error: `Herramienta desconocida: ${call.function.name}` };
  }

  let args: RestockArgs;
  try {
    args = JSON.parse(call.function.arguments) as RestockArgs;
  } catch {
    return { ok: false, error: 'Los argumentos de la herramienta no son JSON válido.' };
  }

  const supplierId = typeof args.supplier_id === 'string' ? args.supplier_id : '';
  const rawItems = Array.isArray(args.items) ? args.items : [];
  const lines = rawItems.map((item) => {
    const record = item as Record<string, unknown>;
    return {
      productUid: String(record.product_uid ?? ''),
      qty: Number(record.qty ?? 0),
    };
  });

  if (!supplierId || lines.length === 0) {
    return { ok: false, error: 'Faltan el proveedor o las líneas del pedido.' };
  }

  const lowStock = await getLowStockProducts({ storeId: store.id });
  const available = new Map(
    lowStock
      .filter((product) => product.supplierId === supplierId)
      .map((product) => [product.uid, product]),
  );

  for (const line of lines) {
    if (!available.has(line.productUid)) {
      return {
        ok: false,
        error: `El producto ${line.productUid} no está bajo de stock o no pertenece al proveedor.`,
      };
    }
  }

  let quote: OrderQuote;
  try {
    quote = await quoteOrder({ supplierId, lines });
  } catch (error) {
    return {
      ok: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }

  const spentThisMonth = await getSpentThisMonth(store.id);
  const decision: SpendingDecision = evaluateSpendingRules({
    rules: store.rules,
    orderTotal: quote.subtotal,
    spentThisMonth,
    supplierId,
  });

  if (decision.status === 'blocked') {
    return {
      ok: false,
      blocked: true,
      reason: decision.reason ?? 'El pedido está bloqueado por las reglas de gasto.',
      total: quote.subtotal,
    };
  }

  const status = decision.status === 'auto_approved' ? 'approved' : 'pending_approval';

  const order = await createOrder(
    {
      storeId: store.id,
      supplierId,
      lines,
      status,
      createdByType: 'agent',
      agentRunId,
    },
    quote,
  );

  let fulfillment: unknown = null;
  let warning: string | null = null;

  if (status === 'approved') {
    try {
      fulfillment = await fulfillOrder(order.id);
    } catch (error) {
      warning = error instanceof Error ? error.message : String(error);
    }
  }

  return {
    ok: true,
    order_id: order.id,
    status: order.status,
    total: order.total,
    decision: decision.status,
    fulfillment,
    ...(warning ? { warning } : {}),
  };
}

function buildSystemPrompt(
  store: StoreContext,
  spentThisMonth: number,
): string {
  return [
    `Eres el agente de reposición de la tienda "${store.name}".`,
    'Tu objetivo es reponer los productos con stock bajo creando pedidos a proveedores con la herramienta create_restock_order.',
    'Reglas obligatorias:',
    '- Solo puedes reponer productos que aparezcan en la lista de stock bajo.',
    '- No repitas productos que ya estén en un pedido abierto.',
    '- Crea como máximo un pedido por proveedor.',
    '- No inventes UIDs, proveedores ni precios.',
    '- Usa cantidades razonables basadas en suggestedQty; no pidas más de lo necesario.',
    `- Máximo por pedido: ${store.rules.maxPerOrder.toFixed(2)} ${store.currency}.`,
    `- Límite mensual: ${store.rules.monthlyLimit.toFixed(2)} ${store.currency}; gastado este mes: ${spentThisMonth.toFixed(2)} ${store.currency}.`,
    store.rules.requireApprovalAbove <= 0
      ? '- Cualquier pedido queda pendiente de aprobación: pregunta siempre antes de comprar.'
      : `- Por encima de ${store.rules.requireApprovalAbove.toFixed(2)} ${store.currency} el pedido quedará pendiente de aprobación.`,
    '- Si no hace falta reponer nada, no llames a la herramienta y explica por qué.',
    'Responde siempre en español, con una explicación breve de lo que hiciste.',
    '- Usa **negrita** (doble asterisco) para el nombre del proveedor, el nombre del producto y el importe total del pedido. No uses otros formatos.',
  ].join('\n');
}

export async function runAgent(params: {
  store: StoreContext;
  userId: string;
}): Promise<AgentRunResult> {
  const provider = new GroqProvider();

  const { data: runData, error: runError } = await supabaseAdmin
    .from('agent_runs')
    .insert({
      store_id: params.store.id,
      provider: provider.name,
      model: provider.model,
      decision: 'running',
    })
    .select('id')
    .single();

  if (runError || !runData) {
    throw new Error(`No se pudo registrar la ejecución: ${runError?.message}`);
  }

  const runId = runData.id as string;

  const lowStock = await getLowStockProducts({ storeId: params.store.id });

  if (lowStock.length === 0) {
    await supabaseAdmin
      .from('agent_runs')
      .update({ decision: 'no_action' })
      .eq('id', runId);

    return {
      orderId: null,
      decision: 'no_action',
      message: 'No hay productos con stock bajo. No se hizo ningún pedido.',
    };
  }

  const spentThisMonth = await getSpentThisMonth(params.store.id);

  const messages: AiMessage[] = [
    { role: 'system', content: buildSystemPrompt(params.store, spentThisMonth) },
    {
      role: 'user',
      content: `Inventario con stock bajo:\n${JSON.stringify(lowStock, null, 2)}`,
    },
  ];

  const executed: Record<string, unknown>[] = [];
  let finalMessage = '';

  try {
    for (let step = 0; step < 3; step += 1) {
      const response = await provider.chat(messages, tools);

      if (response.toolCalls.length === 0) {
        finalMessage = response.content ?? '';
        break;
      }

      messages.push({
        role: 'assistant',
        content: response.content ?? '',
        toolCalls: response.toolCalls,
      });

      for (const call of response.toolCalls) {
        let output: Record<string, unknown>;
        try {
          output = await handleToolCall(call, params.store, runId);
        } catch (error) {
          output = {
            ok: false,
            error: error instanceof Error ? error.message : String(error),
          };
        }

        executed.push(output);
        messages.push({
          role: 'tool',
          content: JSON.stringify(output),
          toolCallId: call.id,
          name: call.function.name,
        });
      }
    }
  } catch (error) {
    await supabaseAdmin
      .from('agent_runs')
      .update({ decision: 'failed', tool_calls: executed })
      .eq('id', runId);
    throw error;
  }

  const orderIds = executed
    .filter((result) => result.ok === true && typeof result.order_id === 'string')
    .map((result) => result.order_id as string);

  const decision =
    orderIds.length > 0
      ? 'order_created'
      : executed.some((result) => result.blocked === true)
        ? 'blocked'
        : 'no_action';

  await supabaseAdmin
    .from('agent_runs')
    .update({
      decision,
      order_id: orderIds[0] ?? null,
      tool_calls: executed,
    })
    .eq('id', runId);

  const defaultMessage =
    decision === 'order_created'
      ? 'Pedido de reposición creado.'
      : decision === 'blocked'
        ? 'El pedido quedó bloqueado por las reglas de gasto.'
        : 'No se creó ningún pedido.';

  return {
    orderId: orderIds[0] ?? null,
    decision,
    message: finalMessage || defaultMessage,
  };
}
