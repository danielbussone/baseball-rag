-- Baseball RAG V2 Database Setup
-- Execute in order to build complete V2 database

-- 1. Master Player Registry
\i v2_master_schema.sql

-- 2. FanGraphs Raw Data Tables  
\i v2_fangraphs_schema.sql

-- 3. Lahman Raw Data Tables (Complete)
\i v2_lahman_complete_schema.sql

-- 4. Chadwick Bureau Registry
\i v2_chadwick_schema.sql

-- 5. Unified Analysis Views
\i v2_unified_views.sql

-- Verify setup
SELECT 'Setup complete. Run ETL scripts next.' AS status;