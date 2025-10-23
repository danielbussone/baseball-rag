import type { ChatMessage } from '../types';
import MessageBubble from './MessageBubble';

interface MessageListProps {
  messages: ChatMessage[];
}

export default function MessageList({ messages }: MessageListProps) {
  if (messages.length === 0) {
    return (
      <div className="flex-1 overflow-y-auto p-6 flex items-center justify-center">
        <div className="text-center text-gray-500">
          <p className="text-lg mb-2">👋 Welcome!</p>
          <p className="text-sm">Ask me about baseball players and stats</p>
          <div className="mt-4 text-xs space-y-1">
            <p>Try: "Compare Mike Trout and Ken Griffey Jr"</p>
            <p>Or: "Tell me about Mookie Betts' 2024 season"</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto p-6 space-y-4">
      {messages.map((message) => (
        <MessageBubble key={message.id} message={message} />
      ))}
    </div>
  );
}
