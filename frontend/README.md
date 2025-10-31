# Frontend Chat Interface

React + TypeScript chat interface for the Baseball RAG system with real-time streaming responses and Material UI components.

## Overview

- **Framework**: React 18 + TypeScript + Vite
- **UI Library**: Material UI (MUI) with custom theming
- **Data Fetching**: TanStack Query for API management
- **Streaming**: Server-Sent Events for real-time responses
- **Styling**: Material UI + CSS modules

## Quick Start

```bash
# Install dependencies
npm install

# Development mode (with hot reload)
npm run dev

# Production build
npm run build

# Preview production build
npm run preview

# Lint code
npm run lint
```

## Features

### Real-time Chat Interface
- **SMS-style bubbles** - Familiar messaging UI with blue (user) and gray (assistant) bubbles
- **Streaming responses** - See LLM responses appear in real-time as they're generated
- **Tool execution indicators** - Visual feedback when backend tools are running
- **Markdown rendering** - Tables, lists, and formatting in responses
- **Auto-scroll** - Automatically scrolls to new messages

### User Experience
- **Keyboard shortcuts** - Enter to send, Shift+Enter for new lines
- **Loading states** - "Thinking..." spinner during processing
- **Error handling** - Clear error messages with retry options
- **Welcome screen** - Example queries to get users started
- **Clear chat** - Reset conversation with trash icon
- **Timestamps** - All messages show creation time

### Responsive Design
- **Mobile-friendly** - Works well on phones and tablets
- **Custom scrollbars** - Styled scrollbars for better aesthetics
- **Flexible layout** - Adapts to different screen sizes

## Architecture

### Component Structure
```
src/
├── components/
│   ├── Chat.tsx         # Main chat container with state management
│   ├── MessageList.tsx  # Message display with empty state
│   ├── MessageBubble.tsx # Individual message component
│   └── ChatInput.tsx    # Input field with keyboard handling
├── lib/
│   └── api.ts          # API client with streaming support
├── types/
│   └── index.ts        # TypeScript interfaces
├── App.tsx             # Root component with theme provider
└── main.tsx           # React entry point
```

### Key Components

**Chat.tsx** - Main Container
- Manages conversation state and message history
- Handles API calls and streaming responses
- Coordinates between input, messages, and loading states
- Implements auto-scroll and error handling

**MessageBubble.tsx** - Message Display
- Renders individual messages with appropriate styling
- Supports markdown formatting with react-markdown
- Shows timestamps and message metadata
- Handles user vs assistant message styling

**ChatInput.tsx** - User Input
- Multi-line text input with keyboard shortcuts
- Send button with loading state
- Character limits and input validation
- Handles Enter/Shift+Enter behavior

**API Client** (`lib/api.ts`)
- Server-Sent Events implementation for streaming
- Error handling and connection management
- Message parsing and event processing
- Automatic reconnection on failures

## Streaming Implementation

### Event Processing
The frontend handles multiple event types from the backend:

```typescript
type StreamEvent = 
  | { type: 'content', content: string }      // LLM response text
  | { type: 'tool_start', tool: string }      // Tool execution begins
  | { type: 'tool_end', tool: string }        // Tool execution completes
  | { type: 'error', error: string }          // Error occurred
  | { type: 'done' }                          // Stream complete
```

### Real-time Updates
- **Content accumulation** - Builds response text incrementally
- **Tool indicators** - Shows active tool execution with spinners
- **Smooth rendering** - Avoids flickering during updates
- **Error boundaries** - Graceful handling of stream errors

## Configuration

### Environment Variables
```bash
# API endpoint (optional - defaults to localhost:3001)
VITE_API_URL=http://localhost:3001

# Development settings
VITE_DEV_MODE=true
```

### Material UI Theme
Custom theme with baseball-inspired colors:

```typescript
const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',  // Blue for user messages
    },
    secondary: {
      main: '#f5f5f5',  // Gray for assistant messages
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
  },
});
```

