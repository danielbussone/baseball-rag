import { OllamaService } from './ollama.js';
import { toolDefinitions, toolExecutors } from '../tools/index.js';

export class ChatService {
  private ollama = new OllamaService();

  async processMessage(userMessage: string): Promise<string> {
    const messages = [
      {
        role: 'system',
        content: `You are a baseball analytics expert. You have access to comprehensive baseball statistics from FanGraphs (1988-2025) including advanced metrics and scouting grades (20-80 scale).

When answering questions:
1. Use the provided tools to retrieve accurate data
2. Cite specific statistics and years
3. Explain grades on the 20-80 scouting scale (50=average, 60=above average, 70=well above average, 80=elite)
4. Provide context about eras, ballparks, and league conditions when relevant
5. Be precise with numbers and avoid speculation

Available tools: search_similar_players, get_player_stats, get_career_summary, compare_players`
      },
      {
        role: 'user',
        content: userMessage
      }
    ];

    let response = await this.ollama.chat(messages, toolDefinitions);

    console.log('Initial response:', JSON.stringify(response, null, 2));
    
    // Handle tool calls
    if (response.message?.tool_calls) {
      console.log('Tool calls:', JSON.stringify(response.message.tool_calls, null, 2));
      for (const toolCall of response.message.tool_calls) {
        console.log('Processing tool call:', toolCall);
        const toolName = toolCall.function.name;
        const args = toolCall.function.arguments;
        
        if (toolName in toolExecutors) {
          try {
            const result = await (toolExecutors as any)[toolName](...Object.values(args));
            
            messages.push({
              role: 'assistant',
              content: response.message.content || '',
              tool_calls: response.message.tool_calls
            });
            
            messages.push({
              role: 'tool',
              content: JSON.stringify(result)
            });
            
            // Get final response with tool results
            response = await this.ollama.chat(messages);
          } catch (error) {
            console.error(`Tool execution error for ${toolName}:`, error);
            return `Error executing ${toolName}: ${error instanceof Error ? error.message : 'Unknown error'}`;
          }
        }
      }
    }

    return response.message?.content || response.response || 'No response generated';
  }
}