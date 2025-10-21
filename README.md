# Baseball RAG Agent - Project Specification

**Version:** 1.4
**Last Updated:** October 21, 2025
**Status:** Phase 1.3 Complete (LLM Integration with known issues), Moving to Phase 1.4 (Backend API)

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
│  - Percentile calculation & grade assignment        │
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
            │  - Percentiles│
            │  - Embeddings│
            └──────┬───────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  TypeScript Backend (Node.js)                       │
│  - Express/Fastify API                              │
│  - Ollama integration (LLM orchestration)           │
│  - Function/tool calling                            │
│  - Vector search (semantic similarity)              │
│  - Full-text search (keyword matching)              │
│  - Cross-encoder reranking                          │
│  - Embedding generation (transformers.js)           │
└──────────────────┬──────────────────────────────────┘
                   ↓
            ┌──────────────┐
            │  React UI    │
            │  - Chat UI   │
            │  - Stats vis │
            │  - Citations │
            │  - Percentile│
            │    graphs    │
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
  - Full-text search (FTS) with tsvector
  - Running via Docker for easy setup

### Application Layer
- **TypeScript/Node.js** - Backend application
  - Runtime: Node 18+
  - Database: `pg` or `kysely` (type-safe query builder)
  - Embeddings: `@xenova/transformers` (transformers.js)
  - Reranking: Cross-encoder models
  - NLP: `compromise` for keyword extraction
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

### Embeddings & Search
- **Bi-encoder:** `all-mpnet-base-v2` (768 dimensions)
  - Good quality/size tradeoff
  - Runs locally via transformers.js
  - ~420MB model size
  
- **Cross-encoder (Reranking):** `cross-encoder/ms-marco-MiniLM-L-6-v2`
  - Reranks top candidates for precision
  - ~80MB model size

---

## Feature Breakdown

### Phase 1: MVP (Core RAG Functionality)
**Status:** ETL ✅, Embeddings ✅, LLM Integration ✅ (with known issues)

#### 1.1 Data Pipeline ✅ COMPLETE (Grades Pending Revision)
- [x] FanGraphs batter leaderboards (1988-2025)
- [x] PostgreSQL schema with proper indexes
- [x] Incremental ETL (upsert logic)
- [x] Three normalized tables (players, season_stats, pitch_data)
- [x] **Grade calculation in R ETL** (20-80 scouting scale)
- [x] **Grade distribution validation**
- [x] Grades persisted to `fg_season_stats` with indexes
- [ ] **PENDING: Migrate to percentile-based grade calculation** (will occur in Phase 2.7.1)

#### 1.2 Embedding Generation ✅ COMPLETE
- [x] Generate natural language summaries for player seasons (template-based)
- [x] Create embeddings using transformers.js (all-mpnet-base-v2)
- [x] Store embeddings in PGVector table
- [x] Test semantic search quality
- [x] **Hybrid search implementation** (semantic + SQL filters on grades)

#### 1.3 LLM Integration ✅ COMPLETE (with known issues)
- [x] Set up Ollama with appropriate model
- [x] Implement tool/function calling
- [x] Create basic tools:
  - `search_similar_players(query, filters)` - Hybrid semantic search
  - `get_player_stats(player_name, year)` - Fetch specific stats
  - `compare_players(player1, player2)` - Side-by-side comparison
  - `get_career_summary(player_name)` - Career aggregates
  - `get_player_percentiles(player_name, year?, scope?)` - Percentile rankings (Phase 2.7)
  - `compare_player_percentiles(player1, player2, scope?)` - Percentile comparison (Phase 2.7)

**Known Issues (To Be Fixed):**
- [ ] Similar players search filters not working correctly
- [ ] Tool function parameter ordering issue (no clear definition found)
- [ ] Career summary aggregating season stats in code instead of using career view
- [ ] Prompt needs iteration for better stat formatting and presentation
- [ ] Scouting grade qualitative descriptors needed (currently copy/pasting examples)

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

#### 2.1 Full-Text Search (FTS) for Short Queries
- [ ] Add PostgreSQL Full-Text Search (FTS) infrastructure
  - [ ] Add `summary_tsv` tsvector column to `player_embeddings`
  - [ ] Create GIN index on `summary_tsv`
  - [ ] Create trigger to auto-update tsvector on insert/update
  - [ ] Populate existing rows with tsvectors
  
- [ ] Implement keyword extraction in TypeScript
  - [ ] Baseball-specific phrase detection (positions, qualities)
  - [ ] NLP-based noun phrase extraction (using `compromise`)
  - [ ] Pattern matching for common query types
  - [ ] Convert keywords to PostgreSQL tsquery format
  
- [ ] Implement query router
  - [ ] Route queries ≤4 tokens to FTS (keyword matching)
  - [ ] Route queries >4 tokens to semantic search (vector similarity)
  - [ ] Hybrid mode: combine FTS + vector for medium queries
  
- [ ] **Benefits:**
  - Solves length normalization bias for short queries
  - Faster than vector search (~10-50ms vs 50-100ms)
  - Exact phrase matching ("all time great" as unit)
  - Better handling of baseball-specific terminology

#### 2.2 Two-Stage Retrieval with Reranking
- [ ] Add cross-encoder reranking model
  - [ ] Load `cross-encoder/ms-marco-MiniLM-L-6-v2` via transformers.js
  - [ ] Batch processing for performance (32 candidates at a time)
  - [ ] Cache model in memory after first load
  
