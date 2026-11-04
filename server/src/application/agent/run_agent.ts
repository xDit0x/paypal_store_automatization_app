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
import { getLowStockProducts, getInactiveProductUids } from '../catalog/get_low_stock.js';
import {
  createOrder,
  quoteOrder,
  type OrderQuote,
} from '../orders/create_order.js';
import { fulfillOrder } from '../orders/fulfill_order.js';
import { getSpentThisMonth } from '../orders/spent_this_month.js';
import {
  agentPrompt,
  copy,
  fill,
  type AppLanguage,
} from '../i18n/messages.js';
import { describeReason } from '../i18n/reasons.js';
import { ReasonError } from '../../domain/reasons.js';
import type { StoreContext } from '../stores/store_service.js';

function buildTools(language: AppLanguage): AiToolDefinition[] {
  const text = copy[language];
  return [
    {
      type: 'function',
      function: {
        name: 'create_restock_order',
        description: text.toolCreateOrder,
        parameters: {
          type: 'object',
          properties: {
            supplier_id: {
              type: 'string',
              description: text.toolSupplierId,
            },
            items: {
              type: 'array',
              description: text.toolItems,
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
              description: text.toolCreateOrderReason,
            },
          },
          required: ['supplier_id', 'items'],
        },
      },
    },
  ];
}

export interface AgentRunResult {
  orderId: string | null;
  decision: string;
  message: string;
}

interface StockyArgs {
  supplier_id?: unknown;
  items?: unknown;
  reasoning?: unknown;
}

async function handleToolCall(
  call: AiToolCall,
  store: StoreContext,
  agentRunId: string,
  language: AppLanguage,
): Promise<Record<string, unknown>> {
  const text = copy[language];

  if (call.function.name !== 'create_restock_order') {
    return {
      ok: false,
      error: fill(text.toolUnknown, { name: call.function.name }),
    };
  }

  let args: StockyArgs;
  try {
    args = JSON.parse(call.function.arguments) as StockyArgs;
  } catch {
    return { ok: false, error: text.toolInvalidArgs };
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
    return { ok: false, error: text.toolMissingSupplier };
  }

  const lowStock = await getLowStockProducts({ storeId: store.id });
  const available = new Map(
    lowStock
      .filter((product) => product.supplierId === supplierId)
      .map((product) => [product.uid, product]),
  );

  // Un producto eliminado no se repone: se comprueba aparte para poder
  // explicarlo con claridad (y no pedir un producto que ya no existe).
  const inactive = await getInactiveProductUids(
    lines.map((line) => line.productUid),
  );

  for (const line of lines) {
    if (inactive.has(line.productUid)) {
      return {
        ok: false,
        error: fill(text.productDeleted, { uid: line.productUid }),
      };
    }
    if (!available.has(line.productUid)) {
      return {
        ok: false,
        error: fill(text.productNotLowStock, { uid: line.productUid }),
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
    currency: store.currency,
  });

  if (decision.status === 'blocked') {
    return {
      ok: false,
      blocked: true,
      code: decision.code,
      reason: describeReason(decision.reason ?? { code: 'blocked_by_rules' }, language),
      total: quote.subtotal,
      spent_this_month: spentThisMonth,
      monthly_limit: store.rules.monthlyLimit,
      max_per_order: store.rules.maxPerOrder,
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
      // El agente compra y paga solo, pero el inventario no se adelanta: el
      // stock sube cuando llega la mercancía y se registra el albarán.
      fulfillment = await fulfillOrder(order.id, { deferStock: true });
    } catch (error) {
      warning =
        error instanceof ReasonError
          ? describeReason(error.reason, language)
          : error instanceof Error
            ? error.message
            : String(error);
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
  language: AppLanguage,
): string {
  const text = copy[language];
  const approvalRule =
    store.rules.requireApprovalAbove <= 0
      ? text.agentApprovalAlways
      : fill(text.agentApprovalAbove, {
          amount: `${store.rules.requireApprovalAbove.toFixed(2)} ${store.currency}`,
        });

  return fill(agentPrompt[language], {
    store: store.name,
    currency: store.currency,
    maxPerOrder: store.rules.maxPerOrder.toFixed(2),
    monthlyLimit: store.rules.monthlyLimit.toFixed(2),
    spentThisMonth: spentThisMonth.toFixed(2),
    approvalRule,
    languageRule: text.agentLanguageRule,
  });
}

export async function runAgent(params: {
  store: StoreContext;
  userId: string;
  /** Idioma en el que contesta el agente (el que está usando la app). */
  language?: AppLanguage;
}): Promise<AgentRunResult> {
  const provider = new GroqProvider();
  const language = params.language ?? 'es';
  const text = copy[language];
  const tools = buildTools(language);

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
      message: text.agentNoLowStock,
    };
  }

  const spentThisMonth = await getSpentThisMonth(params.store.id);

  const messages: AiMessage[] = [
    {
      role: 'system',
      content: buildSystemPrompt(params.store, spentThisMonth, language),
    },
    {
      role: 'user',
      content: `${text.agentLowStockList}\n${JSON.stringify(lowStock, null, 2)}`,
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
          output = await handleToolCall(
            call,
            params.store,
            runId,
            language,
          );
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

  const blockedReasons = [
    ...new Set(
      executed
        .filter(
          (result) =>
            result.blocked === true && typeof result.reason === 'string',
        )
        .map((result) => result.reason as string),
    ),
  ];

  const blockedClause =
    blockedReasons.length === 0
      ? text.blockFallback
      : blockedReasons.join('; ');

  // El agente puede comprar solo: en ese caso el pedido queda pagado y
  // esperando la entrega, así que se avisa de que el stock llega con el
  // albarán.
  const paidPendingDelivery = executed.some(
    (result) => result.ok === true && result.status === 'paid',
  );

  const defaultMessage =
    decision === 'order_created'
      ? blockedReasons.length > 0
        ? fill(text.agentPartialBlocked, { reason: blockedClause })
        : paidPendingDelivery
          ? text.agentOrderPaidPendingDelivery
          : text.agentOrderCreated
      : decision === 'blocked'
        ? fill(text.agentBlocked, { reason: blockedClause })
        : finalMessage.trim().length > 0
          ? finalMessage.trim()
          : text.agentNoOrder;

  return {
    orderId: orderIds[0] ?? null,
    decision,
    message: defaultMessage,
  };
}
