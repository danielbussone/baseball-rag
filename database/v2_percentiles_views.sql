-- Enhanced Views with Percentile Data
-- Add percentile rankings to existing unified views

-- ============================================================================
-- BATTING SEASONS WITH PERCENTILES VIEW
-- ============================================================================

CREATE OR REPLACE VIEW batting_seasons_with_percentiles AS
SELECT 
    b.*,
    
    -- All percentiles
    pp.war_percentile,
    pp.wrc_plus_percentile,
    pp.avg_percentile,
    pp.obp_percentile,
    pp.slg_percentile,
    pp.hr_percentile,
    
    -- Percentile names using functions
    get_percentile_name(pp.war_percentile) as war_tier,
    get_percentile_name(pp.wrc_plus_percentile) as offense_tier,
    get_percentile_name(pp.avg_percentile) as avg_tier,
    get_percentile_name(pp.obp_percentile) as obp_tier,
    get_percentile_name(pp.slg_percentile) as slg_tier,
    get_percentile_name(pp.hr_percentile) as power_tier,
    
    -- Grades using functions
    get_percentile_grade(pp.war_percentile) as war_grade,
    get_percentile_grade(pp.wrc_plus_percentile) as offense_grade,
    get_percentile_grade(pp.avg_percentile) as avg_grade,
    get_percentile_grade(pp.obp_percentile) as obp_grade,
    get_percentile_grade(pp.slg_percentile) as slg_grade,
    get_percentile_grade(pp.hr_percentile) as power_grade,
    
    pp.qualified

FROM batting_seasons_unified b
LEFT JOIN player_percentiles pp ON b.player_id = pp.player_id 
    AND pp.scope = 'season' 
    AND pp.year = b.season;

-- ============================================================================
-- CAREER STATS WITH PERCENTILES VIEW  
-- ============================================================================

CREATE OR REPLACE VIEW career_stats_with_percentiles AS
SELECT 
    c.*,
    
    -- Career percentiles
    pp.war_percentile as career_war_percentile,
    
    -- Career tiers using functions
    get_career_tier(pp.war_percentile) as career_tier,
    get_percentile_name(pp.war_percentile) as career_war_tier,
    get_percentile_grade(pp.war_percentile) as career_grade,
    
    pp.qualified as career_qualified

FROM career_stats_unified c
LEFT JOIN player_percentiles pp ON c.player_id = pp.player_id 
    AND pp.scope = 'career';

-- ============================================================================
-- PERCENTILE LEADERBOARDS VIEW
-- ============================================================================

CREATE OR REPLACE VIEW percentile_leaderboards AS
SELECT 
    'Season WAR' as category,
    pp.year,
    pm.name_first || ' ' || pm.name_last as player_name,
    pp.war_value as stat_value,
    pp.war_percentile as percentile,
    pp.qualified,
    ROW_NUMBER() OVER (PARTITION BY pp.year ORDER BY pp.war_percentile DESC) as rank
FROM player_percentiles pp
JOIN players_master pm ON pp.player_id = pm.player_id
WHERE pp.scope = 'season' 
  AND pp.war_percentile IS NOT NULL
  AND pp.qualified = true

UNION ALL

SELECT 
    'Season wRC+' as category,
    pp.year,
    pm.name_first || ' ' || pm.name_last as player_name,
    pp.wrc_plus_value as stat_value,
    pp.wrc_plus_percentile as percentile,
    pp.qualified,
    ROW_NUMBER() OVER (PARTITION BY pp.year ORDER BY pp.wrc_plus_percentile DESC) as rank
FROM player_percentiles pp
JOIN players_master pm ON pp.player_id = pm.player_id
WHERE pp.scope = 'season' 
  AND pp.wrc_plus_percentile IS NOT NULL
  AND pp.qualified = true

UNION ALL

SELECT 
    'Career WAR' as category,
    NULL as year,
    pm.name_first || ' ' || pm.name_last as player_name,
    pp.war_value as stat_value,
    pp.war_percentile as percentile,
    pp.qualified,
    ROW_NUMBER() OVER (ORDER BY pp.war_percentile DESC) as rank
FROM player_percentiles pp
JOIN players_master pm ON pp.player_id = pm.player_id
WHERE pp.scope = 'career' 
  AND pp.war_percentile IS NOT NULL
  AND pp.qualified = true;

-- ============================================================================
-- PERCENTILE COMPARISON VIEW
-- ============================================================================

CREATE OR REPLACE VIEW percentile_comparisons AS
WITH player_seasons AS (
    SELECT 
        pp.player_id,
        pm.name_first || ' ' || pm.name_last as player_name,
        COUNT(*) as seasons_with_data,
        AVG(pp.war_percentile) as avg_war_percentile,
        MAX(pp.war_percentile) as peak_war_percentile,
        AVG(pp.wrc_plus_percentile) as avg_wrc_plus_percentile,
        MAX(pp.wrc_plus_percentile) as peak_wrc_plus_percentile,
        COUNT(*) FILTER (WHERE pp.qualified = true) as qualified_seasons,
        COUNT(*) FILTER (WHERE pp.war_percentile >= 90) as elite_seasons,
        COUNT(*) FILTER (WHERE pp.war_percentile >= 75) as great_seasons
    FROM player_percentiles pp
    JOIN players_master pm ON pp.player_id = pm.player_id
    WHERE pp.scope = 'season'
    GROUP BY pp.player_id, pm.name_first, pm.name_last
)
SELECT 
    ps.*,
    cp.war_percentile as career_war_percentile,
    
    -- Consistency metrics
    CASE 
        WHEN ps.elite_seasons >= 5 THEN 'Consistently Elite'
        WHEN ps.great_seasons >= 7 THEN 'Consistently Great'
        WHEN ps.avg_war_percentile >= 75 THEN 'Consistently Above Average'
        WHEN ps.avg_war_percentile >= 50 THEN 'Consistently Average'
        ELSE 'Inconsistent'
    END as consistency_tier,
    
    -- Peak vs longevity
    CASE 
        WHEN ps.peak_war_percentile >= 99 AND ps.qualified_seasons >= 10 THEN 'Peak + Longevity'
        WHEN ps.peak_war_percentile >= 99 THEN 'Peak Dominant'
        WHEN ps.qualified_seasons >= 15 AND ps.avg_war_percentile >= 60 THEN 'Longevity Star'
        WHEN ps.qualified_seasons >= 10 THEN 'Solid Career'
        ELSE 'Short Career'
    END as career_type

FROM player_seasons ps
LEFT JOIN player_percentiles cp ON ps.player_id = cp.player_id 
    AND cp.scope = 'career'
WHERE ps.qualified_seasons >= 3;

COMMENT ON VIEW batting_seasons_with_percentiles IS 'Batting seasons enhanced with percentile rankings and grades';
COMMENT ON VIEW career_stats_with_percentiles IS 'Career statistics enhanced with percentile rankings and historical context';
COMMENT ON VIEW percentile_leaderboards IS 'Leaderboards showing top performers by percentile rankings';
COMMENT ON VIEW percentile_comparisons IS 'Compare players across peak performance, consistency, and longevity';