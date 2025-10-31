# Conversation Memory Implementation - TODO List

**Project:** Baseball RAG Agent  
**Feature:** Multi-turn Conversation Support  
**Created:** October 25, 2025  
**Status:** Planning Phase

---

## Overview

This document outlines the implementation tasks for adding conversation memory to the Baseball RAG Agent. The work is split into two phases:

- **Phase 1.3:** Stateless conversation memory (MVP) - ~8 hours
- **Phase 1.4:** Database-backed persistence - ~16 hours

---

## Phase 1.3: Stateless Conversation Memory (MVP)

**Goal:** Enable multi-turn conversations within a single session using browser-based state management.

**Time Estimate:** 8 hours  
**Dependencies:** Phase 1.3 LLM Integration must be started (Ollama setup)

### Frontend Tasks (React)

#### 1. Message State Management (~2 hours)

- [ ] **Create message type definitions**
  ```typescript
  interface Message {
    id: string;
    role: 'user' | 'assistant' | 'tool';
    content: string;
    timestamp: Date;
    toolCalls?: ToolCall[];
    toolResults?: ToolResult[];
  }
  
  interface ToolCall {
    id: string;
    name: string;
    arguments: Record<string, any>;
  }
  
  interface ToolResult {
    toolCallId: string;
    result: any;
    error?: string;
  }
  ```

- [ ] **Add conversation state to main Chat component**
  ```typescript
  const [messages, setMessages] = useState<Message[]>([]);
  const [isStreaming, setIsStreaming] = useState(false);
  ```

- [ ] **Implement message append logic**
  - Add user messages to state
  - Add assistant responses to state
  - Add tool call/result messages to state
  - Assign unique IDs (uuid or nanoid)

- [ ] **Add localStorage persistence**
  ```typescript
  // Save on every message update
  useEffect(() => {
    localStorage.setItem('currentConversation', JSON.stringify(messages));
  }, [messages]);
  
  // Load on mount
  useEffect(() => {
    const saved = localStorage.getItem('currentConversation');
    if (saved) {
      setMessages(JSON.parse(saved));
    }
  }, []);
  ```

- [ ] **Add "Clear Conversation" button**
  - Clear messages state
  - Clear localStorage
  - Reset to empty conversation

#### 2. Chat UI Updates (~2 hours)

- [ ] **Display message history in chat window**
  - Map over messages array
  - Render user messages (right-aligned, blue bubble)
  - Render assistant messages (left-aligned, gray bubble)
  - Render tool calls (collapsed by default, expandable)

- [ ] **Add message timestamps**
  - Display relative time ("2 minutes ago")
  - Use library like `date-fns` for formatting

- [ ] **Add scroll-to-bottom behavior**
  - Auto-scroll on new message
  - Smooth scrolling animation
  - "Scroll to bottom" button if user scrolled up

- [ ] **Show typing indicator while streaming**
  - Animated dots or spinner
  - "Thinking..." or "Analyzing stats..." text

- [ ] **Add message loading states**
  - Skeleton loader for assistant response
  - Loading spinner for tool calls

#### 3. API Integration (~2 hours)

- [ ] **Update chat submission handler**
  ```typescript
  const handleSubmit = async (userInput: string) => {
    // Add user message to state
    const userMessage: Message = {
      id: nanoid(),
      role: 'user',
      content: userInput,
      timestamp: new Date()
    };
    setMessages(prev => [...prev, userMessage]);
    
    // Call API with full message history
    setIsStreaming(true);
    const response = await fetch('/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        messages: [...messages, userMessage]
      })
    });
    
    // Handle streaming response...
  };
  ```

- [ ] **Implement streaming response handling**
  - Use Server-Sent Events (SSE) or WebSocket
  - Append chunks to assistant message as they arrive
  - Handle tool call streaming
  - Handle final message completion

- [ ] **Add error handling**
  - Network errors (show retry button)
  - Timeout errors (configurable timeout, e.g., 60s)
  - API errors (display error message in chat)
  - Graceful fallback if streaming fails

### Backend Tasks (TypeScript/Node.js)

#### 4. Conversation Context Handling (~2 hours)

