-- FanGraphs Complete Schema (All Leaders Tables)

-- ============================================================================
-- FANGRAPHS BATTING LEADERS (Complete)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fg_batting_raw (
    -- Identifiers
    season INTEGER,
    team_name VARCHAR(50),
    bats VARCHAR(5),
    xmlbamid INTEGER,
    playernameroute VARCHAR(255),
    playername VARCHAR(255),
    playerid INTEGER,
    age INTEGER,
    agerng VARCHAR(10),
    seasonmin INTEGER,
    seasonmax INTEGER,
    
    -- Basic counting stats
    g INTEGER,
    ab INTEGER,
    pa INTEGER,
    h INTEGER,
    "1b" INTEGER,
    "2b" INTEGER,
    "3b" INTEGER,
    hr INTEGER,
    r INTEGER,
    rbi INTEGER,
    bb INTEGER,
    ibb INTEGER,
    so INTEGER,
    hbp INTEGER,
    sf INTEGER,
    sh INTEGER,
    gdp INTEGER,
    sb INTEGER,
    cs INTEGER,
    
    -- Rate stats
    avg NUMERIC(5,3),
    gb INTEGER,
    fb INTEGER,
    ld INTEGER,
    iffb INTEGER,
    pitches INTEGER,
    balls INTEGER,
    strikes INTEGER,
    ifh INTEGER,
    bu INTEGER,
    buh INTEGER,
    bb_pct NUMERIC(5,2),
    k_pct NUMERIC(5,2),
    bb_k NUMERIC(5,3),
    obp NUMERIC(5,3),
    slg NUMERIC(5,3),
    ops NUMERIC(5,3),
    iso NUMERIC(5,3),
    babip NUMERIC(5,3),
    gb_fb NUMERIC(5,3),
    ld_pct NUMERIC(5,2),
    gb_pct NUMERIC(5,2),
    fb_pct NUMERIC(5,2),
    iffb_pct NUMERIC(5,2),
    hr_fb NUMERIC(5,2),
    ifh_pct NUMERIC(5,2),
    buh_pct NUMERIC(5,2),
    tto_pct NUMERIC(5,2),
    
    -- Advanced metrics
    woba NUMERIC(5,3),
    wraa NUMERIC(6,1),
    wrc INTEGER,
    batting NUMERIC(6,1),
    fielding NUMERIC(6,1),
    replacement NUMERIC(6,1),
    positional NUMERIC(6,1),
    wleague NUMERIC(6,1),
    defense NUMERIC(6,1),
    offense NUMERIC(6,1),
    rar NUMERIC(6,1),
    war NUMERIC(5,1),
    warold NUMERIC(5,1),
    dollars NUMERIC(8,1),
    baserunning NUMERIC(6,1),
    spd NUMERIC(5,1),
    wrc_plus INTEGER,
    wbsr NUMERIC(6,1),
    
    -- Win Probability
    wpa NUMERIC(6,2),
    wpa_minus NUMERIC(6,2),
    wpa_plus NUMERIC(6,2),
    re24 NUMERIC(6,1),
    rew NUMERIC(6,1),
    pli NUMERIC(5,2),
    ph INTEGER,
    wpa_li NUMERIC(6,2),
    clutch NUMERIC(6,2),
    
    -- Pitch type data (simple)
    fball_pct NUMERIC(5,2),
    fbv NUMERIC(5,1),
    sl_pct NUMERIC(5,2),
    slv NUMERIC(5,1),
    ct_pct NUMERIC(5,2),
    ctv NUMERIC(5,1),
    cb_pct NUMERIC(5,2),
    cbv NUMERIC(5,1),
    ch_pct NUMERIC(5,2),
    chv NUMERIC(5,1),
    sf_pct NUMERIC(5,2),
    sfv NUMERIC(5,1),
    xx_pct NUMERIC(5,2),
    wfb NUMERIC(6,1),
    wsl NUMERIC(6,1),
    wct NUMERIC(6,1),
    wcb NUMERIC(6,1),
    wch NUMERIC(6,1),
    wsf NUMERIC(6,1),
    wfb_c NUMERIC(6,1),
    wsl_c NUMERIC(6,1),
    wct_c NUMERIC(6,1),
    wcb_c NUMERIC(6,1),
    wch_c NUMERIC(6,1),
    wsf_c NUMERIC(6,1),
    
    -- Plate discipline
    o_swing_pct NUMERIC(5,2),
    z_swing_pct NUMERIC(5,2),
    swing_pct NUMERIC(5,2),
    o_contact_pct NUMERIC(5,2),
    z_contact_pct NUMERIC(5,2),
    contact_pct NUMERIC(5,2),
    zone_pct NUMERIC(5,2),
    f_strike_pct NUMERIC(5,2),
    swstr_pct NUMERIC(5,2),
    cstr_pct NUMERIC(5,2),
    c_swstr_pct NUMERIC(5,2),
    
    -- Batted ball direction
    pull INTEGER,
    cent INTEGER,
    oppo INTEGER,
    soft INTEGER,
    med INTEGER,
    hard INTEGER,
    bipcount INTEGER,
    pull_pct NUMERIC(5,2),
    cent_pct NUMERIC(5,2),
    oppo_pct NUMERIC(5,2),
    soft_pct NUMERIC(5,2),
    med_pct NUMERIC(5,2),
    hard_pct NUMERIC(5,2),
    
    -- Baserunning
    ubr NUMERIC(6,1),
    gdpruns NUMERIC(6,1),
    
    -- Plus stats (era-adjusted)
    avg_plus INTEGER,
    bb_pct_plus INTEGER,
    k_pct_plus INTEGER,
    obp_plus INTEGER,
    slg_plus INTEGER,
    iso_plus INTEGER,
    babip_plus INTEGER,
    ld_pct_plus INTEGER,
    gb_pct_plus INTEGER,
    fb_pct_plus INTEGER,
    hrfb_pct_plus INTEGER,
    pull_pct_plus INTEGER,
    cent_pct_plus INTEGER,
    oppo_pct_plus INTEGER,
    soft_pct_plus INTEGER,
    med_pct_plus INTEGER,
    hard_pct_plus INTEGER,
    
    -- Expected stats
    xwoba NUMERIC(5,3),
    xavg NUMERIC(5,3),
    xslg NUMERIC(5,3),
    
    -- Team value
    pptv INTEGER,
    cptv INTEGER,
    bptv INTEGER,
    dsv INTEGER,
    dgv INTEGER,
    btv INTEGER,
    rpptv NUMERIC(6,1),
    rbptv NUMERIC(6,1),
    ebv INTEGER,
    esv INTEGER,
    rfteamv NUMERIC(6,1),
    rbteamv NUMERIC(6,1),
    rtv NUMERIC(6,1),
    
    -- PITCHf/x data
    pfx_fa_pct NUMERIC(5,2),
    pfx_fc_pct NUMERIC(5,2),
    pfx_fs_pct NUMERIC(5,2),
    pfx_fo_pct NUMERIC(5,2),
    pfx_si_pct NUMERIC(5,2),
    pfx_sl_pct NUMERIC(5,2),
    pfx_cu_pct NUMERIC(5,2),
    pfx_kc_pct NUMERIC(5,2),
    pfx_ep_pct NUMERIC(5,2),
    pfx_ch_pct NUMERIC(5,2),
    pfx_sc_pct NUMERIC(5,2),
    pfx_vfa NUMERIC(5,1),
    pfx_vfc NUMERIC(5,1),
    pfx_vfs NUMERIC(5,1),
    pfx_vfo NUMERIC(5,1),
    pfx_vsi NUMERIC(5,1),
    pfx_vsl NUMERIC(5,1),
    pfx_vcu NUMERIC(5,1),
    pfx_vkc NUMERIC(5,1),
    pfx_vep NUMERIC(5,1),
    pfx_vch NUMERIC(5,1),
    pfx_vsc NUMERIC(5,1),
    pfx_fa_x NUMERIC(5,2),
    pfx_fc_x NUMERIC(5,2),
    pfx_fs_x NUMERIC(5,2),
    pfx_fo_x NUMERIC(5,2),
    pfx_si_x NUMERIC(5,2),
    pfx_sl_x NUMERIC(5,2),
    pfx_cu_x NUMERIC(5,2),
    pfx_kc_x NUMERIC(5,2),
    pfx_ep_x NUMERIC(5,2),
    pfx_ch_x NUMERIC(5,2),
    pfx_sc_x NUMERIC(5,2),
    pfx_fa_z NUMERIC(5,2),
    pfx_fc_z NUMERIC(5,2),
    pfx_fs_z NUMERIC(5,2),
    pfx_fo_z NUMERIC(5,2),
    pfx_si_z NUMERIC(5,2),
    pfx_sl_z NUMERIC(5,2),
    pfx_cu_z NUMERIC(5,2),
    pfx_kc_z NUMERIC(5,2),
    pfx_ep_z NUMERIC(5,2),
    pfx_ch_z NUMERIC(5,2),
    pfx_sc_z NUMERIC(5,2),
    pfx_wfa NUMERIC(6,1),
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
    pfx_wfa_c NUMERIC(6,1),
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
    pfx_o_swing_pct NUMERIC(5,2),
    pfx_z_swing_pct NUMERIC(5,2),
    pfx_swing_pct NUMERIC(5,2),
    pfx_o_contact_pct NUMERIC(5,2),
    pfx_z_contact_pct NUMERIC(5,2),
    pfx_contact_pct NUMERIC(5,2),
    pfx_zone_pct NUMERIC(5,2),
    pfx_pace NUMERIC(5,2),
    
    -- PITCHInfo data
    pi_ch_pct NUMERIC(5,2),
    pi_cu_pct NUMERIC(5,2),
    pi_fa_pct NUMERIC(5,2),
    pi_fc_pct NUMERIC(5,2),
    pi_fs_pct NUMERIC(5,2),
    pi_sb_pct NUMERIC(5,2),
    pi_si_pct NUMERIC(5,2),
    pi_sl_pct NUMERIC(5,2),
    pi_vch NUMERIC(5,1),
    pi_vcu NUMERIC(5,1),
    pi_vfa NUMERIC(5,1),
    pi_vfc NUMERIC(5,1),
    pi_vfs NUMERIC(5,1),
    pi_vsb NUMERIC(5,1),
    pi_vsi NUMERIC(5,1),
    pi_vsl NUMERIC(5,1),
    pi_ch_x NUMERIC(5,2),
    pi_cu_x NUMERIC(5,2),
    pi_fa_x NUMERIC(5,2),
    pi_fc_x NUMERIC(5,2),
    pi_fs_x NUMERIC(5,2),
    pi_sb_x NUMERIC(5,2),
    pi_si_x NUMERIC(5,2),
    pi_sl_x NUMERIC(5,2),
    pi_ch_z NUMERIC(5,2),
    pi_cu_z NUMERIC(5,2),
    pi_fa_z NUMERIC(5,2),
    pi_fc_z NUMERIC(5,2),
    pi_fs_z NUMERIC(5,2),
    pi_sb_z NUMERIC(5,2),
    pi_si_z NUMERIC(5,2),
    pi_sl_z NUMERIC(5,2),
    pi_wch NUMERIC(6,1),
    pi_wcu NUMERIC(6,1),
    pi_wfa NUMERIC(6,1),
    pi_wfc NUMERIC(6,1),
    pi_wfs NUMERIC(6,1),
    pi_wsb NUMERIC(6,1),
    pi_wsi NUMERIC(6,1),
    pi_wsl NUMERIC(6,1),
    pi_wch_c NUMERIC(6,1),
    pi_wcu_c NUMERIC(6,1),
    pi_wfa_c NUMERIC(6,1),
    pi_wfc_c NUMERIC(6,1),
    pi_wfs_c NUMERIC(6,1),
    pi_wsb_c NUMERIC(6,1),
    pi_wsi_c NUMERIC(6,1),
    pi_wsl_c NUMERIC(6,1),
    pi_o_swing_pct NUMERIC(5,2),
    pi_z_swing_pct NUMERIC(5,2),
    pi_swing_pct NUMERIC(5,2),
    pi_o_contact_pct NUMERIC(5,2),
    pi_z_contact_pct NUMERIC(5,2),
    pi_contact_pct NUMERIC(5,2),
    pi_zone_pct NUMERIC(5,2),
    pi_pace NUMERIC(5,2),
    
    -- StatCast metrics
    events INTEGER,
    ev NUMERIC(5,1),
    la NUMERIC(5,1),
    barrels INTEGER,
    barrel_pct NUMERIC(5,2),
    maxev NUMERIC(5,1),
    hardhit INTEGER,
    hardhit_pct NUMERIC(5,2),
    q NUMERIC(5,1),
    tg INTEGER,
    tpa INTEGER,
    
    -- Team info
    team_name_abb VARCHAR(10),
    teamid INTEGER,
    pos NUMERIC(5,1),
    phli NUMERIC(5,2),
    
    -- Additional pitch types
    pi_xx_pct NUMERIC(5,2),
    pi_vxx NUMERIC(5,1),
    pi_xx_x NUMERIC(5,2),
    pi_xx_z NUMERIC(5,2),
    pi_wxx NUMERIC(6,1),
    pi_wxx_c NUMERIC(6,1),
    rbtv NUMERIC(6,1),
    pi_cs_pct NUMERIC(5,2),
    pi_vcs NUMERIC(5,1),
    pi_cs_x NUMERIC(5,2),
    pi_cs_z NUMERIC(5,2),
    pi_wcs NUMERIC(6,1),
    pi_wcs_c NUMERIC(6,1),
    kn_pct NUMERIC(5,2),
    knv NUMERIC(5,1),
    wkn NUMERIC(6,1),
    wkn_c NUMERIC(6,1),
    pfx_kn_pct NUMERIC(5,2),
    pfx_vkn NUMERIC(5,1),
    pfx_kn_x NUMERIC(5,2),
    pfx_kn_z NUMERIC(5,2),
    pfx_wkn NUMERIC(6,1),
    pfx_wkn_c NUMERIC(6,1),
    pi_kn_pct NUMERIC(5,2),
    pi_vkn NUMERIC(5,1),
    pi_kn_x NUMERIC(5,2),
    pi_kn_z NUMERIC(5,2),
    pi_wkn NUMERIC(6,1),
    pi_wkn_c NUMERIC(6,1),
    rcptv NUMERIC(6,1),
    cframing NUMERIC(6,1),
    rdgv NUMERIC(6,1),
    rdsv NUMERIC(6,1),
    
    -- Import metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (playerid, season)
);

