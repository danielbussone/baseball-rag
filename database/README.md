# Database Schema & Configuration

PostgreSQL database with pgvector extension for storing baseball statistics, player information, and semantic embeddings.

## Overview

- **Database**: PostgreSQL 16+
- **Extensions**: pgvector for vector storage and similarity search
- **Schema Version**: 1.2 (current), 1.4 (planned for Phase 2.7)
- **Data Coverage**: 1988-2025 FanGraphs batting statistics
- **Records**: ~50,000 player-seasons, ~15,000 unique players

## Quick Start

### Docker Setup (Recommended)
```bash
# Start PostgreSQL with pgvector
docker run -d \
  --name baseball-postgres \
  -e POSTGRES_PASSWORD=baseball123 \
  -p 5432:5432 \
  -v baseball-data:/var/lib/postgresql/data \
  pgvector/pgvector:pg16

# Create schema
psql -h localhost -U postgres -d postgres -f fangraphs_schema.sql
```

### Manual Setup
```bash
# Install PostgreSQL 16+
brew install postgresql@16  # macOS
sudo apt install postgresql-16  # Ubuntu

# Install pgvector extension
git clone https://github.com/pgvector/pgvector.git
cd pgvector
make && sudo make install

# Create database and extension
createdb baseball
psql -d baseball -c "CREATE EXTENSION vector;"
```

## Schema Overview

### Current Schema (v1.2)

#### Core Tables