- [ ] **Create `/api/chat` endpoint**
  ```typescript
  app.post('/api/chat', async (req, res) => {
    const { messages } = req.body;
    
    // Validate messages array
    if (!Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: 'Invalid messages' });
    }
    
    // Process conversation...
  });
  ```

- [ ] **Format messages for Ollama**
  ```typescript
  function formatMessagesForOllama(messages: Message[]) {
    return messages.map(msg => {
      if (msg.role === 'tool') {
        // Format tool results for Ollama
        return {
          role: 'tool',
          content: JSON.stringify(msg.toolResults)
        };
      }
      return {
        role: msg.role,
        content: msg.content
      };
    });
  }
  ```

- [ ] **Implement context window truncation**
  ```typescript
  function truncateContext(messages: Message[], maxTokens: number = 6000) {
    // Estimate tokens (~4 chars per token)
    let totalTokens = 0;
    const truncated: Message[] = [];
    
    // Always keep system prompt (if exists)
    // Then add messages from most recent backwards
    for (let i = messages.length - 1; i >= 0; i--) {
      const estimatedTokens = messages[i].content.length / 4;
      if (totalTokens + estimatedTokens > maxTokens) {
        break;
      }
      truncated.unshift(messages[i]);
      totalTokens += estimatedTokens;
    }
    
    return truncated;
  }
  ```

- [ ] **Add token counting helper**
  - Use simple heuristic (4 chars/token) for MVP
  - Consider adding proper tokenizer library later (e.g., `tiktoken`)

- [ ] **Handle tool calls in conversation flow**
  - When LLM requests tool call, add to messages
  - Execute tool, add result to messages
  - Continue conversation with tool context

#### 5. Streaming Response Implementation (~2 hours)

- [ ] **Set up Server-Sent Events (SSE)**
  ```typescript
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  ```

- [ ] **Stream Ollama responses**
  ```typescript
  const ollamaResponse = await ollama.chat({
    model: 'llama3.1:8b',
    messages: formattedMessages,
    tools: tools,
    stream: true
  });
  
  for await (const chunk of ollamaResponse) {
    res.write(`data: ${JSON.stringify(chunk)}\n\n`);
  }
  
  res.write('data: [DONE]\n\n');
  res.end();
  ```

- [ ] **Handle tool call streaming**
  - Detect when LLM requests tool call
  - Execute tool
  - Stream tool result back to client
  - Continue streaming LLM response

- [ ] **Add error handling for streams**
  - Connection drops
  - Ollama errors
  - Tool execution failures

---

## Phase 1.4: Database-Backed Persistence

**Goal:** Persist conversations to PostgreSQL, enable cross-session continuity, and add conversation management features.

**Time Estimate:** 16 hours  
**Dependencies:** Phase 1.3 complete, PostgreSQL running

### Database Tasks

#### 6. Schema Design & Migration (~2 hours)

- [ ] **Create database migration file**
  - Use migration tool (e.g., `node-pg-migrate`, `kysely`, or raw SQL)
  - Version: `002_add_conversations.sql`

- [ ] **Define `conversations` table**
  ```sql
  CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(255), -- Future: for multi-user support
    title VARCHAR(255),
    summary TEXT, -- Auto-generated from first exchange
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB -- e.g., {"topic": "player_comparison", "players": ["Mike Trout"]}
  );
  
  CREATE INDEX idx_conversations_user ON conversations(user_id);
  CREATE INDEX idx_conversations_created ON conversations(created_at DESC);
  CREATE INDEX idx_conversations_metadata ON conversations USING gin(metadata);
  ```

- [ ] **Define `conversation_messages` table**
  ```sql
  CREATE TABLE conversation_messages (
    id SERIAL PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'tool', 'system')),
    content TEXT,
    tool_calls JSONB, -- Store tool invocations
    tool_results JSONB, -- Store tool responses
    metadata JSONB, -- Additional context (e.g., token count, model used)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  
  CREATE INDEX idx_messages_conversation ON conversation_messages(conversation_id, created_at);
  CREATE INDEX idx_messages_created ON conversation_messages(created_at DESC);
  ```