- [ ] Implement two-stage retrieval pipeline
  - **Stage 1:** Fast retrieval (50-100 candidates)
    - Use FTS for short queries
    - Use vector search for long queries
    - Apply SQL filters (position, grades, years)
  - **Stage 2:** Precise reranking (top 10)
    - Score each candidate with cross-encoder
    - Cross-encoder sees query + document together
    - Sort by rerank score, return top K
    
- [ ] **Benefits:**
  - Solves bi-encoder limitation with opposites
  - Handles negation ("power WITHOUT speed")
  - Better at multi-constraint queries ("elite defense BUT below-average offense")
  - Distinguishes opposites ("all time great" ≠ "replacement level")
  - Deep semantic understanding via attention mechanism
  
- [ ] **Performance target:** <1 second total
  - Stage 1 retrieval: ~50ms
  - Stage 2 reranking (50 candidates): ~500ms
  - Total: ~550ms (acceptable for user query)

#### 2.3 Baseball Reference Integration
- [ ] Web scraper for player biographical data
- [ ] Career narratives and context
- [ ] Awards, All-Star appearances
- [ ] Integration with existing FanGraphs data

#### 2.4 Advanced Query Tools
- [ ] Era-based filtering ("players in the 1990s")
- [ ] Position-based search ("best shortstops")
- [ ] Multi-year aggregations
- [ ] Peak season detection

#### 2.5 Wikipedia Integration
- [ ] API calls for biographical info
- [ ] Career highlights and context
- [ ] Link to external resources

#### 2.6 Statcast Data ⭐ DEPENDENCY for Phase 2.7
- [ ] Pitch-level data (2015+)
- [ ] Exit velocity, launch angle, barrel rate
- [ ] Sprint speed, defensive metrics
- [ ] Aggregation at season level
- [ ] Integration with existing FanGraphs stats

---

### Phase 2.7: Percentile Rankings & Visual Profiles
**Status:** Planned (Requires Statcast Integration)
**Dependencies:** Phase 2.6 (Statcast Data)

#### 2.7.1 Percentile Calculation Infrastructure

**Database Schema:**
- [ ] Create `stat_percentiles` table (season, career, peak7 scopes)
- [ ] Add minimum PA thresholds by scope (502 PA season, 3000 PA career, 3500 PA peak7)
- [ ] Store percentile distributions (p1, p5, p10, p25, p40, p50, p60, p75, p90, p95, p99)
- [ ] Store summary statistics (mean, stddev, min, max, qualified_count)
- [ ] Index on (stat_name, year, scope)

**R ETL Enhancements:**
- [ ] Calculate percentiles during season stats ETL
- [ ] Three calculation scopes:
  - **Season**: Single-season percentiles by year (min 502 PA)
  - **Career**: Career weighted averages → percentiles (min 3000 PA total)
  - **Peak7**: Best 7-year rolling window → percentiles (min 3500 PA total)
- [ ] Methodology:
  - Season: Direct percentile calculation from qualified players each year
  - Career: Calculate weighted career averages, then percentiles from those
  - Peak7: Find best 7-year window per player, then percentiles from peaks
- [ ] Upsert percentile thresholds to database
- [ ] Validation: Check distributions follow expected curves (normal or skewed as appropriate)

**Percentile-Based Grade Calculation (Replaces Current Method):**
- [ ] Calculate player's percentile for each stat via interpolation
- [ ] Implement two grade calculation methods for evaluation:
  - **Method 1 (Percentile)**: 80=99th, 70=90th, 60=75th, 50=50th, 40=25th, 30=10th, 20=1st
  - **Method 2 (Standard Deviation)**: 80=99.7th (μ+3σ), 70=97.7th (μ+2σ), 60=84.1th (μ+1σ), 50=50th (μ), etc.
- [ ] Store both grade sets temporarily: `power_grade_pct`, `power_grade_sd` (etc.)
- [ ] Evaluate which method produces better grades:
  - Test normality of each stat (Shapiro-Wilk, skewness, kurtosis)
  - Compare grade distributions to expectations
  - Eye test with known players (peak Bonds, Trout, etc.)
  - Analyze by stat type (power vs rate vs contact)
- [ ] Choose final method (or hybrid approach: SD for normal stats, percentile for skewed)
- [ ] Store both percentiles AND final grades in `fg_season_stats`
- [ ] Add percentile columns: `power_percentile`, `hit_percentile`, etc. (NUMERIC 5,2)
- [ ] Update existing grade columns with chosen methodology
- [ ] Validate grade distributions match percentile targets
- [ ] Re-run ETL to backfill all historical seasons with new grades
- [ ] Document final decision and statistical rationale

**Benefits of Percentile-Based Grades:**
- Empirically accurate (60 grade = actually top 25% of players)
- Works for non-normal distributions (handles skewed stats like HR, SB)
- Era-neutral by definition (no complex plus stat adjustments needed)
- Single source of truth (percentiles used for grades AND visualization)
- Self-validating (grade distribution must match percentile distribution)

**Stats to Track:**
- **Offense**: `barrel_pct`, `ev90`, `hard_pct`, `maxev`, `la` (launch angle)
- **Plate Discipline**: `bb_pct`, `k_pct`, `o_swing_pct` (chase rate), `swstr_pct` (whiff rate)
- **Power**: `iso`, `hr_per_600`, `avg_hr_distance`
- **Speed**: `sprint_speed`, `bolts` (30+ ft/s runs)
- **Contact**: `contact_pct`, `z_contact_pct`
- **Overall**: `wrc_plus`, `war_per_650`

#### 2.7.2 Backend Percentile Tools

