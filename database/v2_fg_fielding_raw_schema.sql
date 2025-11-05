-- FanGraphs Fielding Schema (Clean Column Names)

CREATE TABLE IF NOT EXISTS fg_fielding_leaders (
    -- Core identifiers
    season INTEGER NOT NULL,
    team_name TEXT,
    x_mlbamid INTEGER,
    player_name_route TEXT,
    player_name TEXT,
    playerid INTEGER NOT NULL,
    season_min INTEGER,
    season_max INTEGER,
    
    -- Position and games
    pos TEXT NOT NULL,
    g INTEGER,
    gs INTEGER,
    inn NUMERIC(8,1),
    tinn NUMERIC(8,1),
    
    -- Basic fielding stats
    po INTEGER,
    a INTEGER,
    e INTEGER,
    dp INTEGER,
    dps INTEGER,
    dpt INTEGER,
    dpf INTEGER,
    fp NUMERIC(6,3),
    
    -- Catcher specific
    pb INTEGER,
    sb INTEGER,
    cs INTEGER,
    wp INTEGER,
    
    -- Error types
    fe INTEGER,
    te INTEGER,
    
    -- Team info
    teamid INTEGER,
    team_name_abb TEXT,
    
    -- Zone rating
    tz INTEGER,
    q NUMERIC(6,1),
    
    -- GDP related
    r_gdp INTEGER,
    r_gfp INTEGER,
    r_pm INTEGER,
    
    -- Advanced fielding metrics
    drs INTEGER,
    biz INTEGER,
    plays INTEGER,
    ooz INTEGER,
    dpr NUMERIC(8,1),
    rng_r NUMERIC(8,1),
    err_r NUMERIC(8,1),
    
    -- UZR (Ultimate Zone Rating)
    uzr NUMERIC(8,1),
    uzr_150 NUMERIC(8,1),
    defense NUMERIC(8,1),
    
    -- Arm metrics
    r_arm INTEGER,
    arm NUMERIC(8,1),
    r_sb INTEGER,
    r_sz NUMERIC(8,1),
    r_cera INTEGER,
    
    -- Positioning and range
    scp INTEGER,
    rzr NUMERIC(6,3),
    cpp NUMERIC(6,3),
    rpp NUMERIC(6,3),
    
    -- Catcher framing
    cstrikes NUMERIC(8,1),
    cframing NUMERIC(8,1),
    fsr INTEGER,
    
    -- Probability-based metrics
    prob0 INTEGER,
    made0 INTEGER,
    made10 NUMERIC(6,3),
    prob10 INTEGER,
    made40 NUMERIC(6,3),
    prob40 INTEGER,
    made60 NUMERIC(6,3),
    prob60 INTEGER,
    made90 NUMERIC(6,3),
    prob90 INTEGER,
    made100 NUMERIC(6,3),
    prob100 INTEGER,
    
    -- Framing metrics
    d_frp INTEGER,
    b_frp INTEGER,
    t_frp INTEGER,
    f_frp INTEGER,
    frp INTEGER,
    oaa INTEGER,
    r_frp INTEGER,
    a_frp INTEGER,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Primary key
    CONSTRAINT fg_fielding_leaders_pkey PRIMARY KEY (playerid, season, pos)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_fg_fielding_leaders_season ON fg_fielding_leaders(season);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_leaders_player ON fg_fielding_leaders(playerid);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_leaders_pos ON fg_fielding_leaders(pos);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_leaders_uzr ON fg_fielding_leaders(uzr DESC);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_leaders_drs ON fg_fielding_leaders(drs DESC);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_leaders_team ON fg_fielding_leaders(team_name_abb);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_leaders_player_name ON fg_fielding_leaders(player_name);

COMMENT ON TABLE fg_fielding_leaders IS 'FanGraphs fielding data with clean snake_case column names';