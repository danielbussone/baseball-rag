-- Percentiles Schema for Baseball RAG V2
-- Pre-calculated percentile distributions and player rankings

-- ============================================================================
-- STAT PERCENTILES TABLE (Pre-calculated distributions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS stat_percentiles (
    id SERIAL PRIMARY KEY,
    stat_name VARCHAR(50) NOT NULL,        -- 'war', 'wrc_plus', 'era', etc.
    scope VARCHAR(20) NOT NULL,            -- 'season', 'career', 'peak7'
    year INTEGER,                          -- Season year (NULL for career/peak7)
    position VARCHAR(10),                  -- Position filter (NULL for all positions)
    era VARCHAR(20),                       -- 'modern' (1988+), 'expansion' (1961-1987), 'integration' (1947-1960), etc.
    min_pa INTEGER,                        -- Minimum PA/IP threshold for qualification
    qualified_count INTEGER NOT NULL,      -- Number of qualified players in sample
    
    -- Percentile thresholds (every 5%)
    p1 NUMERIC(8,3), p5 NUMERIC(8,3), p10 NUMERIC(8,3), p15 NUMERIC(8,3), p20 NUMERIC(8,3),
    p25 NUMERIC(8,3), p30 NUMERIC(8,3), p35 NUMERIC(8,3), p40 NUMERIC(8,3), p45 NUMERIC(8,3),
    p50 NUMERIC(8,3), p55 NUMERIC(8,3), p60 NUMERIC(8,3), p65 NUMERIC(8,3), p70 NUMERIC(8,3),
    p75 NUMERIC(8,3), p80 NUMERIC(8,3), p85 NUMERIC(8,3), p90 NUMERIC(8,3), p95 NUMERIC(8,3), p99 NUMERIC(8,3),
    
    -- Summary statistics
    mean NUMERIC(8,3), stddev NUMERIC(8,3),
    min_value NUMERIC(8,3), max_value NUMERIC(8,3),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PLAYER PERCENTILES TABLE (Individual player rankings)
-- ============================================================================

CREATE TABLE IF NOT EXISTS player_percentiles (
    id SERIAL PRIMARY KEY,
    player_id INTEGER NOT NULL REFERENCES players_master(player_id),
    scope VARCHAR(20) NOT NULL,            -- 'season', 'career', 'peak7'
    year INTEGER,                          -- Season year (NULL for career/peak7)
    
    -- Core stats with percentiles
    war_value NUMERIC(6,1),
    war_percentile NUMERIC(5,2),
    war_era_percentile NUMERIC(5,2),       -- Era-adjusted percentile
    war_position_percentile NUMERIC(5,2),  -- Position-adjusted percentile
    
    -- Offensive stats
    wrc_plus_value INTEGER,
    wrc_plus_percentile NUMERIC(5,2),
    wrc_plus_era_percentile NUMERIC(5,2),
    
    avg_value NUMERIC(5,3),
    avg_percentile NUMERIC(5,2),
    avg_era_percentile NUMERIC(5,2),
    
    obp_value NUMERIC(5,3),
    obp_percentile NUMERIC(5,2),
    obp_era_percentile NUMERIC(5,2),
    
    slg_value NUMERIC(5,3),
    slg_percentile NUMERIC(5,2),
    slg_era_percentile NUMERIC(5,2),
    
    hr_value INTEGER,
    hr_percentile NUMERIC(5,2),
    hr_era_percentile NUMERIC(5,2),
    
    -- Pitching stats (for pitchers)
    era_value NUMERIC(6,2),
    era_percentile NUMERIC(5,2),
    era_era_percentile NUMERIC(5,2),
    
    fip_value NUMERIC(6,2),
    fip_percentile NUMERIC(5,2),
    fip_era_percentile NUMERIC(5,2),
    
    k_9_value NUMERIC(6,2),
    k_9_percentile NUMERIC(5,2),
    k_9_era_percentile NUMERIC(5,2),
    
    -- Fielding stats
    defense_value NUMERIC(6,1),
    defense_percentile NUMERIC(5,2),
    defense_position_percentile NUMERIC(5,2),
    
    -- Context
    primary_position VARCHAR(10),
    era VARCHAR(20),
    qualified BOOLEAN DEFAULT FALSE,       -- Met minimum thresholds
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(player_id, scope, year)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Stat percentiles indexes
CREATE INDEX IF NOT EXISTS idx_stat_percentiles_lookup 
    ON stat_percentiles(stat_name, scope, year, position, era);
CREATE INDEX IF NOT EXISTS idx_stat_percentiles_stat_scope 
    ON stat_percentiles(stat_name, scope);

-- Player percentiles indexes
CREATE INDEX IF NOT EXISTS idx_player_percentiles_player 
    ON player_percentiles(player_id);
CREATE INDEX IF NOT EXISTS idx_player_percentiles_scope_year 
    ON player_percentiles(scope, year);
CREATE INDEX IF NOT EXISTS idx_player_percentiles_war 
    ON player_percentiles(war_percentile DESC) WHERE war_percentile IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_player_percentiles_wrc_plus 
    ON player_percentiles(wrc_plus_percentile DESC) WHERE wrc_plus_percentile IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_player_percentiles_era_stat 
    ON player_percentiles(era_percentile) WHERE era_percentile IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_player_percentiles_position 
    ON player_percentiles(primary_position);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to calculate percentile for a given value within a distribution
CREATE OR REPLACE FUNCTION calculate_percentile(
    stat_value NUMERIC,
    stat_name_param VARCHAR,
    scope_param VARCHAR,
    year_param INTEGER DEFAULT NULL,
    position_param VARCHAR DEFAULT NULL,
    era_param VARCHAR DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE
    percentile_result NUMERIC;
BEGIN
    SELECT 
        CASE 
            WHEN stat_value <= p1 THEN 1
            WHEN stat_value <= p5 THEN 5
            WHEN stat_value <= p10 THEN 10
            WHEN stat_value <= p15 THEN 15
            WHEN stat_value <= p20 THEN 20
            WHEN stat_value <= p25 THEN 25
            WHEN stat_value <= p30 THEN 30
            WHEN stat_value <= p35 THEN 35
            WHEN stat_value <= p40 THEN 40
            WHEN stat_value <= p45 THEN 45
            WHEN stat_value <= p50 THEN 50
            WHEN stat_value <= p55 THEN 55
            WHEN stat_value <= p60 THEN 60
            WHEN stat_value <= p65 THEN 65
            WHEN stat_value <= p70 THEN 70
            WHEN stat_value <= p75 THEN 75
            WHEN stat_value <= p80 THEN 80
            WHEN stat_value <= p85 THEN 85
            WHEN stat_value <= p90 THEN 90
            WHEN stat_value <= p95 THEN 95
            WHEN stat_value <= p99 THEN 99
            ELSE 99.9
        END INTO percentile_result
    FROM stat_percentiles 
    WHERE stat_name = stat_name_param 
      AND scope = scope_param
      AND (year IS NULL OR year = year_param)
      AND (position IS NULL OR position = position_param)
      AND (era IS NULL OR era = era_param)
    LIMIT 1;
    
    RETURN COALESCE(percentile_result, 50);
END;
$$ LANGUAGE plpgsql;

-- Function to get era for a given year
CREATE OR REPLACE FUNCTION get_era(year_param INTEGER) RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE 
        WHEN year_param >= 1988 THEN 'modern'
        WHEN year_param >= 1961 THEN 'expansion'  
        WHEN year_param >= 1947 THEN 'integration'
        WHEN year_param >= 1920 THEN 'lively_ball'
        WHEN year_param >= 1901 THEN 'dead_ball'
        ELSE 'early'
    END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE stat_percentiles IS 'Pre-calculated percentile distributions for baseball statistics';
COMMENT ON TABLE player_percentiles IS 'Individual player percentile rankings for seasons and careers';
COMMENT ON FUNCTION calculate_percentile IS 'Calculate percentile rank for a given statistical value';
COMMENT ON FUNCTION get_era IS 'Determine baseball era for a given year';