import { useState, useRef, useEffect } from 'react';
import { useMutation } from '@tanstack/react-query';
import { Box, Paper, Typography, IconButton } from '@mui/material';
import SportsBaseballIcon from '@mui/icons-material/SportsBaseball';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import { sendChatMessage } from '../lib/api';
import type { ChatMessage } from '../types';
import MessageList from './MessageList';
import ChatInput from './ChatInput';

/**
 * Main chat container component
 * Manages chat state, message sending, and scrolling behavior
 */
export default function Chat() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  /**
   * Scrolls the chat to the bottom when new messages arrive
   */
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

  /**
   * Handles sending a new message
   * @param message - The message text to send
   */
  const handleSendMessage = (message: string) => {
    if (!message.trim() || mutation.isPending) return;
    mutation.mutate(message);
  };

  /**
   * Clears all messages from the chat
   */
  const handleClearChat = () => {
    setMessages([]);
  };

  return (
    <Box
      sx={{
        maxWidth: 1200,
        width: '100%',
        mx: 'auto',
        height: { xs: 'calc(100vh - 16px)', sm: 'calc(100vh - 32px)', md: 'calc(100vh - 48px)' },
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      {/* Header */}
      <Paper
        elevation={2}
        sx={{
          p: 2,
          borderRadius: '16px 16px 0 0',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          bgcolor: 'white',
          position: 'relative',
        }}
      >
        <Box sx={{ flex: 1, textAlign: 'center' }}>
          <Typography variant="h2" component="h1" fontWeight="bold">
            <SportsBaseballIcon sx={{ fontSize: 50, mb: 2, opacity: 0.5 }} /> The Baseball RAG <SportsBaseballIcon sx={{ fontSize: 50, mb: 2, opacity: 0.5 }} />
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Let's Talk Baseball
          </Typography>
        </Box>
        {messages.length > 0 && (
          <IconButton
            onClick={handleClearChat}
            size="small"
            title="Clear chat"
            sx={{
              color: 'text.secondary',
              position: 'absolute',
              right: 16,
              top: '50%',
              transform: 'translateY(-50%)',
            }}
          >
            <DeleteOutlineIcon />
          </IconButton>
        )}
      </Paper>

      {/* Messages */}
      <Box
        sx={{
          flex: 1,
          bgcolor: 'white',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        <MessageList messages={messages} />
        <div ref={messagesEndRef} />
      </Box>

      {/* Input */}
      <Paper
        elevation={2}
        sx={{
          borderRadius: '0 0 16px 16px',
          bgcolor: 'white',
        }}
      >
        <ChatInput
          onSendMessage={handleSendMessage}
          isLoading={mutation.isPending}
        />
      </Paper>
    </Box>
  );
}