**New LLM Tools:**
- [ ] `get_player_percentiles(player_name, year?, scope?)` 
  - Returns percentile data for visualization
  - Flags players below PA minimums with `qualified: false`
  - Defaults to most recent season, "season" scope
  - Calculates player's percentile via interpolation from stored thresholds
  
- [ ] `compare_player_percentiles(player1, player2, scope?)`
  - Side-by-side percentile comparison
  - Highlights biggest differences (>20 percentile points)
  - Useful for "compare X and Y" queries

**Percentile Calculation Logic:**
- [ ] TypeScript function: `calculatePlayerPercentile(value, stat, year, scope)`
  - Binary search or linear interpolation between stored percentile thresholds
  - Returns 0-100 percentile value
  - Handles null values gracefully
- [ ] Cache percentile threshold lookups (rarely change)
- [ ] Handle edge cases:
  - Values below p1 threshold → return 1
  - Values above p99 threshold → return 99
  - Missing stats (pre-Statcast era) → return null

#### 2.7.3 Frontend Visualization

**React Component: `<PercentileProfile>`**
- [ ] Horizontal bar chart rendered with HTML/CSS (fast, interactive)
- [ ] Color gradient: Blue (1st) → Gray (50th) → Red (99th)
  - Use continuous gradient or discrete color steps
  - Invert for "lower is better" stats (K%, Chase%)
- [ ] Interactive features:
  - Hover: Show exact value, percentile, and qualified status
  - Click: Expand to see historical trend
  - Smooth CSS animations on render
  
**Visual Indicators:**
- [ ] Asterisk (*) next to stat name for below PA minimum
- [ ] Faded/dashed bar for non-qualified percentiles
- [ ] Tooltip on hover: "Minimum 502 PA for official ranking (has 387 PA)"
- [ ] Badge for elite (90+) or concerning (<10) percentiles

**Stat Categories:**
- [ ] Group by category with headers:
  - Power (barrel%, ISO, HR rate, exit velo)
  - Plate Discipline (BB%, K%, Chase%, Whiff%)
  - Contact (Contact%, Hard Hit%)
  - Speed (Sprint Speed, Bolts)
  - Overall (wRC+, WAR rate)
- [ ] Collapsible sections for mobile
- [ ] "Inverse" stats (K%, Chase%) where lower is better:
  - Display as "better than X%" instead of raw percentile
  - Flip color gradient (red for low, blue for high)

**Display Modes:**
- [ ] Single player profile (stacked bars with categories)
- [ ] Two-player comparison (side-by-side, highlight differences)
- [ ] Historical view (optional: sparkline of percentile over career)

#### 2.7.4 LLM Integration

**Smart Triggering:**
LLM automatically calls percentile tool for:
- [ ] "Tell me about [player]" queries
- [ ] "Compare [player1] and [player2]"
- [ ] "Show me [player]'s strengths and weaknesses"
- [ ] "What are [player]'s best skills?"
- [ ] "Is [player] elite at [skill]?"

**Narrative Integration:**
- [ ] LLM highlights elite skills (≥90th percentile) in response
  - "Betts ranks in the 92nd percentile for barrel rate, demonstrating elite power..."
- [ ] Notes significant weaknesses (≤30th percentile)
  - "However, his chase rate is concerning at the 28th percentile..."
- [ ] Contextualizes comparisons:
  - "While both are elite hitters, Trout has significantly better plate discipline (95th vs 78th percentile in BB%)"
- [ ] References scope appropriately:
  - Career percentiles for all-time comparisons
  - Season percentiles for current form
  - Peak7 for prime comparisons

**Tool Response Format:**
```json
{
  "player": "Mookie Betts",
  "year": 2024,
  "scope": "season",
  "qualified": true,
  "pa": 609,
  "min_pa": 502,
  "percentiles": [
    {
      "stat": "barrel_pct",
      "display_name": "Barrel %",
      "category": "Power",
      "value": 14.2,
      "percentile": 92,
      "color": "#ef4444",
      "inverse": false
    },
    {
      "stat": "k_pct",
      "display_name": "K%",
      "category": "Plate Discipline",
      "value": 15.8,
      "percentile": 12,
      "better_than": 88,
      "color": "#ef4444",
      "inverse": true
    }
  ]
}
```

#### 2.7.5 Acceptance Criteria

**Must Have:**
- [ ] User asks "Tell me about Mookie Betts"
- [ ] System returns narrative summary + percentile visualization
- [ ] Shows 8-12 key stats grouped by category
- [ ] Color-coded bars with hover tooltips
- [ ] Percentiles accurate to within ±1 percentile point
- [ ] Sub-minimum PA players shown with asterisk/faded bar
- [ ] "Inverse" stats (K%, Chase%) displayed correctly

**Nice to Have:**
- [ ] Smooth animations on bar rendering
- [ ] Export percentile chart as PNG/SVG
- [ ] Historical sparkline (percentile trend over past 3-5 years)
- [ ] Position-adjusted percentiles (compare SS to SS pool, not all players)
- [ ] Configurable stat selection (user picks which stats to show)

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

### 2. **Grades Calculated in R ETL** ⭐ REVISED
**Current Implementation (Phase 1.1):**
- Grades calculated using era-adjusted "plus" stats (e.g., `iso_plus`, `avg_plus` where 100 = league average)
- Uses standard deviation thresholds
- Works but has limitations (assumes normal distribution, arbitrary thresholds)

