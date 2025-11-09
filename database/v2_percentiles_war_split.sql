-- Split Batting and Pitching WAR
-- Add separate columns and update functions

-- Add pitching WAR columns
ALTER TABLE player_percentiles 
ADD COLUMN IF NOT EXISTS batting_war_value NUMERIC(6,1),
ADD COLUMN IF NOT EXISTS batting_war_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS pitching_war_value NUMERIC(6,1),
ADD COLUMN IF NOT EXISTS pitching_war_percentile NUMERIC(5,2);

-- Update batting function to use batting_war columns
CREATE OR REPLACE FUNCTION populate_season_percentiles_batting_only_fixed(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- Batting WAR percentiles (use 'batting_war' as stat name)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'batting_war', 'season', year_to_process, 250, COUNT(*),
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
    WHERE season = year_to_process AND pa >= 250 AND war IS NOT NULL;
    
    -- Populate individual batting percentiles
    INSERT INTO player_percentiles (
        player_id, scope, year,
        batting_war_value, batting_war_percentile,
        wrc_plus_value, wrc_plus_percentile,
        qualified
    )
    SELECT 
        pm.player_id, 'season', year_to_process,
        fg.war, calculate_percentile(fg.war, 'batting_war', 'season', year_to_process),
        fg.w_rc_plus, calculate_percentile(fg.w_rc_plus::numeric, 'wrc_plus', 'season', year_to_process),
        (fg.pa >= 250)
    FROM fg_batting_leaders fg
    JOIN players_master pm ON fg.playerid = pm.fangraphs_id
    WHERE fg.season = year_to_process
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        batting_war_value = EXCLUDED.batting_war_value,
        batting_war_percentile = EXCLUDED.batting_war_percentile,
        wrc_plus_value = EXCLUDED.wrc_plus_value,
        wrc_plus_percentile = EXCLUDED.wrc_plus_percentile,
        qualified = EXCLUDED.qualified;
    
    RETURN 'Populated batting percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;

-- Update pitching function to use pitching_war columns
CREATE OR REPLACE FUNCTION populate_pitcher_percentiles_fixed(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- Pitching WAR percentiles (use 'pitching_war' as stat name)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'pitching_war', 'season', year_to_process, 50, COUNT(*),
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
    FROM fg_pitching_leaders 
    WHERE season = year_to_process AND ip >= 50 AND war IS NOT NULL;
    
    -- Populate individual pitching percentiles
    INSERT INTO player_percentiles (
        player_id, scope, year,
        pitching_war_value, pitching_war_percentile,
        era_value, era_percentile,
        fip_value, fip_percentile,
        qualified
    )
    SELECT 
        pm.player_id, 'season', year_to_process,
        fg.war, calculate_percentile(fg.war, 'pitching_war', 'season', year_to_process),
        fg.era, calculate_percentile(fg.era, 'era', 'season', year_to_process),
        fg.fip, calculate_percentile(fg.fip, 'fip', 'season', year_to_process),
        (fg.ip >= 50)
    FROM fg_pitching_leaders fg
    JOIN players_master pm ON fg.playerid = pm.fangraphs_id
    WHERE fg.season = year_to_process AND fg.ip >= 50
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        pitching_war_value = EXCLUDED.pitching_war_value,
        pitching_war_percentile = EXCLUDED.pitching_war_percentile,
        era_value = EXCLUDED.era_value,
        era_percentile = EXCLUDED.era_percentile,
        fip_value = EXCLUDED.fip_value,
        fip_percentile = EXCLUDED.fip_percentile,
        qualified = EXCLUDED.qualified;
    
    RETURN 'Populated pitching percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;