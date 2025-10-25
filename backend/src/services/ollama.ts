interface OllamaResponse {
  model: string;
  response?: string;
  done: boolean;
  message?: {
    role: string;
    content: string;
    tool_calls?: Array<{
      type: string;
      function: {
        name: string;
        arguments: Record<string, any>;
      };
    }>;
  };
}

import { env } from '../config/env.js';
import { createModuleLogger } from '../config/logger.js';

const logger = createModuleLogger('OllamaService');

export class OllamaService {
  private baseUrl = env.ollama.baseUrl;
  private model = env.ollama.model;

  async chat(messages: any[], tools?: any[]): Promise<OllamaResponse> {
    logger.debug(
      {
        messageCount: messages.length,
        toolCount: tools?.length || 0,
        model: this.model
      },
      'Sending request to Ollama'
    );

    const startTime = Date.now();

    try {
      const response = await fetch(`${this.baseUrl}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: this.model,
          messages,
          tools,
          stream: false
        })
      });

      const duration = Date.now() - startTime;

      if (!response.ok) {
        logger.error(
          { status: response.status, statusText: response.statusText, duration },
          'Ollama API request failed'
        );
        throw new Error(`Ollama API error: ${response.statusText}`);
      }

      const result = await response.json();

      logger.debug(
        {
          duration,
          hasToolCalls: !!result.message?.tool_calls,
          contentLength: result.message?.content?.length || 0
        },
        'Ollama response received'
      );

      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({ err: error, duration, baseUrl: this.baseUrl }, 'Ollama request failed');
      throw error;
    }
  }

  async *chatStream(messages: any[], tools?: any[]): AsyncGenerator<OllamaResponse, void, unknown> {
    logger.debug(
      {
        messageCount: messages.length,
        toolCount: tools?.length || 0,
        model: this.model
      },
      'Starting streaming request to Ollama'
    );

    const startTime = Date.now();

    try {
      const response = await fetch(`${this.baseUrl}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: this.model,
          messages,
          tools,
          stream: true
        })
      });

      if (!response.ok) {
        logger.error(
          { status: response.status, statusText: response.statusText },
          'Ollama streaming API request failed'
        );
        throw new Error(`Ollama API error: ${response.statusText}`);
      }

      if (!response.body) {
        throw new Error('Response body is null');
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();

        if (done) {
          const duration = Date.now() - startTime;
          logger.debug({ duration }, 'Streaming completed');
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');

        // Keep the last incomplete line in the buffer
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (line.trim()) {
            try {
              const chunk: OllamaResponse = JSON.parse(line);
              // logger.debug(`chunk ${JSON.stringify(chunk)}`)

              // Log tool calls when they appear
              if (chunk.message?.tool_calls) {
                logger.debug(
                  {
                    toolCalls: chunk.message.tool_calls.map(tc => tc.function.name),
                    done: chunk.done
                  },
                  'Tool calls in chunk'
                );
              }

              yield chunk;
            } catch (e) {
              logger.warn({ line, err: e }, 'Failed to parse streaming chunk');
            }
          }
        }
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      logger.error({ err: error, duration, baseUrl: this.baseUrl }, 'Ollama streaming request failed');
      throw error;
    }
  }
}