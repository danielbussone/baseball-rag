#!/usr/bin/env Rscript

# Lahman Database ETL Pipeline
# Downloads and imports Sean Lahman's Baseball Database

library(DBI)
library(RPostgres)
library(Lahman)
library(dplyr)

# ============================================================================
# CONFIGURATION
# ============================================================================

# Database connection settings
DB_CONFIG <- list(
  host = "localhost",
  port = 5432,
  dbname = "postgres",
  user = "postgres",
  password = "baseball123"  # YOUR DOCKER PASSWORD
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

# Core tables to import
core_tables <- list(
  "people" = People,
  "batting" = Batting,
  "pitching" = Pitching,
  "fielding" = Fielding,
  "teams" = Teams,
  "awards_players" = AwardsPlayers,
  "hall_of_fame" = HallOfFame,
  "all_star_full" = AllstarFull
)

# Import each table with snake_case columns
for (table_name in names(core_tables)) {
  cat("Importing", table_name, "...\n")
  
  # Drop existing table
  dbExecute(con, paste("DROP TABLE IF EXISTS", table_name, "CASCADE"))
  
  # Convert column names to snake_case
  data <- core_tables[[table_name]]
  names(data) <- gsub("([a-z])([A-Z])", "\\1_\\2", names(data))
  names(data) <- tolower(names(data))
  names(data) <- gsub("^2b$", "doubles", names(data))
  names(data) <- gsub("^3b$", "triples", names(data))
  
  # Write table
  dbWriteTable(con, table_name, data, row.names = FALSE)
  
  cat("✓ Imported", nrow(data), "rows\n")
}

# Create indexes
cat("Creating indexes...\n")
indexes <- c(
  "CREATE INDEX idx_people_player_id ON people(player_id)",
  "CREATE INDEX idx_batting_player_year ON batting(player_id, year_id)",
  "CREATE INDEX idx_pitching_player_year ON pitching(player_id, year_id)",
  "CREATE INDEX idx_fielding_player_year ON fielding(player_id, year_id)",
  "CREATE INDEX idx_teams_year ON teams(year_id, team_id)"
)

for (idx in indexes) {
  dbExecute(con, idx)
}

cat("✓ Lahman database imported successfully\n")
dbDisconnect(con)