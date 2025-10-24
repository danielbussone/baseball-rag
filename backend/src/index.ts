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

// Chat endpoint
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