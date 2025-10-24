export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  isLoading?: boolean;
  error?: string;
  toolExecutions?: ToolExecution[];
}

export interface ToolExecution {
  name: string;
  args: Record<string, any>;
  status: 'executing' | 'completed' | 'error';
  duration?: number;
  error?: string;
}

export interface ChatResponse {
  response: string;
  toolExecutions?: ToolExecution[];
}