- [ ] **Add trigger for `updated_at`**
  ```sql
  CREATE OR REPLACE FUNCTION update_conversation_timestamp()
  RETURNS TRIGGER AS $$
  BEGIN
    UPDATE conversations 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.conversation_id;
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;
  
  CREATE TRIGGER update_conversation_on_message
  AFTER INSERT ON conversation_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_timestamp();
  ```

- [ ] **Run migration**
  ```bash
  npm run migrate:up
  # Or: psql -h localhost -U postgres -d postgres -f migrations/002_add_conversations.sql
  ```

#### 7. Database Access Layer (~3 hours)

- [ ] **Create `ConversationRepository` class/module**
  ```typescript
  class ConversationRepository {
    constructor(private db: Pool) {}
    
    async create(userId?: string): Promise<Conversation>;
    async getById(id: string): Promise<Conversation | null>;
    async listByUser(userId: string, limit?: number): Promise<Conversation[]>;
    async delete(id: string): Promise<void>;
    async updateTitle(id: string, title: string): Promise<void>;
    async updateSummary(id: string, summary: string): Promise<void>;
  }
  ```

- [ ] **Create `MessageRepository` class/module**
  ```typescript
  class MessageRepository {
    constructor(private db: Pool) {}
    
    async create(message: NewMessage): Promise<Message>;
    async listByConversation(
      conversationId: string, 
      options?: { limit?: number; offset?: number }
    ): Promise<Message[]>;
    async getLastN(conversationId: string, n: number): Promise<Message[]>;
    async getFirstUserMessage(conversationId: string): Promise<Message | null>;
    async getMessagesWithToolCalls(conversationId: string): Promise<Message[]>;
  }
  ```

- [ ] **Add TypeScript types**
  ```typescript
  interface Conversation {
    id: string;
    userId?: string;
    title: string;
    summary?: string;
    createdAt: Date;
    updatedAt: Date;
    metadata?: Record<string, any>;
  }
  
  interface Message {
    id: number;
    conversationId: string;
    role: 'user' | 'assistant' | 'tool' | 'system';
    content: string;
    toolCalls?: ToolCall[];
    toolResults?: ToolResult[];
    metadata?: Record<string, any>;
    createdAt: Date;
  }
  ```

- [ ] **Implement repository methods with proper error handling**
  - Try/catch blocks
  - Log errors
  - Return meaningful error messages

- [ ] **Add database connection pooling**
  ```typescript
  import { Pool } from 'pg';
  
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'postgres',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
    max: 20, // Maximum pool size
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  });
  ```

### Backend API Tasks

#### 8. Conversation Management Endpoints (~4 hours)

- [ ] **POST `/api/conversations` - Create new conversation**
  ```typescript
  app.post('/api/conversations', async (req, res) => {
    const { userId } = req.body; // Optional for now
    const conversation = await conversationRepo.create(userId);
    res.json(conversation);
  });
  ```

- [ ] **GET `/api/conversations/:id` - Get conversation with messages**
  ```typescript
  app.get('/api/conversations/:id', async (req, res) => {
    const { id } = req.params;
    const conversation = await conversationRepo.getById(id);
    
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }
    
    const messages = await messageRepo.listByConversation(id);
    res.json({ ...conversation, messages });
  });
  ```

- [ ] **GET `/api/conversations` - List user's conversations**
  ```typescript
  app.get('/api/conversations', async (req, res) => {
    const { userId, limit = 50 } = req.query;
    const conversations = await conversationRepo.listByUser(
      userId as string,
      parseInt(limit as string)
    );
    res.json(conversations);
  });
  ```

- [ ] **DELETE `/api/conversations/:id` - Delete conversation**
  ```typescript
  app.delete('/api/conversations/:id', async (req, res) => {
    const { id } = req.params;
    await conversationRepo.delete(id);
    res.json({ success: true });
  });
  ```

- [ ] **PATCH `/api/conversations/:id` - Update title/summary**
  ```typescript
  app.patch('/api/conversations/:id', async (req, res) => {
    const { id } = req.params;
    const { title, summary } = req.body;
    
    if (title) await conversationRepo.updateTitle(id, title);
    if (summary) await conversationRepo.updateSummary(id, summary);
    
    const updated = await conversationRepo.getById(id);
    res.json(updated);
  });
  ```

