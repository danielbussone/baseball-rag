-- Fielding-Only Percentiles
-- Use FanGraphs fielding data directly, aggregated by player-season

CREATE OR REPLACE FUNCTION populate_season_percentiles_fielding_only(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- UZR percentiles (500+ innings) - higher is better
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'uzr', 'season', year_to_process, 500, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_uzr),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_uzr),
        ROUND(AVG(total_uzr), 3), ROUND(STDDEV(total_uzr), 3), MIN(total_uzr), MAX(total_uzr)
    FROM (
        SELECT playerid, SUM(uzr) as total_uzr, SUM(inn) as total_innings
        FROM fg_fielding_leaders 
        WHERE season = year_to_process AND uzr IS NOT NULL
        GROUP BY playerid
        HAVING SUM(inn) >= 500
    ) fielding_agg;
    
    -- DRS percentiles (500+ innings) - higher is better
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'drs', 'season', year_to_process, 500, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_drs),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_drs),
        ROUND(AVG(total_drs), 3), ROUND(STDDEV(total_drs), 3), MIN(total_drs), MAX(total_drs)
    FROM (
        SELECT playerid, SUM(drs) as total_drs, SUM(inn) as total_innings
        FROM fg_fielding_leaders 
        WHERE season = year_to_process AND drs IS NOT NULL
        GROUP BY playerid
        HAVING SUM(inn) >= 500
    ) fielding_agg;
    
    -- OAA percentiles (500+ innings) - higher is better
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT 'oaa', 'season', year_to_process, 500, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_oaa),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_oaa),
        ROUND(AVG(total_oaa), 3), ROUND(STDDEV(total_oaa), 3), MIN(total_oaa), MAX(total_oaa)
    FROM (
        SELECT playerid, SUM(oaa) as total_oaa, SUM(inn) as total_innings
        FROM fg_fielding_leaders 
        WHERE season = year_to_process AND oaa IS NOT NULL
        GROUP BY playerid
        HAVING SUM(inn) >= 500
    ) fielding_agg;
    
    RETURN 'Populated fielding percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;

-- Add fielding columns to player_percentiles
ALTER TABLE player_percentiles 
ADD COLUMN IF NOT EXISTS uzr_value NUMERIC(6,1),
ADD COLUMN IF NOT EXISTS uzr_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS drs_value NUMERIC(6,1),
ADD COLUMN IF NOT EXISTS drs_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS oaa_value NUMERIC(6,1),
ADD COLUMN IF NOT EXISTS oaa_percentile NUMERIC(5,2);

-- Populate individual fielder percentiles
CREATE OR REPLACE FUNCTION populate_fielder_percentiles(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- Run fielding percentiles
    PERFORM populate_season_percentiles_fielding_only(year_to_process);
    
    -- Populate individual fielder percentiles (aggregated by player)
    INSERT INTO player_percentiles (
        player_id, scope, year,
        uzr_value, uzr_percentile,
        drs_value, drs_percentile,
        oaa_value, oaa_percentile,
        qualified
    )
    SELECT 
        pm.player_id, 'season', year_to_process,
        fa.total_uzr, calculate_percentile(fa.total_uzr, 'uzr', 'season', year_to_process),
        fa.total_drs, calculate_percentile(fa.total_drs, 'drs', 'season', year_to_process),
        fa.total_oaa, calculate_percentile(fa.total_oaa, 'oaa', 'season', year_to_process),
        (fa.total_innings >= 500)
    FROM (
        SELECT 
            fg.playerid,
            SUM(fg.uzr) as total_uzr,
            SUM(fg.drs) as total_drs,
            SUM(fg.oaa) as total_oaa,
            SUM(fg.inn) as total_innings
        FROM fg_fielding_leaders fg
        WHERE fg.season = year_to_process
        GROUP BY fg.playerid
        HAVING SUM(fg.inn) >= 100  -- Lower threshold for inclusion
    ) fa
    JOIN players_master pm ON fa.playerid = pm.fangraphs_id
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        uzr_value = EXCLUDED.uzr_value,
        uzr_percentile = EXCLUDED.uzr_percentile,
        drs_value = EXCLUDED.drs_value,
        drs_percentile = EXCLUDED.drs_percentile,
        oaa_value = EXCLUDED.oaa_value,
        oaa_percentile = EXCLUDED.oaa_percentile,
        qualified = EXCLUDED.qualified;
    
    RETURN 'Populated fielder percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;