# Baseball RAG Agent - Project Specification

**Version:** 1.0  
**Last Updated:** October 14, 2025  
**Status:** Phase 1 Complete (ETL), Moving to Phase 2 (Embeddings)

---

## Project Goal

Build a locally-hosted RAG (Retrieval-Augmented Generation) agent that answers complex baseball questions by querying authoritative data sources and using LLM reasoning. The agent should provide accurate, citation-backed answers to queries like:

- "Compare the careers of Mike Trout and Ken Griffey Jr."
- "Who were the best power hitters in the steroid era?"
- "Compare the pitching styles of Tyler Glasnow and Tarik Skubal"
- "Show me players similar to Vladimir Guerrero Jr's offensive profile"

### Core Principles

1. **Accuracy over speed** - Use real data, not LLM hallucinations
2. **Local-first** - No cloud dependencies, runs entirely on localhost
3. **Separation of concerns** - R for data, TypeScript for application logic
4. **Incremental development** - Ship working features, iterate later

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  Data Sources (External)                            │
│  - FanGraphs (via baseballr)                        │
│  - Baseball Reference (future web scraper)          │
│  - Baseball Savant/Statcast (via baseballr)        │
│  - Wikipedia (future API integration)               │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  R ETL Layer                                        │
│  - baseballr for API access                         │
│  - Data transformation & cleaning                   │
│  - Incremental upserts to Postgres                  │
│  - (Future) R visualization generation              │
└──────────────────┬──────────────────────────────────┘
                   ↓
            ┌──────────────┐
            │  PostgreSQL  │
            │  + PGVector  │
            │              │
            │  Tables:     │
            │  - Players   │
            │  - Stats     │
            │  - Embeddings│
            └──────┬───────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  TypeScript Backend (Node.js)                       │
│  - Express/Fastify API                              │
│  - Ollama integration (LLM orchestration)           │
│  - Function/tool calling                            │
│  - Vector search (semantic similarity)              │
│  - Embedding generation (transformers.js)           │
└──────────────────┬──────────────────────────────────┘
                   ↓
            ┌──────────────┐
            │  React UI    │
            │  - Chat UI   │
            │  - Stats vis │
            │  - Citations │
            └──────────────┘
