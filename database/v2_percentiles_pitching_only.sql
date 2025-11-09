-- Pitching-Only Percentiles
-- Use FanGraphs pitching data directly to avoid duplicates

CREATE OR REPLACE FUNCTION populate_season_percentiles_pitching_only(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- ERA percentiles (50+ IP) - reversed scale (lower is better)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'era', 'season', year_to_process, 50, COUNT(*),
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
    FROM fg_pitching_leaders 
    WHERE season = year_to_process AND ip >= 50 AND era IS NOT NULL;
    
    -- FIP percentiles (reversed scale)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'fip', 'season', year_to_process, 50, COUNT(*),
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
    FROM fg_pitching_leaders 
    WHERE season = year_to_process AND ip >= 50 AND fip IS NOT NULL;
    
    -- xFIP percentiles (reversed scale)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'xfip', 'season', year_to_process, 50, COUNT(*),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY x_fip),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY x_fip),
        ROUND(AVG(x_fip), 3), ROUND(STDDEV(x_fip), 3), MIN(x_fip), MAX(x_fip)
    FROM fg_pitching_leaders 
    WHERE season = year_to_process AND ip >= 50 AND x_fip IS NOT NULL;
    
    -- WHIP percentiles (reversed scale)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'whip', 'season', year_to_process, 50, COUNT(*),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY whip),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY whip),
        ROUND(AVG(whip), 3), ROUND(STDDEV(whip), 3), MIN(whip), MAX(whip)
    FROM fg_pitching_leaders 
    WHERE season = year_to_process AND ip >= 50 AND whip IS NOT NULL;
    
    -- K/9 percentiles (normal scale - higher is better)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'k_9', 'season', year_to_process, 50, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY k_9),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY k_9),
        ROUND(AVG(k_9), 3), ROUND(STDDEV(k_9), 3), MIN(k_9), MAX(k_9)
    FROM fg_pitching_leaders 
    WHERE season = year_to_process AND ip >= 50 AND k_9 IS NOT NULL;
    
    -- BB/9 percentiles (reversed scale - lower is better)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'bb_9', 'season', year_to_process, 50, COUNT(*),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY bb_9),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY bb_9),
        ROUND(AVG(bb_9), 3), ROUND(STDDEV(bb_9), 3), MIN(bb_9), MAX(bb_9)
    FROM fg_pitching_leaders 
    WHERE season = year_to_process AND ip >= 50 AND bb_9 IS NOT NULL;
    
    RETURN 'Populated pitching percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;

-- Add pitching columns to player_percentiles
ALTER TABLE player_percentiles 
ADD COLUMN IF NOT EXISTS era_value NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS era_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS fip_value NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS fip_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS xfip_value NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS xfip_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS whip_value NUMERIC(6,3),
ADD COLUMN IF NOT EXISTS whip_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS k_9_value NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS k_9_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS bb_9_value NUMERIC(6,2),
ADD COLUMN IF NOT EXISTS bb_9_percentile NUMERIC(5,2);

-- Populate individual pitcher percentiles
CREATE OR REPLACE FUNCTION populate_pitcher_percentiles(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- Run pitching percentiles
    PERFORM populate_season_percentiles_pitching_only(year_to_process);
    
    -- Populate individual pitcher percentiles
    INSERT INTO player_percentiles (
        player_id, scope, year,
        era_value, era_percentile,
        fip_value, fip_percentile,
        xfip_value, xfip_percentile,
        whip_value, whip_percentile,
        k_9_value, k_9_percentile,
        bb_9_value, bb_9_percentile,
        qualified
    )
    SELECT 
        pm.player_id, 'season', year_to_process,
        fg.era, calculate_percentile(fg.era, 'era', 'season', year_to_process),
        fg.fip, calculate_percentile(fg.fip, 'fip', 'season', year_to_process),
        fg.x_fip, calculate_percentile(fg.x_fip, 'xfip', 'season', year_to_process),
        fg.whip, calculate_percentile(fg.whip, 'whip', 'season', year_to_process),
        fg.k_9, calculate_percentile(fg.k_9, 'k_9', 'season', year_to_process),
        fg.bb_9, calculate_percentile(fg.bb_9, 'bb_9', 'season', year_to_process),
        (fg.ip >= 50)
    FROM fg_pitching_leaders fg
    JOIN players_master pm ON fg.playerid = pm.fangraphs_id
    WHERE fg.season = year_to_process AND fg.ip >= 50
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        era_value = EXCLUDED.era_value,
        era_percentile = EXCLUDED.era_percentile,
        fip_value = EXCLUDED.fip_value,
        fip_percentile = EXCLUDED.fip_percentile,
        xfip_value = EXCLUDED.xfip_value,
        xfip_percentile = EXCLUDED.xfip_percentile,
        whip_value = EXCLUDED.whip_value,
        whip_percentile = EXCLUDED.whip_percentile,
        k_9_value = EXCLUDED.k_9_value,
        k_9_percentile = EXCLUDED.k_9_percentile,
        bb_9_value = EXCLUDED.bb_9_value,
        bb_9_percentile = EXCLUDED.bb_9_percentile,
        qualified = EXCLUDED.qualified;
    
    RETURN 'Populated pitcher percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;