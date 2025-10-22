import Fastify from 'fastify';
import { ChatService } from './services/chat.js';
import { env } from './config/env.js';

const fastify = Fastify({ logger: true });
const chatService = new ChatService();

// CORS for frontend
fastify.register(import('@fastify/cors'), {
  origin: true
});

// Chat endpoint
fastify.post('/api/chat', async (request, reply) => {
  const { message } = request.body as { message: string };
  
  if (!message) {
    return reply.code(400).send({ error: 'Message is required' });
  }

  try {
    const response = await chatService.processMessage(message);
    return { response };
  } catch (error) {
    console.error('Chat error:', error);
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
    console.log(`🚀 Baseball RAG Backend running on http://localhost:${env.server.port}`);
    console.log(`📊 Environment: ${env.server.nodeEnv}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();