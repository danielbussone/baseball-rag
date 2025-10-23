import { useState, useRef, useEffect } from 'react';
import { useMutation } from '@tanstack/react-query';
import { sendChatMessage } from '../lib/api';
import type { ChatMessage } from '../types';
import MessageList from './MessageList';
import ChatInput from './ChatInput';

export default function Chat() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const mutation = useMutation({
    mutationFn: sendChatMessage,
    onMutate: async (message) => {
      // Add user message immediately
      const userMessage: ChatMessage = {
        id: Date.now().toString(),
        role: 'user',
        content: message,
        timestamp: new Date(),
      };

      // Add loading assistant message
      const loadingMessage: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: '',
        timestamp: new Date(),
        isLoading: true,
      };

      setMessages((prev) => [...prev, userMessage, loadingMessage]);
    },
    onSuccess: (data) => {
      setMessages((prev) => {
        const updated = [...prev];
        const loadingIndex = updated.findIndex((m) => m.isLoading);
        if (loadingIndex !== -1) {
          updated[loadingIndex] = {
            ...updated[loadingIndex],
            content: data.response,
            isLoading: false,
          };
        }
        return updated;
      });
    },
    onError: (error) => {
      setMessages((prev) => {
        const updated = [...prev];
        const loadingIndex = updated.findIndex((m) => m.isLoading);
        if (loadingIndex !== -1) {
          updated[loadingIndex] = {
            ...updated[loadingIndex],
            content: 'Sorry, something went wrong.',
            isLoading: false,
            error: error instanceof Error ? error.message : 'Unknown error',
          };
        }
        return updated;
      });
    },
  });

  const handleSendMessage = (message: string) => {
    if (!message.trim() || mutation.isPending) return;
    mutation.mutate(message);
  };

  const handleClearChat = () => {
    setMessages([]);
  };

  return (
    <div className="bg-white rounded-lg shadow-lg h-[calc(100vh-200px)] flex flex-col">
      <div className="flex justify-between items-center p-4 border-b">
        <h2 className="text-lg font-semibold text-gray-800">Chat</h2>
        {messages.length > 0 && (
          <button
            onClick={handleClearChat}
            className="text-sm text-gray-500 hover:text-gray-700 px-3 py-1 rounded hover:bg-gray-100"
          >
            Clear Chat
          </button>
        )}
      </div>

      <MessageList messages={messages} />
      <div ref={messagesEndRef} />

      <ChatInput
        onSendMessage={handleSendMessage}
        isLoading={mutation.isPending}
      />
    </div>
  );
}
