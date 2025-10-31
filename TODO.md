# Baseball RAG - Detailed TODO List

**Last Updated:** December 2024  
**Current Focus:** New Priority Features

---

## 🎯 Current Priorities (Next 4 Features)

### 1. Lahman Database Integration
**Status:** High Priority  
**Goal:** Use Lahman database as biographical foundation, avoiding scraping issues

*See detailed implementation plan in TODO_LAHMAN_INTEGRATION.md*

- [x] Create Lahman ETL script and schema
- [ ] Import Lahman database (1871-present)
- [ ] Create unified player profiles view
- [ ] Add biographical lookup tools to backend
- [ ] Link Lahman playerID to FanGraphs data
- [ ] Add awards, honors, and career context

### 2. Conversation Memory
**Status:** High Priority  
**Goal:** Multi-turn conversations with context awareness

*See detailed implementation plan in TODO_CONVERSATION_MEMORY.md*

- [ ] Design conversation storage schema
- [ ] Implement conversation context management
- [ ] Add follow-up question handling
- [ ] Create conversation history UI
- [ ] Add conversation persistence
- [ ] Implement context-aware tool calling

### 3. Tool Enhancements
**Status:** High Priority  
**Goal:** Improve existing tools and add new capabilities

*See detailed implementation plan in TODO_TOOL_ENHANCEMENTS.md*

- [ ] Fix search filter parameter extraction
- [ ] Improve career summary aggregations
- [ ] Add new specialized tools
- [ ] Enhance tool error handling
- [ ] Optimize tool performance
- [ ] Add tool result caching

### 4. Percentile Rankings & Visualization
**Status:** High Priority  
**Goal:** Visual player profiles with percentile rankings

*See detailed implementation plan in TODO_PERCENTILE_VISUALIZATION.md*

- [ ] Migrate to percentile-based grade calculation
- [ ] Create percentile calculation infrastructure
- [ ] Add percentile tools for LLM
- [ ] Build React percentile visualization components
- [ ] Integrate with chat interface
- [ ] Add interactive percentile profiles

---

## 🔄 Deferred: Enhanced Retrieval (Phase 2)

### 2.1 Full-Text Search Infrastructure
- [ ] Add PostgreSQL FTS infrastructure to `player_embeddings` table
  - [ ] Add `summary_tsv` tsvector column 
  - [ ] Create GIN index on `summary_tsv`
  - [ ] Create trigger to auto-update tsvector on insert/update
  - [ ] Populate existing rows with tsvectors
  - [ ] Test FTS query performance vs vector search

- [ ] Implement keyword extraction in backend
  - [ ] Baseball-specific phrase detection (positions, qualities)
  - [ ] NLP-based noun phrase extraction using `compromise`
  - [ ] Pattern matching for common query types
  - [ ] Convert keywords to PostgreSQL tsquery format
  - [ ] Add unit tests for keyword extraction

- [ ] Implement query router logic
  - [ ] Route queries ≤4 tokens to FTS (keyword matching)
  - [ ] Route queries >4 tokens to semantic search (vector similarity)
  - [ ] Hybrid mode: combine FTS + vector for medium queries
  - [ ] Add configuration for token thresholds
  - [ ] Log routing decisions for analysis

### 2.2 Cross-Encoder Reranking
- [ ] Add cross-encoder model integration
  - [ ] Load `cross-encoder/ms-marco-MiniLM-L-6-v2` via transformers.js
  - [ ] Implement batch processing for performance (32 candidates at a time)
  - [ ] Cache model in memory after first load
  - [ ] Add model warmup on server startup
  - [ ] Handle model loading errors gracefully

