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