**Future Implementation (Phase 2.7.1):**
- **Percentile-first approach**: Calculate percentiles, then map to 20-80 grades
- Grade mapping based on scouting scale conventions:
  - 80 (Elite) = 99th percentile
  - 70 (Plus-Plus) = 90th percentile
  - 60 (Plus) = 75th percentile
  - 50 (Average) = 50th percentile (median)
  - 40 (Fringe) = 25th percentile
  - 30 (Poor) = 10th percentile
  - 20 (Very Poor) = 1st percentile

**Rationale for Percentile-Based Grades:**
- Empirically accurate (60 grade = actually top 25% of qualified players)
- Works for non-normal distributions (HR, SB are skewed)
- Era-neutral by definition
- Single calculation used for both grades AND visualization
- Self-validating (grade distribution must match percentile targets)

**Migration Path:**
- Current grades remain functional for MVP
- Percentile calculation added in Phase 2.7.1
- Grades recalculated from percentiles in same phase
- Both percentiles and grades stored in `fg_season_stats`

**Benefits:**
- Grade distribution validation during ETL (should see ~10% with 70+ grades)
- SQL queries like `WHERE power_grade >= 70` still work
- No runtime grade calculation overhead
- Single calculation, used everywhere (embeddings, tools, UI, visualization)

### 3. **Hybrid Search (Semantic + Filters)** ⭐ CURRENT
**Rationale:**
- Pure semantic search doesn't respect hard constraints (e.g., "first baseman")
- Combining vector similarity with SQL filters gives best of both worlds
- Leverages indexed grade columns for fast filtering

**Implementation:**
```sql
-- Semantic similarity via pgvector
FROM player_embeddings e
JOIN fg_season_stats s ON e.player_season_id = s.player_season_id
WHERE e.embedding_type = 'season_summary'
  AND s.position ILIKE '%1B%'      -- Hard filter
  AND s.power_grade >= 60           -- Hard filter
  AND s.fielding_grade <= 40        -- Hard filter
ORDER BY e.embedding <=> query_embedding  -- Semantic ranking
```

**Benefits:**
- Respects user constraints (position, grade thresholds, years)
- Uses indexed columns for performance
- Still gets semantic matching on playing style/description
- Natural for LLM tool calling (LLM extracts filters from query)

### 4. **PGVector over ChromaDB**
**Rationale:**
- Single database for structured stats AND vectors
- Enables hybrid queries (filter by year, THEN vector search)
- Better for production scaling
- Mature PostgreSQL ecosystem

**Trade-offs:**
- Slightly more complex setup
- Less "plug-and-play" than specialized vector DBs
- Worth it for query flexibility

### 5. **Ollama over Cloud LLMs**
**Rationale:**
- Fully local, no API costs
- Privacy and data control
- Fast iteration during development
- Good models available (llama3.1, qwen2.5)

**Trade-offs:**
- Requires GPU for decent performance
- Model quality ceiling lower than GPT-4
- Worth it for local-first principle

### 6. **FanGraphs First, Then Baseball Reference**
**Rationale:**
- FanGraphs has clean API via `baseballr`
- Advanced metrics readily available
- Gets us to MVP faster
- BRef provides narrative context later

**Trade-offs:**
- FanGraphs historical coverage less complete
- Missing some biographical richness
- Worth it for rapid prototyping

### 7. **Incremental ETL over Full Refresh**
**Rationale:**
- Preserves manual corrections
- Faster updates
- Less database churn
- Production-ready pattern

**Trade-offs:**
- More complex logic
- Requires conflict handling
- Worth it for data integrity

