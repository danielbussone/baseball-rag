-- Lahman Database Complete Schema (All Tables)

-- ============================================================================
-- LAHMAN CORE TABLES (Complete)
-- ============================================================================

-- People (biographical data)
CREATE TABLE IF NOT EXISTS lahman_people (
    player_id VARCHAR(9) PRIMARY KEY,
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
    name_first VARCHAR(50),
    name_last VARCHAR(50),
    name_given VARCHAR(255),
    weight INTEGER,
    height INTEGER,
    bats CHAR(1),
    throws CHAR(1),
    debut DATE,
    final_game DATE,
    retro_id VARCHAR(9),
    bbref_id VARCHAR(9)
);

-- Batting (regular season)
CREATE TABLE IF NOT EXISTS lahman_batting (
    player_id VARCHAR(9),
    year_id INTEGER,
    stint INTEGER,
    team_id CHAR(3),
    lg_id CHAR(2),
    g INTEGER,
    ab INTEGER,
    r INTEGER,
    h INTEGER,
    doubles INTEGER,
    triples INTEGER,
    hr INTEGER,
    rbi INTEGER,
    sb INTEGER,
    cs INTEGER,
    bb INTEGER,
    so INTEGER,
    ibb INTEGER,
    hbp INTEGER,
    sh INTEGER,
    sf INTEGER,
    gidp INTEGER,
    PRIMARY KEY (player_id, year_id, stint)
);

-- Batting Post (postseason)
CREATE TABLE IF NOT EXISTS lahman_batting_post (
    year_id INTEGER,
    round VARCHAR(10),
    player_id VARCHAR(9),
    team_id VARCHAR(3),
    lg_id VARCHAR(2),
    g INTEGER,
    ab INTEGER,
    r INTEGER,
    h INTEGER,
    doubles INTEGER,
    triples INTEGER,
    hr INTEGER,
    rbi INTEGER,
    sb INTEGER,
    cs INTEGER,
    bb INTEGER,
    so INTEGER,
    ibb INTEGER,
    hbp INTEGER,
    sh INTEGER,
    sf INTEGER,
    gidp INTEGER,
    PRIMARY KEY (year_id, round, player_id)
);

-- Pitching (regular season)
CREATE TABLE IF NOT EXISTS lahman_pitching (
    player_id VARCHAR(9),
    year_id INTEGER,
    stint INTEGER,
    team_id VARCHAR(3),
    lg_id VARCHAR(2),
    w INTEGER,
    l INTEGER,
    g INTEGER,
    gs INTEGER,
    cg INTEGER,
    sho INTEGER,
    sv INTEGER,
    ipouts INTEGER,
    h INTEGER,
    er INTEGER,
    hr INTEGER,
    bb INTEGER,
    so INTEGER,
    baopp FLOAT,
    era FLOAT,
    ibb INTEGER,
    wp INTEGER,
    hbp INTEGER,
    bk INTEGER,
    bfp INTEGER,
    gf INTEGER,
    r INTEGER,
    sh INTEGER,
    sf INTEGER,
    gidp INTEGER,
    PRIMARY KEY (player_id, year_id, stint)
);

-- Pitching Post (postseason)
CREATE TABLE IF NOT EXISTS lahman_pitching_post (
    year_id INTEGER,
    round VARCHAR(10),
    player_id VARCHAR(9),
    team_id VARCHAR(3),
    lg_id VARCHAR(2),
    w INTEGER,
    l INTEGER,
    g INTEGER,
    gs INTEGER,
    cg INTEGER,
    sho INTEGER,
    sv INTEGER,
    ipouts INTEGER,
    h INTEGER,
    er INTEGER,
    hr INTEGER,
    bb INTEGER,
    so INTEGER,
    baopp FLOAT,
    era FLOAT,
    ibb INTEGER,
    wp INTEGER,
    hbp INTEGER,
    bk INTEGER,
    bfp INTEGER,
    gf INTEGER,
    r INTEGER,
    sh INTEGER,
    sf INTEGER,
    gidp INTEGER,
    PRIMARY KEY (year_id, round, player_id)
);

-- Fielding (regular season)
CREATE TABLE IF NOT EXISTS lahman_fielding (
    player_id VARCHAR(9),
    year_id INTEGER,
    stint INTEGER,
    team_id VARCHAR(3),
    lg_id VARCHAR(2),
    pos VARCHAR(2),
    g INTEGER,
    gs INTEGER,
    inn_outs INTEGER,
    po INTEGER,
    a INTEGER,
    e INTEGER,
    dp INTEGER,
    pb INTEGER,
    wp INTEGER,
    sb INTEGER,
    cs INTEGER,
    zr INTEGER,
    PRIMARY KEY (player_id, year_id, stint, pos)
);