-- ============================================================================
-- FANGRAPHS PITCHING LEADERS (Complete)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fg_pitching_raw (
    -- Identifiers
    season INTEGER,
    team_name VARCHAR(50),
    throws VARCHAR(5),
    xmlbamid INTEGER,
    playernameroute VARCHAR(255),
    playername VARCHAR(255),
    playerid INTEGER,
    age INTEGER,
    agerng VARCHAR(10),
    seasonmin INTEGER,
    seasonmax INTEGER,
    
    -- Basic pitching stats
    w INTEGER,
    l INTEGER,
    g INTEGER,
    gs INTEGER,
    cg INTEGER,
    sho INTEGER,
    sv INTEGER,
    hld INTEGER,
    bs INTEGER,
    ipouts INTEGER,
    tbf INTEGER,
    h INTEGER,
    r INTEGER,
    er INTEGER,
    hr INTEGER,
    bb INTEGER,
    ibb INTEGER,
    hbp INTEGER,
    wp INTEGER,
    bk INTEGER,
    so INTEGER,
    
    -- Rate stats
    era NUMERIC(5,2),
    whip NUMERIC(5,3),
    babip NUMERIC(5,3),
    lob_pct NUMERIC(5,2),
    fip NUMERIC(5,2),
    gb_pct NUMERIC(5,2),
    fb_pct NUMERIC(5,2),
    ld_pct NUMERIC(5,2),
    iffb_pct NUMERIC(5,2),
    hr_fb NUMERIC(5,2),
    era_minus INTEGER,
    fip_minus INTEGER,
    xfip NUMERIC(5,2),
    
    -- Plate discipline
    bb_pct NUMERIC(5,2),
    k_pct NUMERIC(5,2),
    k_bb NUMERIC(5,3),
    h9 NUMERIC(5,2),
    hr9 NUMERIC(5,2),
    bb9 NUMERIC(5,2),
    so9 NUMERIC(5,2),
    so_w NUMERIC(5,3),
    
    -- Advanced metrics
    war NUMERIC(5,1),
    rar NUMERIC(6,1),
    dollars NUMERIC(8,1),
    tto_pct NUMERIC(5,2),
    k_minus_bb_pct NUMERIC(5,2),
    
    -- Pitch values
    kwera NUMERIC(5,2),
    
    -- Contact management
    contact_pct NUMERIC(5,2),
    zone_pct NUMERIC(5,2),
    pace NUMERIC(5,2),
    
    -- Batted ball
    gb INTEGER,
    fb INTEGER,
    ld INTEGER,
    pu INTEGER,
    balls INTEGER,
    strikes INTEGER,
    pitches INTEGER,
    
    -- Team info
    team_name_abb VARCHAR(10),
    teamid INTEGER,
    
    -- Import metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (playerid, season)
);

