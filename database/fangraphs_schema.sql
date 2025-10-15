-- FanGraphs Baseball RAG Database Schema
-- Version: 1.0
-- Created: 2025-10-13
-- Data Source: FanGraphs Batter Leaderboards (1988-present)

-- ============================================================================
-- PLAYERS DIMENSION TABLE
-- ============================================================================
-- One row per unique player across all seasons

CREATE TABLE IF NOT EXISTS fg_players (
    fangraphs_id INTEGER PRIMARY KEY,
    mlbam_id INTEGER,
    player_name VARCHAR(255) NOT NULL,
    bats VARCHAR(5), -- L, R, S (switch)
    first_season INTEGER,
    last_season INTEGER,
    total_seasons INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE fg_players IS 'Unique players from FanGraphs with biographical data';
COMMENT ON COLUMN fg_players.fangraphs_id IS 'FanGraphs player ID (primary key)';
COMMENT ON COLUMN fg_players.mlbam_id IS 'MLB Advanced Media ID (for linking to Statcast)';
COMMENT ON COLUMN fg_players.bats IS 'Batting handedness: L (left), R (right), S (switch)';

-- ============================================================================
-- SEASON STATISTICS TABLE
-- ============================================================================
-- One row per player per season with core batting statistics

CREATE TABLE IF NOT EXISTS fg_season_stats (
    player_season_id VARCHAR(50) PRIMARY KEY,
    fangraphs_id INTEGER NOT NULL REFERENCES fg_players(fangraphs_id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    age INTEGER,
    team VARCHAR(10),
    position VARCHAR(50),         -- Position(s) played
    
    -- Basic counting stats
    g INTEGER,              -- Games
    ab INTEGER,             -- At Bats
    pa INTEGER,             -- Plate Appearances
    h INTEGER,              -- Hits
    "1b" INTEGER,           -- Singles
    "2b" INTEGER,           -- Doubles
    "3b" INTEGER,           -- Triples
    hr INTEGER,             -- Home Runs
    r INTEGER,              -- Runs
    rbi INTEGER,            -- RBI
    bb INTEGER,             -- Walks
    ibb INTEGER,            -- Intentional Walks
    so INTEGER,             -- Strikeouts
    hbp INTEGER,            -- Hit By Pitch
    sf INTEGER,             -- Sacrifice Flies
    sh INTEGER,             -- Sacrifice Hits
    gdp INTEGER,            -- Ground into Double Play
    sb INTEGER,             -- Stolen Bases
    cs INTEGER,             -- Caught Stealing
    
    -- Rate stats
    avg NUMERIC(4,3),       -- Batting Average
    obp NUMERIC(4,3),       -- On-Base Percentage
    slg NUMERIC(4,3),       -- Slugging Percentage
    ops NUMERIC(4,3),       -- OPS (OBP + SLG)
    iso NUMERIC(4,3),       -- Isolated Power
    babip NUMERIC(4,3),     -- Batting Average on Balls In Play
    
    -- Advanced rate stats
    bb_pct NUMERIC(5,2),    -- Walk Rate
    k_pct NUMERIC(5,2),     -- Strikeout Rate
    bb_k NUMERIC(5,3),      -- Walk to Strikeout Ratio
    
    -- Plus stats (era-adjusted, 100 = league average)
    avg_plus INTEGER,       -- Batting Average Plus
    bb_pct_plus INTEGER,    -- Walk Rate Plus
    k_pct_plus INTEGER,     -- Strikeout Rate Plus
    obp_plus INTEGER,       -- OBP Plus
    slg_plus INTEGER,       -- Slugging Plus
    iso_plus INTEGER,       -- Isolated Power Plus
    babip_plus INTEGER,     -- BABIP Plus
    
    -- Batted ball metrics
    gb_pct NUMERIC(5,2),    -- Ground Ball %
    fb_pct NUMERIC(5,2),    -- Fly Ball %
    ld_pct NUMERIC(5,2),    -- Line Drive %
    iffb_pct NUMERIC(5,2),  -- Infield Fly Ball %
    hr_fb NUMERIC(5,2),     -- HR per Fly Ball
    pull_pct NUMERIC(5,2),  -- Pull %
    cent_pct NUMERIC(5,2),  -- Center %
    oppo_pct NUMERIC(5,2),  -- Opposite Field %
    soft_pct NUMERIC(5,2),  -- Soft Contact %
    med_pct NUMERIC(5,2),   -- Medium Contact %
    hard_pct NUMERIC(5,2),  -- Hard Contact %
    
    -- Weighted stats
    woba NUMERIC(5,3),      -- Weighted On-Base Average
    wraa NUMERIC(6,1),      -- Weighted Runs Above Average
    wrc INTEGER,            -- Weighted Runs Created
    wrc_plus INTEGER,       -- Weighted Runs Created Plus (park/league adjusted)
    
    -- WAR components
    batting NUMERIC(6,1),   -- Batting Runs Above Average
    fielding NUMERIC(6,1),  -- Fielding Runs Above Average
    baserunning NUMERIC(6,1), -- Baserunning Runs Above Average
    positional NUMERIC(6,1),  -- Positional Adjustment
    defense NUMERIC(6,1),   -- Total Defensive Value
    offense NUMERIC(6,1),   -- Total Offensive Value
    war NUMERIC(5,1),       -- Wins Above Replacement
    rar NUMERIC(6,1),       -- Runs Above Replacement
    
    -- Plate discipline
    o_swing_pct NUMERIC(5,2),   -- Outside Zone Swing %
    z_swing_pct NUMERIC(5,2),   -- Inside Zone Swing %
    swing_pct NUMERIC(5,2),     -- Overall Swing %
    o_contact_pct NUMERIC(5,2), -- Outside Zone Contact %
    z_contact_pct NUMERIC(5,2), -- Inside Zone Contact %
    contact_pct NUMERIC(5,2),   -- Overall Contact %
    zone_pct NUMERIC(5,2),      -- Zone %
    f_strike_pct NUMERIC(5,2),  -- First Pitch Strike %
    swstr_pct NUMERIC(5,2),     -- Swinging Strike %
    
    -- Statcast metrics (available 2015+)
    ev NUMERIC(5,1),        -- Average Exit Velocity
    ev90 NUMERIC(5,1),      -- 90th Percentile Exit Velocity
    la NUMERIC(5,1),        -- Average Launch Angle
    barrels INTEGER,        -- Barrel Count
    barrel_pct NUMERIC(5,2), -- Barrel %
    maxev NUMERIC(5,1),     -- Max Exit Velocity
    hardhit INTEGER,        -- Hard Hit Count
    hardhit_pct NUMERIC(5,2), -- Hard Hit %
    hard_pct_plus INTEGER,  -- Hard Hit % Plus (era-adjusted)
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(fangraphs_id, year, team)
);

COMMENT ON TABLE fg_season_stats IS 'Per-season batting statistics from FanGraphs';
COMMENT ON COLUMN fg_season_stats.position IS 'Position(s) played - may be multi-position like SS/2B or 1B/3B/OF';
COMMENT ON COLUMN fg_season_stats.wrc_plus IS '100 is league average, >100 is above average';
COMMENT ON COLUMN fg_season_stats.war IS 'Wins Above Replacement (FanGraphs calculation)';
COMMENT ON COLUMN fg_season_stats.avg_plus IS 'Era-adjusted batting average, 100 = league average';
COMMENT ON COLUMN fg_season_stats.bb_pct_plus IS 'Era-adjusted walk rate, 100 = league average';
COMMENT ON COLUMN fg_season_stats.k_pct_plus IS 'Era-adjusted strikeout rate, 100 = league average (higher is better)';
COMMENT ON COLUMN fg_season_stats.iso_plus IS 'Era-adjusted isolated power, 100 = league average';
COMMENT ON COLUMN fg_season_stats.ev90 IS '90th percentile exit velocity (better indicator than average EV)';
COMMENT ON COLUMN fg_season_stats.hard_pct_plus IS 'Era-adjusted hard contact rate, 100 = league average';

-- ============================================================================
-- BATTER PITCH DATA TABLE
-- ============================================================================
-- Pitch-level data for batters (what pitches they faced)
-- Extremely granular - separated for performance

CREATE TABLE IF NOT EXISTS fg_batter_pitches_faced (
    player_season_id VARCHAR(50) PRIMARY KEY REFERENCES fg_season_stats(player_season_id) ON DELETE CASCADE,
    fangraphs_id INTEGER NOT NULL REFERENCES fg_players(fangraphs_id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    
    -- Simple pitch velocity columns (older data format)
    fbv NUMERIC(5,1),           -- Fastball velocity (simple)
    slv NUMERIC(5,1),           -- Slider velocity (simple)
    ctv NUMERIC(5,1),           -- Cutter velocity (simple)
    cbv NUMERIC(5,1),           -- Curveball velocity (simple)
    chv NUMERIC(5,1),           -- Changeup velocity (simple)
    sfv NUMERIC(5,1),           -- Splitter velocity (simple)
    
    -- PITCHf/x data (pfx_) - more detailed pitch tracking
    pfx_fa_pct NUMERIC(5,2),    -- Fastball %
    pfx_fc_pct NUMERIC(5,2),    -- Cutter %
    pfx_fs_pct NUMERIC(5,2),    -- Splitter %
    pfx_fo_pct NUMERIC(5,2),    -- Forkball %
    pfx_si_pct NUMERIC(5,2),    -- Sinker %
    pfx_sl_pct NUMERIC(5,2),    -- Slider %
    pfx_cu_pct NUMERIC(5,2),    -- Curveball %
    pfx_kc_pct NUMERIC(5,2),    -- Knuckle Curve %
    pfx_ep_pct NUMERIC(5,2),    -- Eephus %
    pfx_ch_pct NUMERIC(5,2),    -- Changeup %
    pfx_sc_pct NUMERIC(5,2),    -- Screwball %
    pfx_kn_pct NUMERIC(5,2),    -- Knuckleball %
    
    -- Pitch velocities (pfx_v*)
    pfx_vfa NUMERIC(5,1),       -- Fastball velocity
    pfx_vfc NUMERIC(5,1),       -- Cutter velocity
    pfx_vfs NUMERIC(5,1),       -- Splitter velocity
    pfx_vfo NUMERIC(5,1),       -- Forkball velocity
    pfx_vsi NUMERIC(5,1),       -- Sinker velocity
    pfx_vsl NUMERIC(5,1),       -- Slider velocity
    pfx_vcu NUMERIC(5,1),       -- Curveball velocity
    pfx_vkc NUMERIC(5,1),       -- Knuckle Curve velocity
    pfx_vep NUMERIC(5,1),       -- Eephus velocity
    pfx_vch NUMERIC(5,1),       -- Changeup velocity
    pfx_vsc NUMERIC(5,1),       -- Screwball velocity
    pfx_vkn NUMERIC(5,1),       -- Knuckleball velocity
    
    -- Pitch movement (pfx_*-X and pfx_*-Z)
    -- Horizontal and vertical movement for each pitch type
    pfx_fa_x NUMERIC(5,2),
    pfx_fa_z NUMERIC(5,2),
    pfx_fc_x NUMERIC(5,2),
    pfx_fc_z NUMERIC(5,2),
    pfx_fs_x NUMERIC(5,2),
    pfx_fs_z NUMERIC(5,2),
    pfx_fo_x NUMERIC(5,2),
    pfx_fo_z NUMERIC(5,2),
    pfx_si_x NUMERIC(5,2),
    pfx_si_z NUMERIC(5,2),
    pfx_sl_x NUMERIC(5,2),
    pfx_sl_z NUMERIC(5,2),
    pfx_cu_x NUMERIC(5,2),
    pfx_cu_z NUMERIC(5,2),
    pfx_kc_x NUMERIC(5,2),
    pfx_kc_z NUMERIC(5,2),
    pfx_ep_x NUMERIC(5,2),
    pfx_ep_z NUMERIC(5,2),
    pfx_ch_x NUMERIC(5,2),
    pfx_ch_z NUMERIC(5,2),
    pfx_sc_x NUMERIC(5,2),
    pfx_sc_z NUMERIC(5,2),
    pfx_kn_x NUMERIC(5,2),
    pfx_kn_z NUMERIC(5,2),
    
    -- Weighted pitch values (pfx_w* and pfx_w*_C)
    pfx_wfa NUMERIC(6,1),       -- Fastball runs above average
    pfx_wfc NUMERIC(6,1),
    pfx_wfs NUMERIC(6,1),
    pfx_wfo NUMERIC(6,1),
    pfx_wsi NUMERIC(6,1),
    pfx_wsl NUMERIC(6,1),
    pfx_wcu NUMERIC(6,1),
    pfx_wkc NUMERIC(6,1),
    pfx_wep NUMERIC(6,1),
    pfx_wch NUMERIC(6,1),
    pfx_wsc NUMERIC(6,1),
    pfx_wkn NUMERIC(6,1),
    
    pfx_wfa_c NUMERIC(6,1),     -- Per 100 pitches
    pfx_wfc_c NUMERIC(6,1),
    pfx_wfs_c NUMERIC(6,1),
    pfx_wfo_c NUMERIC(6,1),
    pfx_wsi_c NUMERIC(6,1),
    pfx_wsl_c NUMERIC(6,1),
    pfx_wcu_c NUMERIC(6,1),
    pfx_wkc_c NUMERIC(6,1),
    pfx_wep_c NUMERIC(6,1),
    pfx_wch_c NUMERIC(6,1),
    pfx_wsc_c NUMERIC(6,1),
    pfx_wkn_c NUMERIC(6,1),
    
    -- Plate discipline vs pitch types (pfx_*)
    pfx_o_swing_pct NUMERIC(5,2),
    pfx_z_swing_pct NUMERIC(5,2),
    pfx_swing_pct NUMERIC(5,2),
    pfx_o_contact_pct NUMERIC(5,2),
    pfx_z_contact_pct NUMERIC(5,2),
    pfx_contact_pct NUMERIC(5,2),
    pfx_zone_pct NUMERIC(5,2),
    pfx_pace NUMERIC(5,2),
    
    -- PITCHInfo data (pi_*) - alternative pitch classification system
    pi_ch_pct NUMERIC(5,2),
    pi_cu_pct NUMERIC(5,2),
    pi_fa_pct NUMERIC(5,2),
    pi_fc_pct NUMERIC(5,2),
    pi_fs_pct NUMERIC(5,2),
    pi_sb_pct NUMERIC(5,2),
    pi_si_pct NUMERIC(5,2),
    pi_sl_pct NUMERIC(5,2),
    pi_cs_pct NUMERIC(5,2),
    pi_kn_pct NUMERIC(5,2),
    pi_xx_pct NUMERIC(5,2),
    
    pi_vch NUMERIC(5,1),
    pi_vcu NUMERIC(5,1),
    pi_vfa NUMERIC(5,1),
    pi_vfc NUMERIC(5,1),
    pi_vfs NUMERIC(5,1),
    pi_vsb NUMERIC(5,1),
    pi_vsi NUMERIC(5,1),
    pi_vsl NUMERIC(5,1),
    pi_vcs NUMERIC(5,1),
    pi_vkn NUMERIC(5,1),
    pi_vxx NUMERIC(5,1),
    
    -- PITCHInfo movement (X and Z)
    pi_ch_x NUMERIC(5,2),
    pi_cu_x NUMERIC(5,2),
    pi_fa_x NUMERIC(5,2),
    pi_fc_x NUMERIC(5,2),
    pi_fs_x NUMERIC(5,2),
    pi_sb_x NUMERIC(5,2),
    pi_si_x NUMERIC(5,2),
    pi_sl_x NUMERIC(5,2),
    pi_cs_x NUMERIC(5,2),
    pi_kn_x NUMERIC(5,2),
    pi_xx_x NUMERIC(5,2),
    
    pi_ch_z NUMERIC(5,2),
    pi_cu_z NUMERIC(5,2),
    pi_fa_z NUMERIC(5,2),
    pi_fc_z NUMERIC(5,2),
    pi_fs_z NUMERIC(5,2),
    pi_sb_z NUMERIC(5,2),
    pi_si_z NUMERIC(5,2),
    pi_sl_z NUMERIC(5,2),
    pi_cs_z NUMERIC(5,2),
    pi_kn_z NUMERIC(5,2),
    pi_xx_z NUMERIC(5,2),
    
    -- PITCHInfo weighted values
    pi_wch NUMERIC(6,1),
    pi_wcu NUMERIC(6,1),
    pi_wfa NUMERIC(6,1),
    pi_wfc NUMERIC(6,1),
    pi_wfs NUMERIC(6,1),
    pi_wsb NUMERIC(6,1),
    pi_wsi NUMERIC(6,1),
    pi_wsl NUMERIC(6,1),
    pi_wcs NUMERIC(6,1),
    pi_wkn NUMERIC(6,1),
    pi_wxx NUMERIC(6,1),
    
    pi_wch_c NUMERIC(6,1),
    pi_wcu_c NUMERIC(6,1),
    pi_wfa_c NUMERIC(6,1),
    pi_wfc_c NUMERIC(6,1),
    pi_wfs_c NUMERIC(6,1),
    pi_wsb_c NUMERIC(6,1),
    pi_wsi_c NUMERIC(6,1),
    pi_wsl_c NUMERIC(6,1),
    pi_wcs_c NUMERIC(6,1),
    pi_wkn_c NUMERIC(6,1),
    pi_wxx_c NUMERIC(6,1),
    
    -- PITCHInfo plate discipline
    pi_o_swing_pct NUMERIC(5,2),
    pi_z_swing_pct NUMERIC(5,2),
    pi_swing_pct NUMERIC(5,2),
    pi_o_contact_pct NUMERIC(5,2),
    pi_z_contact_pct NUMERIC(5,2),
    pi_contact_pct NUMERIC(5,2),
    pi_zone_pct NUMERIC(5,2),
    pi_pace NUMERIC(5,2),
    
    -- Similar structure for pi_*-X, pi_*-Z, pi_w*, pi_w*_C
    -- (abbreviated for space - full schema would include all)
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE fg_batter_pitches_faced IS 'Detailed pitch-level data for batters';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Players table indexes
CREATE INDEX IF NOT EXISTS idx_fg_players_name ON fg_players(player_name);
CREATE INDEX IF NOT EXISTS idx_fg_players_mlbam_id ON fg_players(mlbam_id);
CREATE INDEX IF NOT EXISTS idx_fg_players_first_season ON fg_players(first_season);
CREATE INDEX IF NOT EXISTS idx_fg_players_last_season ON fg_players(last_season);

-- Season stats indexes
CREATE INDEX IF NOT EXISTS idx_fg_season_stats_player ON fg_season_stats(fangraphs_id);
CREATE INDEX IF NOT EXISTS idx_fg_season_stats_year ON fg_season_stats(year);
CREATE INDEX IF NOT EXISTS idx_fg_season_stats_war ON fg_season_stats(war DESC);
CREATE INDEX IF NOT EXISTS idx_fg_season_stats_player_year ON fg_season_stats(fangraphs_id, year);
CREATE INDEX IF NOT EXISTS idx_fg_season_stats_team ON fg_season_stats(team);
CREATE INDEX IF NOT EXISTS idx_fg_season_stats_wrc_plus ON fg_season_stats(wrc_plus DESC);
CREATE INDEX IF NOT EXISTS idx_fg_season_stats_position ON fg_season_stats(position);

-- Pitch data indexes
CREATE INDEX IF NOT EXISTS idx_fg_pitch_data_player ON fg_batter_pitches_faced(fangraphs_id);
CREATE INDEX IF NOT EXISTS idx_fg_pitch_data_year ON fg_batter_pitches_faced(year);

-- ============================================================================
-- PLAYER EMBEDDINGS TABLE
-- ============================================================================
-- Vector embeddings for semantic search of player seasons

CREATE TABLE IF NOT EXISTS player_embeddings (
    id SERIAL PRIMARY KEY,
    player_season_id VARCHAR(50) NOT NULL,
    fangraphs_id INTEGER NOT NULL REFERENCES fg_players(fangraphs_id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    
    embedding_type VARCHAR(50) NOT NULL, -- 'season_summary', 'career_summary', 'pitch_profile'
    summary_text TEXT NOT NULL,          -- The actual text that was embedded
    embedding vector(768),               -- The embedding itself (768 dimensions for all-mpnet-base-v2)
    
    metadata JSONB,                      -- Store key stats for filtering
    -- e.g., {"war": 8.3, "wrc_plus": 179, "position": "CF", "overall_grade": 70}
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(player_season_id, embedding_type)
);

COMMENT ON TABLE player_embeddings IS 'Vector embeddings of player season summaries for semantic search';
COMMENT ON COLUMN player_embeddings.embedding_type IS 'Type of summary: season_summary, career_summary, or pitch_profile';
COMMENT ON COLUMN player_embeddings.summary_text IS 'Natural language description that was embedded';
COMMENT ON COLUMN player_embeddings.embedding IS '768-dimensional vector from all-mpnet-base-v2 model';
COMMENT ON COLUMN player_embeddings.metadata IS 'JSONB with grades and key stats for hybrid filtering';

-- Indexes for player_embeddings
CREATE INDEX IF NOT EXISTS idx_player_embeddings_vector 
    ON player_embeddings USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_player_embeddings_type 
    ON player_embeddings(embedding_type);
CREATE INDEX IF NOT EXISTS idx_player_embeddings_player 
    ON player_embeddings(fangraphs_id);
CREATE INDEX IF NOT EXISTS idx_player_embeddings_year 
    ON player_embeddings(year);
CREATE INDEX IF NOT EXISTS idx_player_embeddings_metadata 
    ON player_embeddings USING gin(metadata);

-- ============================================================================
-- USEFUL VIEWS
-- ============================================================================

-- Career aggregates view
CREATE OR REPLACE VIEW fg_career_stats AS
SELECT 
    p.fangraphs_id,
    p.player_name,
    p.bats,
    p.first_season,
    p.last_season,
    COUNT(*) as seasons,
    SUM(s.g) as total_games,
    SUM(s.pa) as total_pa,
    SUM(s.hr) as total_hr,
    ROUND(AVG(s.avg)::numeric, 3) as avg_batting_avg,
    ROUND(AVG(s.obp)::numeric, 3) as avg_obp,
    ROUND(AVG(s.slg)::numeric, 3) as avg_slg,
    ROUND(SUM(s.war)::numeric, 1) as total_war,
    ROUND(AVG(s.war)::numeric, 1) as avg_war,
    ROUND(AVG(s.wrc_plus)::numeric, 0) as avg_wrc_plus,
    MAX(s.war) as peak_war,
    (SELECT year FROM fg_season_stats WHERE fangraphs_id = p.fangraphs_id ORDER BY war DESC LIMIT 1) as peak_year
FROM fg_players p
JOIN fg_season_stats s ON p.fangraphs_id = s.fangraphs_id
GROUP BY p.fangraphs_id, p.player_name, p.bats, p.first_season, p.last_season;

COMMENT ON VIEW fg_career_stats IS 'Aggregated career statistics for all players';

-- Active players view (played in last 2 years)
CREATE OR REPLACE VIEW fg_active_players AS
SELECT 
    p.*,
    cs.total_war,
    cs.avg_wrc_plus
FROM fg_players p
JOIN fg_career_stats cs ON p.fangraphs_id = cs.fangraphs_id
WHERE p.last_season >= EXTRACT(YEAR FROM CURRENT_DATE) - 2;

COMMENT ON VIEW fg_active_players IS 'Players who have played in the last 2 seasons';

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to players table
CREATE trigger IF NOT EXISTS update_fg_players_updated_at 
    BEFORE UPDATE ON fg_players
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SCHEMA VERSION TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS schema_version (
    version VARCHAR(20) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

INSERT INTO schema_version (version, description) 
VALUES ('1.1', 'Added position field, plus stats (era-adjusted), EV90, hard_pct_plus, and player_embeddings table')
ON CONFLICT (version) DO NOTHING;

COMMENT ON TABLE schema_version IS 'Tracks database schema versions';

-- Done! Schema version 1.1 created successfully