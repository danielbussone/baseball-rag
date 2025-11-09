-- Extended Percentiles Setup Script
-- Execute to add comprehensive percentile functionality with 5% increments

-- 1. Create percentile tables and functions
\i v2_percentiles_schema.sql
\i v2_percentiles_functions_extended.sql
\i v2_percentile_names.sql

-- 2. Create wrapper function for extended percentiles
CREATE OR REPLACE FUNCTION refresh_all_percentiles_extended() 
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    year_record RECORD;
BEGIN
    -- Refresh career percentiles
    result_text := result_text || populate_career_percentiles_extended() || E'\n';
    
    -- Refresh season percentiles for recent years (last 5 years)
    FOR year_record IN 
        SELECT DISTINCT season 
        FROM batting_seasons_unified 
        WHERE season >= EXTRACT(YEAR FROM CURRENT_DATE) - 5
        ORDER BY season DESC
    LOOP
        result_text := result_text || populate_season_percentiles_extended(year_record.season) || E'\n';
    END LOOP;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- 3. Initial data population (this may take several minutes)
SELECT refresh_all_percentiles_extended();

-- 4. Create sample queries view
CREATE OR REPLACE VIEW percentile_examples AS
SELECT 
    'Season Leaders' as query_type,
    'SELECT player_name, season, war_value, war_percentile, war_tier, war_grade 
     FROM batting_seasons_with_percentile_names 
     WHERE season = 2023 AND qualified = true 
     ORDER BY war_percentile DESC LIMIT 10;' as example_query
UNION ALL
SELECT 
    'Career Tiers',
    'SELECT player_name, career_total_war, career_war_percentile, career_tier, career_grade
     FROM career_stats_with_percentile_names 
     WHERE career_qualified = true 
     ORDER BY career_war_percentile DESC LIMIT 20;'
UNION ALL
SELECT 
    'Percentile Distribution',
    'SELECT stat_name, scope, year, p50 as median, p75, p90, p95, p99 
     FROM stat_percentiles 
     WHERE stat_name = ''war'' AND scope = ''season'' 
     ORDER BY year DESC LIMIT 5;'
UNION ALL
SELECT 
    'Player Comparison',
    'SELECT player_name, war_percentile, war_tier, wrc_plus_percentile, offense_tier
     FROM batting_seasons_with_percentile_names 
     WHERE player_name LIKE ''%Trout%'' AND season >= 2020;';

-- 5. Verify setup
SELECT 
    'Extended percentiles setup complete. Enhanced features:' as status
UNION ALL
SELECT '- 5% increment percentiles (1st, 5th, 10th, 15th, 20th, etc.)'
UNION ALL
SELECT '- Descriptive tier names (Elite, Superstar, All-Star, etc.)'
UNION ALL
SELECT '- 20-80 scouting grades'
UNION ALL
SELECT '- Career historical tiers (Hall of Fame, etc.)'
UNION ALL
SELECT '- Statistics covered: WAR, wRC+, ERA, FIP, AVG, OBP, SLG, HR'
UNION ALL
SELECT '- stat_percentiles: ' || COUNT(*)::text || ' distributions'
FROM stat_percentiles
UNION ALL  
SELECT '- player_percentiles: ' || COUNT(*)::text || ' player rankings'
FROM player_percentiles;

COMMENT ON FUNCTION refresh_all_percentiles_extended IS 'Refresh all percentiles with 5% increments and extended statistics';