- [ ] **Add input validation**
  - Validate UUIDs
  - Validate string lengths
  - Sanitize inputs

- [ ] **Add rate limiting**
  - Prevent abuse (e.g., max 100 conversations per user)
  - Use library like `express-rate-limit`

#### 9. Update Chat Endpoint for Persistence (~3 hours)

- [ ] **Modify POST `/api/chat` to handle conversation IDs**
  ```typescript
  app.post('/api/chat', async (req, res) => {
    const { messages, conversationId } = req.body;
    
    let convId = conversationId;
    
    // Create new conversation if not provided
    if (!convId) {
      const conversation = await conversationRepo.create();
      convId = conversation.id;
    }
    
    // ... rest of chat logic
  });
  ```

- [ ] **Save user message to database**
  ```typescript
  const userMessage = await messageRepo.create({
    conversationId: convId,
    role: 'user',
    content: userInput,
    metadata: { source: 'chat_ui' }
  });
  ```

- [ ] **Save assistant response to database**
  ```typescript
  // After streaming completes
  const assistantMessage = await messageRepo.create({
    conversationId: convId,
    role: 'assistant',
    content: fullResponse,
    toolCalls: toolCallsMade, // If any
    metadata: { 
      model: 'llama3.1:8b',
      tokenCount: estimatedTokens 
    }
  });
  ```

- [ ] **Save tool call messages to database**
  ```typescript
  if (toolCalls.length > 0) {
    await messageRepo.create({
      conversationId: convId,
      role: 'tool',
      content: null,
      toolResults: toolResults,
      metadata: { toolNames: toolCalls.map(t => t.name) }
    });
  }
  ```

- [ ] **Return conversation ID in response**
  ```typescript
  res.json({
    conversationId: convId,
    message: assistantMessage
  });
  ```

#### 10. Smart Context Loading (~4 hours)

- [ ] **Implement context loading strategy**
  ```typescript
  async function loadSmartContext(
    conversationId: string,
    maxTokens: number = 6000
  ): Promise<Message[]> {
    // 1. Get last 5 messages (recent context)
    const recent = await messageRepo.getLastN(conversationId, 5);
    
    // 2. Get first user message (topic setter)
    const firstMessage = await messageRepo.getFirstUserMessage(conversationId);
    
    // 3. Get important tool call messages
    const pivotalMessages = await messageRepo.getMessagesWithToolCalls(conversationId);
    
    // 4. Check if we're within token budget
    const combinedMessages = [
      firstMessage,
      ...pivotalMessages,
      ...recent
    ].filter(Boolean);
    
    const estimatedTokens = estimateTokenCount(combinedMessages);
    
    if (estimatedTokens <= maxTokens) {
      return combinedMessages;
    }
    
    // 5. If over budget, summarize middle messages
    const summary = await summarizeMiddleMessages(conversationId, {
      exclude: [...recent.map(m => m.id), firstMessage?.id, ...pivotalMessages.map(m => m.id)]
    });
    
    return [
      { role: 'system', content: `Conversation context: ${summary}` },
      firstMessage,
      ...recent
    ].filter(Boolean);
  }
  ```

- [ ] **Implement token estimation**
  ```typescript
  function estimateTokenCount(messages: Message[]): number {
    return messages.reduce((total, msg) => {
      return total + (msg.content?.length || 0) / 4; // ~4 chars per token
    }, 0);
  }
  ```

- [ ] **Implement message summarization**
  ```typescript
  async function summarizeMiddleMessages(
    conversationId: string,
    options: { exclude: number[] }
  ): Promise<string> {
    const messages = await messageRepo.listByConversation(conversationId);
    
    const toSummarize = messages.filter(m => !options.exclude.includes(m.id));
    
    // Option 1: Simple concatenation (MVP)
    const summary = toSummarize
      .map(m => `${m.role}: ${m.content?.substring(0, 100)}...`)
      .join('\n');
    
    // Option 2: Use LLM to summarize (future enhancement)
    // const summary = await ollama.generate({
    //   model: 'llama3.1:8b',
    //   prompt: `Summarize this conversation in 2-3 sentences: ${messagesText}`
    // });
    
    return summary;
  }
  ```