```

---

## Technology Stack

### Data Layer
- **R** (4.x+) - ETL and data transformation
  - `baseballr` - Baseball API wrapper
  - `DBI`, `RPostgres` - Database connectivity
  - `dplyr` - Data manipulation
  - (Future) `ggplot2`, `plotly` for visualizations
  
- **PostgreSQL** (16+) - Primary database
  - `pgvector` extension for vector storage
  - Running via Docker for easy setup

### Application Layer
- **TypeScript/Node.js** - Backend application
  - Runtime: Node 18+
  - Database: `pg` or `kysely` (type-safe query builder)
  - Embeddings: `@xenova/transformers` (transformers.js)
  - API Framework: Express or Fastify
  
- **Ollama** - Local LLM runtime
  - Models: llama3.1:8b or qwen2.5:14b
  - Function calling support required
  - REST API integration

### Frontend
- **React** with TypeScript
  - TanStack Query for data fetching
  - WebSocket/SSE for streaming responses
  - Recharts or D3.js for visualizations

### Embeddings
- **Model:** `all-mpnet-base-v2` (768 dimensions)
  - Good quality/size tradeoff
  - Runs locally via transformers.js
  - ~420MB model size

---

## Feature Breakdown

### Phase 1: MVP (Core RAG Functionality)
**Status:** ETL Complete ✅, Moving to Embeddings

#### 1.1 Data Pipeline ✅ COMPLETE
- [x] FanGraphs batter leaderboards (1988-2025)
- [x] PostgreSQL schema with proper indexes
- [x] Incremental ETL (upsert logic)
- [x] Three normalized tables (players, season_stats, pitch_data)
- [x] **Grade calculation in R ETL** (20-80 scouting scale)
- [x] **Grade distribution validation**
- [x] Grades persisted to `fg_season_stats` with indexes
- [x] **JAWS calculation in `fg_career_stats` view** (career + 7-year peak WAR)

#### 1.2 Embedding Generation ✅ COMPLETE
- [x] Generate natural language summaries for player seasons (template-based)
- [x] Create embeddings using transformers.js (all-mpnet-base-v2)
- [x] Store embeddings in PGVector table
- [x] Test semantic search quality
- [x] **Hybrid search implementation** (semantic + SQL filters on grades)

#### 1.3 LLM Integration
- [ ] Set up Ollama with appropriate model
- [ ] Implement tool/function calling
- [ ] Create basic tools:
  - `get_player_stats(player_name, year)` - Fetch specific stats
  - `search_similar_players(query)` - Vector similarity search
  - `compare_players(player1, player2)` - Side-by-side comparison
  - `get_career_summary(player_name)` - Career aggregates

#### 1.4 Backend API
- [ ] Express/Fastify server
- [ ] `/chat` endpoint with streaming responses
- [ ] PostgreSQL connection pooling
- [ ] Error handling and logging

#### 1.5 Frontend
- [ ] Chat interface (text input/output)
- [ ] Display LLM responses with citations
- [ ] Show retrieved stats in structured format
- [ ] Basic loading/error states

#### 1.6 MVP Acceptance Criteria
- User can ask: "Compare Mike Trout and Ken Griffey Jr"
- System retrieves career stats from database
- LLM generates coherent comparison with citations
- Stats are displayed alongside the narrative

---

### Phase 2: Enhanced Retrieval
**Status:** Not Started

#### 2.1 Baseball Reference Integration
- [ ] Web scraper for player biographical data
- [ ] Career narratives and context
- [ ] Awards, All-Star appearances
- [ ] Integration with existing FanGraphs data

#### 2.2 Advanced Query Tools
- [ ] Era-based filtering ("players in the 1990s")
- [ ] Position-based search ("best shortstops")
- [ ] Multi-year aggregations
- [ ] Peak season detection

#### 2.3 Wikipedia Integration
- [ ] API calls for biographical info
- [ ] Career highlights and context
- [ ] Link to external resources

#### 2.4 Statcast Data
- [ ] Pitch-level data (2015+)
- [ ] Exit velocity, launch angle, barrel rate
- [ ] Sprint speed, defensive metrics

---

### Phase 3: Visualization Integration
**Status:** Future

#### 3.1 R Visualization Engine
- [ ] Trigger R scripts from TypeScript backend
- [ ] Generate visualizations on-demand:
  - Career trajectory charts
  - Pitch mix comparisons
  - Batted ball heat maps
  - WAR component breakdowns
  
#### 3.2 Frontend Visualization
- [ ] Render R-generated plots
- [ ] Interactive charts (D3.js or Recharts)
- [ ] Export visualization data

#### 3.3 Smart Visualization Triggers
- [ ] LLM detects when visualization would help
- [ ] Automatically generates appropriate charts
- [ ] Display alongside text response

---

### Phase 4: Advanced Features
**Status:** Future

#### 4.1 Pitcher Data
- [ ] FanGraphs pitcher leaderboards
- [ ] Pitching stats and advanced metrics
- [ ] Pitcher comparison tools

#### 4.2 Team Analytics
- [ ] Team-level statistics
- [ ] Roster construction analysis
- [ ] Historical team comparisons

#### 4.3 Multi-turn Conversations
- [ ] Conversation memory
- [ ] Follow-up questions
- [ ] Contextual awareness

#### 4.4 Advanced Search
- [ ] Complex filters (age ranges, date ranges)
- [ ] Statistical thresholds
- [ ] Multi-dimensional similarity

---

## Key Architecture Decisions

### 1. **R for ETL, TypeScript for Application**
**Rationale:**
- R excels at data transformation and has mature baseball packages (`baseballr`)
- TypeScript provides type safety for complex application logic
- Separates data concerns from application concerns
- Allows future integration of R visualizations

**Trade-offs:**
- Two language ecosystems to maintain
- More complex deployment
- Worth it for leveraging best-in-class tools

### 2. **PGVector over ChromaDB**
**Rationale:**
- Single database for structured stats AND vectors
- Enables hybrid queries (filter by year, THEN vector search)
- Better for production scaling
- Mature PostgreSQL ecosystem

**Trade-offs:**
- Slightly more complex setup
- Less "plug-and-play" than specialized vector DBs
- Worth it for query flexibility

### 3. **Ollama over Cloud LLMs**
**Rationale:**
- Fully local, no API costs
- Privacy and data control
- Fast iteration during development
- Good models available (llama3.1, qwen2.5)

**Trade-offs:**
- Requires GPU for decent performance
- Model quality ceiling lower than GPT-4
- Worth it for local-first principle

### 4. **FanGraphs First, Then Baseball Reference**
**Rationale:**
- FanGraphs has clean API via `baseballr`
- Advanced metrics readily available
- Gets us to MVP faster
- BRef provides narrative context later

**Trade-offs:**
- FanGraphs historical coverage less complete
- Missing some biographical richness
- Worth it for rapid prototyping

### 5. **Incremental ETL over Full Refresh**
**Rationale:**
- Preserves manual corrections
- Faster updates
- Less database churn
- Production-ready pattern

**Trade-offs:**
- More complex logic
- Requires conflict handling
- Worth it for data integrity

---

## Database Schema

### Version 1.0 (Current)

#### `fg_players`
Dimension table with one row per unique player.

**Key columns:**
- `fangraphs_id` (PK) - FanGraphs player identifier
- `mlbam_id` - MLB Advanced Media ID (for Statcast linking)
- `player_name` - Full player name
- `bats` - Batting handedness (L/R/S)
- `first_season`, `last_season` - Career span
- `created_at`, `updated_at` - Audit timestamps

#### `fg_season_stats`
One row per player per season with batting statistics.

**Key columns:**
- `player_season_id` (PK) - Composite key: `{fangraphs_id}_{year}`
- `fangraphs_id` (FK) - Links to players
- `year`, `age`, `team` - Context
- Basic stats: `g`, `pa`, `ab`, `h`, `hr`, `rbi`, `sb`, etc.
- Rate stats: `avg`, `obp`, `slg`, `ops`, `iso`, `babip`
- Advanced: `wrc_plus`, `war`, `woba`, `bb_pct`, `k_pct`
- Batted ball: `gb_pct`, `fb_pct`, `ld_pct`, `hard_pct`
- Statcast (2015+): `ev`, `la`, `barrel_pct`, `maxev`

**Indexes:**
- `fangraphs_id`, `year`, `war DESC`, `wrc_plus DESC`

#### `fg_batter_pitches_faced`
Pitch-level data for what batters faced (optional, very granular).

**Key columns:**
- `player_season_id` (PK, FK)
- PITCHf/x data: pitch types, velocities, movement
- PITCHInfo data: alternative classification system
- Plate discipline vs pitch types

#### Future Tables
- `player_embeddings` - Vector embeddings for semantic search
- `fg_pitcher_stats` - Pitcher statistics
- `bref_players` - Baseball Reference biographical data
- `statcast_metrics` - Aggregated Statcast data

---

## Development Workflow

### Current Phase Checklist

**Phase 1.2: Embeddings (Current)**
1. Design player season summary template
2. Create TypeScript script to:
   - Read from `fg_season_stats`
   - Generate natural language descriptions
   - Create embeddings with transformers.js
   - Store in new `player_embeddings` table
3. Test embedding quality with sample queries
4. Optimize embedding generation (batch processing)

### Running the Project (Current State)

#### Prerequisites
- Docker Desktop (for PostgreSQL)
- R 4.x+ with packages: `baseballr`, `DBI`, `RPostgres`, `dplyr`
- Node.js 18+ (for future TypeScript work)

#### Setup Database
```bash
# Start PostgreSQL with pgvector
docker run -d \
  --name baseball-postgres \
  -e POSTGRES_PASSWORD=yourpassword \
  -p 5432:5432 \
  -v pgvector-data:/var/lib/postgresql/data \
  pgvector/pgvector:pg16

