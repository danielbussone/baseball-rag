# Backend API Server

TypeScript/Node.js backend that orchestrates LLM interactions, database queries, and tool execution for the Baseball RAG system.

## Overview

- **Framework**: Fastify with TypeScript
- **LLM Integration**: Ollama REST API with function calling
- **Database**: PostgreSQL with connection pooling
- **Features**: Real-time streaming responses, structured logging, tool execution

## Quick Start

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your database credentials

# Development mode (with hot reload)
npm run dev

# Production mode
npm start

# Build TypeScript
npm run build
```

## API Endpoints

### POST `/api/chat/stream`
Streaming chat endpoint with real-time LLM responses.

**Request:**
```json
{
  "message": "Compare Mike Trout and Ken Griffey Jr's careers"
}
```

**Response:** Server-Sent Events stream
```
data: {"type": "content", "content": "Mike Trout and Ken Griffey Jr..."}
data: {"type": "tool_start", "tool": "compare_players", "args": {...}}
data: {"type": "tool_end", "tool": "compare_players", "duration": 234}
data: {"type": "content", "content": "Based on the data..."}
data: {"type": "done"}
```

### GET `/api/health`
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "database": "connected",
  "ollama": "available"
}
```

## LLM Tools

The system provides specialized tools that the LLM can call to retrieve baseball data:

### `search_similar_players`
Hybrid semantic + SQL search for players matching a description.

**Parameters:**
- `query` (string) - Natural language description
- `filters` (object) - Optional SQL filters
  - `position` - Position filter ("1B", "SS", "OF", etc.)
  - `minPowerGrade` / `maxPowerGrade` - Power grade range (20-80)
  - `minHitGrade` / `maxHitGrade` - Contact grade range
  - `minFieldingGrade` / `maxFieldingGrade` - Defense grade range
  - `startYear` / `endYear` - Year range
  - `limit` - Number of results (default: 10)

**Example:**
```json
{
  "query": "elite power hitter with defensive issues",
  "filters": {
    "minPowerGrade": 70,
    "maxFieldingGrade": 40,
    "startYear": 2015
  }
}
```

### `get_player_stats`
Retrieve specific season statistics for a player.

**Parameters:**
- `playerName` (string) - Player name
- `year` (number) - Season year

### `compare_players`
Side-by-side comparison of two players' careers.

**Parameters:**
- `player1` (string) - First player name
- `player2` (string) - Second player name

### `get_career_summary`
Career aggregation and highlights for a player.

**Parameters:**
- `playerName` (string) - Player name

## Architecture

### Project Structure
```
src/
├── config/          # Environment and logger configuration
├── services/        # Core business logic
│   ├── chat.ts      # LLM orchestration and streaming
│   ├── ollama.ts    # Ollama API client
│   ├── database.ts  # PostgreSQL connection pool
│   └── embedding.ts # Embedding generation service
├── tools/           # LLM tool implementations
│   ├── definitions.ts   # Tool schemas for Ollama
│   ├── search.ts       # Semantic search tool
│   ├── player-stats.ts # Player statistics tools
│   └── compare.ts      # Player comparison tool
├── types/           # TypeScript interfaces
└── index.ts         # Server entry point
```

### Key Services

**Chat Service** (`services/chat.ts`)
- Orchestrates LLM conversations with tool calling
- Handles streaming responses with Server-Sent Events
- Manages tool execution between streaming phases
- Implements dual streaming loops (pre-tools + post-tools)

**Ollama Service** (`services/ollama.ts`)
- REST API client for local Ollama instance
- Handles model selection and parameter tuning
- Processes streaming responses and tool calls
- Error handling and retry logic

**Database Service** (`services/database.ts`)
- PostgreSQL connection pooling with `pg`
- Query builders for complex baseball statistics
- Transaction management for data consistency
- Connection health monitoring

## Configuration

### Environment Variables
```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your_password

# Ollama
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=llama3.2

# Server
PORT=3001
NODE_ENV=development

# Logging
LOG_LEVEL=info
LOG_PRETTY=true  # Pretty print in development
```

### Ollama Model Requirements
- **Function calling support** - Required for tool execution
- **Recommended models**: `llama3.2`, `qwen2.5:14b`, `mistral-nemo`
- **Minimum context**: 8K tokens for complex queries
- **Temperature**: 0.1 for consistent, factual responses

