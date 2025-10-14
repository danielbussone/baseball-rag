# FanGraphs ETL Pipeline to PostgreSQL
# Pulls batter leaderboard data and loads into local Postgres database

# Install required packages (run once)
# install.packages("baseballr")
# install.packages("DBI")
# install.packages("RPostgres")
# install.packages("dplyr")
# install.packages("tidyr")

library(baseballr)
library(DBI)
library(RPostgres)
library(dplyr)
library(tidyr)

# ============================================================================
# CONFIGURATION
# ============================================================================

# Database connection settings
DB_CONFIG <- list(
  host = "localhost",
  port = 5432,
  dbname = "postgres",
  user = "postgres",
  password = "KenGriffeyJr.24PG"  # YOUR DOCKER PASSWORD
)

# Date range for data pull
START_YEAR <- 1988
END_YEAR <- 2025
NUM_YEARS = END_YEAR - START_YEAR

# Minimum plate appearances for inclusion
MIN_PA <- 50

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

cat("Connected successfully!\n\n")

# ============================================================================
# PULL FANGRAPHS DATA
# ============================================================================

cat("Fetching FanGraphs batter leaderboard data...\n")
cat(sprintf("Years: %d-%d, Min PA: %d\n\n", START_YEAR, END_YEAR, MIN_PA))

# FG doesn't seems to like pulling multiple years at once, so we will loop
# Pull data beginning with START_YEAR
cat(sprintf("Getting Year: %d, Min PA: %d\n\n", START_YEAR, MIN_PA))
fg_data <- fg_batter_leaders(startseason = START_YEAR, endseason = START_YEAR, qual = MIN_PA)


# Pull individual season leaderboards and bind to the data frame
for (i in 1:NUM_YEARS) {
  year <- START_YEAR + i
  cat(sprintf("Getting Year: %d, Min PA: %d\n\n", year, MIN_PA))
  fg_year <- fg_batter_leaders(startseason = year, endseason = year, qual = MIN_PA)
  fg_data <- rbind(fg_data, fg_year, fill=TRUE)
}

cat(sprintf("Retrieved %d player-seasons\n", nrow(fg_data)))
cat(sprintf("Columns: %d\n\n", ncol(fg_data)))

# Show sample
cat("Sample of data:\n")
print(head(fg_data %>% select(Season, PlayerName, Age, G, PA, HR, AVG, OBP, SLG, WAR)))

# ============================================================================
# DATA CLEANING & TRANSFORMATION
# ============================================================================

cat("\nCleaning and transforming data...\n")

# Clean column names (remove special characters, convert to snake_case)
clean_names <- function(names) {
  names %>%
    gsub("%", "_pct", .) %>%
    gsub("\\+", "_plus", .) %>%
    gsub("-", "_", .) %>%
    gsub("\\(", "", .) %>%
    gsub("\\)", "", .) %>%
    tolower()
}

names(fg_data) <- clean_names(names(fg_data))

# Rename key columns for consistency
fg_data <- fg_data %>%
  rename(
    year = season,
    fangraphs_id = playerid,
    mlbam_id = xmlbamid,
    player_name = playername,
    team = team_name_abb
  ) %>%
  # Add a unique player-season identifier
  mutate(
    player_season_id = paste0(fangraphs_id, "_", year)
  )

# Separate into logical tables
# 1. Players (biographical data)
# 2. Season stats (the main stats table)
# 3. Advanced metrics (can be separate or combined)

# ============================================================================
# CREATE PLAYERS TABLE
# ============================================================================

cat("\nCreating players dimension table...\n")

players <- fg_data %>%
  group_by(fangraphs_id) %>%
  summarize(
    mlbam_id = first(mlbam_id),
    player_name = first(player_name),
    bats = first(bats),
    first_season = min(year, na.rm = TRUE),
    last_season = max(year, na.rm = TRUE),
    total_seasons = n_distinct(year),
    .groups = "drop"
  ) %>%
  mutate(
    created_at = Sys.time(),
    updated_at = Sys.time()
  )

cat(sprintf("Unique players: %d\n", nrow(players)))

# ============================================================================
# CREATE SEASON STATS TABLE
# ============================================================================

cat("\nPreparing season stats table...\n")

# Core batting stats
season_stats <- fg_data %>%
  select(
    player_season_id,
    fangraphs_id,
    year,
    age,
    team,
    position,
    # Basic counting stats
    g, ab, pa, h, `1b`, `2b`, `3b`, hr, r, rbi,
    bb, ibb, so, hbp, sf, sh, gdp, sb, cs,
    # Rate stats
    avg, obp, slg, ops, iso, babip,
    # Advanced rate stats
    bb_pct, k_pct, bb_k,
    # Batted ball
    gb_pct, fb_pct, ld_pct, iffb_pct, hr_fb,
    pull_pct, cent_pct, oppo_pct,
    soft_pct, med_pct, hard_pct,
    # Weighted stats
    woba, wraa, wrc, wrc_plus,
    # WAR components
    batting, fielding, baserunning, positional, defense, offense,
    war, rar,
    # Plate discipline
    o_swing_pct, z_swing_pct, swing_pct,
    o_contact_pct, z_contact_pct, contact_pct,
    zone_pct, f_strike_pct, swstr_pct,
    # Plus stats (era-adjusted)
    avg_plus, bb_pct_plus, k_pct_plus, 
    obp_plus, slg_plus, iso_plus, babip_plus,
    # Statcast (if available)
    ev, ev90, la, barrels, barrel_pct, maxev, hardhit, hardhit_pct, hard_pct_plus
  ) %>%
  mutate(
    created_at = Sys.time()
  )

