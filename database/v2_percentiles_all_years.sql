-- Populate All Years Percentiles (1871-2025)
-- Comprehensive percentile calculation for all available data

CREATE OR REPLACE FUNCTION populate_all_years_percentiles() 
RETURNS TEXT AS $$
DECLARE
    year_record RECORD;
    result_text TEXT := '';
    batting_years INTEGER := 0;
    pitching_years INTEGER := 0;
    fielding_years INTEGER := 0;
BEGIN
    -- Batting percentiles (FanGraphs era: 1988+)
    FOR year_record IN 
        SELECT DISTINCT season 
        FROM fg_batting_leaders 
        WHERE season BETWEEN 1988 AND 2025
        ORDER BY season
    LOOP
        PERFORM populate_season_percentiles_batting_only(year_record.season);
        PERFORM populate_season_percentiles_with_plus(year_record.season);
        batting_years := batting_years + 1;
        
        IF batting_years % 10 = 0 THEN
            result_text := result_text || 'Completed batting through ' || year_record.season || E'\n';
        END IF;
    END LOOP;
    
    -- Pitching percentiles (FanGraphs era: 1988+)
    FOR year_record IN 
        SELECT DISTINCT season 
        FROM fg_pitching_leaders 
        WHERE season BETWEEN 1988 AND 2025
        ORDER BY season
    LOOP
        PERFORM populate_pitcher_percentiles(year_record.season);
        pitching_years := pitching_years + 1;
        
        IF pitching_years % 10 = 0 THEN
            result_text := result_text || 'Completed pitching through ' || year_record.season || E'\n';
        END IF;
    END LOOP;
    
    -- Fielding percentiles (FanGraphs era: 2002+ for advanced metrics)
    FOR year_record IN 
        SELECT DISTINCT season 
        FROM fg_fielding_leaders 
        WHERE season BETWEEN 2002 AND 2025
        ORDER BY season
    LOOP
        PERFORM populate_fielder_percentiles(year_record.season);
        fielding_years := fielding_years + 1;
        
        IF fielding_years % 5 = 0 THEN
            result_text := result_text || 'Completed fielding through ' || year_record.season || E'\n';
        END IF;
    END LOOP;
    
    -- Career percentiles
    PERFORM populate_career_percentiles_extended();
    
    result_text := result_text || 'COMPLETED: ' || batting_years || ' batting seasons, ' || 
                   pitching_years || ' pitching seasons, ' || fielding_years || ' fielding seasons';
    
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Quick function for recent years only (last 10 years)
CREATE OR REPLACE FUNCTION populate_recent_percentiles() 
RETURNS TEXT AS $$
DECLARE
    current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE);
    start_year INTEGER := current_year - 10;
    year_record RECORD;
    result_text TEXT := '';
BEGIN
    FOR year_record IN 
        SELECT generate_series(start_year, current_year) as season
    LOOP
        -- Try batting (will skip if no data)
        BEGIN
            PERFORM populate_season_percentiles_batting_only(year_record.season);
            PERFORM populate_season_percentiles_with_plus(year_record.season);
        EXCEPTION WHEN OTHERS THEN
            -- Skip if no data
        END;
        
        -- Try pitching
        BEGIN
            PERFORM populate_pitcher_percentiles(year_record.season);
        EXCEPTION WHEN OTHERS THEN
            -- Skip if no data
        END;
        
        -- Try fielding
        BEGIN
            PERFORM populate_fielder_percentiles(year_record.season);
        EXCEPTION WHEN OTHERS THEN
            -- Skip if no data
        END;
        
        result_text := result_text || year_record.season || ' ';
    END LOOP;
    
    PERFORM populate_career_percentiles_extended();
    
    RETURN 'Populated recent years: ' || result_text;
END;
$$ LANGUAGE plpgsql;