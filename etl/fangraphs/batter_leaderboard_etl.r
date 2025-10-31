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
  password = "baseball123"  # YOUR DOCKER PASSWORD
)

# Date range for data pull
START_YEAR <- 1988
END_YEAR <- 2025
NUM_YEARS = END_YEAR - START_YEAR

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
cat(sprintf("Years: %d-%d\n\n", START_YEAR, END_YEAR))

# FG doesn't seems to like pulling multiple years at once, so we will loop
# Pull data beginning with START_YEAR
cat(sprintf("Getting Year: %d\n\n", START_YEAR))
fg_batter_data <- fg_batter_leaders(startseason = START_YEAR, endseason = START_YEAR)

fg_pitcher_data <- fg_pitcher_leaders(startseason = START_YEAR, endseason = START_YEAR)

fg_fielder_data <- fg_fielder_leaders(startseason = START_YEAR, endseason = START_YEAR)


# Pull individual season leaderboards and bind to the data frame
for (i in 1:NUM_YEARS) {
  year <- START_YEAR + i
  cat(sprintf("\nGetting Year: %d\n", year))
  
  cat(sprintf("Getting Batting Leaders\n"))
  fg_batter_year <- fg_batter_leaders(startseason = year, endseason = year)
  fg_batter_data <- rbind(fg_batter_data, fg_batter_year, fill=TRUE)
  
  cat(sprintf("Getting Pitching Leaders\n"))
  fg_pitcher_year <- fg_pitcher_leaders(startseason = year, endseason = year)
  fg_pitcher_data <- rbind(fg_pitcher_data, fg_pitcher_year, fill=TRUE)
  
  cat(sprintf("Getting Fielding Leaders\n"))
  fg_fielder_year <- fg_fielder_leaders(startseason = year, endseason = year)
  fg_fielder_data <- rbind(fg_fielder_data, fg_fielder_year, fill=TRUE)
}

cat(sprintf("Retrieved %d player-batter-seasons\n", nrow(fg_batter_data)))
cat(sprintf("Columns: %d\n\n", ncol(fg_batter_data)))

cat(sprintf("Retrieved %d player-pitcher-seasons\n", nrow(fg_pitcher_data)))
cat(sprintf("Columns: %d\n\n", ncol(fg_pitcher_data)))

cat(sprintf("Retrieved %d player-fielder-seasons\n", nrow(fg_fielder_data)))
cat(sprintf("Columns: %d\n\n", ncol(fg_fielder_data)))

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

mookie <- season_stats %>% filter(fangraphs_id == "13611")

dodgers <- season_stats %>% filter(team == "LAD")

# ============================================================================
# GRADE CALCULATION (20-80 Scouting Scale)
# ============================================================================

cat("\nCalculating player grades (20-80 scale)...\n")

# Generic Helper function for plus stat grading (100 = average)
grade_plus_stat <- function(plus_stat) {
  case_when(
    is.na(plus_stat) ~ NA_integer_,
    plus_stat >= 180 ~ 80L,
    plus_stat >= 160 ~ 70L,
    plus_stat >= 130 ~ 60L,
    plus_stat >= 110 ~ 55L,
    plus_stat >= 90 ~ 50L,
    plus_stat >= 50 ~ 45L,
    plus_stat >= 30 ~ 40L,
    plus_stat >= 10 ~ 30L,
    TRUE ~ 20L
  )
}

# Grade WAR
grade_war <- function(war) {
  case_when(
    is.na(war) ~ NA_integer_,
    war >= 8.0 ~ 80L,
    war >= 6.0 ~ 70L,
    war >= 3.5 ~ 60L,
    war >= 2.0 ~ 55L,
    war >= 0.5 ~ 50L,
    war >= 0 ~ 45L,
    war >= -1 ~ 40L,
    war >= -1.5 ~ 30L,
    TRUE ~ 20L
  )
}

