import { useState, useRef, useEffect } from 'react';
import { Box, Paper, Typography, IconButton } from '@mui/material';
import SportsBaseballIcon from '@mui/icons-material/SportsBaseball';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import { sendChatMessageStream } from '../lib/api';
import type { ChatMessage, ToolExecution } from '../types';
import MessageList from './MessageList';
import ChatInput from './ChatInput';

/**
 * Main chat container component
 * Manages chat state, message sending, and scrolling behavior
 */
export default function Chat() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const contentBufferRef = useRef<string>('');



  /**
   * Scrolls the chat to the bottom when new messages arrive
   */
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  /**
   * Handles sending a new message with streaming
   * @param message - The message text to send
   */
  const handleSendMessage = async (message: string) => {
    if (!message.trim() || isLoading) return;

    setIsLoading(true);

    // Add user message immediately
    const userMessage: ChatMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: message,
      timestamp: new Date(),
    };

    // Add streaming assistant message
    const assistantMessageId = (Date.now() + 1).toString();
    const assistantMessage: ChatMessage = {
      id: assistantMessageId,
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      isLoading: true,
      toolExecutions: [],
    };

    setMessages((prev) => [...prev, userMessage, assistantMessage]);

    // Reset buffer
    contentBufferRef.current = '';

    try {
      await sendChatMessageStream(message, {
        onContent: (content) => {
          contentBufferRef.current += content;
          setMessages((prev) => {
            const updated = [...prev];
            const index = updated.findIndex((m) => m.id === assistantMessageId);
            if (index !== -1) {
              updated[index] = {
                ...updated[index],
                content: contentBufferRef.current,
              };
            }
            return updated;
          });
        },
        onToolStart: (toolExecution: ToolExecution) => {
          console.log('[Stream] Tool start:', toolExecution.name);
          setMessages((prev) => {
            const updated = [...prev];
            const index = updated.findIndex((m) => m.id === assistantMessageId);
            if (index !== -1) {
              const existingTools = updated[index].toolExecutions || [];
              updated[index] = {
                ...updated[index],
                toolExecutions: [...existingTools, toolExecution],
              };
            }
            return updated;
          });
        },
        onToolEnd: (toolExecution: ToolExecution) => {
          console.log('[Stream] Tool end:', toolExecution.name, toolExecution.duration + 'ms');
          setMessages((prev) => {
            const updated = [...prev];
            const index = updated.findIndex((m) => m.id === assistantMessageId);
            if (index !== -1) {
              const tools = updated[index].toolExecutions || [];
              const toolIndex = tools.findIndex((t) => t.name === toolExecution.name);
              if (toolIndex !== -1) {
                tools[toolIndex] = toolExecution;
                updated[index] = {
                  ...updated[index],
                  toolExecutions: [...tools],
                };
              }
            }
            return updated;
          });
        },
        onDone: () => {
          console.log('[Stream] Done');
          setMessages((prev) => {
            const updated = [...prev];
            const index = updated.findIndex((m) => m.id === assistantMessageId);
            if (index !== -1) {
              updated[index] = {
                ...updated[index],
                isLoading: false,
              };
            }
            return updated;
          });
          setIsLoading(false);
        },
        onError: (error: string) => {
          setMessages((prev) => {
            const updated = [...prev];
            const index = updated.findIndex((m) => m.id === assistantMessageId);
            if (index !== -1) {
              updated[index] = {
                ...updated[index],
                content: contentBufferRef.current || 'Sorry, something went wrong.',
                isLoading: false,
                error,
              };
            }
            return updated;
          });
          setIsLoading(false);
        },
      });
    } catch (error) {
      setMessages((prev) => {
        const updated = [...prev];
        const index = updated.findIndex((m) => m.id === assistantMessageId);
        if (index !== -1) {
          updated[index] = {
            ...updated[index],
            content: contentBufferRef.current || 'Sorry, something went wrong.',
            isLoading: false,
            error: error instanceof Error ? error.message : 'Unknown error',
          };
        }
        return updated;
      });
      setIsLoading(false);
    }
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
          isLoading={isLoading}
        />
      </Paper>
    </Box>
  );
}
