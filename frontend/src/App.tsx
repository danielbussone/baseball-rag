import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import Box from '@mui/material/Box';
import Chat from './components/Chat';

const queryClient = new QueryClient();

// Create MUI theme with custom colors
const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    background: {
      default: '#D2EBED', // SMS-style background color
      paper: '#ffffff',
    },
  },
  typography: {
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
  },
});

/**
 * Root application component
 * Provides theme, query client, and main layout
 */
function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Box
          sx={{
            minHeight: '100vh',
            bgcolor: 'background.default',
            display: 'flex',
            flexDirection: 'column',
            p: { xs: 1, sm: 2, md: 3 },
          }}
        >
          <Chat />
        </Box>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;
