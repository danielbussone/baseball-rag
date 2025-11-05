#!/usr/bin/env Rscript
# Chadwick Bureau Registry ETL

library(DBI)
library(RPostgres)
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
# FETCH CHADWICK REGISTRY
# ============================================================================

cat("Fetching Chadwick Bureau player registry...\n")
chadwick_registry <- tryCatch({
  baseballr::chadwick_player_lu()
}, error = function(e) {
  cat("Error fetching Chadwick registry:", e$message, "\n")
  stop("Failed to fetch Chadwick registry")
})

cat("Retrieved", nrow(chadwick_registry), "player records\n")

# ============================================================================
# DATA CLEANING
# ============================================================================

cat("Cleaning Chadwick data...\n")

# Clean column names to match schema
names(chadwick_registry) <- tolower(names(chadwick_registry))

# Add metadata
chadwick_registry$created_at <- Sys.time()
chadwick_registry$updated_at <- Sys.time()

# ============================================================================
# WRITE TO DATABASE
# ============================================================================

cat("Writing to chadwick_registry table...\n")

# Truncate and reload
dbExecute(con, "TRUNCATE TABLE chadwick_registry")

# Write data
dbWriteTable(con, "chadwick_registry", as.data.frame(chadwick_registry), append = TRUE, row.names = FALSE)
# ============================================================================
# VERIFICATION
# ============================================================================

cat("Verification:\n")

# Count records
total_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM chadwick_registry")
cat("Total records:", total_count$count, "\n")

# Count by ID type
fg_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM chadwick_registry WHERE key_fangraphs IS NOT NULL")
cat("Records with FanGraphs ID:", fg_count$count, "\n")

mlb_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM chadwick_registry WHERE key_mlbam IS NOT NULL")
cat("Records with MLB ID:", mlb_count$count, "\n")

bbref_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM chadwick_registry WHERE key_bbref IS NOT NULL AND key_bbref != ''")
cat("Records with Baseball Reference ID:", bbref_count$count, "\n")

retro_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM chadwick_registry WHERE key_retro IS NOT NULL AND key_retro != ''")
cat("Records with Retrosheet ID:", retro_count$count, "\n")

dbDisconnect(con)
cat("Chadwick ETL complete!\n")