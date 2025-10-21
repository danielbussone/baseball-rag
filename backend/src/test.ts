import { ChatService } from './services/chat.js';

const chatService = new ChatService();

async function test() {
  console.log('🧪 Testing Baseball RAG Backend...\n');
  
  const testQueries = [
    "Tell me about Mike Trout's 2019 season",
    "Compare Mike Trout and Ken Griffey Jr",
    "Find elite power hitters from 2015-2020"
  ];
  
  for (const query of testQueries) {
    console.log(`❓ Query: ${query}`);
    try {
      const response = await chatService.processMessage(query);
      console.log(`✅ Response: ${response.substring(0, 200)}...\n`);
    } catch (error) {
      console.error(`❌ Error: ${error}\n`);
    }
  }
}

test().catch(console.error);