- [ ] Implement two-stage retrieval pipeline
  - [ ] **Stage 1**: Fast retrieval (50-100 candidates)
    - [ ] Use FTS for short queries
    - [ ] Use vector search for long queries  
    - [ ] Apply SQL filters (position, grades, years)
  - [ ] **Stage 2**: Precise reranking (top 10)
    - [ ] Score each candidate with cross-encoder
    - [ ] Sort by rerank score, return top K
    - [ ] Add timing metrics for each stage
  - [ ] Add fallback to single-stage if reranking fails

- [ ] Performance optimization
  - [ ] Target <1 second total retrieval time
  - [ ] Stage 1 retrieval: ~50ms
  - [ ] Stage 2 reranking (50 candidates): ~500ms
  - [ ] Add caching for identical queries
  - [ ] Monitor and log performance metrics

### 2.3 Query Quality Evaluation
- [ ] Create test query dataset
  - [ ] Short queries: "all time great", "replacement level"
  - [ ] Negation queries: "power WITHOUT speed"
  - [ ] Multi-constraint: "elite defense BUT poor offense"
  - [ ] Baseball terminology: "five tool player", "contact hitter"
  - [ ] Position-specific: "slugging first baseman"

- [ ] Benchmark search methods
  - [ ] Current single-stage semantic search
  - [ ] FTS-only approach
  - [ ] Two-stage with reranking
  - [ ] Measure precision@10, recall@10
  - [ ] Manual evaluation of result quality

- [ ] A/B testing framework
  - [ ] Route percentage of queries to new system
  - [ ] Collect user feedback on result quality
  - [ ] Compare response times
  - [ ] Gradual rollout based on performance

---

## 🔧 Phase 1 Improvements (Technical Debt)

### Backend Issues
- [ ] Fix similar players search filters not working correctly
  - [ ] Debug parameter extraction from LLM queries
  - [ ] Add validation for filter parameters
  - [ ] Improve error messages for invalid filters
  - [ ] Add integration tests for filter combinations

- [ ] Resolve tool function parameter ordering issues
  - [ ] Research OpenAI function calling parameter specification
  - [ ] Add explicit parameter validation in tool functions
  - [ ] Improve error handling for malformed tool calls
  - [ ] Document expected parameter formats

- [ ] Optimize career summary tool
  - [ ] Use `fg_career_stats` view instead of aggregating in code
  - [ ] Add caching for frequently requested players
  - [ ] Improve performance for players with many seasons
  - [ ] Add career highlights detection

- [ ] Improve LLM prompt engineering
  - [ ] Better stat formatting and presentation
  - [ ] Add scouting grade qualitative descriptors
  - [ ] Reduce copy/pasting of examples in responses
  - [ ] Add context-aware response templates

### Database Optimizations
- [ ] Add missing indexes for common query patterns
  - [ ] Composite indexes for multi-column filters
  - [ ] Partial indexes for qualified players (PA >= 502)
  - [ ] Index on player name for faster lookups

- [ ] Optimize hybrid search query performance
  - [ ] Analyze query execution plans
  - [ ] Consider materialized views for common aggregations
  - [ ] Add query result caching
  - [ ] Monitor slow query log

### Frontend Enhancements
- [ ] Add citations display for tool results
  - [ ] Show which database queries were used
  - [ ] Link to original data sources
  - [ ] Display confidence scores for search results

- [ ] Improve error handling and user feedback
  - [ ] Better error messages for common failures
  - [ ] Retry mechanisms for failed requests
  - [ ] Offline detection and graceful degradation

- [ ] Optional UI improvements
  - [ ] Copy message button
  - [ ] Dark mode toggle
  - [ ] Message search within conversation

---

## 📋 Future Features

### Data Expansion
- [ ] Statcast data integration
  - [ ] Pitch-level data (2015+)
  - [ ] Exit velocity, launch angle, barrel rate
  - [ ] Sprint speed, defensive metrics
  - [ ] Season-level aggregations

- [ ] Pitcher data pipeline
  - [ ] FanGraphs pitcher leaderboards
  - [ ] Pitching grades and advanced metrics
  - [ ] Pitcher comparison tools
  - [ ] Pitch mix and arsenal analysis