-- ============================================================================
-- FANGRAPHS FIELDING LEADERS (Complete)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fg_fielding_raw (
    -- Identifiers
    season INTEGER,
    team_name VARCHAR(50),
    xmlbamid INTEGER,
    playernameroute VARCHAR(255),
    playername VARCHAR(255),
    playerid INTEGER,
    age INTEGER,
    agerng VARCHAR(10),
    seasonmin INTEGER,
    seasonmax INTEGER,
    
    -- Position and games
    pos VARCHAR(10),
    g INTEGER,
    gs INTEGER,
    inn NUMERIC(6,1),
    po INTEGER,
    a INTEGER,
    e INTEGER,
    fe INTEGER,
    te INTEGER,
    dp INTEGER,
    dps INTEGER,
    dpt INTEGER,
    dpf INTEGER,
    scp INTEGER,
    sb INTEGER,
    cs INTEGER,
    pb INTEGER,
    wp INTEGER,
    fp NUMERIC(5,3),
    
    -- Advanced fielding metrics
    tz INTEGER,
    tzl INTEGER,
    tzr INTEGER,
    tzcatcher INTEGER,
    tzfirst INTEGER,
    tzsecond INTEGER,
    tzthird INTEGER,
    tzshort INTEGER,
    tzleft INTEGER,
    tzcenter INTEGER,
    tzright INTEGER,
    
    -- UZR (Ultimate Zone Rating)
    uzr NUMERIC(6,1),
    uzr_150 NUMERIC(6,1),
    
    -- DRS (Defensive Runs Saved)
    drs INTEGER,
    biz INTEGER,
    plays INTEGER,
    
    -- Range and efficiency
    rngr NUMERIC(6,1),
    errr NUMERIC(6,1),
    uzrpm NUMERIC(6,1),
    
    -- Framing (catchers)
    framing NUMERIC(6,1),
    blocking NUMERIC(6,1),
    throwing NUMERIC(6,1),
    
    -- Team info
    team_name_abb VARCHAR(10),
    teamid INTEGER,
    
    -- Import metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (playerid, season, pos)
);

