import assert from 'node:assert/strict';
import test from 'node:test';

import type { AiChatResult, AiMessage, AiProvider } from '../src/infrastructure/ai/provider.js';

// Valores falsos: el test no llega a llamar a Supabase.
process.env.SUPABASE_URL ??= 'https://example.supabase.co';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'test';

// Se importa dentro de cada test (después de poner las variables de entorno)
// para no usar un await suelto en el archivo.
async function assistantChat(
  ...args: Parameters<typeof import('../src/application/assistant/assistant_chat.js').assistantChat>
) {
  const module = await import('../src/application/assistant/assistant_chat.js');
  return module.assistantChat(...args);
}

const store = {
  id: 's1', name: 'Café Prueba', currency: 'EUR', paypalMerchantEmail: null, notificationEmail: null,
  rules: { maxPerOrder: 200, monthlyLimit: 800, requireApprovalAbove: 50, allowedSupplierIds: [] },
};

function fake(results: AiChatResult[]): AiProvider & { seen: AiMessage[][] } {
  const seen: AiMessage[][] = [];
  return {
    name: 'fake', model: 'fake', seen,
    async chat(messages) {
      seen.push(messages);
      return results.shift() ?? { content: 'fin', toolCalls: [] };
    },
  };
}

test('pregunta la región con respuestas rápidas', async () => {
  const provider = fake([{
    content: null,
    toolCalls: [{ id: 'c1', type: 'function', function: {
      name: 'ask_user',
      arguments: JSON.stringify({ question: '¿Dónde busco?', options: ['Solo España', 'Europa', 'Todo el mundo'] }),
    } }],
  }]);
  const reply = await assistantChat({ store, history: [{ role: 'user', content: 'Quiero vender kombucha' }], provider, products: [] });
  assert.equal(reply.reply, '¿Dónde busco?');
  assert.deepEqual(reply.quickReplies, ['Solo España', 'Europa', 'Todo el mundo']);
  assert.equal(reply.market, null);
});

test('respuesta normal y historial recortado', async () => {
  const provider = fake([{ content: 'Hola, ¿qué necesitas?', toolCalls: [] }]);
  const history = Array.from({ length: 40 }, (_, i) => ({
    role: (i % 2 === 0 ? 'user' : 'assistant') as 'user' | 'assistant',
    content: 'x'.repeat(5000),
  }));
  const reply = await assistantChat({ store, history, provider, products: [] });
  assert.equal(reply.reply, 'Hola, ¿qué necesitas?');
  const sent = provider.seen[0]!;
  assert.equal(sent.length, 21); // sistema + 20 turnos
  assert.ok(sent.every((m) => m.content.length <= 2000 || m.role === 'system'));
});

test('el asistente ajusta el presupuesto cuando el dueño lo pide', async () => {
  const provider = fake([
    { content: null, toolCalls: [{ id: 'c1', type: 'function', function: { name: 'adjust_budget', arguments: JSON.stringify({ monthly_limit: 200 }) } }] },
    { content: 'He ajustado el presupuesto mensual a 200 euros.', toolCalls: [] },
  ]);
  const reply = await assistantChat({
    store,
    history: [{ role: 'user', content: 'Sí, ajusta el presupuesto máximo a 200 euros' }],
    provider,
    products: [],
    updateRules: async () => ({ ...store.rules }),
  });
  assert.equal(reply.reply, 'He ajustado el presupuesto mensual a 200 euros.');
  assert.deepEqual(reply.quickReplies, []);
});

test('el asistente no ajusta con valores inválidos', async () => {
  const provider = fake([
    { content: null, toolCalls: [{ id: 'c1', type: 'function', function: { name: 'adjust_budget', arguments: JSON.stringify({ max_per_order: 0 }) } }] },
    { content: 'No puedo ajustar ese presupuesto.', toolCalls: [] },
  ]);
  const reply = await assistantChat({
    store,
    history: [{ role: 'user', content: 'Quiero un presupuesto de 0 euros' }],
    provider,
    products: [],
    updateRules: async () => ({ ...store.rules }),
  });
  assert.equal(reply.reply, 'No puedo ajustar ese presupuesto.');
  const second = provider.seen[1]!;
  const toolMessage = second.find((m) => m.role === 'tool');
  assert.ok(toolMessage?.content !== undefined);
  assert.match(String(toolMessage?.content), /mayor que 0/);
});

test('herramienta desconocida no rompe el chat', async () => {
  const provider = fake([
    { content: null, toolCalls: [{ id: 'c1', type: 'function', function: { name: 'borrar_todo', arguments: '{}' } }] },
    { content: 'No puedo hacer eso.', toolCalls: [] },
  ]);
  const reply = await assistantChat({ store, history: [{ role: 'user', content: 'hola' }], provider, products: [] });
  assert.equal(reply.reply, 'No puedo hacer eso.');
  const second = provider.seen[1]!;
  assert.match(second[second.length - 1]!.content, /desconocida/);
});
