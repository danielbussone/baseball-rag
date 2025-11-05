-- Lahman Database Raw Tables (Store As-Is)

-- ============================================================================
-- LAHMAN CORE TABLES
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
    x2b INTEGER,
    x3b INTEGER,
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
    x2b INTEGER,
    x3b INTEGER,
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

-- Awards
CREATE TABLE IF NOT EXISTS lahman_awards_players (
    player_id VARCHAR(9),
    award_id VARCHAR(75),
    year_id INTEGER,
    lg_id CHAR(2),
    tie VARCHAR(1),
    notes VARCHAR(100)
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

-- ============================================================================
-- LAHMAN INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_lahman_people_name ON lahman_people(name_last, name_first);
CREATE INDEX IF NOT EXISTS idx_lahman_batting_player_year ON lahman_batting(player_id, year_id);
CREATE INDEX IF NOT EXISTS idx_lahman_batting_post_player ON lahman_batting_post(player_id);
CREATE INDEX IF NOT EXISTS idx_lahman_pitching_player_year ON lahman_pitching(player_id, year_id);
CREATE INDEX IF NOT EXISTS idx_lahman_awards_player ON lahman_awards_players(player_id);
CREATE INDEX IF NOT EXISTS idx_lahman_hof_player ON lahman_hall_of_fame(player_id);

COMMENT ON TABLE lahman_people IS 'Lahman biographical data (1871-2024)';
COMMENT ON TABLE lahman_batting_post IS 'Lahman postseason batting stats';
COMMENT ON TABLE lahman_pitching_post IS 'Lahman postseason pitching stats';