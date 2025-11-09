-- Critical Schema Fixes

-- 1. Add foreign key constraints
ALTER TABLE fg_batting_leaders 
ADD CONSTRAINT fk_fg_batting_playerid 
FOREIGN KEY (playerid) REFERENCES players_master(fangraphs_id);

-- 2. Add data validation constraints  
ALTER TABLE fg_batting_leaders 
ADD CONSTRAINT chk_season_range CHECK (season BETWEEN 1871 AND 2030),
ADD CONSTRAINT chk_war_range CHECK (war BETWEEN -5 AND 15);

-- 3. Fix index ordering (move after materialized view)
-- Remove duplicate index creation from unified_views.sql

-- 4. Add partitioning for large tables
CREATE TABLE fg_batting_leaders_partitioned (
    LIKE fg_batting_leaders INCLUDING ALL
) PARTITION BY RANGE (season);

-- 5. Add missing indexes for common queries
CREATE INDEX idx_fg_batting_age_season ON fg_batting_leaders(age, season);
CREATE INDEX idx_players_master_debut_year ON players_master(EXTRACT(YEAR FROM debut_date));