-- ============================================================================
-- FANGRAPHS INDEXES
-- ============================================================================

-- Batting indexes
CREATE INDEX IF NOT EXISTS idx_fg_batting_season ON fg_batting_raw(season);
CREATE INDEX IF NOT EXISTS idx_fg_batting_player ON fg_batting_raw(playerid);
CREATE INDEX IF NOT EXISTS idx_fg_batting_war ON fg_batting_raw(war DESC);
CREATE INDEX IF NOT EXISTS idx_fg_batting_wrc_plus ON fg_batting_raw(wrc_plus DESC);
CREATE INDEX IF NOT EXISTS idx_fg_batting_team ON fg_batting_raw(team_name_abb);

-- Pitching indexes
CREATE INDEX IF NOT EXISTS idx_fg_pitching_season ON fg_pitching_raw(season);
CREATE INDEX IF NOT EXISTS idx_fg_pitching_player ON fg_pitching_raw(playerid);
CREATE INDEX IF NOT EXISTS idx_fg_pitching_war ON fg_pitching_raw(war DESC);
CREATE INDEX IF NOT EXISTS idx_fg_pitching_era ON fg_pitching_raw(era);

-- Fielding indexes
CREATE INDEX IF NOT EXISTS idx_fg_fielding_season ON fg_fielding_raw(season);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_player ON fg_fielding_raw(playerid);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_pos ON fg_fielding_raw(pos);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_uzr ON fg_fielding_raw(uzr DESC);
CREATE INDEX IF NOT EXISTS idx_fg_fielding_drs ON fg_fielding_raw(drs DESC);

COMMENT ON TABLE fg_batting_raw IS 'Complete FanGraphs batting leaders data (1871-present)';
COMMENT ON TABLE fg_pitching_raw IS 'Complete FanGraphs pitching leaders data (1871-present)';
COMMENT ON TABLE fg_fielding_raw IS 'Complete FanGraphs fielding leaders data (1871-present)';