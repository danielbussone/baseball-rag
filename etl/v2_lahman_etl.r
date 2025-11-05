#!/usr/bin/env Rscript
# Lahman V2 ETL - CSV Import with Master Player Registry

library(DBI)
library(RPostgres)
library(Lahman)
library(baseballr)
library(dplyr)

# ============================================================================
# CONFIGURATION  
# ============================================================================

DB_CONFIG <- list(
  host = "localhost",
  port = 5432,
  dbname = "postgres",
  user = "postgres", 
  password = "baseball123"
)



# ============================================================================
# DATABASE CONNECTION
# ============================================================================

cat("Connecting to PostgreSQL...\n")
con <- dbConnect(
  RPostgres::Postgres(),
  host = DB_CONFIG$host,
  port = DB_CONFIG$port,
  dbname = DB_CONFIG$dbname,
  user = DB_CONFIG$user,
  password = DB_CONFIG$password
)

# ============================================================================
# LAHMAN R PACKAGE DATA MAPPING
# ============================================================================

lahman_tables <- list(
  "lahman_people" = People,
  "lahman_batting" = Batting,
  "lahman_batting_post" = BattingPost,
  "lahman_pitching" = Pitching,
  "lahman_pitching_post" = PitchingPost,
  "lahman_fielding" = Fielding,
  "lahman_fielding_post" = FieldingPost,
  "lahman_appearances" = Appearances,
  "lahman_managers" = Managers,
  "lahman_awards_players" = AwardsPlayers,
  "lahman_awards_share_players" = AwardsSharePlayers,
  "lahman_hall_of_fame" = HallOfFame,
  "lahman_all_star_full" = AllstarFull,
  "lahman_series_post" = SeriesPost,
  "lahman_salaries" = Salaries,
  "lahman_college_playing" = CollegePlaying,
  "lahman_schools" = Schools,
  "lahman_parks" = Parks,
  "lahman_teams" = Teams,
  "lahman_teams_franchises" = TeamsFranchises
)

# ============================================================================
# IMPORT LAHMAN TABLES
# ============================================================================

for (table_name in names(lahman_tables)) {
  cat("Importing", table_name, "\n")
  
  # Get data from R package
  data <- lahman_tables[[table_name]]
  
  # Convert column names to snake_case
  names(data) <- gsub("([a-z])([A-Z])", "\\1_\\2", names(data))
  names(data) <- tolower(names(data))
  
  # Truncate and reload
  dbExecute(con, paste("TRUNCATE TABLE", table_name))
  
  # Write to database
  dbWriteTable(con, table_name, data, row.names = FALSE, overwrite = TRUE)
  
  cat("✓ Imported", nrow(data), "rows\n")
}

# ============================================================================
# BUILD MASTER PLAYER REGISTRY
# ============================================================================

cat("Building master player registry...\n")

# Start with Lahman people as the base (most complete biographical data)
dbExecute(con, "TRUNCATE TABLE players_master")

# Remove duplicate bbref_id entries, keeping the correct one
dbExecute(con, "DELETE FROM lahman_people WHERE player_id = 'kellyho99'")

dbExecute(con, "
INSERT INTO players_master (
  lahman_id, name_first, name_last, name_given,
  birth_year, birth_month, birth_day, birth_country, birth_state, birth_city,
  death_year, death_month, death_day, death_country, death_state, death_city,
  height_inches, weight_lbs, bats, throws, debut_date, final_game_date, bbref_id
)
SELECT 
  player_id, name_first, name_last, name_given,
  birth_year, birth_month, birth_day, birth_country, birth_state, birth_city,
  death_year, death_month, death_day, death_country, death_state, death_city,
  height, weight, bats, throws, debut::date, final_game::date, bbref_id
FROM lahman_people
")

# Link FanGraphs IDs using Chadwick Bureau registry
cat("Linking player IDs using Chadwick registry...\n")

# Check if Chadwick registry exists
chadwick_exists <- dbGetQuery(con, "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_name = 'chadwick_registry'")$count > 0

if (chadwick_exists) {
  # Use Chadwick registry for precise ID linking
  cat("Using Chadwick Bureau registry for ID linking...\n")
  
  dbExecute(con, "
  UPDATE players_master pm
  SET fangraphs_id = CASE WHEN c.key_fangraphs IS NOT NULL THEN c.key_fangraphs ELSE NULL END,
      mlbam_id = CASE WHEN c.key_mlbam IS NOT NULL THEN c.key_mlbam ELSE NULL end,
      retro_id = CASE WHEN c.key_retro != '' THEN c.key_retro ELSE NULL END
  FROM chadwick_registry c
  WHERE (pm.bbref_id = c.key_bbref AND pm.bbref_id IS NOT NULL AND c.key_bbref IS NOT NULL AND c.key_bbref != '')
     OR (pm.retro_id = c.key_retro AND pm.retro_id IS NOT NULL AND c.key_retro IS NOT NULL AND c.key_retro != '')
  ")
  
} else {
  # Fallback to name matching
  cat("Chadwick registry not found, using name matching for ID linking...\n")
  dbExecute(con, "
  UPDATE players_master pm
  SET fangraphs_id = fg.playerid,
      mlbam_id = fg.xmlbamid
  FROM (
    SELECT DISTINCT playerid, xmlbamid, playername
    FROM fg_batting_raw 
    WHERE playerid IS NOT NULL
  ) fg
  WHERE LOWER(pm.name_first || ' ' || pm.name_last) = LOWER(fg.playername)
    AND pm.fangraphs_id IS NULL
  ")
}

# ============================================================================
# VERIFICATION
# ============================================================================

cat("Verification:\n")

# Count records
people_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM lahman_people")
cat("Lahman people:", people_count$count, "\n")

batting_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM lahman_batting")  
cat("Lahman batting seasons:", batting_count$count, "\n")

postseason_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM lahman_batting_post")
cat("Postseason batting records:", postseason_count$count, "\n")

master_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM players_master")
cat("Master player registry:", master_count$count, "\n")

linked_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM players_master WHERE fangraphs_id IS NOT NULL")
cat("Players linked to FanGraphs:", linked_count$count, "\n")

dbDisconnect(con)
cat("Lahman ETL complete!\n")