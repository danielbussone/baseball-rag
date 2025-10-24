import type { ChatResponse, ToolExecution } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001';

export interface StreamChunk {
  type: 'content' | 'tool_start' | 'tool_end' | 'done' | 'error';
  content?: string;
  toolExecution?: ToolExecution;
  error?: string;
}

export interface StreamCallbacks {
  onContent: (content: string) => void;
  onToolStart: (toolExecution: ToolExecution) => void;
  onToolEnd: (toolExecution: ToolExecution) => void;
  onDone: () => void;
  onError: (error: string) => void;
}

/**
 * Sends a chat message to the backend API
 * @param message - The user's message text
 * @returns Promise resolving to the API response containing the assistant's reply
 * @throws Error if the API request fails or returns an error status
 *
 * @example
 * ```ts
 * const response = await sendChatMessage("Compare Mike Trout and Ken Griffey Jr");
 * console.log(response.response); // Assistant's reply
 * ```
 */
export async function sendChatMessage(message: string): Promise<ChatResponse> {
  const response = await fetch(`${API_BASE_URL}/api/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ message }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Unknown error' }));
    throw new Error(error.error || `HTTP ${response.status}: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Sends a chat message with streaming response via Server-Sent Events
 * @param message - The user's message text
 * @param callbacks - Callback functions for handling different stream events
 * @returns Promise that resolves when the stream is complete
 * @throws Error if the API request fails
 *
 * @example
 * ```ts
 * await sendChatMessageStream("Tell me about Mike Trout", {
 *   onContent: (content) => console.log(content),
 *   onToolStart: (tool) => console.log(`Tool ${tool.name} started`),
 *   onToolEnd: (tool) => console.log(`Tool ${tool.name} completed`),
 *   onDone: () => console.log('Stream complete'),
 *   onError: (error) => console.error(error)
 * });
 * ```
 */
export async function sendChatMessageStream(
  message: string,
  callbacks: StreamCallbacks
): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/api/chat/stream`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ message }),
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  if (!response.body) {
    throw new Error('Response body is null');
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  try {
    while (true) {
      const { done, value } = await reader.read();

      if (done) {
        break;
      }

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');

      // Keep the last incomplete line in the buffer
      buffer = lines.pop() || '';

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6); // Remove 'data: ' prefix
          if (data.trim()) {
            try {
              const chunk: StreamChunk = JSON.parse(data);

              switch (chunk.type) {
                case 'content':
                  if (chunk.content) {
                    callbacks.onContent(chunk.content);
                  }
                  break;
                case 'tool_start':
                  if (chunk.toolExecution) {
                    callbacks.onToolStart(chunk.toolExecution);
                  }
                  break;
                case 'tool_end':
                  if (chunk.toolExecution) {
                    callbacks.onToolEnd(chunk.toolExecution);
                  }
                  break;
                case 'done':
                  callbacks.onDone();
                  break;
                case 'error':
                  callbacks.onError(chunk.error || 'Unknown error');
                  break;
              }
            } catch (e) {
              console.error('Failed to parse SSE chunk:', e);
            }
          }
        }
      }
    }
  } catch (error) {
    callbacks.onError(error instanceof Error ? error.message : 'Unknown error');
  } finally {
    reader.releaseLock();
  }
}