**`fg_players`** - Player dimension table
```sql
CREATE TABLE fg_players (
    fangraphs_id INTEGER PRIMARY KEY,
    mlbam_id INTEGER,
    player_name VARCHAR(100) NOT NULL,
    bats CHAR(1),  -- L/R/S
    first_season INTEGER,
    last_season INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**`fg_season_stats`** - Season-level batting statistics with grades
```sql
CREATE TABLE fg_season_stats (
    player_season_id VARCHAR(50) PRIMARY KEY,  -- {fangraphs_id}_{year}
    fangraphs_id INTEGER REFERENCES fg_players(fangraphs_id),
    year INTEGER NOT NULL,
    age INTEGER,
    team VARCHAR(10),
    position VARCHAR(20),
    
    -- Basic stats
    g INTEGER, pa INTEGER, ab INTEGER, h INTEGER, hr INTEGER,
    rbi INTEGER, sb INTEGER, cs INTEGER, bb INTEGER, so INTEGER,
    
    -- Rate stats  
    avg NUMERIC(5,3), obp NUMERIC(5,3), slg NUMERIC(5,3),
    ops NUMERIC(5,3), iso NUMERIC(5,3), babip NUMERIC(5,3),
    
    -- Advanced metrics
    wrc_plus INTEGER, war NUMERIC(4,1), woba NUMERIC(5,3),
    bb_pct NUMERIC(4,1), k_pct NUMERIC(4,1),
    
    -- Batted ball data
    gb_pct NUMERIC(4,1), fb_pct NUMERIC(4,1), ld_pct NUMERIC(4,1),
    hard_pct NUMERIC(4,1),
    
    -- Statcast (2015+)
    ev NUMERIC(4,1), ev90 NUMERIC(4,1), la NUMERIC(3,1),
    barrel_pct NUMERIC(4,1), maxev NUMERIC(4,1),
    
    -- Scouting grades (20-80 scale)
    overall_grade INTEGER,
    offense_grade INTEGER,
    power_grade INTEGER,
    hit_grade INTEGER,
    discipline_grade INTEGER,
    contact_grade INTEGER,
    speed_grade INTEGER,
    fielding_grade INTEGER,
    hard_contact_grade INTEGER,  -- 2015+
    exit_velo_grade INTEGER,     -- 2015+
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**`player_embeddings`** - Vector embeddings for semantic search
```sql
CREATE TABLE player_embeddings (
    id SERIAL PRIMARY KEY,
    player_season_id VARCHAR(50) REFERENCES fg_season_stats(player_season_id),
    fangraphs_id INTEGER REFERENCES fg_players(fangraphs_id),
    year INTEGER NOT NULL,
    embedding_type VARCHAR(50) NOT NULL,  -- 'season_summary'
    summary_text TEXT NOT NULL,
    embedding vector(768) NOT NULL,  -- all-mpnet-base-v2 embeddings
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### Views

**`fg_career_stats`** - Career aggregations
```sql
CREATE VIEW fg_career_stats AS
SELECT 
    p.fangraphs_id,
    p.player_name,
    COUNT(*) as seasons,
    MIN(s.year) as first_year,
    MAX(s.year) as last_year,
    SUM(s.pa) as total_pa,
    SUM(s.h) as total_h,
    SUM(s.hr) as total_hr,
    SUM(s.rbi) as total_rbi,
    SUM(s.sb) as total_sb,
    SUM(s.war) as total_war,
    -- Weighted averages
    ROUND(SUM(s.h * s.pa) / NULLIF(SUM(s.pa), 0), 3) as career_avg,
    ROUND(SUM(s.wrc_plus * s.pa) / NULLIF(SUM(s.pa), 0), 0) as career_wrc_plus
FROM fg_players p
JOIN fg_season_stats s ON p.fangraphs_id = s.fangraphs_id
WHERE s.pa >= 50  -- Minimum PA threshold
GROUP BY p.fangraphs_id, p.player_name;
```

### Indexes

#### Performance Indexes
```sql
-- Primary lookups
CREATE INDEX idx_season_stats_player_year ON fg_season_stats(fangraphs_id, year);
CREATE INDEX idx_season_stats_year ON fg_season_stats(year);
CREATE INDEX idx_season_stats_position ON fg_season_stats(position);

-- Grade filtering (for hybrid search)
CREATE INDEX idx_season_stats_overall_grade ON fg_season_stats(overall_grade);
CREATE INDEX idx_season_stats_power_grade ON fg_season_stats(power_grade);
CREATE INDEX idx_season_stats_hit_grade ON fg_season_stats(hit_grade);
CREATE INDEX idx_season_stats_fielding_grade ON fg_season_stats(fielding_grade);

-- Statistical sorting
CREATE INDEX idx_season_stats_war ON fg_season_stats(war DESC);
CREATE INDEX idx_season_stats_wrc_plus ON fg_season_stats(wrc_plus DESC);

-- Embedding search
CREATE INDEX ON player_embeddings USING hnsw (embedding vector_cosine_ops);
CREATE INDEX idx_embeddings_type_year ON player_embeddings(embedding_type, year);
CREATE INDEX idx_embeddings_player ON player_embeddings(fangraphs_id, year);
```

## Planned Schema (v1.4 - Phase 2.7)

### New Tables

**`stat_percentiles`** - Pre-calculated percentile distributions
```sql
CREATE TABLE stat_percentiles (
    id SERIAL PRIMARY KEY,
    stat_name VARCHAR(50) NOT NULL,  -- 'barrel_pct', 'wrc_plus', etc.
    year INTEGER NOT NULL,           -- Season year, 0 for career/peak7
    scope VARCHAR(20) NOT NULL,      -- 'season', 'career', 'peak7'
    min_pa INTEGER NOT NULL,         -- PA minimum for qualified pool
    qualified_count INTEGER NOT NULL, -- Number of qualified players
    
    -- Percentile thresholds
    p1 NUMERIC(6,3), p5 NUMERIC(6,3), p10 NUMERIC(6,3),
    p25 NUMERIC(6,3), p40 NUMERIC(6,3), p50 NUMERIC(6,3),
    p60 NUMERIC(6,3), p75 NUMERIC(6,3), p90 NUMERIC(6,3),
    p95 NUMERIC(6,3), p99 NUMERIC(6,3),
    
    -- Summary statistics
    mean NUMERIC(6,3), stddev NUMERIC(6,3),
    min_value NUMERIC(6,3), max_value NUMERIC(6,3),
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_percentiles_lookup ON stat_percentiles(stat_name, year, scope);
```

### Enhanced Columns

**Additional percentile columns in `fg_season_stats`:**
```sql
-- Add percentile columns (Phase 2.7.1)
ALTER TABLE fg_season_stats ADD COLUMN overall_percentile NUMERIC(5,2);
ALTER TABLE fg_season_stats ADD COLUMN offense_percentile NUMERIC(5,2);
ALTER TABLE fg_season_stats ADD COLUMN power_percentile NUMERIC(5,2);
ALTER TABLE fg_season_stats ADD COLUMN hit_percentile NUMERIC(5,2);
ALTER TABLE fg_season_stats ADD COLUMN discipline_percentile NUMERIC(5,2);
ALTER TABLE fg_season_stats ADD COLUMN contact_percentile NUMERIC(5,2);
ALTER TABLE fg_season_stats ADD COLUMN speed_percentile NUMERIC(5,2);
ALTER TABLE fg_season_stats ADD COLUMN fielding_percentile NUMERIC(5,2);

-- Index percentile columns for visualization queries
CREATE INDEX idx_season_stats_overall_pct ON fg_season_stats(overall_percentile);
CREATE INDEX idx_season_stats_power_pct ON fg_season_stats(power_percentile);
```

## Data Quality & Validation

### Record Counts (Expected)
```sql
-- Verify data completeness
SELECT 
    'Players' as table_name, 
    COUNT(*) as records,
    MIN(first_season) as earliest_year,
    MAX(last_season) as latest_year
FROM fg_players
UNION ALL
SELECT 
    'Season Stats' as table_name,
    COUNT(*) as records,
    MIN(year) as earliest_year,
    MAX(year) as latest_year  
FROM fg_season_stats
UNION ALL
SELECT 
    'Embeddings' as table_name,
    COUNT(*) as records,
    MIN(year) as earliest_year,
    MAX(year) as latest_year
FROM player_embeddings;
```

### Grade Distribution Validation
```sql
-- Check grade distributions (should be ~10% with 70+ grades)
SELECT 
    grade_range,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as percentage
FROM (
    SELECT 
        CASE 
            WHEN overall_grade >= 80 THEN '80+ (Elite)'
            WHEN overall_grade >= 70 THEN '70-79 (Plus-Plus)'
            WHEN overall_grade >= 60 THEN '60-69 (Plus)'
            WHEN overall_grade >= 50 THEN '50-59 (Average)'
            WHEN overall_grade >= 40 THEN '40-49 (Fringe)'
            WHEN overall_grade >= 30 THEN '30-39 (Poor)'
            ELSE '20-29 (Very Poor)'
        END as grade_range
    FROM fg_season_stats 
    WHERE pa >= 502  -- Qualified seasons only
) grade_dist
GROUP BY grade_range
ORDER BY MIN(CASE 
    WHEN grade_range LIKE '80+%' THEN 80
    WHEN grade_range LIKE '70-%' THEN 70
    WHEN grade_range LIKE '60-%' THEN 60
    WHEN grade_range LIKE '50-%' THEN 50
    WHEN grade_range LIKE '40-%' THEN 40
    WHEN grade_range LIKE '30-%' THEN 30
    ELSE 20
END) DESC;
```

### Statistical Outliers
```sql
-- Find potential data quality issues
SELECT 
    player_name, year, pa, war, wrc_plus,
    CASE 
        WHEN war > 12 THEN 'Extremely high WAR'
        WHEN war < -3 THEN 'Extremely low WAR'
        WHEN wrc_plus > 200 THEN 'Extremely high wRC+'
        WHEN wrc_plus < 50 AND pa > 300 THEN 'Very low wRC+ with high PA'
        ELSE 'Normal'
    END as flag
FROM fg_season_stats s
JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
WHERE war > 12 OR war < -3 OR wrc_plus > 200 OR (wrc_plus < 50 AND pa > 300)
ORDER BY war DESC;
```

## Performance Tuning

### Query Optimization

**Hybrid Search Performance**
```sql
-- Optimized hybrid search query
EXPLAIN ANALYZE
SELECT s.player_season_id, s.year, p.player_name, s.war, s.overall_grade,
       e.embedding <=> $1 as similarity
FROM player_embeddings e
JOIN fg_season_stats s ON e.player_season_id = s.player_season_id  
JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
WHERE e.embedding_type = 'season_summary'
  AND s.position ILIKE '%1B%'      -- Uses index
  AND s.power_grade >= 60          -- Uses index  
  AND s.fielding_grade <= 40       -- Uses index
ORDER BY e.embedding <=> $1        -- Uses HNSW index
LIMIT 10;
```

**Career Aggregation Performance**
```sql
-- Use materialized view for frequently accessed career stats
CREATE MATERIALIZED VIEW fg_career_stats_mv AS
SELECT * FROM fg_career_stats;

CREATE INDEX idx_career_stats_war ON fg_career_stats_mv(total_war DESC);
CREATE INDEX idx_career_stats_name ON fg_career_stats_mv(player_name);

-- Refresh periodically
REFRESH MATERIALIZED VIEW fg_career_stats_mv;
```

### Connection Pooling
```typescript
// Recommended pool configuration
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'baseball123',
  max: 20,          // Maximum connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

## Backup & Maintenance

### Regular Backups
```bash
# Full database backup
pg_dump -h localhost -U postgres postgres > baseball_backup_$(date +%Y%m%d).sql

# Schema-only backup
pg_dump -h localhost -U postgres --schema-only postgres > schema_backup.sql

# Data-only backup (for large datasets)
pg_dump -h localhost -U postgres --data-only --table=fg_season_stats postgres > stats_data.sql
```

### Maintenance Tasks
```sql
-- Update table statistics (run weekly)
ANALYZE fg_season_stats;
ANALYZE player_embeddings;

-- Reindex if performance degrades
REINDEX INDEX idx_season_stats_war;
REINDEX INDEX player_embeddings_embedding_idx;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

## Troubleshooting

### Common Issues

**pgvector Extension Missing**
```sql
-- Check if extension is installed
SELECT * FROM pg_extension WHERE extname = 'vector';

-- Install if missing
CREATE EXTENSION vector;
```

**Slow Vector Queries**
```sql
-- Check HNSW index exists
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'player_embeddings' 
  AND indexdef LIKE '%hnsw%';

-- Rebuild if missing
CREATE INDEX ON player_embeddings USING hnsw (embedding vector_cosine_ops);
```

**Grade Distribution Issues**
```sql
-- Check for NULL grades (indicates calculation problems)
SELECT COUNT(*) as null_grades
FROM fg_season_stats 
WHERE overall_grade IS NULL AND pa >= 100;

-- Check grade ranges (should be 20-80)
SELECT MIN(overall_grade), MAX(overall_grade)
FROM fg_season_stats
WHERE overall_grade IS NOT NULL;
```

**Connection Pool Exhaustion**
```
Error: remaining connection slots are reserved
```
- Increase `max_connections` in postgresql.conf
- Reduce application pool size
- Check for connection leaks in application code
- Monitor active connections: `SELECT count(*) FROM pg_stat_activity;`

### Performance Issues

**Slow Hybrid Searches**
- Verify indexes exist on grade columns
- Check query execution plan with `EXPLAIN ANALYZE`
- Consider increasing `work_mem` for complex queries
- Monitor `pg_stat_user_indexes` for index usage

**Large Table Maintenance**
- Use `VACUUM ANALYZE` regularly on large tables
- Consider partitioning by year for very large datasets
- Monitor table bloat with `pg_stat_user_tables`

## Migration Guide

### Upgrading to Schema v1.4
```sql
-- Add percentile columns (Phase 2.7.1)
ALTER TABLE fg_season_stats 
ADD COLUMN overall_percentile NUMERIC(5,2),
ADD COLUMN power_percentile NUMERIC(5,2),
ADD COLUMN hit_percentile NUMERIC(5,2),
ADD COLUMN fielding_percentile NUMERIC(5,2);

-- Create percentiles table
CREATE TABLE stat_percentiles (
    -- See schema definition above
);

-- Create indexes
CREATE INDEX idx_season_stats_overall_pct ON fg_season_stats(overall_percentile);
CREATE INDEX idx_percentiles_lookup ON stat_percentiles(stat_name, year, scope);

-- Populate percentile data (run R ETL script)
-- Update grades based on percentiles (run R ETL script)
```

### Data Migration
```bash
# Export current data
pg_dump -h localhost -U postgres --data-only postgres > current_data.sql

# Apply schema changes
psql -h localhost -U postgres -f schema_v1.4.sql

# Re-import data
psql -h localhost -U postgres -f current_data.sql

# Run ETL to populate new columns
cd ../fangraphs && Rscript batter_leaderboard_etl.r
```