-- Percentile Names and Tier Functions
-- Convert percentile numbers to descriptive names

CREATE OR REPLACE FUNCTION get_percentile_name(percentile_value NUMERIC) 
RETURNS TEXT AS $$
BEGIN
    RETURN CASE 
        WHEN percentile_value >= 99 THEN 'Elite (99th+)'
        WHEN percentile_value >= 95 THEN 'Superstar (95-99th)'
        WHEN percentile_value >= 90 THEN 'All-Star (90-95th)'
        WHEN percentile_value >= 85 THEN 'Excellent (85-90th)'
        WHEN percentile_value >= 80 THEN 'Very Good (80-85th)'
        WHEN percentile_value >= 75 THEN 'Good (75-80th)'
        WHEN percentile_value >= 70 THEN 'Above Average+ (70-75th)'
        WHEN percentile_value >= 65 THEN 'Above Average (65-70th)'
        WHEN percentile_value >= 60 THEN 'Slightly Above Average (60-65th)'
        WHEN percentile_value >= 55 THEN 'Average+ (55-60th)'
        WHEN percentile_value >= 50 THEN 'Average (50-55th)'
        WHEN percentile_value >= 45 THEN 'Average- (45-50th)'
        WHEN percentile_value >= 40 THEN 'Slightly Below Average (40-45th)'
        WHEN percentile_value >= 35 THEN 'Below Average (35-40th)'
        WHEN percentile_value >= 30 THEN 'Below Average- (30-35th)'
        WHEN percentile_value >= 25 THEN 'Poor (25-30th)'
        WHEN percentile_value >= 20 THEN 'Poor- (20-25th)'
        WHEN percentile_value >= 15 THEN 'Very Poor (15-20th)'
        WHEN percentile_value >= 10 THEN 'Very Poor- (10-15th)'
        WHEN percentile_value >= 5 THEN 'Terrible (5-10th)'
        WHEN percentile_value >= 1 THEN 'Awful (1-5th)'
        ELSE 'Historically Bad (<1st)'
    END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_percentile_grade(percentile_value NUMERIC) 
RETURNS INTEGER AS $$
BEGIN
    RETURN CASE 
        WHEN percentile_value >= 99 THEN 80
        WHEN percentile_value >= 95 THEN 75
        WHEN percentile_value >= 90 THEN 70
        WHEN percentile_value >= 85 THEN 65
        WHEN percentile_value >= 80 THEN 60
        WHEN percentile_value >= 75 THEN 58
        WHEN percentile_value >= 70 THEN 56
        WHEN percentile_value >= 65 THEN 54
        WHEN percentile_value >= 60 THEN 52
        WHEN percentile_value >= 55 THEN 51
        WHEN percentile_value >= 50 THEN 50
        WHEN percentile_value >= 45 THEN 49
        WHEN percentile_value >= 40 THEN 48
        WHEN percentile_value >= 35 THEN 46
        WHEN percentile_value >= 30 THEN 44
        WHEN percentile_value >= 25 THEN 42
        WHEN percentile_value >= 20 THEN 40
        WHEN percentile_value >= 15 THEN 35
        WHEN percentile_value >= 10 THEN 30
        WHEN percentile_value >= 5 THEN 25
        ELSE 20
    END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_career_tier(percentile_value NUMERIC) 
RETURNS TEXT AS $$
BEGIN
    RETURN CASE 
        WHEN percentile_value >= 99.5 THEN 'Inner Circle Hall of Fame'
        WHEN percentile_value >= 99 THEN 'Hall of Fame Lock'
        WHEN percentile_value >= 97 THEN 'Strong Hall of Fame Case'
        WHEN percentile_value >= 95 THEN 'Hall of Fame Candidate'
        WHEN percentile_value >= 90 THEN 'Borderline Hall of Fame'
        WHEN percentile_value >= 85 THEN 'Hall of Very Good'
        WHEN percentile_value >= 80 THEN 'Excellent Career'
        WHEN percentile_value >= 75 THEN 'Very Good Career'
        WHEN percentile_value >= 70 THEN 'Good Career'
        WHEN percentile_value >= 60 THEN 'Above Average Career'
        WHEN percentile_value >= 40 THEN 'Average Career'
        WHEN percentile_value >= 25 THEN 'Below Average Career'
        WHEN percentile_value >= 10 THEN 'Poor Career'
        ELSE 'Replacement Level Career'
    END;
END;
$$ LANGUAGE plpgsql;

-- Enhanced views with percentile names
CREATE OR REPLACE VIEW batting_seasons_with_percentile_names AS
SELECT 
    b.*,
    pp.war_percentile,
    pp.wrc_plus_percentile,
    pp.avg_percentile,
    pp.obp_percentile,
    pp.slg_percentile,
    pp.hr_percentile,
    
    -- Percentile names
    get_percentile_name(pp.war_percentile) as war_tier,
    get_percentile_name(pp.wrc_plus_percentile) as offense_tier,
    get_percentile_name(pp.avg_percentile) as avg_tier,
    get_percentile_name(pp.obp_percentile) as obp_tier,
    get_percentile_name(pp.slg_percentile) as slg_tier,
    get_percentile_name(pp.hr_percentile) as power_tier,
    
    -- Grades (20-80 scale)
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

CREATE OR REPLACE VIEW career_stats_with_percentile_names AS
SELECT 
    c.*,
    pp.war_percentile as career_war_percentile,
    
    -- Career tier names
    get_career_tier(pp.war_percentile) as career_tier,
    get_percentile_name(pp.war_percentile) as career_war_tier,
    
    -- Career grade
    get_percentile_grade(pp.war_percentile) as career_grade,
    
    pp.qualified as career_qualified

FROM career_stats_unified c
LEFT JOIN player_percentiles pp ON c.player_id = pp.player_id 
    AND pp.scope = 'career';

COMMENT ON FUNCTION get_percentile_name IS 'Convert percentile to descriptive tier name';
COMMENT ON FUNCTION get_percentile_grade IS 'Convert percentile to 20-80 scouting grade';
COMMENT ON FUNCTION get_career_tier IS 'Convert career percentile to historical significance tier';