import Fastify from 'fastify';
import { ChatService } from './services/chat.js';

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
    await fastify.listen({ port: 3001, host: '0.0.0.0' });
    console.log('🚀 Baseball RAG Backend running on http://localhost:3001');
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();