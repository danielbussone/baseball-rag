-- Final Consolidated Percentiles System
-- All-in-one file with schema, functions, and setup

-- ============================================================================
-- SCHEMA
-- ============================================================================

CREATE TABLE IF NOT EXISTS stat_percentiles (
    id SERIAL PRIMARY KEY,
    stat_name VARCHAR(50) NOT NULL,
    scope VARCHAR(20) NOT NULL,
    year INTEGER,
    position VARCHAR(10),
    era VARCHAR(20),
    min_pa INTEGER,
    qualified_count INTEGER NOT NULL,
    
    p1 NUMERIC(8,3), p5 NUMERIC(8,3), p10 NUMERIC(8,3), p15 NUMERIC(8,3), p20 NUMERIC(8,3),
    p25 NUMERIC(8,3), p30 NUMERIC(8,3), p35 NUMERIC(8,3), p40 NUMERIC(8,3), p45 NUMERIC(8,3),
    p50 NUMERIC(8,3), p55 NUMERIC(8,3), p60 NUMERIC(8,3), p65 NUMERIC(8,3), p70 NUMERIC(8,3),
    p75 NUMERIC(8,3), p80 NUMERIC(8,3), p85 NUMERIC(8,3), p90 NUMERIC(8,3), p95 NUMERIC(8,3), p99 NUMERIC(8,3),
    
    mean NUMERIC(8,3), stddev NUMERIC(8,3), min_value NUMERIC(8,3), max_value NUMERIC(8,3),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS player_percentiles (
    id SERIAL PRIMARY KEY,
    player_id INTEGER NOT NULL REFERENCES players_master(player_id),
    scope VARCHAR(20) NOT NULL,
    year INTEGER,
    
    -- Batting stats
    batting_war_value NUMERIC(6,1), batting_war_percentile NUMERIC(5,2),
    wrc_plus_value INTEGER, wrc_plus_percentile NUMERIC(5,2),
    avg_value NUMERIC(5,3), avg_percentile NUMERIC(5,2),
    obp_value NUMERIC(5,3), obp_percentile NUMERIC(5,2),
    slg_value NUMERIC(5,3), slg_percentile NUMERIC(5,2),
    hr_value INTEGER, hr_percentile NUMERIC(5,2),
    
    -- Pitching stats
    pitching_war_value NUMERIC(6,1), pitching_war_percentile NUMERIC(5,2),
    era_value NUMERIC(6,2), era_percentile NUMERIC(5,2),
    fip_value NUMERIC(6,2), fip_percentile NUMERIC(5,2),
    k_9_value NUMERIC(6,2), k_9_percentile NUMERIC(5,2),
    
    -- Fielding stats
    uzr_value NUMERIC(6,1), uzr_percentile NUMERIC(5,2),
    drs_value NUMERIC(6,1), drs_percentile NUMERIC(5,2),
    
    qualified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(player_id, scope, year)
);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_percentile(
    stat_value NUMERIC, stat_name_param VARCHAR, scope_param VARCHAR, year_param INTEGER DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE 
    percentile_result NUMERIC;
    is_reversed BOOLEAN;
BEGIN
    -- Check if this is a reversed stat (lower is better)
    is_reversed := stat_name_param IN ('era', 'fip', 'xfip', 'whip', 'bb_9', 'hr_9');
    
    IF is_reversed THEN
        -- For reversed stats, higher percentile = lower value
        SELECT CASE 
            WHEN stat_value >= p1 THEN 1 WHEN stat_value >= p5 THEN 5 WHEN stat_value >= p10 THEN 10
            WHEN stat_value >= p15 THEN 15 WHEN stat_value >= p20 THEN 20 WHEN stat_value >= p25 THEN 25
            WHEN stat_value >= p30 THEN 30 WHEN stat_value >= p35 THEN 35 WHEN stat_value >= p40 THEN 40
            WHEN stat_value >= p45 THEN 45 WHEN stat_value >= p50 THEN 50 WHEN stat_value >= p55 THEN 55
            WHEN stat_value >= p60 THEN 60 WHEN stat_value >= p65 THEN 65 WHEN stat_value >= p70 THEN 70
            WHEN stat_value >= p75 THEN 75 WHEN stat_value >= p80 THEN 80 WHEN stat_value >= p85 THEN 85
            WHEN stat_value >= p90 THEN 90 WHEN stat_value >= p95 THEN 95 WHEN stat_value >= p99 THEN 99
            ELSE 99.9 END INTO percentile_result
        FROM stat_percentiles 
        WHERE stat_name = stat_name_param AND scope = scope_param AND (year IS NULL OR year = year_param)
        LIMIT 1;
    ELSE
        -- For normal stats, higher percentile = higher value
        SELECT CASE 
            WHEN stat_value <= p1 THEN 1 WHEN stat_value <= p5 THEN 5 WHEN stat_value <= p10 THEN 10
            WHEN stat_value <= p15 THEN 15 WHEN stat_value <= p20 THEN 20 WHEN stat_value <= p25 THEN 25
            WHEN stat_value <= p30 THEN 30 WHEN stat_value <= p35 THEN 35 WHEN stat_value <= p40 THEN 40
            WHEN stat_value <= p45 THEN 45 WHEN stat_value <= p50 THEN 50 WHEN stat_value <= p55 THEN 55
            WHEN stat_value <= p60 THEN 60 WHEN stat_value <= p65 THEN 65 WHEN stat_value <= p70 THEN 70
            WHEN stat_value <= p75 THEN 75 WHEN stat_value <= p80 THEN 80 WHEN stat_value <= p85 THEN 85
            WHEN stat_value <= p90 THEN 90 WHEN stat_value <= p95 THEN 95 WHEN stat_value <= p99 THEN 99
            ELSE 99.9 END INTO percentile_result
        FROM stat_percentiles 
        WHERE stat_name = stat_name_param AND scope = scope_param AND (year IS NULL OR year = year_param)
        LIMIT 1;
    END IF;
    
    RETURN COALESCE(percentile_result, 50);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_percentile_name(percentile_value NUMERIC) RETURNS TEXT AS $$
BEGIN
    RETURN CASE 
        WHEN percentile_value >= 99 THEN 'Elite (99th+)'
        WHEN percentile_value >= 95 THEN 'Superstar (95-99th)'
        WHEN percentile_value >= 90 THEN 'All-Star (90-95th)'
        WHEN percentile_value >= 85 THEN 'Excellent (85-90th)'
        WHEN percentile_value >= 80 THEN 'Very Good (80-85th)'
        WHEN percentile_value >= 75 THEN 'Good (75-80th)'
        WHEN percentile_value >= 70 THEN 'Above Average+ (70-75th)'
        WHEN percentile_value >= 65 THEN 'Above Average (65-70th)'
        WHEN percentile_value >= 60 THEN 'Slightly Above Average (60-65th)'
        WHEN percentile_value >= 55 THEN 'Average+ (55-60th)'
        WHEN percentile_value >= 50 THEN 'Average (50-55th)'
        WHEN percentile_value >= 45 THEN 'Average- (45-50th)'
        WHEN percentile_value >= 40 THEN 'Slightly Below Average (40-45th)'
        WHEN percentile_value >= 35 THEN 'Below Average (35-40th)'
        WHEN percentile_value >= 30 THEN 'Below Average- (30-35th)'
        WHEN percentile_value >= 25 THEN 'Poor (25-30th)'
        WHEN percentile_value >= 20 THEN 'Poor- (20-25th)'
        WHEN percentile_value >= 15 THEN 'Very Poor (15-20th)'
        WHEN percentile_value >= 10 THEN 'Very Poor- (10-15th)'
        WHEN percentile_value >= 5 THEN 'Terrible (5-10th)'
        WHEN percentile_value >= 1 THEN 'Awful (1-5th)'
        ELSE 'Historically Bad (<1st)'
    END;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- MAIN POPULATION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION populate_all_percentiles(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
    result_text TEXT := '';
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- Clear existing data
    DELETE FROM stat_percentiles WHERE scope = 'season' AND year = year_to_process;
    DELETE FROM player_percentiles WHERE scope = 'season' AND year = year_to_process;
    
    -- Batting WAR percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'batting_war', 'season', year_to_process, 250, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY war),
        ROUND(AVG(war), 3), ROUND(STDDEV(war), 3), MIN(war), MAX(war)
    FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND war IS NOT NULL;
    
    -- Pitching WAR percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'pitching_war', 'season', year_to_process, 50, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY war), PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY war),
        ROUND(AVG(war), 3), ROUND(STDDEV(war), 3), MIN(war), MAX(war)
    FROM fg_pitching_leaders WHERE season = year_to_process AND ip >= 50 AND war IS NOT NULL;
    
    -- wRC+ percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'wrc_plus', 'season', year_to_process, 250, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY w_rc_plus), PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY w_rc_plus),
        ROUND(AVG(w_rc_plus), 3), ROUND(STDDEV(w_rc_plus), 3), MIN(w_rc_plus), MAX(w_rc_plus)
    FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND w_rc_plus IS NOT NULL;
    
    -- ERA percentiles (reversed)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'era', 'season', year_to_process, 50, COUNT(*),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY era), PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY era),
        ROUND(AVG(era), 3), ROUND(STDDEV(era), 3), MIN(era), MAX(era)
    FROM fg_pitching_leaders WHERE season = year_to_process AND ip >= 50 AND era IS NOT NULL;
    
    -- Populate player percentiles
    INSERT INTO player_percentiles (player_id, scope, year, batting_war_value, batting_war_percentile, wrc_plus_value, wrc_plus_percentile, qualified)
    SELECT pm.player_id, 'season', year_to_process, fg.war, 
           calculate_percentile(fg.war, 'batting_war', 'season', year_to_process),
           fg.w_rc_plus, calculate_percentile(fg.w_rc_plus::numeric, 'wrc_plus', 'season', year_to_process),
           (fg.pa >= 250)
    FROM fg_batting_leaders fg
    JOIN players_master pm ON fg.playerid = pm.fangraphs_id
    WHERE fg.season = year_to_process
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        batting_war_value = EXCLUDED.batting_war_value, batting_war_percentile = EXCLUDED.batting_war_percentile,
        wrc_plus_value = EXCLUDED.wrc_plus_value, wrc_plus_percentile = EXCLUDED.wrc_plus_percentile;
    
    -- Add pitching percentiles
    INSERT INTO player_percentiles (player_id, scope, year, pitching_war_value, pitching_war_percentile, era_value, era_percentile, qualified)
    SELECT pm.player_id, 'season', year_to_process, fg.war, 
           calculate_percentile(fg.war, 'batting_war', 'season', year_to_process), 
           fg.era, calculate_percentile(fg.era, 'era', 'season', year_to_process), (fg.ip >= 50)
    FROM fg_pitching_leaders fg
    JOIN players_master pm ON fg.playerid = pm.fangraphs_id
    WHERE fg.season = year_to_process AND fg.ip >= 50
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        era_value = EXCLUDED.era_value, era_percentile = EXCLUDED.era_percentile;
    
    RETURN 'Populated percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS
-- ============================================================================

CREATE OR REPLACE VIEW player_percentiles_with_names AS
SELECT 
    pm.name_first || ' ' || pm.name_last as player_name,
    pp.*,
    get_percentile_name(pp.batting_war_percentile) as batting_war_tier,
    get_percentile_name(pp.wrc_plus_percentile) as offense_tier,
    get_percentile_name(pp.pitching_war_percentile) as pitching_tier
FROM player_percentiles pp
JOIN players_master pm ON pp.player_id = pm.player_id;

-- ============================================================================
-- SETUP
-- ============================================================================

-- Run for recent years
DO $$
DECLARE
    year_val INTEGER;
BEGIN
    FOR year_val IN SELECT generate_series(1871, 2025) LOOP
        PERFORM populate_all_percentiles(year_val);
    END LOOP;
END $$;