## Logging

Structured JSON logging with Pino:

```typescript
// Request tracing
logger.info({ requestId, method, url, duration }, 'Request completed');

// Tool execution
logger.info({ tool: 'search_similar_players', args, duration }, 'Tool executed');

// Database queries
logger.debug({ query, params, rows }, 'Database query');

// Errors with context
logger.error({ err, requestId, tool }, 'Tool execution failed');
```

**Log Levels:**
- `debug` - Detailed execution flow, SQL queries
- `info` - Important events (requests, tool calls, startup)
- `warn` - Unexpected but handled situations
- `error` - Failures requiring attention

## Streaming Implementation

### Dual Streaming Architecture
1. **Initial Stream**: LLM generates response, identifies needed tools
2. **Tool Execution**: Execute tools, send progress events
3. **Final Stream**: LLM incorporates tool results into final response

### Event Types
```typescript
type StreamEvent = 
  | { type: 'content', content: string }
  | { type: 'tool_start', tool: string, args: any }
  | { type: 'tool_end', tool: string, duration: number, success: boolean }
  | { type: 'error', error: string }
  | { type: 'done' };
```

### Buffer Management
- **Token buffering**: 50ms intervals or 20+ characters
- **Coherent chunks**: Avoid mid-word breaks
- **Tool boundaries**: Clean separation between content and tool execution

## Performance

### Response Times
- **Simple queries**: 1-2 seconds
- **Complex queries with tools**: 3-5 seconds
- **Database queries**: 50-200ms
- **LLM generation**: 1-3 seconds (depends on model/hardware)

### Optimization
- **Connection pooling**: Reuse database connections
- **Query optimization**: Indexed searches, efficient joins
- **Streaming**: Immediate user feedback, perceived performance
- **Caching**: Tool results cached for identical queries

## Development

### Adding New Tools
1. **Define schema** in `tools/definitions.ts`
2. **Implement logic** in appropriate tool file
3. **Add to executor** in `tools/index.ts`
4. **Test with LLM** using example queries

### Testing
```bash
# Unit tests
npm test

# Integration tests with database
npm run test:integration

# Manual testing with curl
curl -X POST http://localhost:3001/api/chat/stream \
  -H "Content-Type: application/json" \
  -d '{"message": "Tell me about Mike Trout"}'
```

### Debugging
```bash
# Enable debug logging
LOG_LEVEL=debug npm run dev

# Test specific tools
node -e "require('./dist/tools/search.js').searchSimilarPlayers('power hitter')"

# Database connection test
node -e "require('./dist/services/database.js').testConnection()"
```

## Troubleshooting

### Common Issues

**Ollama Connection Failed**
```
Error: connect ECONNREFUSED 127.0.0.1:11434
```
- Ensure Ollama is running: `ollama serve`
- Check model is available: `ollama list`
- Verify OLLAMA_HOST in .env

**Database Connection Error**
```
Error: password authentication failed
```
- Check DB_PASSWORD in .env
- Verify PostgreSQL is running: `docker ps`
- Test connection: `psql -h localhost -U postgres`

**Tool Execution Timeout**
```
Warning: Tool execution took longer than expected
```
- Check database query performance
- Verify embedding service is responsive
- Consider increasing timeout limits

**Streaming Issues**
```
Error: Cannot set headers after they are sent
```
- Ensure proper error handling in streaming loops
- Check for multiple response writes
- Verify client connection handling

### Performance Issues

**Slow Database Queries**
- Check query execution plans: `EXPLAIN ANALYZE`
- Verify indexes are being used
- Consider query optimization or caching

**High Memory Usage**
- Monitor connection pool size
- Check for memory leaks in streaming
- Consider garbage collection tuning

**LLM Response Quality**
- Adjust temperature and top_p parameters
- Improve system prompts and examples
- Consider different model selection

## Future Enhancements

- **Caching layer** - Redis for tool results and embeddings
- **Rate limiting** - Protect against abuse
- **Authentication** - User management and API keys
- **Metrics** - Prometheus/Grafana monitoring
- **WebSocket support** - Alternative to Server-Sent Events
- **Batch processing** - Handle multiple queries efficiently