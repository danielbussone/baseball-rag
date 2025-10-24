import Fastify from 'fastify';
import { ChatService } from './services/chat.js';
import { env } from './config/env.js';
import { logger, loggerConfig } from './config/logger.js';

// Initialize Fastify with centralized logger config
const fastify = Fastify({
  logger: loggerConfig,
  // Generate request IDs for tracing
  requestIdLogLabel: 'reqId',
  requestIdHeader: 'x-request-id',
});

const chatService = new ChatService();

// CORS for frontend
fastify.register(import('@fastify/cors'), {
  origin: true
});

// Chat endpoint (non-streaming)
fastify.post('/api/chat', async (request, reply) => {
  const { message } = request.body as { message: string };

  if (!message) {
    request.log.warn({ body: request.body }, 'Chat request missing message field');
    return reply.code(400).send({ error: 'Message is required' });
  }

  request.log.info({ messageLength: message.length }, 'Processing chat message');

  try {
    const startTime = Date.now();
    const result = await chatService.processMessage(message);
    const duration = Date.now() - startTime;

    request.log.info(
      { duration, responseLength: result.response.length, toolCount: result.toolExecutions?.length || 0 },
      'Chat message processed successfully'
    );

    return result;
  } catch (error) {
    request.log.error({ err: error, message }, 'Error processing chat message');

    return reply.code(500).send({
      error: 'Internal server error',
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Chat endpoint (streaming with SSE)
fastify.post('/api/chat/stream', async (request, reply) => {
  const { message } = request.body as { message: string };

  if (!message) {
    request.log.warn({ body: request.body }, 'Chat stream request missing message field');
    return reply.code(400).send({ error: 'Message is required' });
  }

  request.log.info({ messageLength: message.length }, 'Processing streaming chat message');

  // Set SSE headers
  reply.raw.setHeader('Content-Type', 'text/event-stream');
  reply.raw.setHeader('Cache-Control', 'no-cache');
  reply.raw.setHeader('Connection', 'keep-alive');

  // Set CORS headers for streaming endpoint
  reply.raw.setHeader('Access-Control-Allow-Origin', '*');
  reply.raw.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  reply.raw.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  try {
    const startTime = Date.now();
    let chunkCount = 0;

    for await (const chunk of chatService.processMessageStream(message)) {
      chunkCount++;
      // Send SSE formatted data
      reply.raw.write(`data: ${JSON.stringify(chunk)}\n\n`);
    }

    const duration = Date.now() - startTime;
    request.log.info(
      { duration, chunkCount },
      'Streaming chat message processed successfully'
    );

    reply.raw.end();
  } catch (error) {
    request.log.error({ err: error, message }, 'Error processing streaming chat message');

    const errorChunk = {
      type: 'error',
      error: error instanceof Error ? error.message : 'Unknown error'
    };

    reply.raw.write(`data: ${JSON.stringify(errorChunk)}\n\n`);
    reply.raw.end();
  }
});

// Health check
fastify.get('/api/health', async () => {
  return { status: 'ok', timestamp: new Date().toISOString() };
});

const start = async () => {
  try {
    await fastify.listen({ port: env.server.port, host: env.server.host });

    logger.info(
      {
        port: env.server.port,
        host: env.server.host,
        nodeEnv: env.server.nodeEnv,
        ollamaUrl: env.ollama.baseUrl,
        ollamaModel: env.ollama.model,
      },
      '🚀 Baseball RAG Backend started successfully'
    );
  } catch (err) {
    logger.error({ err }, 'Failed to start server');
    process.exit(1);
  }
};

// Graceful shutdown
const shutdown = async (signal: string) => {
  logger.info({ signal }, 'Received shutdown signal, closing server gracefully');

  try {
    await fastify.close();
    logger.info('Server closed successfully');
    process.exit(0);
  } catch (err) {
    logger.error({ err }, 'Error during shutdown');
    process.exit(1);
  }
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

start();