# Grade Offense
grade_offense <- function(wrc_plus) {
  case_when(
    is.na(wrc_plus) ~ NA_integer_,
    wrc_plus >= 170 ~ 80L,
    wrc_plus >= 150 ~ 70L,
    wrc_plus >= 125 ~ 60L,
    wrc_plus >= 110 ~ 55L,
    wrc_plus >= 90 ~ 50L,
    wrc_plus >= 50 ~ 45L,
    wrc_plus >= 30 ~ 40L,
    wrc_plus >= 10 ~ 30L,
    TRUE ~ 20L
  )
}

# Grade Hit Tool
grade_hit <- function(avg_plus) {
  case_when(
    is.na(avg_plus) ~ NA_integer_,
    avg_plus >= 120 ~ 80L,
    avg_plus >= 115 ~ 70L,
    avg_plus >= 110 ~ 60L,
    avg_plus >= 105 ~ 55L,
    avg_plus >= 95 ~ 50L,
    avg_plus >= 90 ~ 45L,
    avg_plus >= 70 ~ 40L,
    avg_plus >= 50 ~ 30L,
    TRUE ~ 20L
  )
}

# Grade Contact Tool
grade_contact <- function(k_pct_plus) {
  case_when(
    is.na(k_pct_plus) ~ NA_integer_,
    k_pct_plus >= 200 ~ 80L,
    k_pct_plus >= 180 ~ 70L,
    k_pct_plus >= 150 ~ 60L,
    k_pct_plus >= 125 ~ 55L,
    k_pct_plus >= 90 ~ 50L,
    k_pct_plus >= 75 ~ 45L,
    k_pct_plus >= 50 ~ 40L,
    k_pct_plus >= 40 ~ 30L,
    TRUE ~ 20L
  )
}

# Grade speed (SB per 600 PA)
grade_speed <- function(sb, pa) {
  sb_per_600 <- (sb / pa) * 600
  case_when(
    is.na(sb) | is.na(pa) | pa == 0 ~ NA_integer_,
    sb_per_600 >= 55 ~ 80L,
    sb_per_600 >= 40 ~ 70L,
    sb_per_600 >= 25 ~ 60L,
    sb_per_600 >= 20 ~ 55L,
    sb_per_600 >= 15 ~ 50L,
    sb_per_600 >= 10 ~ 45L,
    sb_per_600 >= 5 ~ 40L,
    sb_per_600 >= 2 ~ 30L,
    TRUE ~ 20L
  )
}

# Grade EV90
grade_ev90 <- function(ev90) {
  case_when(
    is.na(ev90) ~ NA_integer_,
    ev90 >= 112.0 ~ 80L,
    ev90 >= 110.0 ~ 70L,
    ev90 >= 108.0 ~ 60L,
    ev90 >= 107.0 ~ 55L,
    ev90 >= 105.0 ~ 50L,
    ev90 >= 103.0 ~ 45L,
    ev90 >= 101.0 ~ 40L,
    ev90 >= 99.0 ~ 30L,
    TRUE ~ 20L
  )
}