cat(sprintf("Season stats records: %d\n", nrow(season_stats)))

# ============================================================================
# CREATE PITCH DATA TABLE (OPTIONAL - SEPARATE NORMALIZED TABLE)
# ============================================================================

# This separates pitch-level data which is extremely granular
# Only create if you want to query "what pitches did Player X see most?"

cat("\nPreparing pitch data table (optional)...\n")

pitch_cols <- names(fg_data)[grepl("^(pfx_|pi_|fbv|slv|ctv|cbv|chv|sfv)", names(fg_data))]

pitch_data <- fg_data %>%
  select(player_season_id, fangraphs_id, year, all_of(pitch_cols)) %>%
  mutate(created_at = Sys.time())

cat(sprintf("Pitch data columns: %d\n", length(pitch_cols)))

# ============================================================================
# WRITE TO DATABASE (UPSERT MODE)
# ============================================================================

cat("\n=== WRITING TO DATABASE ===\n")

# Helper function for upsert (insert or update on conflict)
upsert_table <- function(con, table_name, data, conflict_columns) {
  # Use temporary table approach for upsert
  temp_table <- paste0("temp_", table_name)
  
  # Write to temporary table
  dbWriteTable(con, temp_table, data, temporary = TRUE, overwrite = TRUE, row.names = FALSE)
  
  # Get all column names except conflict columns
  all_cols <- names(data)
  update_cols <- setdiff(all_cols, conflict_columns)
  
  # Build UPDATE SET clause
  update_set <- paste(
    sapply(update_cols, function(col) sprintf("\"%s\" = EXCLUDED.\"%s\"", col, col)),
    collapse = ",\n"
  )
  
  # Build INSERT statement with ON CONFLICT
  sql <- sprintf(
    "INSERT INTO %s \n SELECT * FROM %s \n ON CONFLICT (%s) \n DO UPDATE SET %s",
    table_name,
    temp_table,
    paste(conflict_columns, collapse = ", "),
    update_set
  )
  cat(sql)
  
  # Execute upsert
  result <- dbExecute(con, sql)
  
  # Drop temporary table
  dbExecute(con, sprintf("DROP TABLE %s", temp_table))
  
  return(result)
}

# Upsert players table
cat("Upserting players table...\n")
rows_affected <- upsert_table(con, "fg_players", players, c("fangraphs_id"))
cat(sprintf("✓ Upserted %d players\n", rows_affected))

# Upsert season stats table
cat("Upserting season_stats table...\n")
rows_affected <- upsert_table(con, "fg_season_stats", season_stats, c("player_season_id"))
cat(sprintf("✓ Upserted %d season records\n", rows_affected))

# Upsert pitch data table
cat("Upserting pitch_data table...\n")
rows_affected <- upsert_table(con, "fg_batter_pitches_faced", pitch_data, c("player_season_id"))
cat(sprintf("✓ Upserted %d pitch data records\n", rows_affected))

# ============================================================================
# VERIFICATION QUERIES
# ============================================================================

cat("\n=== VERIFICATION ===\n")

# Count records
player_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM fg_players")
cat(sprintf("Players in database: %d\n", as.integer(player_count$count)))

season_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM fg_season_stats")
cat(sprintf("Season records in database: %d\n", as.integer(season_count$count)))

# Top 10 by career WAR
cat("\nTop 10 players by total WAR (2010-2024):\n")
top_players <- dbGetQuery(con, "
  SELECT 
    p.player_name,
    COUNT(*) as seasons,
    ROUND(SUM(s.war)::numeric, 1) as total_war,
    ROUND(AVG(s.war)::numeric, 1) as avg_war,
    SUM(s.hr) as total_hr,
    ROUND(AVG(s.wrc_plus)::numeric, 0) as avg_wrc_plus
  FROM fg_players p
  JOIN fg_season_stats s ON p.fangraphs_id = s.fangraphs_id
  GROUP BY p.player_name
  ORDER BY total_war DESC
  LIMIT 10
")
print(top_players)

# ============================================================================
# CLEANUP
# ============================================================================

dbDisconnect(con)
cat("\n✓ Database connection closed\n")
cat("\n=== ETL COMPLETE ===\n")
cat(sprintf("Loaded data for years %d-%d\n", START_YEAR, END_YEAR))
cat("Tables created: fg_players, fg_season_stats, fg_pitch_data\n")
