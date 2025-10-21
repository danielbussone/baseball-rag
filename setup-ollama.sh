#!/bin/bash

echo "🦙 Setting up Ollama for Baseball RAG..."

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama not found. Please install from https://ollama.ai"
    exit 1
fi

echo "✅ Ollama found"

# Start Ollama service (if not running)
echo "🚀 Starting Ollama service..."
ollama serve &
sleep 3

# Pull the model
echo "📥 Pulling llama3.1:8b model (this may take a while)..."
ollama pull llama3.1:8b

echo "✅ Setup complete! You can now run:"
echo "  cd backend && npm run dev"
echo ""
echo "Test with:"
echo "  curl -X POST http://localhost:3001/api/chat \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"message\": \"Tell me about Mike Trout\"}'"