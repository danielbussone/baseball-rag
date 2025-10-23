import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import Chat from './components/Chat';

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-6xl mx-auto p-4">
          <header className="mb-8 text-center">
            <h1 className="text-4xl font-bold text-gray-900 mb-2">
              ⚾ Baseball RAG Agent
            </h1>
            <p className="text-gray-600">
              Ask me anything about baseball stats and player comparisons
            </p>
          </header>
          <Chat />
        </div>
      </div>
    </QueryClientProvider>
  );
}

export default App;
