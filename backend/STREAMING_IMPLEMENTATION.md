# Streaming Chat Implementation Plan

## Overview
Add Server-Sent Events (SSE) streaming to the `/api/chat` endpoint to provide real-time token-by-token responses from the LLM, improving perceived performance and user experience.

---

## Current Architecture

### Non-Streaming Flow:
```
User Request → Fastify → ChatService → OllamaService → Ollama (stream: false)
                                                        ↓
User Response ← Fastify ← ChatService ← Full Response ← Ollama
```

**Issues:**
- User waits for entire response (can be 10-30+ seconds)
- No feedback during tool execution
- Poor UX for long responses

---

## Proposed Streaming Architecture

### Streaming Flow:
```
User Request → Fastify → ChatService → OllamaService → Ollama (stream: true)
                 ↓                                        ↓
            SSE Stream ← Token chunks ← AsyncIterator ← Ollama Stream
```

**Benefits:**
- Tokens appear as they're generated
- Can show "Thinking..." and "Using tool..." messages
- Better perceived performance
- User can see progress

---

## Required Changes

### 1. **OllamaService** (src/services/ollama.ts)

#### Add streaming method:
```typescript
async *chatStream(messages: any[], tools?: any[]): AsyncGenerator<OllamaStreamChunk> {
  const response = await fetch(`${this.baseUrl}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: this.model,
      messages,
      tools,
      stream: true  // Enable streaming
    })
  });

  if (!response.ok) {
    throw new Error(`Ollama API error: ${response.statusText}`);
  }

  // Parse NDJSON stream (newline-delimited JSON)
  const reader = response.body!.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';

    for (const line of lines) {
      if (line.trim()) {
        const chunk = JSON.parse(line);
        yield chunk;
      }
    }
  }
}
```

#### Stream response format:
```typescript
interface OllamaStreamChunk {
  model: string;
  created_at: string;
  message?: {
    role: string;
    content: string;  // Incremental token
    tool_calls?: ToolCall[];
  };
  done: boolean;
}
```

---

### 2. **ChatService** (src/services/chat.ts)

#### Add streaming method:
```typescript
async *processMessageStream(userMessage: string): AsyncGenerator<ChatStreamEvent> {
  const messages = [...]; // Same setup as non-streaming

  // Yield "thinking" event
  yield { type: 'thinking', data: 'Processing your question...' };

  // Get initial LLM response (may include tool calls)
  let fullContent = '';
  let toolCalls: ToolCall[] | undefined;

  for await (const chunk of this.ollama.chatStream(messages, toolDefinitions)) {
    if (chunk.message?.content) {
      fullContent += chunk.message.content;
      // Yield token to user
      yield { type: 'token', data: chunk.message.content };
    }

    if (chunk.done && chunk.message?.tool_calls) {
      toolCalls = chunk.message.tool_calls;
    }
  }

  // Handle tool calls (if any)
  if (toolCalls) {
    for (const toolCall of toolCalls) {
      const toolName = toolCall.function.name;

      // Yield tool execution event
      yield { type: 'tool', data: `Using tool: ${toolName}...` };

      // Execute tool
      const result = await toolExecutors[toolName](...args);

      // Add to conversation
      messages.push({ role: 'assistant', content: fullContent, tool_calls });
      messages.push({ role: 'tool', content: JSON.stringify(result) });

      // Stream final response with tool results
      for await (const chunk of this.ollama.chatStream(messages)) {
        if (chunk.message?.content) {
          yield { type: 'token', data: chunk.message.content };
        }
      }
    }
  }

  // Yield done event
  yield { type: 'done', data: null };
}
```

#### Stream event types:
```typescript
type ChatStreamEvent =
  | { type: 'thinking'; data: string }
  | { type: 'tool'; data: string }
  | { type: 'token'; data: string }
  | { type: 'error'; data: string }
  | { type: 'done'; data: null };