### Advanced Features
- [ ] R visualization integration
  - [ ] Trigger R scripts from TypeScript backend
  - [ ] Career trajectory charts
  - [ ] Batted ball heat maps
  - [ ] WAR component breakdowns
  - [ ] Interactive charts in frontend

- [ ] Team analytics
  - [ ] Team-level statistics and roster analysis
  - [ ] Historical team comparisons
  - [ ] Roster construction insights

---

## 🚀 Infrastructure & DevOps

### Production Readiness
- [ ] Docker optimization
  - [ ] Multi-stage builds for smaller images
  - [ ] Health checks for all services
  - [ ] Resource limits and monitoring
  - [ ] Automated backup procedures

- [ ] Monitoring and observability
  - [ ] Prometheus metrics collection
  - [ ] Grafana dashboards for performance
  - [ ] Error tracking and alerting
  - [ ] Database performance monitoring

- [ ] Security improvements
  - [ ] API rate limiting
  - [ ] Input validation and sanitization
  - [ ] Database connection security
  - [ ] HTTPS/TLS configuration

### Development Experience
- [ ] Testing infrastructure
  - [ ] Unit tests for all components
  - [ ] Integration tests for API endpoints
  - [ ] End-to-end tests for user workflows
  - [ ] Performance regression tests

- [ ] CI/CD pipeline
  - [ ] Automated testing on pull requests
  - [ ] Automated deployment to staging
  - [ ] Database migration automation
  - [ ] Rollback procedures

- [ ] Documentation improvements
  - [ ] API documentation with OpenAPI/Swagger
  - [ ] Architecture decision records (ADRs)
  - [ ] Deployment and operations guide
  - [ ] Troubleshooting runbooks

---

## 🐛 Known Issues & Bug Fixes

### High Priority
- [ ] **Search filter parameters not extracted correctly from LLM queries**
  - Impact: Users can't effectively filter search results
  - Root cause: LLM prompt needs better examples and structure
  - Fix: Improve prompt engineering and add parameter validation

- [ ] **Tool execution timeout handling**
  - Impact: Long-running queries can hang the interface
  - Root cause: No timeout mechanism for tool execution
  - Fix: Add configurable timeouts and graceful error handling

### Medium Priority  
- [ ] **Grade distribution validation warnings in ETL**
  - Impact: Potential data quality issues
  - Root cause: Grade calculation thresholds may need adjustment
  - Fix: Review grade calculation methodology and thresholds

- [ ] **Streaming response buffering inconsistencies**
  - Impact: Occasional choppy text display
  - Root cause: Buffer timing edge cases
  - Fix: Improve buffer management logic

### Low Priority
- [ ] **Frontend bundle size optimization**
  - Impact: Slower initial page load (~500KB)
  - Root cause: Material UI and dependencies
  - Fix: Code splitting and tree shaking optimization

- [ ] **Database connection pool warnings**
  - Impact: Occasional connection exhaustion under load
  - Root cause: Pool size configuration
  - Fix: Tune pool parameters and add monitoring

---

## 📊 Success Metrics

### Current Priority Goals
- [ ] **Baseball Reference Integration**: Complete biographical data for top 1000 players
- [ ] **Conversation Memory**: Support 5+ turn conversations with context
- [ ] **Tool Enhancements**: >95% successful tool parameter extraction
- [ ] **Percentile Visualization**: Interactive profiles for all qualified seasons

### Technical Metrics
- [ ] **Database Performance**: <100ms for hybrid search queries
- [ ] **API Response Time**: <2 seconds for complex tool chains
- [ ] **Frontend Performance**: <3 seconds for initial page load
- [ ] **System Reliability**: >99% uptime for core functionality

---

**Note:** This TODO list is actively maintained. Completed items are moved to the "Lessons Learned" section in PROJECT_PLAN.md.