import Groq from 'groq-sdk';

import { env, requireGroqEnv } from '../../config/env.js';
import type {
  AiChatResult,
  AiMessage,
  AiProvider,
  AiToolCall,
  AiToolDefinition,
} from './provider.js';

export class GroqProvider implements AiProvider {
  readonly name = 'groq';
  readonly model: string;
  private readonly client: Groq;

  constructor(options?: { apiKey?: string; model?: string }) {
    requireGroqEnv();
    const apiKey = options?.apiKey ?? env.groqApiKey;
    this.client = new Groq({ apiKey });
    this.model = options?.model ?? env.aiModel;
  }

  async chat(
    messages: AiMessage[],
    tools: AiToolDefinition[] = [],
  ): Promise<AiChatResult> {
    const completion = await this.client.chat.completions.create({
      model: this.model,
      messages: messages.map((message) => ({
        role: message.role,
        content: message.content,
        ...(message.toolCallId ? { tool_call_id: message.toolCallId } : {}),
        ...(message.name ? { name: message.name } : {}),
        ...(message.toolCalls?.length ? { tool_calls: message.toolCalls } : {}),
      })) as Groq.Chat.ChatCompletionMessageParam[],
      ...(tools.length > 0
        ? {
            tools: tools as Groq.Chat.ChatCompletionTool[],
            tool_choice: 'auto' as const,
          }
        : {}),
    });

    const message = completion.choices[0]?.message;
    const toolCalls: AiToolCall[] = (message?.tool_calls ?? []).map((call) => ({
      id: call.id,
      type: 'function',
      function: {
        name: call.function.name,
        arguments: call.function.arguments,
      },
    }));

    return {
      content: message?.content ?? null,
      toolCalls,
    };
  }
}
