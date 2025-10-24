import { Box, Typography } from '@mui/material';
import SportsBaseballIcon from '@mui/icons-material/SportsBaseball';
import type { ChatMessage } from '../types';
import MessageBubble from './MessageBubble';

interface MessageListProps {
  messages: ChatMessage[];
}

/**
 * Message list component that displays all chat messages
 * Shows empty state when no messages exist
 */
export default function MessageList({ messages }: MessageListProps) {
  if (messages.length === 0) {
    return (
      <Box
        sx={{
          flex: 1,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          p: 4,
        }}
      >
        <Box sx={{ textAlign: 'center', color: 'text.secondary' }}>
          <Typography variant="h4" gutterBottom>
            Welcome to<br/>The Baseball RAG!
          </Typography>
          <SportsBaseballIcon sx={{ fontSize: 58, mb: 2, opacity: 0.5 }} />
          <Typography variant="body2" sx={{ mb: 2 }}>
            Ask me about baseball players and stats
          </Typography>
          <Box sx={{ mt: 3 }}>
            <Typography variant="caption" display="block" sx={{ opacity: 0.7 }}>
              Try asking:
            </Typography>
            <Typography variant="caption" display="block" sx={{ mt: 0.5 }}>
              "Compare Mike Trout and Ken Griffey Jr"
            </Typography>
            <Typography variant="caption" display="block">
              "Tell me about Mookie Betts' 2024 season"
            </Typography>
          </Box>
        </Box>
      </Box>
    );
  }

  return (
    <Box
      sx={{
        flex: 1,
        overflowY: 'auto',
        py: 2,
        '&::-webkit-scrollbar': {
          width: '8px',
        },
        '&::-webkit-scrollbar-track': {
          backgroundColor: 'transparent',
        },
        '&::-webkit-scrollbar-thumb': {
          backgroundColor: 'rgba(0,0,0,0.2)',
          borderRadius: '4px',
        },
      }}
    >
      {messages.map((message) => (
        <MessageBubble key={message.id} message={message} />
      ))}
    </Box>
  );
}