-- Fielding Post (postseason)
CREATE TABLE IF NOT EXISTS lahman_fielding_post (
    year_id INTEGER,
    round VARCHAR(10),
    player_id VARCHAR(9),
    team_id VARCHAR(3),
    lg_id VARCHAR(2),
    pos VARCHAR(2),
    g INTEGER,
    gs INTEGER,
    inn_outs INTEGER,
    po INTEGER,
    a INTEGER,
    e INTEGER,
    dp INTEGER,
    tp INTEGER,
    pb INTEGER,
    sb INTEGER,
    cs INTEGER,
    PRIMARY KEY (year_id, round, player_id, pos)
);

-- Appearances by position
CREATE TABLE IF NOT EXISTS lahman_appearances (
    year_id INTEGER,
    team_id VARCHAR(3),
    lg_id VARCHAR(2),
    player_id VARCHAR(9),
    g_all INTEGER,
    gs INTEGER,
    g_batting INTEGER,
    g_defense INTEGER,
    g_p INTEGER,
    g_c INTEGER,
    g_1b INTEGER,
    g_2b INTEGER,
    g_3b INTEGER,
    g_ss INTEGER,
    g_lf INTEGER,
    g_cf INTEGER,
    g_rf INTEGER,
    g_of INTEGER,
    g_dh INTEGER,
    g_ph INTEGER,
    g_pr INTEGER,
    PRIMARY KEY (year_id, team_id, player_id)
);

-- Managers
CREATE TABLE IF NOT EXISTS lahman_managers (
    player_id VARCHAR(9),
    year_id INTEGER,
    team_id VARCHAR(3),
    lg_id VARCHAR(2),
    inseason INTEGER,
    g INTEGER,
    w INTEGER,
    l INTEGER,
    rank INTEGER,
    plyr_mgr VARCHAR(1),
    PRIMARY KEY (player_id, year_id, team_id, inseason)
);

-- Awards
CREATE TABLE IF NOT EXISTS lahman_awards_players (
    player_id VARCHAR(9),
    award_id VARCHAR(75),
    year_id INTEGER,
    lg_id CHAR(2),
    tie VARCHAR(1),
    notes VARCHAR(100)
);

-- Awards Share Players (voting details)
CREATE TABLE IF NOT EXISTS lahman_awards_share_players (
    award_id VARCHAR(75),
    year_id INTEGER,
    lg_id VARCHAR(2),
    player_id VARCHAR(9),
    points_won NUMERIC(6,2),
    points_max INTEGER,
    votes_first INTEGER
);

-- Hall of Fame
CREATE TABLE IF NOT EXISTS lahman_hall_of_fame (
    player_id VARCHAR(9),
    year_id INTEGER,
    voted_by VARCHAR(64),
    ballots INTEGER,
    needed INTEGER,
    votes INTEGER,
    inducted CHAR(1),
    category VARCHAR(20),
    needed_note VARCHAR(25)
);

-- All-Star
CREATE TABLE IF NOT EXISTS lahman_all_star_full (
    player_id VARCHAR(9),
    year_id INTEGER,
    game_num INTEGER,
    game_id VARCHAR(12),
    team_id CHAR(3),
    lg_id CHAR(2),
    gp INTEGER,
    starting_pos INTEGER
);

-- Series Post (postseason series results)
CREATE TABLE IF NOT EXISTS lahman_series_post (
    year_id INTEGER,
    round VARCHAR(10),
    winner VARCHAR(3),
    loser VARCHAR(3),
    wins INTEGER,
    losses INTEGER,
    ties INTEGER,
    PRIMARY KEY (year_id, round)
);

-- Salaries
CREATE TABLE IF NOT EXISTS lahman_salaries (
    year_id INTEGER,
    team_id VARCHAR(3),
    lg_id VARCHAR(2),
    player_id VARCHAR(9),
    salary INTEGER,
    PRIMARY KEY (year_id, team_id, player_id)
);

-- College Playing
CREATE TABLE IF NOT EXISTS lahman_college_playing (
    player_id VARCHAR(9),
    school_id VARCHAR(15),
    year_id INTEGER
);

-- Schools
CREATE TABLE IF NOT EXISTS lahman_schools (
    school_id VARCHAR(15) PRIMARY KEY,
    name_full VARCHAR(255),
    city VARCHAR(55),
    state VARCHAR(55),
    country VARCHAR(55)
);

