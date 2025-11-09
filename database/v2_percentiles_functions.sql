-- Percentile Calculation Functions
-- Functions to populate and maintain percentile data

-- ============================================================================
-- POPULATE SEASON PERCENTILES
-- ============================================================================

CREATE OR REPLACE FUNCTION populate_season_percentiles(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
    result_text TEXT := '';
BEGIN
    -- If no year specified, process current year - 1
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- Clear existing data for this year
    DELETE FROM stat_percentiles WHERE scope = 'season' AND year = year_to_process;
    DELETE FROM player_percentiles WHERE scope = 'season' AND year = year_to_process;
    
    -- Calculate WAR percentiles for qualified batters (250+ PA)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count, 
                                 p1, p5, p10, p25, p40, p50, p60, p75, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 
        'war' as stat_name,
        'season' as scope,
        year_to_process,
        250 as min_pa,
        COUNT(*) as qualified_count,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY war) as percentile_1st,
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY war) as percentile_5th,
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY war) as percentile_10th,
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY war) as percentile_15th,
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY war) as percentile_20th,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY war) as percentile_25th,
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY war) as percentile_30th,
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY war) as percentile_35th,
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY war) as percentile_40th,
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY war) as percentile_45th,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY war) as percentile_50th,
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY war) as percentile_55th,
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY war) as percentile_60th,
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY war) as percentile_65th,
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY war) as percentile_70th,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY war) as percentile_75th,
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY war) as percentile_80th,
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY war) as percentile_85th,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY war) as percentile_90th,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY war) as percentile_95th,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY war) as percentile_99th,
        ROUND(AVG(war), 3),
        ROUND(STDDEV(war), 3),
        MIN(war),
        MAX(war)
    FROM batting_seasons_unified 
    WHERE season = year_to_process 
      AND plate_appearances >= 250
      AND war IS NOT NULL;
    
    -- Calculate wRC+ percentiles for qualified batters
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p25, p40, p50, p60, p75, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 
        'wrc_plus' as stat_name,
        'season' as scope,
        year_to_process,
        250 as min_pa,
        COUNT(*) as qualified_count,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY w_rc_plus),
        ROUND(AVG(w_rc_plus), 3),
        ROUND(STDDEV(w_rc_plus), 3),
        MIN(w_rc_plus),
        MAX(w_rc_plus)
    FROM batting_seasons_unified 
    WHERE season = year_to_process 
      AND plate_appearances >= 250
      AND w_rc_plus IS NOT NULL;
    
    -- Calculate ERA percentiles for qualified pitchers (162+ IP)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p25, p40, p50, p60, p75, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 
        'era' as stat_name,
        'season' as scope,
        year_to_process,
        162 as min_pa, -- IP instead of PA
        COUNT(*) as qualified_count,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY era), -- Reverse for ERA (lower is better)
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY era),
        ROUND(AVG(era), 3),
        ROUND(STDDEV(era), 3),
        MIN(era),
        MAX(era)
    FROM pitching_seasons_unified 
    WHERE season = year_to_process 
      AND innings_pitched >= 162
      AND era IS NOT NULL;
    
    -- Populate individual player percentiles for this season
    INSERT INTO player_percentiles (
        player_id, scope, year, 
        war_value, war_percentile,
        wrc_plus_value, wrc_plus_percentile,
        primary_position, era, qualified
    )
    SELECT 
        b.player_id,
        'season' as scope,
        year_to_process,
        b.war,
        calculate_percentile(b.war, 'war', 'season', year_to_process),
        b.w_rc_plus,
        calculate_percentile(b.w_rc_plus::numeric, 'wrc_plus', 'season', year_to_process),
        'Unknown' as primary_position, -- TODO: Calculate primary position
        get_era(year_to_process),
        (b.plate_appearances >= 502) as qualified
    FROM batting_seasons_unified b
    WHERE b.season = year_to_process
      AND (b.war IS NOT NULL OR b.w_rc_plus IS NOT NULL);
    
    result_text := 'Populated percentiles for ' || year_to_process || ' season';
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- POPULATE CAREER PERCENTILES
-- ============================================================================

CREATE OR REPLACE FUNCTION populate_career_percentiles() 
RETURNS TEXT AS $$
BEGIN
    -- Clear existing career percentiles
    DELETE FROM stat_percentiles WHERE scope = 'career';
    DELETE FROM player_percentiles WHERE scope = 'career';
    
    -- Calculate career WAR percentiles (min 1000 PA career)
    INSERT INTO stat_percentiles (stat_name, scope, min_pa, qualified_count,
                                 p1, p5, p10, p25, p40, p50, p60, p75, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 
        'career_war' as stat_name,
        'career' as scope,
        1000 as min_pa,
        COUNT(*) as qualified_count,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY career_batting_war),
        ROUND(AVG(career_batting_war), 3),
        ROUND(STDDEV(career_batting_war), 3),
        MIN(career_batting_war),
        MAX(career_batting_war)
    FROM career_stats_unified 
    WHERE career_pa >= 1000
      AND career_batting_war IS NOT NULL;
    
    -- Populate individual career percentiles
    INSERT INTO player_percentiles (
        player_id, scope,
        war_value, war_percentile,
        qualified
    )
    SELECT 
        c.player_id,
        'career' as scope,
        c.career_batting_war,
        calculate_percentile(c.career_batting_war, 'career_war', 'career'),
        (c.career_pa >= 1000) as qualified
    FROM career_stats_unified c
    WHERE c.career_batting_war IS NOT NULL;
    
    RETURN 'Populated career percentiles';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- REFRESH ALL PERCENTILES
-- ============================================================================

CREATE OR REPLACE FUNCTION refresh_all_percentiles() 
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    year_record RECORD;
BEGIN
    -- Refresh career percentiles
    result_text := result_text || populate_career_percentiles() || E'\n';
    
    -- Refresh season percentiles for recent years (last 5 years)
    FOR year_record IN 
        SELECT DISTINCT season 
        FROM batting_seasons_unified 
        WHERE season >= EXTRACT(YEAR FROM CURRENT_DATE) - 5
        ORDER BY season DESC
    LOOP
        result_text := result_text || populate_season_percentiles(year_record.season) || E'\n';
    END LOOP;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION populate_season_percentiles IS 'Calculate and populate percentiles for a specific season';
COMMENT ON FUNCTION populate_career_percentiles IS 'Calculate and populate career percentiles';
COMMENT ON FUNCTION refresh_all_percentiles IS 'Refresh all percentile calculations';