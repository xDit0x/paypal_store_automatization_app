export type AiRole = 'system' | 'user' | 'assistant' | 'tool';

export interface AiMessage {
  role: AiRole;
  content: string;
  toolCallId?: string;
  name?: string;
  toolCalls?: AiToolCall[];
}

export interface AiToolDefinition {
  type: 'function';
  function: {
    name: string;
    description: string;
    parameters: Record<string, unknown>;
  };
}

export interface AiToolCall {
  id: string;
  type: 'function';
  function: {
    name: string;
    arguments: string;
  };
}

export interface AiChatResult {
  content: string | null;
  toolCalls: AiToolCall[];
}

export interface AiProvider {
  readonly name: string;
  readonly model: string;
  chat(messages: AiMessage[], tools?: AiToolDefinition[]): Promise<AiChatResult>;
}
