-- Baseball RAG V2 Database Schema
-- Master Player Registry + Raw Data Tables + Unified Views

-- ============================================================================
-- MASTER PLAYER REGISTRY (Links all data sources)
-- ============================================================================

CREATE TABLE IF NOT EXISTS players_master (
    player_id SERIAL PRIMARY KEY,
    
    -- External IDs (for linking data sources)
    lahman_id VARCHAR(9) UNIQUE,
    fangraphs_id INTEGER UNIQUE,
    mlbam_id INTEGER UNIQUE,
    bbref_id VARCHAR(9) UNIQUE,
    retro_id VARCHAR(9) UNIQUE,
    
    -- Canonical player info (from Lahman)
    name_first VARCHAR(50),
    name_last VARCHAR(50),
    name_given VARCHAR(255),
    
    -- Biographical
    birth_year INTEGER,
    birth_month INTEGER,
    birth_day INTEGER,
    birth_country VARCHAR(50),
    birth_state VARCHAR(50),
    birth_city VARCHAR(50),
    
    death_year INTEGER,
    death_month INTEGER,
    death_day INTEGER,
    death_country VARCHAR(50),
    death_state VARCHAR(50),
    death_city VARCHAR(50),
    
    -- Physical
    height_inches INTEGER,
    weight_lbs INTEGER,
    bats CHAR(1),
    throws CHAR(1),
    
    -- Career span
    debut_date DATE,
    final_game_date DATE,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for master registry
CREATE INDEX IF NOT EXISTS idx_players_master_lahman ON players_master(lahman_id);
CREATE INDEX IF NOT EXISTS idx_players_master_fangraphs ON players_master(fangraphs_id);
CREATE INDEX IF NOT EXISTS idx_players_master_mlbam ON players_master(mlbam_id);
CREATE INDEX IF NOT EXISTS idx_players_master_name ON players_master(name_last, name_first);
CREATE INDEX IF NOT EXISTS idx_players_master_debut ON players_master(debut_date);

COMMENT ON TABLE players_master IS 'Master player registry linking all data sources';
COMMENT ON COLUMN players_master.lahman_id IS 'Lahman Database playerID';
COMMENT ON COLUMN players_master.fangraphs_id IS 'FanGraphs playerid';
COMMENT ON COLUMN players_master.mlbam_id IS 'MLB Advanced Media ID (for StatCast)';
COMMENT ON COLUMN players_master.bbref_id IS 'Baseball Reference ID';

-- ============================================================================
-- SCHEMA VERSION TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS schema_versions (
    version VARCHAR(20) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

INSERT INTO schema_versions (version, description) 
VALUES ('2.0.0', 'V2 Foundation: Master Player Registry + Raw Data Tables')
ON CONFLICT (version) DO NOTHING;