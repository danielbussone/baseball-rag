-- Plus Stats Percentiles
-- All FanGraphs plus statistics with 5% increments

CREATE OR REPLACE FUNCTION populate_plus_stats_percentiles(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- Plus stats percentiles (250+ PA)
    INSERT INTO stat_percentiles (stat_name, scope, year, min_pa, qualified_count,
                                 p1, p5, p10, p15, p20, p25, p30, p35, p40, p45, p50, p55, p60, p65, p70, p75, p80, p85, p90, p95, p99,
                                 mean, stddev, min_value, max_value)
    SELECT stat_name, 'season', year_to_process, 250, COUNT(*),
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.15) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.35) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.45) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.55) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.65) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY stat_value),
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY stat_value),
        ROUND(AVG(stat_value), 3), ROUND(STDDEV(stat_value), 3), MIN(stat_value), MAX(stat_value)
    FROM (
        SELECT 'avg_plus' as stat_name, avg_plus as stat_value FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND avg_plus IS NOT NULL
        UNION ALL
        SELECT 'obp_plus', obp_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND obp_plus IS NOT NULL
        UNION ALL
        SELECT 'slg_plus', slg_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND slg_plus IS NOT NULL
        UNION ALL
        SELECT 'iso_plus', iso_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND iso_plus IS NOT NULL
        UNION ALL
        SELECT 'babip_plus', babip_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND babip_plus IS NOT NULL
        UNION ALL
        SELECT 'bb_pct_plus', bb_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND bb_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'k_pct_plus', k_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND k_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'ld_pct_plus', ld_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND ld_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'gb_pct_plus', gb_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND gb_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'fb_pct_plus', fb_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND fb_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'hrfb_pct_plus', hrfb_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND hrfb_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'pull_pct_plus', pull_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND pull_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'cent_pct_plus', cent_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND cent_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'oppo_pct_plus', oppo_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND oppo_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'soft_pct_plus', soft_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND soft_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'med_pct_plus', med_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND med_pct_plus IS NOT NULL
        UNION ALL
        SELECT 'hard_pct_plus', hard_pct_plus FROM fg_batting_leaders WHERE season = year_to_process AND pa >= 250 AND hard_pct_plus IS NOT NULL
    ) plus_stats
    GROUP BY stat_name;
    
    RETURN 'Populated plus stats percentiles for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;

-- Add plus stats to player percentiles table
ALTER TABLE player_percentiles 
ADD COLUMN IF NOT EXISTS avg_plus_value INTEGER,
ADD COLUMN IF NOT EXISTS avg_plus_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS obp_plus_value INTEGER,
ADD COLUMN IF NOT EXISTS obp_plus_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS slg_plus_value INTEGER,
ADD COLUMN IF NOT EXISTS slg_plus_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS iso_plus_value INTEGER,
ADD COLUMN IF NOT EXISTS iso_plus_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS babip_plus_value INTEGER,
ADD COLUMN IF NOT EXISTS babip_plus_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS bb_pct_plus_value INTEGER,
ADD COLUMN IF NOT EXISTS bb_pct_plus_percentile NUMERIC(5,2),
ADD COLUMN IF NOT EXISTS k_pct_plus_value INTEGER,
ADD COLUMN IF NOT EXISTS k_pct_plus_percentile NUMERIC(5,2);

-- Enhanced batting function with plus stats
CREATE OR REPLACE FUNCTION populate_season_percentiles_with_plus(target_year INTEGER DEFAULT NULL) 
RETURNS TEXT AS $$
DECLARE
    year_to_process INTEGER;
BEGIN
    year_to_process := COALESCE(target_year, EXTRACT(YEAR FROM CURRENT_DATE) - 1);
    
    -- Run base percentiles
    PERFORM populate_season_percentiles_batting_only(year_to_process);
    
    -- Run plus stats percentiles
    PERFORM populate_plus_stats_percentiles(year_to_process);
    
    -- Update player percentiles with plus stats
    INSERT INTO player_percentiles (
        player_id, scope, year,
        avg_plus_value, avg_plus_percentile,
        obp_plus_value, obp_plus_percentile,
        slg_plus_value, slg_plus_percentile,
        iso_plus_value, iso_plus_percentile,
        bb_pct_plus_value, bb_pct_plus_percentile,
        k_pct_plus_value, k_pct_plus_percentile
    )
    SELECT 
        pm.player_id, 'season', year_to_process,
        fg.avg_plus, calculate_percentile(fg.avg_plus::numeric, 'avg_plus', 'season', year_to_process),
        fg.obp_plus, calculate_percentile(fg.obp_plus::numeric, 'obp_plus', 'season', year_to_process),
        fg.slg_plus, calculate_percentile(fg.slg_plus::numeric, 'slg_plus', 'season', year_to_process),
        fg.iso_plus, calculate_percentile(fg.iso_plus::numeric, 'iso_plus', 'season', year_to_process),
        fg.bb_pct_plus, calculate_percentile(fg.bb_pct_plus::numeric, 'bb_pct_plus', 'season', year_to_process),
        fg.k_pct_plus, calculate_percentile(fg.k_pct_plus::numeric, 'k_pct_plus', 'season', year_to_process)
    FROM fg_batting_leaders fg
    JOIN players_master pm ON fg.playerid = pm.fangraphs_id
    WHERE fg.season = year_to_process AND fg.pa >= 250
    ON CONFLICT (player_id, scope, year) DO UPDATE SET
        avg_plus_value = EXCLUDED.avg_plus_value,
        avg_plus_percentile = EXCLUDED.avg_plus_percentile,
        obp_plus_value = EXCLUDED.obp_plus_value,
        obp_plus_percentile = EXCLUDED.obp_plus_percentile,
        slg_plus_value = EXCLUDED.slg_plus_value,
        slg_plus_percentile = EXCLUDED.slg_plus_percentile,
        iso_plus_value = EXCLUDED.iso_plus_value,
        iso_plus_percentile = EXCLUDED.iso_plus_percentile,
        bb_pct_plus_value = EXCLUDED.bb_pct_plus_value,
        bb_pct_plus_percentile = EXCLUDED.bb_pct_plus_percentile,
        k_pct_plus_value = EXCLUDED.k_pct_plus_value,
        k_pct_plus_percentile = EXCLUDED.k_pct_plus_percentile;
    
    RETURN 'Populated percentiles with plus stats for ' || year_to_process;
END;
$$ LANGUAGE plpgsql;