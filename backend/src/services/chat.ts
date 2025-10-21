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
3. Describe the player's carying tools/grades (highest scouting grades on 20-80 scale) with qualitative descriptors to describe their playing style instead of raw numbers
        *EXAMPLE*
        - Instead of: 70 grade contact, 55 grade power
          Something like: He is an amazing contact hitter with some pop
        - Instead of: 60 grade contact, 60 grade power
          Something like: He was an all around hitter who could hit for contact and power
        - Instead of: 70 grade power, 70 grade power
          Something like: A player with a rare combination of power and speed
        - Instead of: 70 grade power, 20 grade power
          Something like: A fearsome slugger who clogged the bases
4. If content is provided from a tool, include it in the response as a suplementary formatted table
        *EXAMPLE*
        Seasons Stats:
        | Year | Team | AVG | OBP | SLG | wRC+ | WAR | ... |
        | 2024 | LAD | .270 | .353 | .489 | 148 | 6.2 | ... |
        | 2025 | LAD | .257 | .342 | .476 | 132 | 4.1 | ... |
5. Provide context about eras, ballparks, and league conditions when relevant
6. Be precise with numbers and avoid speculation
7. Use animated languaage

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

            // console.log(`Tool Result:\n${JSON.stringify(result)}`);
            
            messages.push({
              role: 'assistant',
              content: response.message?.content || '',
              tool_calls: response.message?.tool_calls
            });
            
            messages.push({
              role: 'tool',
              content: JSON.stringify(result)
            });

            // console.log(`Message to LLM:\n${JSON.stringify(messages, null, 2)}`);
            
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