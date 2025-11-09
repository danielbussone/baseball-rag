-- Batting-Only Percentiles (No Fielding Duplicates)
-- Use FanGraphs batting data directly to avoid position duplicates

CREATE OR REPLACE FUNCTION populate_season_percentiles_batting_only(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    DELETE FROM stat_percentiles WHERE scope = 'season' AND year = year_to_process;
    DELETE FROM player_percentiles WHERE scope = 'season' AND year = year_to_process;
    
    -- WAR percentiles (250+ PA) - Use FanGraphs directly
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count, 
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'war', 'season', year_to_process, 500, COUNT(*),
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
    FROM fg_batting_leaders 
    WHERE season = year_to_process AND pa >= 500 AND war IS NOT NULL;
    
    -- wRC+ percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'wrc_plus', 'season', year_to_process, 500, COUNT(*),
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
    FROM fg_batting_leaders 
    WHERE season = year_to_process AND pa >= 500 AND w_rc_plus IS NOT NULL;
    
    -- AVG percentiles
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'avg', 'season', year_to_process, 500, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY average),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY average),
        ROUND(AVG(average), 3), ROUND(STDDEV(average), 3), MIN(average), MAX(average)
    FROM fg_batting_leaders 
    WHERE season = year_to_process AND pa >= 500 AND average IS NOT NULL;
    
    -- OBP, SLG, HR percentiles (similar pattern)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'obp', 'season', year_to_process, 500, COUNT(*),
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
    FROM fg_batting_leaders 
    WHERE season = year_to_process AND pa >= 500 AND obp IS NOT NULL;
    
    -- Populate individual player percentiles using FanGraphs + player mapping
    INSERT INTO player_percentiles (
        player_id, scope, year,
        war_value, war_percentile,
        wrc_plus_value, wrc_plus_percentile,
        avg_value, avg_percentile,
        obp_value, obp_percentile,
        qualified
    )
    SELECT 
        pm.player_id,
        'season',
        year_to_process,
        fg.war,
        calculate_percentile(fg.war, 'war', 'season', year_to_process),
        fg.w_rc_plus,
        calculate_percentile(fg.w_rc_plus::numeric, 'wrc_plus', 'season', year_to_process),
        fg.average,
        calculate_percentile(fg.average, 'avg', 'season', year_to_process),
        fg.obp,
        calculate_percentile(fg.obp, 'obp', 'season', year_to_process),
        (fg.pa >= 250)
    FROM fg_batting_leaders fg
    JOIN players_master pm ON fg.playerid = pm.fangraphs_id
    WHERE fg.season = year_to_process
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        war_value = EXCLUDED.war_value,
        war_percentile = EXCLUDED.war_percentile,
        wrc_plus_value = EXCLUDED.wrc_plus_value,
        wrc_plus_percentile = EXCLUDED.wrc_plus_percentile,
        avg_value = EXCLUDED.avg_value,
        avg_percentile = EXCLUDED.avg_percentile,
        obp_value = EXCLUDED.obp_value,
        obp_percentile = EXCLUDED.obp_percentile,
        qualified = EXCLUDED.qualified;
    
    RETURN 'Populated batting-only percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;

-- Wrapper function
CREATE OR REPLACE FUNCTION refresh_batting_percentiles() 
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    year_record RECORD;
BEGIN
    FOR year_record IN 
        SELECT DISTINCT season 
        FROM fg_batting_leaders 
        WHERE season >= EXTRACT(YEAR FROM CURRENT_DATE) - 5
        ORDER BY season DESC
    LOOP
        result_text := result_text || populate_season_percentiles_batting_only(year_record.season) || E'\n';
    END LOOP;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;