- [ ] **Add caching for context loading**
  ```typescript
  const contextCache = new Map<string, { messages: Message[], timestamp: number }>();
  
  function getCachedContext(conversationId: string, maxAge: number = 60000) {
    const cached = contextCache.get(conversationId);
    if (cached && Date.now() - cached.timestamp < maxAge) {
      return cached.messages;
    }
    return null;
  }
  ```

- [ ] **Handle edge cases**
  - Empty conversation (no messages yet)
  - Very first message (no context to load)
  - Conversation with only tool calls (no user messages)

### Frontend Tasks (Persistence UI)

#### 11. Conversation List Sidebar (~3 hours)

- [ ] **Create `<ConversationList>` component**
  ```typescript
  interface ConversationListProps {
    conversations: Conversation[];
    activeConversationId?: string;
    onSelectConversation: (id: string) => void;
    onDeleteConversation: (id: string) => void;
    onNewConversation: () => void;
  }
  ```

- [ ] **Fetch conversations on mount**
  ```typescript
  useEffect(() => {
    async function loadConversations() {
      const response = await fetch('/api/conversations');
      const conversations = await response.json();
      setConversations(conversations);
    }
    loadConversations();
  }, []);
  ```

- [ ] **Render conversation items**
  - Title (truncated if long)
  - Last updated timestamp (relative)
  - Preview of last message (first 50 chars)
  - Delete button (with confirmation)

- [ ] **Add "New Chat" button**
  - Create new conversation via API
  - Switch to new conversation
  - Clear current messages

- [ ] **Add conversation selection**
  - Click to load conversation
  - Highlight active conversation
  - Fetch messages for selected conversation

- [ ] **Add conversation deletion**
  ```typescript
  const handleDelete = async (id: string) => {
    if (confirm('Delete this conversation?')) {
      await fetch(`/api/conversations/${id}`, { method: 'DELETE' });
      setConversations(prev => prev.filter(c => c.id !== id));
      if (activeConversationId === id) {
        // Switch to new conversation
        handleNewConversation();
      }
    }
  };
  ```

- [ ] **Add loading states**
  - Skeleton loaders while fetching conversations
  - Loading spinner while creating new conversation

- [ ] **Add empty state**
  - "No conversations yet" message
  - "Start a new chat" CTA

#### 12. Auto-Save & Title Generation (~2 hours)

- [ ] **Implement auto-save on every message**
  ```typescript
  const handleSubmit = async (userInput: string) => {
    // If no active conversation, create one
    if (!conversationId) {
      const response = await fetch('/api/conversations', { method: 'POST' });
      const { id } = await response.json();
      setConversationId(id);
    }
    
    // Send message with conversation ID
    await fetch('/api/chat', {
      method: 'POST',
      body: JSON.stringify({
        messages: [...messages, userMessage],
        conversationId
      })
    });
  };
  ```

- [ ] **Generate conversation title from first exchange**
  ```typescript
  async function generateTitle(conversationId: string, firstMessage: string) {
    // Option 1: Simple extraction (MVP)
    const title = firstMessage.substring(0, 50) + (firstMessage.length > 50 ? '...' : '');
    
    // Option 2: LLM-generated title (future)
    // const title = await ollama.generate({
    //   prompt: `Create a 5-word title for this question: "${firstMessage}"`
    // });
    
    await fetch(`/api/conversations/${conversationId}`, {
      method: 'PATCH',
      body: JSON.stringify({ title })
    });
  }
  ```

- [ ] **Update conversation title after first exchange**
  ```typescript
  useEffect(() => {
    if (messages.length === 2 && conversationId) {
      // First user message + first assistant response
      const firstUserMessage = messages.find(m => m.role === 'user');
      if (firstUserMessage) {
        generateTitle(conversationId, firstUserMessage.content);
      }
    }
  }, [messages, conversationId]);
  ```

- [ ] **Add manual title editing**
  - Double-click conversation title to edit
  - Save on blur or Enter key
  - Update via PATCH endpoint