-- Parks
CREATE TABLE IF NOT EXISTS lahman_parks (
    park_key VARCHAR(255) PRIMARY KEY,
    park_name VARCHAR(255),
    park_alias VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    country VARCHAR(255)
);

-- Teams
CREATE TABLE IF NOT EXISTS lahman_teams (
    year_id INTEGER,
    lg_id VARCHAR(2),
    team_id VARCHAR(3),
    franch_id VARCHAR(3),
    div_id VARCHAR(1),
    rank INTEGER,
    g INTEGER,
    ghome INTEGER,
    w INTEGER,
    l INTEGER,
    div_win VARCHAR(1),
    wcwin VARCHAR(1),
    lg_win VARCHAR(1),
    wswin VARCHAR(1),
    r INTEGER,
    ab INTEGER,
    h INTEGER,
    x2b INTEGER,
    x3b INTEGER,
    hr INTEGER,
    bb INTEGER,
    so INTEGER,
    sb INTEGER,
    cs INTEGER,
    hbp INTEGER,
    sf INTEGER,
    ra INTEGER,
    er INTEGER,
    era FLOAT,
    cg INTEGER,
    sho INTEGER,
    sv INTEGER,
    ipouts INTEGER,
    ha INTEGER,
    hra INTEGER,
    bba INTEGER,
    soa INTEGER,
    e INTEGER,
    dp INTEGER,
    fp FLOAT,
    name VARCHAR(50),
    park VARCHAR(50),
    attendance INTEGER,
    bpf INTEGER,
    ppf INTEGER,
    team_idbr VARCHAR(3),
    team_idlahman45 VARCHAR(3),
    team_idretro VARCHAR(3),
    PRIMARY KEY (year_id, team_id)
);

-- Teams Franchises
CREATE TABLE IF NOT EXISTS lahman_teams_franchises (
    franch_id VARCHAR(3) PRIMARY KEY,
    franch_name VARCHAR(50),
    active VARCHAR(1),
    na_assoc VARCHAR(3)
);

-- ============================================================================
-- LAHMAN INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_lahman_people_name ON lahman_people(name_last, name_first);
CREATE INDEX IF NOT EXISTS idx_lahman_batting_player_year ON lahman_batting(player_id, year_id);
CREATE INDEX IF NOT EXISTS idx_lahman_batting_post_player ON lahman_batting_post(player_id);
CREATE INDEX IF NOT EXISTS idx_lahman_pitching_player_year ON lahman_pitching(player_id, year_id);
CREATE INDEX IF NOT EXISTS idx_lahman_pitching_post_player ON lahman_pitching_post(player_id);
CREATE INDEX IF NOT EXISTS idx_lahman_fielding_player_year ON lahman_fielding(player_id, year_id);
CREATE INDEX IF NOT EXISTS idx_lahman_fielding_post_player ON lahman_fielding_post(player_id);
CREATE INDEX IF NOT EXISTS idx_lahman_appearances_player_year ON lahman_appearances(player_id, year_id);
CREATE INDEX IF NOT EXISTS idx_lahman_awards_player ON lahman_awards_players(player_id);
CREATE INDEX IF NOT EXISTS idx_lahman_awards_share_player ON lahman_awards_share_players(player_id);
CREATE INDEX IF NOT EXISTS idx_lahman_hof_player ON lahman_hall_of_fame(player_id);
CREATE INDEX IF NOT EXISTS idx_lahman_salaries_player_year ON lahman_salaries(player_id, year_id);
CREATE INDEX IF NOT EXISTS idx_lahman_managers_player_year ON lahman_managers(player_id, year_id);

COMMENT ON TABLE lahman_people IS 'Lahman biographical data (1871-2024)';
COMMENT ON TABLE lahman_batting_post IS 'Lahman postseason batting stats';
COMMENT ON TABLE lahman_pitching_post IS 'Lahman postseason pitching stats';
COMMENT ON TABLE lahman_fielding_post IS 'Lahman postseason fielding stats';
COMMENT ON TABLE lahman_appearances IS 'Games played by position';
COMMENT ON TABLE lahman_awards_share_players IS 'Award voting details with vote totals';
COMMENT ON TABLE lahman_salaries IS 'Player salaries (1985-2016)';
COMMENT ON TABLE lahman_managers IS 'Managerial records';
COMMENT ON TABLE lahman_series_post IS 'Postseason series results';
COMMENT ON TABLE lahman_college_playing IS 'College attendance records';
COMMENT ON TABLE lahman_parks IS 'Ballpark information';
COMMENT ON TABLE lahman_teams_franchises IS 'Franchise information';