grade_fielding <- function(fielding, position, year) {
  # The case_when() function evaluates the conditions in order
  # and returns the result for the first condition that is TRUE.
  case_when(
    is.na(fielding) ~ NA_integer_, # If fielding is NULL, return empty
    
    # Catcher criteria
    grepl("C", position, ignore.case = TRUE) & year <= 2001 & fielding >= 15 ~ 80L,
    grepl("C", position, ignore.case = TRUE) & year <= 2001 & fielding >= 10 ~ 70L,
    grepl("C", position, ignore.case = TRUE) & year <= 2001 & fielding >= 5 ~ 60L,
    grepl("C", position, ignore.case = TRUE) & year <= 2001 & fielding > -1 ~ 50L,
    grepl("C", position, ignore.case = TRUE) & year <= 2001 & fielding > -10 ~ 40L,
    grepl("C", position, ignore.case = TRUE) & year <= 2001 & fielding > -15 ~ 30L,
    grepl("C", position, ignore.case = TRUE) & year <= 2001 & fielding < -15 ~ 20L,
    
    # Catcher criteria (post-2001)
    grepl("C", position, ignore.case = TRUE) & year > 2001 & fielding >= 30 ~ 80L,
    grepl("C", position, ignore.case = TRUE) & year > 2001 & fielding >= 20 ~ 70L,
    grepl("C", position, ignore.case = TRUE) & year > 2001 & fielding >= 10 ~ 60L,
    grepl("C", position, ignore.case = TRUE) & year > 2001 & fielding > -1 ~ 50L,
    grepl("C", position, ignore.case = TRUE) & year > 2001 & fielding > -20 ~ 40L,
    grepl("C", position, ignore.case = TRUE) & year > 2001 & fielding > -30 ~ 30L,
    grepl("C", position, ignore.case = TRUE) & year > 2001 & fielding < -30 ~ 20L,
    
    # Fielder criteria (pre-2002)
    year <= 2001 & fielding >= 20 ~ 80L,
    year <= 2001 & fielding >= 15 ~ 70L,
    year <= 2001 & fielding >= 10 ~ 60L,
    year <= 2001 & fielding > -1 ~ 50L,
    year <= 2001 & fielding > -15 ~ 40L,
    year <= 2001 & fielding > -20 ~ 30L,
    year <= 2001 & fielding < -20 ~ 20L,
    
    # Fielder criteria (post-2001)
    year > 2001 & fielding >= 15 ~ 80L,
    year > 2001 & fielding >= 10 ~ 70L,
    year > 2001 & fielding >= 5 ~ 60L,
    year > 2001 & fielding > -1 ~ 50L,
    year > 2001 & fielding > -10 ~ 40L,
    year > 2001 & fielding > -15 ~ 30L,
    year > 2001 & fielding < -15 ~ 20L,
    
    # Fallback for any unmatched case
    TRUE ~ NA_integer_
  )
}


# Grade fielding (era-adjusted by position)
grade_fielding_foo <- function(fielding, year, position) {
  # Define thresholds by era
  if (year <= 2001) {
    catcher_80 <- 15
    catcher_50 <- 0
    catcher_20 <- -15
    other_80 <- 20
    other_50 <- 0
    other_20 <- -20
  } else if (year <= 2015) {
    catcher_80 <- 30
    catcher_50 <- 0
    catcher_20 <- -30
    other_80 <- 15
    other_50 <- 0
    other_20 <- -15
  } else {
    catcher_80 <- 30
    catcher_50 <- 0
    catcher_20 <- -30
    other_80 <- 15
    other_50 <- 0
    other_20 <- -15
  }
  
  # Use catcher thresholds if position includes 'C'
  is_catcher <- grepl("^C$|^C/|/C", position)
  
  g80 <- if_else(is_catcher, catcher_80, other_80)
  g50 <- if_else(is_catcher, catcher_50, other_50)
  g20 <- if_else(is_catcher, catcher_20, other_20)
  
  # Calculate grade
  case_when(
    fielding >= g80 ~ 80L,
    fielding >= g50 ~ as.integer(50 + ((fielding - g50) / (g80 - g50)) * 30),
    fielding >= g20 ~ as.integer(20 + ((fielding - g20) / (g50 - g20)) * 30),
    TRUE ~ 20L
  )
}

# Apply grades to season_stats
season_stats <- season_stats %>%
  mutate(
    overall_grade = grade_war(war),
    offense_grade = grade_offense(wrc_plus),
    power_grade = grade_plus_stat(iso_plus),
    hit_grade = grade_hit(avg_plus),
    discipline_grade = grade_plus_stat(bb_pct_plus),
    contact_grade = grade_contact(k_pct_plus),
    speed_grade = grade_speed(sb, pa),
    fielding_grade = grade_fielding(fielding, year, position),
    hard_contact_grade = grade_plus_stat(hard_pct_plus),
    exit_velo_grade = grade_ev90(ev90)
  )

cat("✓ Grades calculated\n")

# ============================================================================
# GRADE DISTRIBUTION VALIDATION
# ============================================================================