---

## Testing Checklist

### Phase 1.3 Testing

- [ ] **Single-turn conversation**
  - User asks question
  - Agent responds
  - Message appears in UI

- [ ] **Multi-turn conversation**
  - User asks follow-up question
  - Agent uses previous context
  - "Compare Trout and Griffey" → "What about their defense?"

- [ ] **Tool call in conversation**
  - Tool call message appears
  - Results are used in subsequent responses
  - Tool results visible when expanded

- [ ] **Context window truncation**
  - Conversation with 20+ messages
  - Verify oldest messages are dropped
  - Recent context preserved

- [ ] **Browser refresh**
  - Conversation persists via localStorage
  - Messages reload correctly
  - Can continue conversation

- [ ] **Clear conversation**
  - Button clears all messages
  - localStorage cleared
  - Fresh start

- [ ] **Error handling**
  - Network error displays message
  - Timeout shows retry button
  - Malformed response handled gracefully

### Phase 1.4 Testing

- [ ] **Conversation creation**
  - New conversation created via API
  - ID returned and stored
  - Appears in sidebar

- [ ] **Message persistence**
  - User message saved to DB
  - Assistant message saved to DB
  - Tool calls saved to DB

- [ ] **Conversation loading**
  - Click conversation in sidebar
  - Messages load from DB
  - Displayed in correct order

- [ ] **Cross-session continuity**
  - Close browser
  - Reopen
  - Conversations still listed
  - Can resume any conversation

- [ ] **Smart context loading**
  - Long conversation (30+ messages)
  - Verify first message included
  - Verify tool calls included
  - Verify recent messages included
  - Verify fits in token budget

- [ ] **Conversation deletion**
  - Delete button works
  - Confirmation prompt appears
  - Conversation removed from DB
  - Messages cascade deleted

- [ ] **Title generation**
  - First message generates title
  - Title appears in sidebar
  - Manual edit works

- [ ] **Multiple conversations**
  - Create 5+ conversations
  - Switch between them
  - Context doesn't leak between conversations

- [ ] **Edge cases**
  - Empty conversation
  - Conversation with only system messages
  - Very long messages (>5000 chars)
  - Special characters in messages
  - Concurrent requests

---

## Performance Considerations

### Phase 1.3

- [ ] **Optimize re-renders**
  - Use `React.memo()` for message components
  - Avoid unnecessary state updates

- [ ] **Throttle localStorage writes**
  - Don't write on every character typed
  - Write on message send only

- [ ] **Lazy load message history**
  - Don't render all messages at once if 100+
  - Virtual scrolling for very long conversations

### Phase 1.4

- [ ] **Database query optimization**
  - Use indexes on conversation_id, created_at
  - LIMIT queries to prevent full table scans
  - Connection pooling configured

- [ ] **Cache frequently accessed data**
  - Cache conversation list (60s TTL)
  - Cache loaded messages (30s TTL)
  - Invalidate on new messages

- [ ] **Batch message inserts**
  - If saving multiple messages (user + tool + assistant)
  - Use single transaction
  - Reduces DB round trips

- [ ] **Monitor DB size**
  - Track total messages stored
  - Add cleanup job for old conversations (future)
  - Consider archiving strategy if >100k messages

---

## Future Enhancements (Post-Phase 1.4)

### Conversation Search
- [ ] Full-text search across conversations
- [ ] Search by player names, stats, date ranges
- [ ] Filter by conversation topic/metadata

### Conversation Export
- [ ] Export as Markdown
- [ ] Export as PDF
- [ ] Export as JSON (for data portability)

### Conversation Sharing
- [ ] Generate public link to conversation
- [ ] Share via email/Slack
- [ ] Embed conversation on webpage

### Advanced Context Management
- [ ] LLM-based summarization of old messages
- [ ] Automatic topic detection
- [ ] Smart context compression (keep important, drop fluff)

### Multi-User Support
- [ ] User authentication (OAuth, email/password)
- [ ] User-specific conversation lists
- [ ] Shared conversations (team collaboration)

### Analytics
- [ ] Most common queries
- [ ] Average conversation length
- [ ] Tool usage statistics
- [ ] User engagement metrics

