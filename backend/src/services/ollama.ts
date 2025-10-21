interface OllamaResponse {
  model: string;
  response?: string;
  done: boolean;
  message?: {
    role: string;
    content: string;
    tool_calls?: Array<{
      type: string;
      function: {
        name: string;
        arguments: Record<string, any>;
      };
    }>;
  };
}

export class OllamaService {
  private baseUrl = 'http://localhost:11434';

  async chat(messages: any[], tools?: any[]): Promise<OllamaResponse> {
    const response = await fetch(`${this.baseUrl}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'llama3.1:8b',
        messages,
        tools,
        stream: false
      })
    });

    if (!response.ok) {
      throw new Error(`Ollama API error: ${response.statusText}`);
    }

    return response.json();
  }
}