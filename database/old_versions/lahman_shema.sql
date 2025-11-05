-- Lahman Database Schema
-- Core tables for baseball statistics and biographical data

-- Player biographical information
CREATE TABLE IF NOT EXISTS people (
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

-- Batting statistics by player-season
CREATE TABLE IF NOT EXISTS batting (
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

-- Awards and honors
CREATE TABLE IF NOT EXISTS awards_players (
    player_id VARCHAR(9),
    award_id VARCHAR(75),
    year_id INTEGER,
    lg_id CHAR(2),
    tie VARCHAR(1),
    notes VARCHAR(100)
);

-- Hall of Fame voting
CREATE TABLE IF NOT EXISTS hall_of_fame (
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

-- All-Star appearances
CREATE TABLE IF NOT EXISTS all_star_full (
    player_id VARCHAR(9),
    year_id INTEGER,
    game_num INTEGER,
    game_id VARCHAR(12),
    team_id CHAR(3),
    lg_id CHAR(2),
    gp INTEGER,
    starting_pos INTEGER
);

-- Pitching statistics by player-season
CREATE TABLE IF NOT EXISTS pitching (
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

-- Fielding statistics by player-season-position
CREATE TABLE IF NOT EXISTS fielding (
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

-- Team statistics by season
CREATE TABLE IF NOT EXISTS teams (
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

-- Create unified player view combining biographical and career stats
CREATE OR REPLACE VIEW player_profiles AS
WITH career_batting AS (
    SELECT 
        player_id,
        SUM(g) AS career_games,
        SUM(ab) AS career_ab,
        SUM(h) AS career_hits,
        SUM(hr) AS career_hr,
        SUM(rbi) AS career_rbi,
        SUM(sb) AS career_sb,
        SUM(bb) AS career_bb,
        SUM(hbp) AS career_hbp,
        SUM(sf) AS career_sf
    FROM batting
    GROUP BY player_id
), career_awards AS (
    SELECT
        player_id,
        COUNT(award_id) AS total_awards,
        SUM(CASE WHEN award_id = 'Most Valuable Player' THEN 1 ELSE 0 END) AS mvps,
        SUM(CASE WHEN award_id = 'Cy Young Award' THEN 1 ELSE 0 END) AS cy_youngs,
        SUM(CASE WHEN award_id = 'Rookie of the Year' THEN 1 ELSE 0 END) AS roy,
        SUM(CASE WHEN award_id = 'Gold Glove' THEN 1 ELSE 0 END) AS gold_gloves,
        SUM(CASE WHEN award_id = 'Platinum Glove' THEN 1 ELSE 0 END) AS platinum_gloves,
        SUM(CASE WHEN award_id ILIKE 'Silver Slugger' THEN 1 ELSE 0 END) AS silver_sluggers,
        SUM(CASE WHEN award_id = 'World Series MVP' THEN 1 ELSE 0 END) AS ws_mvps,
        SUM(CASE WHEN award_id = 'All-Star Game MVP' THEN 1 ELSE 0 END) AS asg_mvps,
        SUM(CASE WHEN award_id = 'ALCS MVP' THEN 1 ELSE 0 END) AS alcs_mvps,
        SUM(CASE WHEN award_id = 'NLCS MVP' THEN 1 ELSE 0 END) AS nlcs_mvps,
        SUM(CASE WHEN award_id = 'Triple Crown' THEN 1 ELSE 0 END) AS triple_crowns,
        SUM(CASE WHEN award_id = 'Pitching Triple Crown' THEN 1 ELSE 0 END) AS pitching_triple_crowns,
        SUM(CASE WHEN award_id = 'Hank Aaron Award' THEN 1 ELSE 0 END) AS hank_aaron_awards,
        SUM(CASE WHEN award_id = 'Roberto Clemente Award' THEN 1 ELSE 0 END) AS clemente_awards,
        SUM(CASE WHEN award_id = 'Comeback Player of the Year' THEN 1 ELSE 0 END) AS comeback_awards,
        SUM(CASE WHEN award_id = 'Reliever of the Year Award' THEN 1 ELSE 0 END) AS reliever_awards
    FROM awards_players
    GROUP BY player_id 
), career_all_star_games AS (
    SELECT
        player_id,
        COUNT(year_id) AS all_star_games
    FROM all_star_full
    GROUP BY player_id 
), career_pitching AS (
    SELECT 
        player_id,
        SUM(w) AS career_wins,
        SUM(l) AS career_losses,
        SUM(g) AS career_games_pitched,
        SUM(gs) AS career_games_started,
        SUM(sv) AS career_saves,
        SUM(so) AS career_strikeouts,
        ROUND(SUM(ipouts) / 3.0, 1) AS career_innings_pitched,
        CASE WHEN SUM(ipouts) > 0 THEN ROUND(9.0 * SUM(er) / (SUM(ipouts) / 3.0), 2) END AS career_era
    FROM pitching
    GROUP BY player_id
), career_fielding AS (
    SELECT 
        player_id,
        STRING_AGG(DISTINCT pos, ',' ORDER BY pos) AS positions_played,
        SUM(g) AS career_fielding_games,
        SUM(po + a) AS career_total_chances,
        SUM(e) AS career_errors,
        CASE WHEN SUM(po + a + e) > 0 THEN ROUND(1.0 - (SUM(e)::numeric / SUM(po + a + e)::numeric), 3) END AS career_fielding_pct
    FROM fielding
    GROUP BY player_id
), career_hall_of_fame AS (
    SELECT 
        player_id,
        SUM(CASE WHEN inducted = 'Y' THEN 1 ELSE 0 END) AS hall_of_fame
    FROM hall_of_fame
    GROUP BY player_id
)
SELECT 
    p.player_id,
    p.name_first || ' ' || p.name_last AS full_name,
    p.birth_year,
    p.birth_country,
    p.birth_state,
    p.birth_city,
    p.bats,
    p.throws,
    p.debut,
    p.final_game,
    EXTRACT(YEAR FROM COALESCE(p.final_game::date, '2024-12-31'::date)) - EXTRACT(YEAR FROM p.debut::date) + 1 AS career_years,
    
    -- Career batting totals
    COALESCE(cb.career_games, 0) AS career_games,
    COALESCE(cb.career_ab, 0) AS career_ab,
    COALESCE(cb.career_hits, 0) AS career_hits,
    COALESCE(cb.career_hr, 0) AS career_hr,
    COALESCE(cb.career_rbi, 0) AS career_rbi,
    COALESCE(cb.career_sb, 0) AS career_sb,
    
    -- Career pitching totals
    COALESCE(cp.career_wins, 0) AS career_wins,
    COALESCE(cp.career_losses, 0) AS career_losses,
    COALESCE(cp.career_games_pitched, 0) AS career_games_pitched,
    COALESCE(cp.career_games_started, 0) AS career_games_started,
    COALESCE(cp.career_saves, 0) AS career_saves,
    COALESCE(cp.career_strikeouts, 0) AS career_strikeouts,
    COALESCE(cp.career_innings_pitched, 0) AS career_innings_pitched,
    cp.career_era,
    
    -- Career fielding totals
    cf.positions_played,
    COALESCE(cf.career_fielding_games, 0) AS career_fielding_games,
    COALESCE(cf.career_total_chances, 0) AS career_total_chances,
    COALESCE(cf.career_errors, 0) AS career_errors,
    cf.career_fielding_pct,
    
    -- Awards and honors
    COALESCE(ca.total_awards, 0) AS total_awards,
    COALESCE(ca.mvps, 0) AS mvps,
    COALESCE(ca.cy_youngs, 0) AS cy_youngs,
    COALESCE(ca.roy, 0) AS roy,
    COALESCE(ca.gold_gloves, 0) AS gold_gloves,
    COALESCE(ca.silver_sluggers, 0) AS silver_sluggers,
    COALESCE(ca.ws_mvps, 0) AS ws_mvps,
    COALESCE(ca.asg_mvps, 0) AS asg_mvps,
    COALESCE(ca.alcs_mvps, 0) AS alcs_mvps,
    COALESCE(ca.nlcs_mvps, 0) AS nlcs_mvps,
    COALESCE(ca.triple_crowns, 0) AS triple_crowns,
    COALESCE(ca.hank_aaron_awards, 0) AS hank_aaron_awards,
    COALESCE(ca.clemente_awards, 0) AS clemente_awards,
    COALESCE(ca.comeback_awards, 0) AS comeback_awards,
    COALESCE(ca.reliever_awards, 0) AS reliever_awards,
    COALESCE(ca.platinum_gloves, 0) AS platinum_gloves,
    COALESCE(ca.pitching_triple_crowns, 0) AS pitching_triple_crowns,
    COALESCE(casg.all_star_games, 0) AS all_star_games,
    COALESCE(chof.hall_of_fame, 0) AS hall_of_fame
FROM people p
LEFT JOIN career_batting cb ON p.player_id = cb.player_id
LEFT JOIN career_pitching cp ON p.player_id = cp.player_id
LEFT JOIN career_fielding cf ON p.player_id = cf.player_id
LEFT JOIN career_awards ca ON p.player_id = ca.player_id
LEFT JOIN career_all_star_games casg ON p.player_id = casg.player_id
LEFT JOIN career_hall_of_fame chof ON p.player_id = chof.player_id
WHERE p.debut IS NOT NULL;