---

## Migration Path from Phase 1.3 → 1.4

**Goal:** Seamlessly upgrade from stateless to database-backed without breaking existing functionality.

### Step 1: Deploy DB Schema
- [ ] Run migration to create tables
- [ ] Verify tables exist and indexes created

### Step 2: Update Backend (Backward Compatible)
- [ ] Add conversation repositories
- [ ] Update `/api/chat` to accept optional `conversationId`
- [ ] If `conversationId` missing, create new conversation automatically
- [ ] Save all messages to DB
- [ ] Keep existing stateless logic working

### Step 3: Update Frontend (Feature Flag)
- [ ] Add feature flag: `ENABLE_CONVERSATION_PERSISTENCE`
- [ ] If enabled, show conversation sidebar
- [ ] If disabled, use localStorage (Phase 1.3 behavior)
- [ ] Allows gradual rollout

### Step 4: Migrate localStorage to DB (Optional)
- [ ] Detect localStorage conversation on load
- [ ] Prompt user: "Save this conversation?"
- [ ] Create conversation in DB with existing messages
- [ ] Clear localStorage
- [ ] Switch to DB mode

### Step 5: Remove Feature Flag
- [ ] After testing period
- [ ] Remove localStorage fallback code
- [ ] All new conversations go to DB

---

## Documentation Tasks

- [ ] **Update README**
  - Add conversation memory features
  - Document API endpoints
  - Add screenshots of conversation UI

- [ ] **API Documentation**
  - Document all conversation endpoints
  - Request/response examples
  - Error codes and handling

- [ ] **Database Schema Docs**
  - Document table purposes
  - Column descriptions
  - Index rationale

- [ ] **User Guide**
  - How to start a conversation
  - How to switch between conversations
  - How to delete conversations
  - How to export conversations (future)

---

## Success Criteria

### Phase 1.3 Success
✅ User can have multi-turn conversation (5+ exchanges)  
✅ Follow-up questions use previous context  
✅ Conversation survives page refresh (localStorage)  
✅ Clear conversation button works  
✅ Tool calls appear in conversation history  

### Phase 1.4 Success
✅ Conversations persist across browser sessions  
✅ Conversation list sidebar shows all conversations  
✅ User can switch between conversations  
✅ User can delete conversations  
✅ Conversation titles auto-generate  
✅ Smart context loading fits within token budget  
✅ Database queries perform well (<100ms for loads)  

---

## Time Tracking Template

| Task | Estimated | Actual | Notes |
|------|-----------|--------|-------|
| Phase 1.3: Message state | 2h | | |
| Phase 1.3: Chat UI | 2h | | |
| Phase 1.3: API integration | 2h | | |
| Phase 1.3: Context handling | 2h | | |
| **Phase 1.3 Total** | **8h** | | |
| Phase 1.4: Schema design | 2h | | |
| Phase 1.4: DB access layer | 3h | | |
| Phase 1.4: API endpoints | 4h | | |
| Phase 1.4: Chat persistence | 3h | | |
| Phase 1.4: Smart context | 4h | | |
| Phase 1.4: Conversation UI | 3h | | |
| Phase 1.4: Auto-save | 2h | | |
| **Phase 1.4 Total** | **16h** | | |
| **Grand Total** | **24h** | | |

---

## Questions to Resolve

- [ ] Which model to use for conversation summarization? (Same as main model or smaller/faster?)
- [ ] Should conversation titles be editable by users?
- [ ] Max conversation history to keep in DB? (Delete after 90 days? Archive?)
- [ ] Should we support conversation forking? (Branch from any message)
- [ ] Implement conversation search in Phase 1.4 or defer to Phase 2?
- [ ] User authentication needed before Phase 1.4 or use anonymous mode?

---

**Next Steps:**
1. Review this TODO list
2. Confirm Phase 1.3 scope (stateless MVP)
3. Begin implementation with frontend message state
4. Test with multi-turn baseball queries
5. Decide when to proceed to Phase 1.4

---

**Status Legend:**
- [ ] Not started
- [x] Complete
- [~] In progress
- [!] Blocked
