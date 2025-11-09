-- Extended Percentile Functions with 5% Increments
-- All statistics with comprehensive percentile calculations

CREATE OR REPLACE FUNCTION populate_season_percentiles_extended(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
    result_text TEXT := '';
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    DELETE FROM stat_percentiles WHERE scope = 'season' AND year = year_to_process;
    DELETE FROM player_percentiles WHERE scope = 'season' AND year = year_to_process;
    
    -- WAR percentiles (250+ PA)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count, 
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'war', 'season', year_to_process, 250, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY war),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY war),
        ROUND(AVG(war), 3), ROUND(STDDEV(war), 3), MIN(war), MAX(war)
    FROM batting_seasons_unified 
    WHERE season = year_to_process AND plate_appearances >= 250 AND war IS NOT NULL;
    
    -- wRC+ percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'wrc_plus', 'season', year_to_process, 250, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY w_rc_plus),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY w_rc_plus),
        ROUND(AVG(w_rc_plus), 3), ROUND(STDDEV(w_rc_plus), 3), MIN(w_rc_plus), MAX(w_rc_plus)
    FROM batting_seasons_unified 
    WHERE season = year_to_process AND plate_appearances >= 250 AND w_rc_plus IS NOT NULL;
    
    -- ERA percentiles (reversed - lower is better)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'era', 'season', year_to_process, 162, COUNT(*),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY era),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY era),
        ROUND(AVG(era), 3), ROUND(STDDEV(era), 3), MIN(era), MAX(era)
    FROM pitching_seasons_unified 
    WHERE season = year_to_process AND innings_pitched >= 162 AND era IS NOT NULL;
    
    -- FIP percentiles (reversed - lower is better)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'fip', 'season', year_to_process, 162, COUNT(*),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY fip),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY fip),
        ROUND(AVG(fip), 3), ROUND(STDDEV(fip), 3), MIN(fip), MAX(fip)
    FROM pitching_seasons_unified 
    WHERE season = year_to_process AND innings_pitched >= 162 AND fip IS NOT NULL;
    
    -- Batting Average percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'avg', 'season', year_to_process, 250, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY batting_avg),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY batting_avg),
        ROUND(AVG(batting_avg), 3), ROUND(STDDEV(batting_avg), 3), MIN(batting_avg), MAX(batting_avg)
    FROM batting_seasons_unified 
    WHERE season = year_to_process AND plate_appearances >= 250 AND batting_avg IS NOT NULL;
    
    -- OBP percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'obp', 'season', year_to_process, 250, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY obp),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY obp),
        ROUND(AVG(obp), 3), ROUND(STDDEV(obp), 3), MIN(obp), MAX(obp)
    FROM batting_seasons_unified 
    WHERE season = year_to_process AND plate_appearances >= 250 AND obp IS NOT NULL;
    
    -- SLG percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'slg', 'season', year_to_process, 250, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY slg),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY slg),
        ROUND(AVG(slg), 3), ROUND(STDDEV(slg), 3), MIN(slg), MAX(slg)
    FROM batting_seasons_unified 
    WHERE season = year_to_process AND plate_appearances >= 250 AND slg IS NOT NULL;
    
    -- Home Runs percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'hr', 'season', year_to_process, 250, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY home_runs),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY home_runs),
        ROUND(AVG(home_runs), 3), ROUND(STDDEV(home_runs), 3), MIN(home_runs), MAX(home_runs)
    FROM batting_seasons_unified 
    WHERE season = year_to_process AND plate_appearances >= 250 AND home_runs IS NOT NULL;
    
    -- Populate individual player percentiles
    INSERT INTO player_percentiles (
        player_id, scope, year,
        war_value, war_percentile,
        wrc_plus_value, wrc_plus_percentile,
        avg_value, avg_percentile,
        obp_value, obp_percentile,
        slg_value, slg_percentile,
        hr_value, hr_percentile,
        qualified
    )
    SELECT 
        b.player_id,
        'season',
        year_to_process,
        b.war,
        calculate_percentile(b.war, 'war', 'season', year_to_process),
        b.w_rc_plus,
        calculate_percentile(b.w_rc_plus::numeric, 'wrc_plus', 'season', year_to_process),
        b.batting_avg,
        calculate_percentile(b.batting_avg, 'avg', 'season', year_to_process),
        b.obp,
        calculate_percentile(b.obp, 'obp', 'season', year_to_process),
        b.slg,
        calculate_percentile(b.slg, 'slg', 'season', year_to_process),
        b.home_runs,
        calculate_percentile(b.home_runs::numeric, 'hr', 'season', year_to_process),
        (b.plate_appearances >= 250)
    FROM batting_seasons_unified b
    WHERE b.season = year_to_process
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        war_value = EXCLUDED.war_value,
        war_percentile = EXCLUDED.war_percentile,
        wrc_plus_value = EXCLUDED.wrc_plus_value,
        wrc_plus_percentile = EXCLUDED.wrc_plus_percentile,
        avg_value = EXCLUDED.avg_value,
        avg_percentile = EXCLUDED.avg_percentile,
        obp_value = EXCLUDED.obp_value,
        obp_percentile = EXCLUDED.obp_percentile,
        slg_value = EXCLUDED.slg_value,
        slg_percentile = EXCLUDED.slg_percentile,
        hr_value = EXCLUDED.hr_value,
        hr_percentile = EXCLUDED.hr_percentile,
        qualified = EXCLUDED.qualified;
    
    RETURN 'Populated extended percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;

-- Career percentiles with 5% increments
CREATE OR REPLACE FUNCTION populate_career_percentiles_extended() 
RETURNS TEXT AS $$
BEGIN
    DELETE FROM stat_percentiles WHERE scope = 'career';
    DELETE FROM player_percentiles WHERE scope = 'career';
    
    -- Career WAR percentiles
    INSERT INTO stat_percentiles (stat_name, scope, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'career_war', 'career', 1000, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY career_batting_war),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY career_batting_war),
        ROUND(AVG(career_batting_war), 3), ROUND(STDDEV(career_batting_war), 3), MIN(career_batting_war), MAX(career_batting_war)
    FROM career_stats_unified 
    WHERE career_pa >= 1000 AND career_batting_war IS NOT NULL;
    
    -- Populate individual career percentiles
    INSERT INTO player_percentiles (
        player_id, scope,
        war_value, war_percentile,
        qualified
    )
    SELECT 
        c.player_id,
        'career',
        c.career_batting_war,
        calculate_percentile(c.career_batting_war, 'career_war', 'career'),
        (c.career_pa >= 1000)
    FROM career_stats_unified c
    WHERE c.career_batting_war IS NOT NULL
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        war_value = EXCLUDED.war_value,
        war_percentile = EXCLUDED.war_percentile,
        qualified = EXCLUDED.qualified;
    
    RETURN 'Populated extended career percentiles';
END;
$$ LANGUAGE plpgsql;