```

---

### 3. **Fastify Endpoint** (src/index.ts)

#### Add SSE streaming endpoint:
```typescript
fastify.post('/api/chat/stream', async (request, reply) => {
  const { message } = request.body as { message: string };

  if (!message) {
    return reply.code(400).send({ error: 'Message is required' });
  }

  // Set SSE headers
  reply.raw.setHeader('Content-Type', 'text/event-stream');
  reply.raw.setHeader('Cache-Control', 'no-cache');
  reply.raw.setHeader('Connection', 'keep-alive');

  request.log.info({ messageLength: message.length }, 'Starting streaming chat');

  try {
    for await (const event of chatService.processMessageStream(message)) {
      // Format as SSE
      reply.raw.write(`event: ${event.type}\n`);
      reply.raw.write(`data: ${JSON.stringify(event.data)}\n\n`);
    }

    reply.raw.end();
  } catch (error) {
    request.log.error({ err: error }, 'Streaming error');
    reply.raw.write(`event: error\n`);
    reply.raw.write(`data: ${JSON.stringify({ error: 'Stream failed' })}\n\n`);
    reply.raw.end();
  }
});
```

---

### 4. **Frontend Changes** (React/TypeScript)

#### SSE Client:
```typescript
async function streamChat(message: string) {
  const eventSource = new EventSource('/api/chat/stream', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message })
  });

  eventSource.addEventListener('token', (e) => {
    const token = JSON.parse(e.data);
    appendToMessage(token);
  });

  eventSource.addEventListener('thinking', (e) => {
    showThinkingIndicator();
  });

  eventSource.addEventListener('tool', (e) => {
    const toolName = JSON.parse(e.data);
    showToolIndicator(toolName);
  });

  eventSource.addEventListener('done', () => {
    eventSource.close();
    hideIndicators();
  });

  eventSource.addEventListener('error', (e) => {
    console.error('Stream error:', e);
    eventSource.close();
  });
}
```

---

## Implementation Checklist

### Backend:
- [ ] Add `chatStream()` method to OllamaService
  - [ ] Handle NDJSON parsing
  - [ ] Yield chunks as they arrive
  - [ ] Handle errors and cleanup

- [ ] Add `processMessageStream()` to ChatService
  - [ ] Stream initial LLM response
  - [ ] Emit "thinking" and "tool" events
  - [ ] Handle tool calls (may need to pause streaming)
  - [ ] Stream final response after tools

- [ ] Add `/api/chat/stream` endpoint
  - [ ] Set SSE headers
  - [ ] Format events properly
  - [ ] Handle errors and cleanup
  - [ ] Add logging

- [ ] Keep existing `/api/chat` for backwards compatibility

### Frontend (Phase 1.5):
- [ ] Create SSE client utility
- [ ] Update chat UI to append tokens
- [ ] Add "thinking" and "tool execution" indicators
- [ ] Handle reconnection and errors
- [ ] Add loading states

---

## Challenges & Considerations

### 1. **Tool Calling Complexity**
When the LLM needs to call a tool:
- Initial stream produces tool_calls (no user-visible content)
- Must execute tool (non-streaming operation)
- Resume streaming for final response

**Solution:** Emit "tool execution" events to keep user informed during non-streaming phases.

### 2. **Error Handling**
Streams can fail mid-response:
- Network interruptions
- Ollama crashes
- Tool execution errors

**Solution:**
- Emit error events on failure
- Frontend should show error and allow retry
- Log errors comprehensively

### 3. **Multiple Tool Calls**
If LLM calls multiple tools sequentially:
- Stream pauses between each tool
- Can feel janky to user

**Solution:** Show clear "Using tool X..." messages during pauses.

### 4. **Performance**
SSE can be slower than a single response for short messages.

**Solution:**
- Keep non-streaming endpoint for simple queries
- Use streaming only for complex queries or frontend preference

### 5. **Logging**
Harder to log full responses when streaming.

**Solution:**
- Buffer tokens for logging
- Log when stream completes or fails
- Track streaming metrics (time to first token, total duration)

---

## Testing Plan

1. **Unit Tests**
   - Test NDJSON parsing in OllamaService
   - Test event generation in ChatService
   - Test SSE formatting in endpoint

2. **Integration Tests**
   - Test full streaming flow end-to-end
   - Test tool calling during streams
   - Test error scenarios (network failures, Ollama crashes)

3. **Manual Testing**
   - Compare streaming vs non-streaming UX
   - Test with slow network
   - Test with multiple concurrent streams

---

## Alternative: Keep It Simple

**For MVP, streaming is optional.** Consider deferring until Phase 2 because:
- Non-streaming works fine for most queries
- Adds significant complexity
- Tool calling makes streaming harder
- Frontend not built yet anyway

**Recommendation:** Ship Phase 1.4 without streaming, revisit in Phase 2 after frontend is built and you can properly test UX improvements.

---

## Estimated Effort

- **Backend Implementation:** 4-6 hours
- **Frontend Implementation:** 3-4 hours
- **Testing & Bug Fixes:** 2-3 hours
- **Total:** ~10-13 hours

**Value vs Effort:** Medium value for significant effort. Better to focus on Phase 1.3 bugs and Phase 1.5 frontend first.