cat("\n=== GRADE DISTRIBUTION VALIDATION ===\n")
cat("Expected: 50 = average (50th %ile), 60 = +1 SD (84th %ile), 70 = +2 SD (97th %ile), 80 = +3 SD (99th %ile)\n\n")

# Function to show grade distribution
show_grade_distribution <- function(grades, grade_name) {
  grade_dist <- table(grades, useNA = "ifany")
  grade_pct <- prop.table(grade_dist) * 100
  
  cat(sprintf("%s Grade Distribution:\n", grade_name))
  print(round(grade_pct, 1))
  
  # Calculate percentiles for key grades
  non_na_grades <- grades[!is.na(grades)]
  if (length(non_na_grades) > 0) {
    pct_60_plus <- mean(non_na_grades >= 60) * 100
    pct_70_plus <- mean(non_na_grades >= 70) * 100
    pct_80 <- mean(non_na_grades >= 80) * 100
    
    cat(sprintf("  60+ grade: %.1f%% (expect ~16%%)\n", pct_60_plus))
    cat(sprintf("  70+ grade: %.1f%% (expect ~3%%)\n", pct_70_plus))
    cat(sprintf("  80 grade:  %.1f%% (expect ~1%%)\n\n", pct_80))
  }
}

# Validate distributions
show_grade_distribution(season_stats$overall_grade, "Overall (WAR)")
show_grade_distribution(season_stats$offense_grade, "Offense (wRC+)")
show_grade_distribution(season_stats$power_grade, "Power (ISO+)")
show_grade_distribution(season_stats$hit_grade, "Hit Tool (AVG+)")
show_grade_distribution(season_stats$discipline_grade, "Plate Discipline (BB%+)")
show_grade_distribution(season_stats$contact_grade, "Contact Tool (K%+)")
show_grade_distribution(season_stats$speed_grade, "Speed (SB)")

catcher_season_stats <- season_stats %>% filter(grepl("C", position, ignore.case = TRUE))
fielder_season_stats <- season_stats %>% filter(!grepl("C", position, ignore.case = TRUE))

show_grade_distribution(catcher_season_stats$fielding_grade, "Catcher Fielding")
show_grade_distribution(fielder_season_stats$fielding_grade, "Fielder Fielding")
show_grade_distribution(season_stats$hard_contact_grade, "Hard Contact (Hard%+)")
show_grade_distribution(season_stats$exit_velo_grade, "Exit Velo (EV90)")

# Show some example elite seasons
cat("\n=== EXAMPLE 80-GRADE OVERALL SEASONS ===\n")
elite_seasons <- season_stats %>%
  filter(overall_grade == 80) %>%
  select(year, fangraphs_id, war, overall_grade) %>%
  head(10)

if (nrow(elite_seasons) > 0) {
  # Get player names
  elite_with_names <- elite_seasons %>%
    left_join(players %>% select(fangraphs_id, player_name), by = "fangraphs_id") %>%
    select(player_name, year, war, overall_grade) %>%
    arrange(desc(war))
  
  print(elite_with_names)
} else {
  cat("No 80-grade seasons found\n")
}

cat("\n")

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
  dbWriteTable(con, temp_table, data, temporary = FALSE, overwrite = TRUE, row.names = FALSE)
  
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
cat("\nUpserting players table...\n")
rows_affected <- upsert_table(con, "fg_players", players, c("fangraphs_id"))
cat(sprintf("\n✓ Upserted %d players\n", rows_affected))

# Upsert season stats table
cat("\nUpserting season_stats table...\n")
rows_affected <- upsert_table(con, "fg_season_stats", season_stats, c("player_season_id"))
cat(sprintf("\n✓ Upserted %d season records\n", rows_affected))

# Upsert pitch data table
cat("\nUpserting pitch_data table...\n")
rows_affected <- upsert_table(con, "fg_batter_pitches_faced", pitch_data, c("player_season_id"))
cat(sprintf("\n✓ Upserted %d pitch data records\n", rows_affected))

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