### 8. **Career Percentiles from Weighted Averages**
**Rationale:**
- Career percentiles calculated from career stat averages, not mean of season percentiles
- Avoids statistical distortion (percentiles don't average linearly)
- Season percentiles: Direct calculation from qualified players each year
- Career percentiles: Weighted career averages → then calculate percentiles
- Peak7 percentiles: Best 7-year rolling window → then calculate percentiles
- Small computational cost (~5-10 seconds during ETL) for statistical accuracy

**Trade-offs:**
- Slightly more complex than averaging season percentiles
- Requires rolling window calculation for Peak7
- Worth it for accurate, defensible percentile rankings

### 9. **Pre-computed Percentiles in Database**
**Rationale:**
- Store percentile thresholds (p1, p5, p10...p99) in database
- Runtime interpolation to find player's percentile (fast)
- Enables instant percentile lookups without recalculation
- Three scopes (season/career/peak7) for different contexts

**Benefits:**
- Sub-millisecond percentile lookups
- Consistent methodology across application
- Easy to update during ETL
- Supports multiple comparison contexts

### 10. **Percentile-Based Grades (Future)** ⭐ MAJOR IMPROVEMENT
**Current State:**
- Grades calculated using plus stats and standard deviations
- Works but has theoretical limitations

**Future State (Phase 2.7.1):**
- Calculate percentiles first, then derive grades
- Two methodologies to evaluate:
  - **Percentile approach**: 70 grade = 90th percentile (10% get 70+)
  - **Standard Deviation approach**: 70 grade = μ + 2σ ≈ 97.7th percentile (2.3% get 70+)
- Store both percentiles and grades in `fg_season_stats`

**Rationale:**
- The 20-80 scale was originally based on standard deviations (50 = mean, ±10 = ±1σ)
- However, many baseball stats are NOT normally distributed:
  - Power stats (HR, ISO, SLG) are right-skewed
  - WAR has a replacement-level floor (skewed right)
  - Contact/average stats are bounded (can't exceed 1.000)
- Percentile approach is distribution-agnostic and more intuitive
- SD approach is theoretically pure but may be too stringent for skewed stats

**Implementation Strategy:**
- Calculate both grade sets during Phase 2.7.1
- Test normality of each stat (Shapiro-Wilk, skewness)
- Evaluate which method produces more accurate/useful grades
- Consider hybrid: SD for normal stats, percentile for skewed stats
- Choose final methodology based on empirical analysis

**Benefits:**
- Empirically accurate: Grades mean what scouts intend
- Can validate against stat distributions
- Single calculation serves dual purpose (grading + visualization)
- Flexible: Can adjust thresholds based on data

**Migration:**
- Current grades remain functional until Phase 2.7.1
- Backward compatible: Grade columns stay, just calculated differently
- Re-run ETL to backfill historical data with percentile-based grades

### 11. **Two-Stage Retrieval (FTS + Reranking)** ⭐ PHASE 2
**Rationale:**
- Single-stage retrieval has fundamental limitations:
  - **Bi-encoders** (current): Fast but can't distinguish opposites, handle negation poorly
  - **Short queries**: Match terse descriptions due to length normalization bias
  - **Structural similarity**: Template uniformity dominates semantic differences

**Solution: Two-stage pipeline**
1. **Stage 1 - Fast Retrieval (FTS or Vector):**
   - Goal: High recall, get 50-100 candidates quickly
   - Short queries (≤4 tokens): Use PostgreSQL FTS (keyword matching)
   - Long queries (>4 tokens): Use vector search (semantic similarity)
   - Apply SQL filters (position, grades, years)
   
2. **Stage 2 - Precise Reranking (Cross-Encoder):**
   - Goal: High precision, score top 10 accurately
   - Cross-encoder sees query + document together
   - Full attention mechanism reasons about relationships
   - Can handle negation, opposites, multi-constraint queries

**Benefits:**
- Solves "all time great" vs "replacement level" confusion
- Handles complex queries: "power WITHOUT speed", "elite defense BUT poor offense"
- Respects exact phrases via FTS
- Best of both worlds: speed + accuracy

**Performance:**
- Stage 1: ~50ms (FTS or vector search)
- Stage 2: ~500ms (rerank 50 candidates)
- Total: <1 second (acceptable UX)

**Trade-offs:**
- More complex architecture (three search methods: FTS, vector, cross-encoder)
- Additional model to load (~80MB cross-encoder)
- Worth it for dramatically better search quality

---

## Database Schema

### Version 1.4 (Planned - Phase 2.7)

#### `stat_percentiles`
Pre-calculated percentile thresholds for fast player ranking across three scopes.

**Key columns:**
- `id` (PK) - Auto-increment
- `stat_name` - Name of statistic (e.g., 'barrel_pct', 'wrc_plus')
- `year` - Season year for 'season' scope, 0 for 'career'/'peak7'
- `scope` - 'season', 'career', or 'peak7'
- `min_pa` - PA minimum used for qualified pool
- `qualified_count` - Number of qualified players in distribution
- Percentile thresholds: `p1`, `p5`, `p10`, `p25`, `p40`, `p50`, `p60`, `p75`, `p90`, `p95`, `p99`
- Summary stats: `mean`, `stddev`, `min_value`, `max_value`

**Calculation methodology:**
- **Season scope**: Percentiles calculated directly from qualified players each year (min 502 PA)
- **Career scope**: Career weighted averages calculated per player (min 3000 PA), then percentiles from those averages
- **Peak7 scope**: Best 7-year rolling window per player (min 3500 PA), then percentiles from peak values

**Grade Calculation (20-80 Scale):**
Grades are derived from percentiles. Two methodologies will be evaluated:

**Method 1: Percentile-Based (Practical Approach)**
```
80 (Elite)         → 99th percentile
75 (Plus-Plus/Elite) → 95th percentile
70 (Plus-Plus)     → 90th percentile
65 (Above Plus)    → 80th percentile
60 (Plus)          → 75th percentile
55 (Above Avg)     → 60th percentile
50 (Average)       → 50th percentile (median)
45 (Below Avg)     → 40th percentile
40 (Fringe)        → 25th percentile
35 (Poor)          → 15th percentile
30 (Poor)          → 10th percentile
25 (Very Poor)     → 5th percentile
20 (Very Poor)     → 1st percentile
```

**Method 2: Standard Deviation-Based (Traditional Scouting Scale)**
The 20-80 scale was originally based on standard deviations from the mean:
```
80 grade = μ + 3σ  → 99.7th percentile (3 SD above mean)
70 grade = μ + 2σ  → 97.7th percentile (2 SD above mean)
60 grade = μ + 1σ  → 84.1th percentile (1 SD above mean)
50 grade = μ       → 50th percentile (mean)
40 grade = μ - 1σ  → 15.9th percentile (1 SD below mean)
30 grade = μ - 2σ  → 2.3rd percentile (2 SD below mean)
20 grade = μ - 3σ  → 0.3rd percentile (3 SD below mean)
```

**Key Differences:**
- **SD approach**: Assumes normal distribution, more stringent (only ~2.3% get 70+ grades)
- **Percentile approach**: Distribution-agnostic, more generous (10% get 70+ grades)
- **Baseball reality**: Many stats are NOT normally distributed (HR, SB are right-skewed; AVG is bounded)

**Implementation Plan:**
- [ ] Calculate grades using both methods during Phase 2.7.1
- [ ] Store both sets of grades temporarily: `power_grade_pct`, `power_grade_sd`
- [ ] Evaluate which approach produces more accurate/useful grades:
  - Check grade distributions (2% vs 10% with 70+ grades)
  - Eye test: Do grades "feel right" for known players?
  - Test normality of each stat (Shapiro-Wilk test)
  - Compare skewness: Power stats (HR, ISO) vs rate stats (BB%, K%)
- [ ] Choose one method (or hybrid: SD for normal stats, percentile for skewed)
- [ ] Document final decision and rationale

**Expected Findings:**
- Power stats (HR, ISO, SLG): Heavily right-skewed → percentile approach more appropriate
- Rate stats (BB%, K%): Closer to normal → SD approach may align well
- WAR: Right-skewed (replacement floor) → percentile approach likely better
- Contact stats (AVG, OBP): Bounded above → percentile approach more robust

This ensures that grades have empirical meaning:
- A 60-grade tool means top 16-25% of qualified players (depending on method)
- A 70-grade tool means top 2-10% of qualified players (depending on method)
- A 50-grade tool means exactly league average (mean or median)

**Indexes:**
- Composite: `(stat_name, year, scope)` for fast lookups
- Single: `stat_name`

**Example row:**
```
stat_name: 'barrel_pct'
year: 2024
scope: 'season'
min_pa: 502
qualified_count: 143
p1: 2.1, p5: 3.4, p10: 4.2, p25: 6.1, p40: 7.2, p50: 8.5, p60: 9.8, p75: 11.2, p90: 13.8, p95: 15.1, p99: 17.9
mean: 8.7, stddev: 3.4
```

---

### Version 1.2 (Current)

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
One row per player per season with batting statistics **and grades**.

**Key columns:**
- `player_season_id` (PK) - Composite key: `{fangraphs_id}_{year}`
- `fangraphs_id` (FK) - Links to players
- `year`, `age`, `team`, `position` - Context
- Basic stats: `g`, `pa`, `ab`, `h`, `hr`, `rbi`, `sb`, etc.
- Rate stats: `avg`, `obp`, `slg`, `ops`, `iso`, `babip`
- Advanced: `wrc_plus`, `war`, `woba`, `bb_pct`, `k_pct`
- Plus stats (era-adjusted): `avg_plus`, `iso_plus`, `bb_pct_plus`, `k_pct_plus`, etc.
- Batted ball: `gb_pct`, `fb_pct`, `ld_pct`, `hard_pct`
- Statcast (2015+): `ev`, `ev90`, `la`, `barrel_pct`, `maxev`
- **Grades (20-80 scale)**: ⭐ CURRENT (Plus-stat based, to be revised in Phase 2.7.1)
  - `overall_grade` - WAR-based
  - `offense_grade` - wRC+ based
  - `power_grade` - ISO+ based
  - `hit_grade` - AVG+ based
  - `discipline_grade` - BB%+ based
  - `contact_grade` - K%+ based
  - `speed_grade` - SB/600PA based
  - `fielding_grade` - Era/position adjusted
  - `hard_contact_grade` - Hard Hit%+ (2015+)
  - `exit_velo_grade` - EV90 (2015+)
- **Percentiles (0-100)**: ⭐ PLANNED (Phase 2.7.1)
  - `overall_percentile` - WAR percentile
  - `offense_percentile` - wRC+ percentile
  - `power_percentile` - ISO percentile
  - `hit_percentile` - AVG percentile
  - `discipline_percentile` - BB% percentile
  - `contact_percentile` - K% percentile (inverse: lower K% = higher percentile)
  - `speed_percentile` - SB/600PA percentile
  - `fielding_percentile` - Fielding percentile
  - `hard_contact_percentile` - Hard Hit% percentile (2015+)
  - `exit_velo_percentile` - EV90 percentile (2015+)

**Indexes:**
- `fangraphs_id`, `year`, `war DESC`, `wrc_plus DESC`, `position`
- **Grade indexes**: `overall_grade`, `power_grade`, `hit_grade`, `fielding_grade`
- **Percentile indexes** (Phase 2.7.1): `overall_percentile`, `power_percentile`, `hit_percentile`, `fielding_percentile`

#### `fg_batter_pitches_faced`
Pitch-level data for what batters faced (optional, very granular).

**Key columns:**
- `player_season_id` (PK, FK)
- PITCHf/x data: pitch types, velocities, movement
- PITCHInfo data: alternative classification system
- Plate discipline vs pitch types

#### `player_embeddings`
Vector embeddings for semantic search of player seasons.

**Key columns:**
- `id` (PK) - Auto-increment
- `player_season_id` - Links to season_stats
- `fangraphs_id` (FK) - Links to players
- `year` - Season year
- `embedding_type` - 'season_summary', 'career_summary', 'pitch_profile'
- `summary_text` - Natural language description that was embedded
- `summary_tsv` - tsvector for full-text search (Phase 2.1)
- `embedding` - 768-dimensional vector (all-mpnet-base-v2)
- `metadata` - JSONB with key stats for filtering

**Indexes:**
- HNSW index on embedding vector
- GIN index on summary_tsv (Phase 2.1)
- Indexes on type, player, year
- GIN index on metadata JSONB

#### Future Tables
- ~~`player_embeddings`~~ ✅ COMPLETE - Vector embeddings for semantic search
- `stat_percentiles` - Pre-calculated percentile distributions (Phase 2.7)
- `fg_pitcher_stats` - Pitcher statistics
- `bref_players` - Baseball Reference biographical data
- `statcast_metrics` - Aggregated Statcast data

---

## Development Workflow

### Current Phase Checklist

**Phase 1.3: LLM Integration ✅ COMPLETE**
1. ✅ Install and configure Ollama locally
2. ✅ Choose model (llama3.1:8b or qwen2.5:14b)
3. ✅ Create tool definitions:
   - ✅ `search_similar_players()` - wraps hybrid search
   - ✅ `get_player_stats()` - fetch specific season
   - ✅ `compare_players()` - side-by-side comparison
   - ✅ `get_career_summary()` - career aggregates
4. ✅ Implement tool calling loop
5. ✅ Test with example queries

**Phase 1.4: Backend API (Current)**
1. Set up Express/Fastify server
2. Implement `/chat` endpoint with streaming responses
3. Configure PostgreSQL connection pooling
4. Add error handling and logging
5. Integrate Ollama with TypeScript backend

### Running the Project (Current State)

#### Prerequisites
- Docker Desktop (for PostgreSQL)
- R 4.x+ with packages: `baseballr`, `DBI`, `RPostgres`, `dplyr`
- Node.js 18+ (for TypeScript backend and embedding system)
- Ollama (for local LLM)

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

# This will:
# - Pull FanGraphs data (1988-2025)
# - Calculate grades (20-80 scale)
# - Validate grade distributions
# - Load to Postgres with upsert
```

#### Generate Embeddings
```bash
cd embeddings
npm install
npm run build     # Compile TypeScript
npm run generate  # Generates embeddings for all seasons (~15-20 minutes)
```

#### Test Hybrid Search
```bash
# Basic semantic search
npm start test "elite power hitter"

# Hybrid search with filters
npm start hybrid "slugging first baseman" --position=1B --minPowerGrade=60 --maxFieldingGrade=40
npm start hybrid "defensive wizard" --position=SS --minFieldingGrade=70
npm start hybrid "five tool player" --minOverallGrade=60 --minPowerGrade=60 --minFieldingGrade=60
```

#### Run LLM Chat (Phase 1.3)
```bash
cd backend
npm install
npm run dev  # Start the chat interface

# Example queries:
# - "Compare Mike Trout and Ken Griffey Jr"
# - "Tell me about Mookie Betts' 2024 season"
# - "Find power hitters with elite defense"
```

#### Verify Data
```bash
psql -h localhost -U postgres -d postgres

# Check record counts
SELECT COUNT(*) FROM fg_players;
SELECT COUNT(*) FROM fg_season_stats;
SELECT COUNT(*) FROM player_embeddings;

# Top players by WAR
SELECT * FROM fg_career_stats ORDER BY total_war DESC LIMIT 10;

# Test grade filtering
SELECT player_name, year, war, overall_grade, power_grade
FROM fg_season_stats s
JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
WHERE power_grade >= 70
ORDER BY power_grade DESC, war DESC
LIMIT 10;
```

---

## Performance Considerations

### Database
- Indexes on all foreign keys
- Composite indexes on common query patterns
- HNSW index on vector embeddings (fast similarity search)
- GIN index on tsvector for full-text search (Phase 2.1)
- Connection pooling in application

### Embeddings
- Batch generation (100-500 at a time)
- Cache embeddings, regenerate only on data changes
- Consider quantization for production

### Search (Phase 2)
- FTS queries: ~10-50ms (GIN index)
- Vector queries: ~50-100ms (HNSW index)
- Cross-encoder reranking: ~10ms per candidate, ~500ms for 50 candidates
- Total two-stage retrieval: <1 second

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
- Validate percentile distributions (Phase 2.7)
- Test grade calculation methodologies (Phase 2.7)

### Embedding Quality
- Manual review of similar player results
- Test queries with known similar players
- Measure retrieval precision/recall

### Search Quality (Phase 2)
- Test FTS with short queries ("all time great")
- Test semantic search with long queries ("power hitter with plate discipline")
- Test reranking improvement (before/after comparison)
- Test negation handling ("power WITHOUT speed")
- Test opposite distinction ("all time great" vs "replacement level")

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
- PostgreSQL FTS scales to millions of documents
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

### Phase 1.1 (ETL)
1. **FanGraphs API behavior:** Doesn't handle multi-year requests well, required year-by-year iteration
2. **Schema evolution:** Pitch tracking data format changed over time (simple velocities vs. PITCHf/x)
3. **Upsert strategy:** Critical for incremental updates without data loss
4. **Column naming:** FanGraphs uses special characters (`%`, `+`, `-`) requiring careful cleaning

### Phase 1.2 (Embeddings & Search)
5. **Grade calculation in R is superior:** Statistical validation, single source of truth, enables SQL filtering
6. **Template-based summaries work well:** Consistent, fast, good semantic matching without LLM overhead
7. **Hybrid search is essential:** Pure semantic search doesn't respect hard constraints (position, grade thresholds)
8. **Join to stats table, don't use JSONB metadata:** Leverages indexes, faster, type-safe
9. **Position descriptions matter:** "at catcher" vs "catcher" affects embedding quality
10. **Grade distribution validation catches errors:** Immediately see if grading thresholds are wrong
11. **Length normalization bias in semantic search:** Sparse embeddings (short descriptions) match sparse queries better than dense embeddings (long descriptions), even when semantically opposite. Short queries should use FTS instead of vector search.
12. **Query-document asymmetry:** Short queries (3-5 tokens) embed poorly against long documents (50+ tokens) due to structural mismatch. Solutions: FTS for short queries, LLM query expansion for medium queries, semantic search only for detailed queries.
13. **Bi-encoders can't distinguish opposites:** Embedding models measure distributional similarity (words appearing in similar contexts), NOT logical meaning. "All-time great season" and "replacement level season" appear similar because they share sentence structure. Cross-encoder reranking solves this by encoding query+document together.
14. **"Semantic search" is a misnomer:** The term implies understanding of meaning, but embeddings actually measure contextual/distributional similarity. They excel at clustering concepts expressed with different vocabulary, but fail at logical operations (negation, contradiction, opposites). This is why "all time great" matches "replacement level" - they appear in similar sentence structures.
15. **Modular TypeScript structure improves maintainability:** Refactored embedding system from single 895-line file into 18 organized modules. Each interface in its own file, clear separation of concerns (types, constants, config, utils, services, commands). Dramatically easier to navigate, test, and extend. Follow industry best practices: single responsibility, separation of concerns, dependency injection.

### Phase 1.3 (LLM Integration) - Complete
16. **Tool function parameter ordering matters:** Encountered issues where LLM-provided parameter order didn't match function definitions, but no clear OpenAI function calling spec for parameter ordering found. May need explicit parameter validation.
17. **LLM prompt engineering is iterative:** Initial prompts work but need refinement for better stat formatting and presentation to user.
18. **Scouting grade qualitative descriptors needed:** LLM tends to copy/paste examples from system prompt even when not perfectly applicable. Need better grade-to-description mappings.
19. **Career aggregations should use database views:** Currently aggregating season stats in code for `get_career_summary()`. Should leverage `fg_career_stats` view for consistency and performance.
20. **Search filter parameter extraction is fragile:** LLM doesn't always extract filters correctly from natural language queries (e.g., "similar players with power" not triggering power filter). May need more explicit prompt guidance or examples.

### Phase 2.7 (Percentile Rankings) - Future
21. **Career percentiles from averages, not mean of percentiles:** Statistically sound, avoids non-linear distortion
22. **Three scopes serve different purposes:** Season (current), Career (all-time), Peak7 (prime comparison)
23. **Percentile-first grade calculation is superior:** Industry-standard scouting scale mapping, empirically accurate, works for any distribution, self-validating
24. **Store both percentiles and grades:** Percentiles for exact visualization, grades for scouting-style filtering and descriptions
25. **SD vs Percentile debate:** Test both approaches empirically - SD (μ±σ) is theoretically pure but assumes normality, percentile approach is distribution-agnostic but deviates from scouting origins. Baseball stats are often skewed, so validate which works better in practice.

### Phase 2 (Enhanced Retrieval) - Future
26. **Two-stage retrieval is industry standard:** Separate retrieval (recall-focused) from ranking (precision-focused) for best results
27. **FTS + Vector + Reranking complement each other:** FTS for short/exact queries, vector for semantic similarity, cross-encoder for final precision
28. **Keyword extraction matters:** Baseball-specific phrase detection (positions, qualities) significantly improves FTS accuracy
29. **Query routing reduces latency:** Short queries to FTS (<50ms), long queries to vector (~100ms), reranking only top candidates (~500ms)

---

## Contact & Resources

### Documentation
- FanGraphs schema: `fangraphs_schema.sql` (v1.2, will become v1.4 in Phase 2.7)
- ETL script: `batter_leaderboard_etl.r`
- Embedding system: `embeddings/src/` (modular TypeScript architecture)
- Project spec: This document

### Key Files
```
baseball-rag/
├── fangraphs_schema.sql         # Database schema v1.2
├── batter_leaderboard_etl.r     # R ETL with grade calculation
├── embeddings/                  # TypeScript embedding system (refactored)
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── index.ts             # CLI entry point
│       ├── types/               # TypeScript interfaces
│       │   ├── SeasonStats.ts
│       │   ├── PlayerGrades.ts
│       │   ├── EmbeddingRecord.ts
│       │   ├── SearchFilters.ts
│       │   └── index.ts         # Type barrel export
│       ├── constants/
│       │   └── grading.ts       # Grade descriptors (20-80 scale)
│       ├── config/
│       │   └── database.ts      # PostgreSQL pool & table verification
│       ├── utils/
│       │   ├── position.ts      # Position helpers & fielding descriptions
│       │   ├── grading.ts       # Grade calculation & WAR/wRC+ descriptions
│       │   └── text.ts          # Text utilities
│       ├── services/
│       │   ├── embedding.ts     # Transformers.js model & generation
│       │   ├── database.ts      # DB queries (fetch seasons, save embeddings)
│       │   └── summary.ts       # Season summary generation
│       └── commands/
│           ├── generate.ts      # Generate all embeddings
│           ├── test.ts          # Test similarity search
│           ├── hybrid.ts        # Hybrid search with filters
│           └── sample.ts        # Generate sample summaries
├── backend/                     # TypeScript backend with LLM integration
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── index.ts             # CLI entry point
│       ├── types/
│       │   └── index.ts         # Interface types
│       ├── services/
│       │   ├── chat.ts          # LLM orchestration & tool calling
│       │   ├── ollama.ts        # Ollama API client
│       │   └── embedding.ts     # Embedding service
│       └── tools/
│           ├── index.ts         # Tool definitions export
│           ├── definitions.ts   # tool definitions
│           ├── search.ts        # search_similar_players tool
│           ├── player-stats.ts  # get_player_stats & get_career_summary tools
│           └── compare.ts       # compare_players tool (future)
└── README.md                    # This document (v1.4)
```

### External Resources
- baseballr: https://billpetti.github.io/baseballr/
- FanGraphs: https://www.fangraphs.com/
- PGVector: https://github.com/pgvector/pgvector
- Ollama: https://ollama.ai/
- transformers.js: https://huggingface.co/docs/transformers.js
- PostgreSQL Full-Text Search: https://www.postgresql.org/docs/current/textsearch.html
- Cross-Encoders: https://www.sbert.net/examples/applications/cross-encoder/README.html

---

**Next Step:** Install Ollama and implement tool calling for LLM integration (Phase 1.3)