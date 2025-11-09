-- Percentiles Setup Script
-- Execute to add percentile functionality to Baseball RAG V2

-- 1. Create percentile tables and functions
\i v2_percentiles_schema.sql
\i v2_percentiles_functions.sql
\i v2_percentiles_views.sql

-- 2. Initial data population (this may take several minutes)
SELECT refresh_all_percentiles();

-- 3. Create maintenance job function
CREATE OR REPLACE FUNCTION maintain_percentiles() 
RETURNS TEXT AS $$
DECLARE
    current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE);
    result_text TEXT := '';
BEGIN
    -- Update current season percentiles monthly during season
    IF EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN 4 AND 10 THEN
        result_text := result_text || populate_season_percentiles(current_year) || E'\n';
    END IF;
    
    -- Update previous season percentiles in off-season
    IF EXTRACT(MONTH FROM CURRENT_DATE) BETWEEN 11 AND 3 THEN
        result_text := result_text || populate_season_percentiles(current_year - 1) || E'\n';
    END IF;
    
    -- Update career percentiles quarterly
    IF EXTRACT(MONTH FROM CURRENT_DATE) IN (1, 4, 7, 10) THEN
        result_text := result_text || populate_career_percentiles() || E'\n';
    END IF;
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- 4. Verify setup
SELECT 
    'Percentiles setup complete. Tables created:' as status
UNION ALL
SELECT '- stat_percentiles: ' || COUNT(*)::text || ' distributions'
FROM stat_percentiles
UNION ALL  
SELECT '- player_percentiles: ' || COUNT(*)::text || ' player rankings'
FROM player_percentiles;

COMMENT ON FUNCTION maintain_percentiles IS 'Scheduled maintenance function for percentile data - run monthly';