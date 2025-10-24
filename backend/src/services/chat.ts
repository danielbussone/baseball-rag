import { OllamaService } from './ollama.js';
import { toolDefinitions, toolExecutors } from '../tools/index.js';
import { ChatMessage, ToolExecution, ChatResponse } from '../types/index.js';
import { createModuleLogger } from '../config/logger.js';

const logger = createModuleLogger('ChatService');

const prompt = 
  `You are a baseball analytics expert with access to comprehensive FanGraphs data (1988-2025) including advanced metrics and scouting grades on the 20-80 scale.

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

export interface StreamChunk {
  type: 'content' | 'tool_start' | 'tool_end' | 'done' | 'error';
  content?: string;
  toolExecution?: ToolExecution;
  error?: string;
}

export class ChatService {
  private ollama = new OllamaService();

  async processMessage(userMessage: string): Promise<ChatResponse> {
    logger.debug({ userMessage }, 'Starting message processing');
    const toolExecutions: ToolExecution[] = [];
    
    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: prompt
      },
      {
        role: 'user',
        content: userMessage
      }
    ];

    let response = await this.ollama.chat(messages, toolDefinitions);

    logger.debug({ hasToolCalls: !!response.message?.tool_calls }, 'Received initial LLM response');

    // Handle tool calls
    if (response.message?.tool_calls) {
      logger.info(
        { toolCount: response.message.tool_calls.length },
        'Processing tool calls'
      );

      for (const toolCall of response.message.tool_calls) {
        const toolName = toolCall.function.name;
        const args = toolCall.function.arguments;

        const toolExecution: ToolExecution = {
          name: toolName,
          args,
          status: 'executing'
        };
        toolExecutions.push(toolExecution);

        logger.info({ toolName, args }, 'Executing tool');

        if (toolName in toolExecutors) {
          try {
            const startTime = Date.now();
            const result = await (toolExecutors as any)[toolName](...Object.values(args));
            const duration = Date.now() - startTime;

            toolExecution.status = 'completed';
            toolExecution.duration = duration;

            logger.info(
              { toolName, duration, resultSize: JSON.stringify(result).length },
              'Tool executed successfully'
            );

            messages.push({
              role: 'assistant',
              content: response.message?.content || '',
              tool_calls: response.message?.tool_calls
            });

            messages.push({
              role: 'tool',
              content: JSON.stringify(result)
            });

            // Get final response with tool results
            logger.debug('Requesting final LLM response with tool results');
            response = await this.ollama.chat(messages);
          } catch (error) {
            toolExecution.status = 'error';
            toolExecution.error = error instanceof Error ? error.message : 'Unknown error';
            
            logger.error({ err: error, toolName, args }, 'Tool execution failed');
            return {
              response: `Error executing ${toolName}: ${error instanceof Error ? error.message : 'Unknown error'}`,
              toolExecutions
            };
          }
        } else {
          toolExecution.status = 'error';
          toolExecution.error = 'Unknown tool';
          logger.warn({ toolName, availableTools: Object.keys(toolExecutors) }, 'Unknown tool requested');
        }
      }
    }

    const finalResponse = response.message?.content || response.response || 'No response generated';
    logger.debug({ responseLength: finalResponse.length }, 'Message processing complete');

    return {
      response: finalResponse,
      toolExecutions: toolExecutions.length > 0 ? toolExecutions : undefined
    };
  }

  async *processMessageStream(userMessage: string): AsyncGenerator<StreamChunk, void, unknown> {
    logger.debug({ userMessage }, 'Starting streaming message processing');
    const toolExecutions: ToolExecution[] = [];

    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: prompt
      },
      {
        role: 'user',
        content: userMessage
      }
    ];

    try {
      let accumulatedContent = '';
      let toolCalls: any[] = [];

      // First stream: get initial response with potential tool calls
      for await (const chunk of this.ollama.chatStream(messages, toolDefinitions)) {
        if (chunk.message?.content) {
          const newContent = chunk.message.content.slice(accumulatedContent.length);
          accumulatedContent = chunk.message.content;

          if (newContent) {
            yield { type: 'content', content: newContent };
          }
        }

        // Capture tool calls whenever they appear
        if (chunk.message?.tool_calls) {
          toolCalls = chunk.message.tool_calls;
          logger.debug({ toolCount: toolCalls.length }, 'Tool calls detected in stream chunk');
        }
      }

      logger.debug({ toolCallsFound: toolCalls.length, contentLength: accumulatedContent.length }, 'Stream completed');

      // Handle tool calls if any
      if (toolCalls.length > 0) {
        logger.info({ toolCount: toolCalls.length }, 'Processing tool calls in stream');

        for (const toolCall of toolCalls) {
          const toolName = toolCall.function.name;
          const args = toolCall.function.arguments;

          const toolExecution: ToolExecution = {
            name: toolName,
            args,
            status: 'executing'
          };
          toolExecutions.push(toolExecution);

          // Notify frontend that tool is starting
          yield { type: 'tool_start', toolExecution: { ...toolExecution } };

          if (toolName in toolExecutors) {
            try {
              const startTime = Date.now();
              const result = await (toolExecutors as any)[toolName](...Object.values(args));
              const duration = Date.now() - startTime;

              toolExecution.status = 'completed';
              toolExecution.duration = duration;

              // Notify frontend that tool completed
              yield { type: 'tool_end', toolExecution: { ...toolExecution } };

              messages.push({
                role: 'assistant',
                content: accumulatedContent,
                tool_calls: toolCalls
              });

              messages.push({
                role: 'tool',
                content: JSON.stringify(result)
              });
            } catch (error) {
              toolExecution.status = 'error';
              toolExecution.error = error instanceof Error ? error.message : 'Unknown error';

              yield {
                type: 'error',
                error: `Error executing ${toolName}: ${toolExecution.error}`,
                toolExecution: { ...toolExecution }
              };
              return;
            }
          } else {
            toolExecution.status = 'error';
            toolExecution.error = 'Unknown tool';

            yield {
              type: 'error',
              error: `Unknown tool: ${toolName}`,
              toolExecution: { ...toolExecution }
            };
            return;
          }
        }

        // Stream final response with tool results
        accumulatedContent = '';
        for await (const chunk of this.ollama.chatStream(messages)) {
          if (chunk.message?.content) {
            const newContent = chunk.message.content.slice(accumulatedContent.length);
            accumulatedContent = chunk.message.content;

            if (newContent) {
              yield { type: 'content', content: newContent };
            }
          }
        }
      }

      yield { type: 'done' };
      logger.debug('Streaming message processing complete');
    } catch (error) {
      logger.error({ err: error }, 'Streaming message processing failed');
      yield {
        type: 'error',
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }
}