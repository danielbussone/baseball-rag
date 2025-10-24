#!/bin/bash

# Baseball RAG Agent - Docker Startup Script

set -e

echo "🏟️  Baseball RAG Agent - Docker Setup"
echo "======================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo "❌ Ollama is not running. Please start Ollama first:"
    echo "   ollama serve"
    exit 1
fi

# Check if llama3.2 model is available
if ! ollama list | grep -q "llama3.2"; then
    echo "⚠️  llama3.2 model not found. Pulling model..."
    ollama pull llama3.2
fi

# Determine which compose file to use
COMPOSE_FILE="docker-compose.yml"
if [[ "$1" == "dev" ]]; then
    COMPOSE_FILE="docker-compose.dev.yml"
    echo "🔧 Starting in development mode..."
else
    echo "🚀 Starting in production mode..."
fi

# Start the services
echo "📦 Building and starting containers..."
docker-compose -f $COMPOSE_FILE up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check health
echo "🔍 Checking service health..."

# Check database
if docker-compose -f $COMPOSE_FILE exec -T database pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ Database is ready"
else
    echo "❌ Database is not ready"
fi

# Check backend
if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
    echo "✅ Backend is ready"
else
    echo "⚠️  Backend is starting up..."
fi

# Check frontend
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend is ready"
else
    echo "⚠️  Frontend is starting up..."
fi

echo ""
echo "🎉 Services are starting up!"
echo ""
echo "📊 Access the application:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:3001"
echo "   Database: localhost:5432 (postgres/baseball123)"
echo ""
echo "📝 Next steps:"
echo "   1. Run ETL: cd fangraphs && Rscript batter_leaderboard_etl.r"
echo "   2. Generate embeddings: cd embeddings && npm run generate"
echo "   3. Start chatting about baseball!"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: docker-compose -f $COMPOSE_FILE logs -f"
echo "   Stop:      docker-compose -f $COMPOSE_FILE down"
echo "   Restart:   ./start.sh"