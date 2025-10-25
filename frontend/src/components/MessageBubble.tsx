import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { Box, Paper, Typography, CircularProgress } from '@mui/material';
import type { ChatMessage } from '../types';
import ToolExecutionIndicator from './ToolExecutionIndicator';

interface MessageBubbleProps {
  message: ChatMessage;
}

/**
 * Individual message bubble component with SMS-style appearance
 * Supports user messages, assistant messages, loading states, and errors
 */
export default function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === 'user';

  return (
    <Box
      sx={{
        display: 'flex',
        justifyContent: isUser ? 'flex-end' : 'flex-start',
        mb: 1.5,
        px: 2,
      }}
    >
      <Paper
        elevation={isUser ? 2 : 1}
        sx={{
          maxWidth: '90%',
          p: 1.5,
          borderRadius: isUser ? '18px 18px 4px 18px' : '18px 18px 18px 4px',
          bgcolor: isUser ? '#1976d2' : '#f0f0f0',
          color: isUser ? 'white' : 'text.primary',
        }}
      >
        {/* Error State */}
        {message.error && (
          <Box>
            <Typography variant="body2" color="error.main">
              {message.content}
            </Typography>
            <Typography variant="caption" color="error.light" sx={{ mt: 0.5, display: 'block' }}>
              {message.error}
            </Typography>
          </Box>
        )}

        {/* Normal Message */}
        {!message.error && (
          <>
            {/* Loading indicator for streaming */}
            {message.isLoading && (
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                <CircularProgress size={16} sx={{ color: 'text.secondary' }} />
                <Typography variant="body2" color="text.secondary">
                  Thinking...
                </Typography>
              </Box>
            )}

            {/* Tool Execution Indicators for Assistant Messages */}
            {!isUser && message.toolExecutions && (
              <ToolExecutionIndicator toolExecutions={message.toolExecutions} />
            )}
            
            {isUser ? (
              <Typography
                variant="body1"
                sx={{
                  whiteSpace: 'pre-wrap',
                  wordBreak: 'break-word',
                }}
              >
                {message.content}
              </Typography>
            ) : (
              message.content && (
                <Box
                  sx={{
                    '& p': { margin: '0.5em 0' },
                    '& p:first-of-type': { marginTop: 0 },
                    '& p:last-of-type': { marginBottom: 0 },
                    '& ul, & ol': { margin: '0.5em 0', paddingLeft: '1.5em' },
                    '& table': {
                      borderCollapse: 'collapse',
                      width: '100%',
                      margin: '0.75em 0',
                      fontSize: '0.875em',
                      display: 'table',
                      overflowX: 'auto',
                    },
                    '& th, & td': {
                      border: '1px solid #ddd',
                      padding: '8px 12px',
                      textAlign: 'left',
                      whiteSpace: 'nowrap',
                    },
                    '& th': {
                      backgroundColor: '#e3f2fd',
                      fontWeight: 'bold',
                      color: '#1565c0',
                      borderBottom: '2px solid #1976d2',
                    },
                    '& tbody tr:nth-of-type(even)': {
                      backgroundColor: '#f9f9f9',
                    },
                    '& tbody tr:hover': {
                      backgroundColor: '#f5f5f5',
                    },
                    '& code': {
                      backgroundColor: '#f5f5f5',
                      padding: '2px 4px',
                      borderRadius: '3px',
                      fontSize: '0.875em',
                    },
                    '& pre': {
                      backgroundColor: '#f5f5f5',
                      padding: '8px',
                      borderRadius: '4px',
                      overflow: 'auto',
                    },
                    '& strong': {
                      fontWeight: 'bold',
                    },
                    // Table container for horizontal scroll
                    '& > :has(table)': {
                      overflowX: 'auto',
                      maxWidth: '100%',
                    },
                  }}
                >
                  <ReactMarkdown remarkPlugins={[remarkGfm]}>
                    {message.content}
                  </ReactMarkdown>
                </Box>
              )
            )}

            {/* Timestamp */}
            <Typography
              variant="caption"
              sx={{
                display: 'block',
                mt: 0.5,
                opacity: 0.7,
                fontSize: '0.7rem',
              }}
            >
              {message.timestamp.toLocaleTimeString([], {
                hour: '2-digit',
                minute: '2-digit',
              })}
            </Typography>
          </>
        )}
      </Paper>
    </Box>
  );
}
