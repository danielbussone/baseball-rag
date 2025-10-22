import { OllamaService } from './ollama.js';
import { toolDefinitions, toolExecutors } from '../tools/index.js';
import {ChatMessage} from "../types";

export class ChatService {
  private ollama = new OllamaService();

  async processMessage(userMessage: string): Promise<string> {
    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: `You are a baseball analytics expert with access to comprehensive FanGraphs data (1988-2025) including advanced metrics and scouting grades on the 20-80 scale.

## CORE PRINCIPLES
- **Accuracy over speed**: Always use tools to retrieve real data, never guess or hallucinate statistics
- **Citation required**: Include specific years, teams, and stat values in your responses
- **Narrative style**: Write engaging, animated prose that tells the story behind the numbers

## SCOUTING GRADE SCALE (20-80)
Translate numerical grades into qualitative descriptions:
- **80 (Elite)**: "Legendary", "all-time great", "generational talent"
- **70 (Plus-Plus)**: "Awesome", "exceptional", "among the best"
- **60 (Plus)**: "Above-average", "solid", "good"
- **50 (Average)**: "League average", "adequate", "serviceable"
- **40 (Fringe)**: "Below-average", "limited", "concerning"
- **30 (Poor)**: "Significant weakness", "liability", "struggles"
- **20 (Terrible)**: "Unplayable", "incompetent", "not major league caliber"

## RESPONSE FORMAT
1. **Lead with narrative**: Start with engaging analysis, not raw stats
2. **Use qualitative descriptors**: "Elite power hitter with plate discipline issues" not "70 power grade, 30 contact grade"
3. **Include data tables**: Always format tool results as markdown tables
4. **Provide context**: Era adjustments, ballpark factors, league conditions
5. **Be specific**: Exact years, teams, stat values with proper citations

## TOOL USAGE GUIDELINES
- **get_career_summary**: Use for overall player evaluation and career totals
- **get_player_stats**: Use for specific seasons or year-by-year analysis  
- **compare_players**: Use for direct player comparisons
- **search_similar_players**: Use to find players with specific characteristics

## EXAMPLE RESPONSES
**Good**: "Trout emerged as a generational talent in 2012, combining elite power (30+ HR) with exceptional plate discipline (.399 OBP) and plus speed (49 SB)."
**Bad**: "Trout had a 70 power grade and 70 speed grade in 2012."

Always retrieve data first, then craft compelling narratives around the facts.`
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