## Development

### Adding New Features

**New Message Types**
1. Add type to `types/index.ts`
2. Update `MessageBubble.tsx` rendering logic
3. Handle in `Chat.tsx` state management
4. Test with backend integration

**UI Improvements**
1. Modify components in `components/`
2. Update Material UI theme in `App.tsx`
3. Add CSS modules for custom styling
4. Test responsive behavior

**API Changes**
1. Update `lib/api.ts` client
2. Modify TypeScript interfaces
3. Handle new event types in components
4. Update error handling

### Testing

```bash
# Component testing with React Testing Library
npm run test

# E2E testing with Playwright
npm run test:e2e

# Visual regression testing
npm run test:visual

# Manual testing
npm run dev
# Open http://localhost:3000
```

### Build Optimization

```bash
# Analyze bundle size
npm run build
npm run analyze

# Check for unused dependencies
npm run depcheck

# Optimize images and assets
npm run optimize
```

## Performance

### Bundle Size
- **Initial bundle**: ~500KB gzipped
- **Code splitting**: Automatic route-based splitting
- **Tree shaking**: Unused Material UI components removed
- **Asset optimization**: Images and fonts optimized

### Runtime Performance
- **Virtual scrolling**: For long conversation histories
- **Memoization**: React.memo for expensive components
- **Debounced input**: Prevents excessive API calls
- **Lazy loading**: Components loaded on demand

### Streaming Optimization
- **Efficient updates**: Minimal re-renders during streaming
- **Buffer management**: Handles high-frequency updates
- **Memory management**: Cleans up event listeners
- **Connection pooling**: Reuses SSE connections

## Troubleshooting

### Common Issues

**Streaming Not Working**
```
Messages appear all at once instead of streaming
```
- Check VITE_API_URL points to correct backend
- Verify backend streaming endpoint is working
- Check browser developer tools for SSE connection
- Ensure CORS is configured properly

**Build Failures**
```
Error: TypeScript compilation failed
```
- Run `npm run lint` to check for type errors
- Verify all imports have correct paths
- Check tsconfig.json configuration
- Update dependencies if needed

**Styling Issues**
```
Material UI components not rendering correctly
```
- Verify Material UI theme is properly configured
- Check for CSS conflicts with global styles
- Ensure proper import statements for MUI components
- Test in different browsers

**Performance Issues**
```
Chat becomes slow with many messages
```
- Implement message pagination or virtualization
- Check for memory leaks in event listeners
- Optimize re-rendering with React.memo
- Consider message history limits

### Development Issues

**Hot Reload Not Working**
```bash
# Clear Vite cache
rm -rf node_modules/.vite
npm run dev
```

**TypeScript Errors**
```bash
# Check types
npm run type-check

# Update type definitions
npm update @types/react @types/react-dom
```

**API Connection Issues**
```bash
# Test backend directly
curl http://localhost:3001/api/health

# Check network tab in browser dev tools
# Verify CORS headers are present
```

## Future Enhancements

### Planned Features
- **Dark mode toggle** - User preference for light/dark themes
- **Message search** - Find specific conversations or topics
- **Export conversations** - Save chat history as text/PDF
- **Voice input** - Speech-to-text for queries
- **Conversation history** - Persistent storage across sessions

### Technical Improvements
- **WebSocket support** - Alternative to Server-Sent Events
- **Offline support** - Service worker for offline functionality
- **Progressive Web App** - Install as mobile/desktop app
- **Accessibility** - Screen reader support and keyboard navigation
- **Internationalization** - Multi-language support

### UI/UX Enhancements
- **Message reactions** - Like/dislike responses
- **Copy to clipboard** - Easy sharing of responses
- **Syntax highlighting** - Better code display in responses
- **Charts and graphs** - Visual data representations
- **Player cards** - Rich media for player information