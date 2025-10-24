# Docker Setup for Baseball RAG Agent

This guide explains how to run the entire Baseball RAG application using Docker Compose.

## Prerequisites

- Docker Desktop installed and running
- Ollama installed locally (for LLM functionality)
- At least 8GB RAM available for containers

## Quick Start

### 1. Start Ollama (Required)

The backend connects to Ollama running on your host machine:

```bash
# Start Ollama service
ollama serve

# Pull the required model (in another terminal)
ollama pull llama3.2
```

### 2. Production Setup

Run the full application stack:

```bash
# Build and start all services
docker-compose up --build

# Or run in background
docker-compose up -d --build
```

This will start:
- **Database**: PostgreSQL with pgvector on port 5432
- **Backend**: Node.js API on port 3001
- **Frontend**: React app served by nginx on port 3000

Access the application at: http://localhost:3000

### 3. Development Setup (Hot Reload)

For development with hot reload:

```bash
# Use the development compose file
docker-compose -f docker-compose.dev.yml up --build

# Or run in background
docker-compose -f docker-compose.dev.yml up -d --build
```

## Services Overview

### Database (PostgreSQL + pgvector)
- **Image**: `pgvector/pgvector:pg16`
- **Port**: 5432
- **Credentials**: postgres/baseball123
- **Features**: 
  - Automatic schema initialization
  - Persistent data storage
  - Health checks

### Backend (Node.js + TypeScript)
- **Port**: 3001
- **Environment**: Production or Development
- **Features**:
  - Fastify API server
  - Ollama integration
  - PostgreSQL connection
  - Health check endpoint

### Frontend (React + Vite)
- **Port**: 3000
- **Production**: Built and served by nginx
- **Development**: Vite dev server with hot reload
- **Features**:
  - Material UI components
  - Chat interface
  - API integration

## Environment Variables

The containers use these default environment variables:

### Database
- `POSTGRES_DB=postgres`
- `POSTGRES_USER=postgres`
- `POSTGRES_PASSWORD=baseball123`

### Backend
- `DB_HOST=database`
- `DB_PORT=5432`
- `OLLAMA_BASE_URL=http://host.docker.internal:11434`
- `OLLAMA_MODEL=llama3.2`
- `PORT=3001`

### Frontend
- `VITE_API_URL=http://localhost:3001`

## Data Setup

After starting the containers, you'll need to populate the database:

### 1. Run ETL Process

The R ETL script needs to run on your host machine (not in Docker):

```bash
# Install R dependencies first
R -e "install.packages(c('baseballr', 'DBI', 'RPostgres', 'dplyr'))"

# Run the ETL script
cd fangraphs
Rscript batter_leaderboard_etl.r
```

### 2. Generate Embeddings

```bash
# Build and run embeddings generation
cd embeddings
npm install
npm run build
npm run generate
```

## Useful Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f database
```

### Stop Services
```bash
# Stop all services
docker-compose down

# Stop and remove volumes (deletes database data)
docker-compose down -v
```

### Rebuild Services
```bash
# Rebuild specific service
docker-compose build backend
docker-compose build frontend

# Rebuild and restart
docker-compose up --build backend
```

### Database Access
```bash
# Connect to PostgreSQL
docker exec -it baseball-postgres psql -U postgres -d postgres

# Or from host (if you have psql installed)
psql -h localhost -U postgres -d postgres
```

### Health Checks
```bash
# Check backend health
curl http://localhost:3001/api/health

# Check if frontend is serving
curl http://localhost:3000
```

## Troubleshooting

### Common Issues

1. **Ollama Connection Failed**
   - Ensure Ollama is running: `ollama serve`
   - Check model is available: `ollama list`
   - Verify model name matches: `llama3.2`

2. **Database Connection Failed**
   - Wait for database to be ready (health check)
   - Check logs: `docker-compose logs database`
   - Verify port 5432 is not in use by another service

3. **Frontend Can't Connect to Backend**
   - Ensure backend is healthy: `curl http://localhost:3001/api/health`
   - Check CORS configuration in backend
   - Verify `VITE_API_URL` environment variable

4. **Port Conflicts**
   - Change ports in docker-compose.yml if needed
   - Default ports: 3000 (frontend), 3001 (backend), 5432 (database)

### Performance Tips

1. **Allocate More Memory**
   - Increase Docker Desktop memory limit to 8GB+
   - Especially important for embedding generation

2. **Use Development Mode**
   - Faster startup with `docker-compose.dev.yml`
   - Hot reload for code changes

3. **Persistent Volumes**
   - Database data persists between restarts
   - Use `docker-compose down -v` only if you want to reset data

## File Structure

```
baseball-rag/
├── docker-compose.yml          # Production setup
├── docker-compose.dev.yml      # Development setup
├── backend/
│   ├── Dockerfile             # Production backend image
│   ├── Dockerfile.dev         # Development backend image
│   └── .dockerignore
├── frontend/
│   ├── Dockerfile             # Production frontend image
│   ├── Dockerfile.dev         # Development frontend image
│   ├── nginx.conf             # Nginx configuration
│   └── .dockerignore
└── database/
    └── fangraphs_schema.sql   # Database schema
```

## Next Steps

1. Start the services with Docker Compose
2. Run the ETL process to populate data
3. Generate embeddings for semantic search
4. Access the chat interface at http://localhost:3000
5. Ask baseball questions and enjoy!