# Create schema
psql -h localhost -U postgres -d postgres -f fangraphs_schema.sql
```

#### Run ETL
```bash
# Edit batter_leaderboard_etl.r to set password
# Then run:
Rscript batter_leaderboard_etl.r
```

#### Verify Data
```bash
psql -h localhost -U postgres -d postgres

# Check record counts
SELECT COUNT(*) FROM fg_players;
SELECT COUNT(*) FROM fg_season_stats;

# Top players by WAR
SELECT * FROM fg_career_stats ORDER BY total_war DESC LIMIT 10;
```

---

## Performance Considerations

### Database
- Indexes on all foreign keys
- Composite indexes on common query patterns
- HNSW index on vector embeddings (fast similarity search)
- Connection pooling in application

### Embeddings
- Batch generation (100-500 at a time)
- Cache embeddings, regenerate only on data changes
- Consider quantization for production

### LLM
- Stream responses to user (don't wait for full completion)
- Implement request timeouts
- Cache common queries

---

## Testing Strategy

### Data Quality
- Validate FanGraphs data completeness (no missing seasons)
- Check for statistical outliers (sanity checks)
- Verify player ID linkages across tables

### Embedding Quality
- Manual review of similar player results
- Test queries with known similar players
- Measure retrieval precision/recall

### LLM Integration
- Test tool calling accuracy
- Verify citation correctness
- Check for hallucinations vs. retrieved data

### End-to-End
- Sample queries for common use cases
- Performance benchmarks (query latency)
- Error handling (network failures, invalid inputs)

---

## Future Considerations

### Scalability
- Current design handles ~15,000 player-seasons easily
- PGVector scales to millions of embeddings
- Consider read replicas if query volume increases

### Data Freshness
- Run ETL daily/weekly during season
- Webhook for real-time updates (future)
- Cache invalidation strategy

### Additional Data Sources
- Baseball Prospectus (PECOTA projections)
- Retrosheet (play-by-play historical data)
- MLB.com (news, transactions)

### Deployment
- Containerize all components (Docker Compose)
- Environment variable configuration
- Automated backups
- Monitoring and logging

---

## Lessons Learned

1. **FanGraphs API behavior:** Doesn't handle multi-year requests well, required year-by-year iteration
2. **Schema evolution:** Pitch tracking data format changed over time (simple velocities vs. PITCHf/x)
3. **Upsert strategy:** Critical for incremental updates without data loss
4. **Column naming:** FanGraphs uses special characters (`%`, `+`, `-`) requiring careful cleaning

---

## Contact & Resources

### Documentation
- FanGraphs schema: `fangraphs_schema.sql`
- ETL script: `batter_leaderboard_etl.r`
- Project spec: This document

### External Resources
- baseballr: https://billpetti.github.io/baseballr/
- FanGraphs: https://www.fangraphs.com/
- PGVector: https://github.com/pgvector/pgvector
- Ollama: https://ollama.ai/
- transformers.js: https://huggingface.co/docs/transformers.js

---

**Next Step:** Create TypeScript embedding generation script
