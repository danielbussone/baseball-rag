-- Chadwick Bureau Player Registry Schema (Complete)

-- ============================================================================
-- CHADWICK PLAYER REGISTRY (All Columns)
-- ============================================================================

CREATE TABLE IF NOT EXISTS chadwick_registry (
    -- Primary identifiers
    key_person VARCHAR(9),
    key_uuid VARCHAR(50),
    key_mlbam INTEGER,
    key_retro VARCHAR(9),
    key_bbref VARCHAR(9),
    key_bbref_minors VARCHAR(50),
    key_fangraphs INTEGER,
    key_npb INTEGER,
    key_sr_nfl VARCHAR(50),
    key_sr_nba VARCHAR(50),
    key_sr_nhl VARCHAR(50),
    key_wikidata VARCHAR(50),
    
    -- Player names
    name_last VARCHAR(50),
    name_first VARCHAR(50),
    name_given VARCHAR(255),
    name_suffix VARCHAR(20),
    name_matrilineal VARCHAR(50),
    name_nick VARCHAR(50),
    
    -- Birth information
    birth_year INTEGER,
    birth_month INTEGER,
    birth_day INTEGER,
    
    -- Death information  
    death_year INTEGER,
    death_month INTEGER,
    death_day INTEGER,
    
    -- Playing career
    pro_played_first INTEGER,
    pro_played_last INTEGER,
    mlb_played_first INTEGER,
    mlb_played_last INTEGER,
    col_played_first INTEGER,
    col_played_last INTEGER,
    
    -- Managing career
    pro_managed_first INTEGER,
    pro_managed_last INTEGER,
    mlb_managed_first INTEGER,
    mlb_managed_last INTEGER,
    col_managed_first INTEGER,
    col_managed_last INTEGER,
    
    -- Umpiring career
    pro_umpired_first INTEGER,
    pro_umpired_last INTEGER,
    mlb_umpired_first INTEGER,
    mlb_umpired_last INTEGER,
    
    -- Import metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CHADWICK INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_chadwick_key_person ON chadwick_registry(key_person);
CREATE INDEX IF NOT EXISTS idx_chadwick_key_uuid ON chadwick_registry(key_uuid);
CREATE INDEX IF NOT EXISTS idx_chadwick_key_mlbam ON chadwick_registry(key_mlbam);
CREATE INDEX IF NOT EXISTS idx_chadwick_key_retro ON chadwick_registry(key_retro);
CREATE INDEX IF NOT EXISTS idx_chadwick_key_bbref ON chadwick_registry(key_bbref);
CREATE INDEX IF NOT EXISTS idx_chadwick_key_fangraphs ON chadwick_registry(key_fangraphs);
CREATE INDEX IF NOT EXISTS idx_chadwick_name ON chadwick_registry(name_last, name_first);
CREATE INDEX IF NOT EXISTS idx_chadwick_birth_year ON chadwick_registry(birth_year);
CREATE INDEX IF NOT EXISTS idx_chadwick_mlb_career ON chadwick_registry(mlb_played_first, mlb_played_last);

COMMENT ON TABLE chadwick_registry IS 'Complete Chadwick Bureau cross-reference registry for player IDs across all major baseball databases';
COMMENT ON COLUMN chadwick_registry.key_person IS 'Chadwick unique person identifier';
COMMENT ON COLUMN chadwick_registry.key_uuid IS 'UUID for the person';
COMMENT ON COLUMN chadwick_registry.key_mlbam IS 'MLB Advanced Media ID (for StatCast)';
COMMENT ON COLUMN chadwick_registry.key_fangraphs IS 'FanGraphs player ID';
COMMENT ON COLUMN chadwick_registry.key_bbref IS 'Baseball Reference player ID';
COMMENT ON COLUMN chadwick_registry.key_retro IS 'Retrosheet player ID';
COMMENT ON COLUMN chadwick_registry.key_bbref_minors IS 'Baseball Reference minor league ID';
COMMENT ON COLUMN chadwick_registry.key_npb IS 'Nippon Professional Baseball ID';
COMMENT ON COLUMN chadwick_registry.pro_played_first IS 'First year played professionally';
COMMENT ON COLUMN chadwick_registry.mlb_played_first IS 'First year played in MLB';
COMMENT ON COLUMN chadwick_registry.pro_managed_first IS 'First year managed professionally';
COMMENT ON COLUMN chadwick_registry.mlb_managed_first IS 'First year managed in MLB';
COMMENT ON COLUMN chadwick_registry.pro_umpired_first IS 'First year umpired professionally';
COMMENT ON COLUMN chadwick_registry.mlb_umpired_first IS 'First year umpired in MLB';