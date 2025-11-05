#!/usr/bin/env Rscript
# FanGraphs V2 ETL - Full Historical Data (1871-2024)

library(baseballr)
library(DBI)
library(RPostgres)
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

START_YEAR <- 1871
END_YEAR <- 2025

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
# FUNCTION OVERRIDES
# ============================================================================

danny_pitcher_leaders <- function(
    age = "",
    pos = "all",
    stats = "pit",
    lg = "all",
    qual = "0",
    startseason = "2023",
    endseason = "2023",
    startdate = "",
    enddate = "",
    month = "0",
    hand = "",
    team = "0",
    pageitems = "10000",
    pagenum = "1",
    ind = "0",
    rost = "0",
    players = "",
    type = "8",
    postseason = "",
    sortdir = "default",
    sortstat = "WAR") {
  
  params <- list(
    age = age,
    pos = pos,
    stats = stats,
    lg = lg,
    qual = qual,
    season = startseason,
    season1 = endseason,
    startdate = startdate,
    enddate = enddate,
    month = month,
    hand = hand,
    team = team,
    pageitems = pageitems,
    pagenum = pagenum,
    ind = ind,
    rost = rost,
    players = players,
    type = type,
    postseason = postseason,
    sortdir = sortdir,
    sortstat = sortstat
  )
  
  url <- "https://www.fangraphs.com/api/leaders/major-league/data"
  
  fg_endpoint <- httr::modify_url(url, query = params)
  
  lookup <- c(
    "Start_IP" = "Start-IP",
    "Relief_IP" = "Relief-IP",
    "WPA_minus" = "-WPA",
    "WPA_plus" = "+WPA", 
    "AgeRng" = "AgeR",
    "team_name" = "TeamName",
    "team_name_abb" = "TeamNameAbb")
  
  tryCatch(
    expr = {
      
      resp <- fg_endpoint %>% 
        mlb_api_call()
      
      fg_df <- resp$data %>% 
        jsonlite::toJSON() %>%
        jsonlite::fromJSON(flatten=TRUE)
      
      c <- colnames(fg_df)
      c <- gsub("%", "_pct", c, fixed = TRUE)
      c <- gsub("/", "_", c, fixed = TRUE)
      c <- ifelse(substr(c, nchar(c) - 1 + 1, nchar(c)) == ".", gsub("\\.", "_pct", c), c)
      c <- gsub(" ", "_", c, fixed = TRUE)
      colnames(fg_df) <- c
      leaders <- fg_df %>% 
        dplyr::rename_with(~ gsub("pi", "pi_", .x), starts_with("pi")) %>% 
        dplyr::rename_with(~ gsub("pfx", "pfx_", .x), starts_with("pfx")) %>%
        dplyr::rename(any_of(lookup)) %>%
        dplyr::select(-dplyr::any_of(c(
          "Name", 
          "Team"
        ))) %>%
        dplyr::select(
          "Season",
          "team_name",
          "Throws", 
          "xMLBAMID", 
          "PlayerNameRoute",
          "PlayerName",
          "playerid",
          "Age",
          "AgeRng",
          tidyr::everything()) %>% 
        make_baseballr_data("MLB Player Pitching Leaders data from FanGraphs.com",Sys.time())
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no player pitching leaders data available!"))
    },
    finally = {
    }
  )
  return(leaders)
}

danny_batter_leaders <- function(
    age = "",
    pos = "all",
    stats = "bat",
    lg = "all",
    qual = "0",
    startseason = "2023",
    endseason = "2023",
    startdate = "",
    enddate = "",
    month = "0",
    hand = "",
    team = "0",
    pageitems = "10000",
    pagenum = "1",
    ind = "0",
    rost = "0",
    players = "",
    type = "8",
    postseason = "",
    sortdir = "default",
    sortstat = "WAR") {
  
  params <- list(
    age = age,
    pos = pos,
    stats = stats,
    lg = lg,
    qual = qual,
    season = startseason,
    season1 = endseason,
    startdate = startdate,
    enddate = enddate,
    month = month,
    hand = hand,
    team = team,
    pageitems = pageitems,
    pagenum = pagenum,
    ind = ind,
    rost = rost,
    players = players,
    type = type,
    postseason = postseason,
    sortdir = sortdir,
    sortstat = sortstat
  )
  
  url <- "https://www.fangraphs.com/api/leaders/major-league/data"
  
  fg_endpoint <- httr::modify_url(url, query = params)
  
  lookup <- c(
    "wRC_plus" = "wRC+",
    "WPA_minus" = "-WPA",
    "WPA_plus" = "+WPA", 
    "AgeRng" = "AgeR",
    "team_name" = "TeamName",
    "team_name_abb" = "TeamNameAbb")
  
  tryCatch(
    expr = {
      
      resp <- fg_endpoint %>% 
        mlb_api_call()
      
      fg_df <- resp$data %>% 
        jsonlite::toJSON() %>%
        jsonlite::fromJSON(flatten=TRUE)
      
      c <- colnames(fg_df)
      c <- gsub("%", "_pct", c, fixed = TRUE)
      c <- gsub("/", "_", c, fixed = TRUE)
      c <- ifelse(substr(c, nchar(c) - 1 + 1, nchar(c)) == ".", gsub("\\.", "_pct", c), c)
      c <- gsub(" ", "_", c, fixed = TRUE)
      colnames(fg_df) <- c
      leaders <- fg_df %>% 
        dplyr::rename_with(~ gsub("pi", "pi_", .x), starts_with("pi")) %>% 
        dplyr::rename_with(~ gsub("pfx", "pfx_", .x), starts_with("pfx")) %>%
        dplyr::rename(any_of(lookup)) %>%
        dplyr::select(-dplyr::any_of(c(
          "Name", 
          "Team"
        ))) %>%
        dplyr::select(
          "Season",
          "team_name",
          "Bats", 
          "xMLBAMID", 
          "PlayerNameRoute",
          "PlayerName",
          "playerid",
          "Age",
          "AgeRng",
          tidyr::everything()) %>% 
        make_baseballr_data("MLB Player Batting Leaders data from FanGraphs.com",Sys.time())
      
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no player batting leaders data available!"))
    },
    finally = {
    }
  )
  return(leaders)
}

danny_fielder_leaders <- function(
    age = "",
    pos = "all",
    stats = "fld",
    lg = "all",
    qual = "0",
    startseason = "2023",
    endseason = "2023",
    startdate = "",
    enddate = "",
    month = "0",
    hand = "",
    team = "0",
    pageitems = "10000",
    pagenum = "1",
    ind = "0",
    rost = "0",
    players = "",
    type = "1",
    postseason = "",
    sortdir = "default",
    sortstat = "Defense") {
  
  params <- list(
    age = age,
    pos = pos,
    stats = stats,
    lg = lg,
    qual = qual,
    season = startseason,
    season1 = endseason,
    startdate = startdate,
    enddate = enddate,
    month = month,
    hand = hand,
    team = team,
    pageitems = pageitems,
    pagenum = pagenum,
    ind = ind,
    rost = rost,
    players = players,
    type = type,
    postseason = postseason,
    sortdir = sortdir,
    sortstat = sortstat
  )
  
  url <- "https://www.fangraphs.com/api/leaders/major-league/data"
  
  fg_endpoint <- httr::modify_url(url, query = params)
  
  tryCatch(
    expr = {
      
      resp <- fg_endpoint %>% 
        mlb_api_call()
      
      fg_df <- resp$data %>% 
        jsonlite::toJSON() %>%
        jsonlite::fromJSON(flatten=TRUE)
      
      c <- colnames(fg_df)
      c <- gsub("%", "_pct", c, fixed = TRUE)
      c <- gsub("/", "_", c, fixed = TRUE)
      c <- ifelse(substr(c, nchar(c) - 1 + 1, nchar(c)) == ".", gsub("\\.", "_pct", c), c)
      c <- gsub(" ", "_", c, fixed = TRUE)
      colnames(fg_df) <- c
      leaders <- fg_df %>% 
        dplyr::rename_with(~ gsub("pi", "pi_", .x), starts_with("pi")) %>% 
        dplyr::rename_with(~ gsub("pfx", "pfx_", .x), starts_with("pfx")) %>%
        dplyr::rename(
          "team_name" = "TeamName",
          "team_name_abb" = "TeamNameAbb") %>%
        dplyr::select(-dplyr::any_of(c(
          "Name", 
          "Team"
        ))) %>%
        dplyr::select(
          "Season",
          "team_name",
          "xMLBAMID", 
          "PlayerNameRoute",
          "PlayerName",
          "playerid",
          tidyr::everything()) %>% 
        make_baseballr_data("MLB Player Fielding data from FanGraphs.com",Sys.time())
      
    },
    error = function(e) {
      message(glue::glue("{Sys.time()}: Invalid arguments or no fielding leaders data available!"))
    },
    finally = {
    }
  )
  return(leaders)
}

# ============================================================================
# PULL FANGRAPHS DATA (ALL YEARS)
# ============================================================================

cat("Fetching FanGraphs data", START_YEAR, "-", END_YEAR, "\n")

# Pull all FanGraphs data
all_batting <- data.frame()
all_pitching <- data.frame()
all_fielding <- data.frame()
pitching_leaders <- (danny_pitcher_leaders(startseason = 1900, endseason = 1900))
batting_leaders <- (danny_batter_leaders(startseason = 1900, endseason = 1900))
fielding_leaders <- (danny_batter_leaders(startseason = 1900, endseason = 1900))

for (year in START_YEAR:END_YEAR) {
  cat("Getting data for", year, "\n")
  
  # Batting data
  tryCatch({
    batting_data <- danny_batter_leaders(
      startseason = year, 
      endseason = year,
      qual = 0
    )
    if (nrow(batting_data) > 0) {
      all_batting <- rbind(all_batting, batting_data, fill = TRUE)
    }
  }, error = function(e) {
    cat("Batting error for", year, ":", e$message, "\n")
  })

  Sys.sleep(1) # Rate limiting
  
  # Pitching data
  tryCatch({
    pitching_data <- danny_pitcher_leaders(
      startseason = year,
      endseason = year, 
      qual = 0
    )
    if (nrow(pitching_data) > 0) {
      all_pitching <- rbind(all_pitching, pitching_data, fill = TRUE)
    }
  }, error = function(e) {
    cat("Pitching error for", year, ":", e$message, "\n")
  })

  Sys.sleep(1) # Rate limiting
  
  # Fielding data
  tryCatch({
    fielding_data <- danny_fielder_leaders(
      startseason = year,
      endseason = year,
      qual = 0
    )
    if (nrow(fielding_data) > 0) {
      all_fielding <- rbind(all_fielding, fielding_data, fill = TRUE)
    }
  }, error = function(e) {
    cat("Fielding error for", year, ":", e$message, "\n")
  })
  
  Sys.sleep(1) # Rate limiting
}

cat("Retrieved", nrow(all_batting), "batting seasons\n")
cat("Retrieved", nrow(all_pitching), "pitching seasons\n")
cat("Retrieved", nrow(all_fielding), "fielding seasons\n")

# ============================================================================
# DATA CLEANING
# ============================================================================

cat("Cleaning FanGraphs data...\n")

cat("Batting Columns:\n", colnames(all_batting))
cat("Pitching Columns:\n", colnames(all_pitching))
cat("Fielding Columns:\n", colnames(all_fielding))

batting_renamed <- all_batting
pitching_renamed <- all_pitching
fielding_renamed <- all_fielding

# Clean batting data
if (nrow(batting_renamed) > 0) {
  # CamelCase to snake_case
  names(batting_renamed) <- gsub("([a-z])([A-Z])", "\\1_\\2", names(batting_renamed))
  # Convert to lowercase
  names(batting_renamed) <- tolower(names(batting_renamed))
  # Replace + with _plus
  names(batting_renamed) <- gsub("\\+", "_plus_", names(batting_renamed))
  # Replace % with _pct
  names(batting_renamed) <- gsub("\\%", "_pct", names(batting_renamed))
  # Replace - with _
  names(batting_renamed) <- gsub("-", "_", names(batting_renamed))
  # Replace special characters with _
  names(batting_renamed) <- gsub("[^a-z0-9_]", "_", names(batting_renamed))
  # Remove multiple underscores
  names(batting_renamed) <- gsub("_+", "_", names(batting_renamed))
  # Remove trailing underscores
  names(batting_renamed) <- gsub("_$", "", names(batting_renamed))
  # Handle columns starting with numbers
  names(batting_renamed) <- ifelse(grepl("^1b$", names(batting_renamed)), "singles", names(batting_renamed))
  names(batting_renamed) <- ifelse(grepl("^2b$", names(batting_renamed)), "doubles", names(batting_renamed))
  names(batting_renamed) <- ifelse(grepl("^3b$", names(batting_renamed)), "triples", names(batting_renamed))
  # Handle PostgreSQL reserved words
  names(batting_renamed) <- ifelse(names(batting_renamed) == "pos", "pos_num", names(batting_renamed))
  names(batting_renamed) <- ifelse(names(batting_renamed) == "position", "pos", names(batting_renamed))
  names(batting_renamed) <- ifelse(names(batting_renamed) == "avg", "batting_avg", names(batting_renamed))
}
# Round all plus stats to integers
plus_cols <- grep("_plus$", names(batting_renamed), value = TRUE)
for(col in plus_cols) {
  batting_renamed[[col]] <- round(batting_renamed[[col]])
}

# Clean pitching data
if (nrow(pitching_renamed) > 0) {
  # CamelCase to snake_case
  names(pitching_renamed) <- gsub("([a-z])([A-Z])", "\\1_\\2", names(pitching_renamed))
  # Convert to lowercase
  names(pitching_renamed) <- tolower(names(pitching_renamed))
  # Replace + with _plus
  names(pitching_renamed) <- gsub("\\+", "_plus_", names(pitching_renamed))
  # Replace trailing - with _minus
  names(pitching_renamed) <- gsub("\\-$", "_minus", names(pitching_renamed))
  # Replace % with _pct
  names(pitching_renamed) <- gsub("\\%", "_pct", names(pitching_renamed))
  # Replace - with _
  names(pitching_renamed) <- gsub("-", "_", names(pitching_renamed))
  # Replace special characters with _
  names(pitching_renamed) <- gsub("[^a-z0-9_]", "_", names(pitching_renamed))
  # Remove multiple underscores
  names(pitching_renamed) <- gsub("_+", "_", names(pitching_renamed))
  # Remove trailing underscores
  names(pitching_renamed) <- gsub("_$", "", names(pitching_renamed))
  # Handle PostgreSQL reserved words
  names(pitching_renamed) <- ifelse(names(pitching_renamed) == "pos", "pos_num", names(pitching_renamed))
  names(pitching_renamed) <- ifelse(names(pitching_renamed) == "position", "pos", names(pitching_renamed))
  names(pitching_renamed) <- ifelse(names(pitching_renamed) == "avg", "batting_avg", names(pitching_renamed))
  # Replace K-BB_pct (which was converted to not have minus) to k_minus_bb_pct
  names(pitching_renamed) <- ifelse(names(pitching_renamed) == "k_bb_pct", "k_minus_bb_pct", names(pitching_renamed))
}
# Round all plus/minus stats to integers
plus_minus_cols <- grep("_(plus|minus)$", names(pitching_renamed), value = TRUE)
for(col in plus_minus_cols) {
  pitching_renamed[[col]] <- round(pitching_renamed[[col]])
}

# Clean fielding data
if (nrow(fielding_renamed) > 0) {
  # CamelCase to snake_case
  names(fielding_renamed) <- gsub("([a-z])([A-Z])", "\\1_\\2", names(fielding_renamed))
  # Convert to lowercase
  names(fielding_renamed) <- tolower(names(fielding_renamed))
  # Replace + with _plus
  names(fielding_renamed) <- gsub("\\+", "_plus_", names(fielding_renamed))
  # Replace trailing - with _minus
  names(fielding_renamed) <- gsub("\\-$", "_minus", names(fielding_renamed))
  # Replace % with _pct
  names(fielding_renamed) <- gsub("\\%", "_pct", names(fielding_renamed))
  # Replace - with _
  names(fielding_renamed) <- gsub("-", "_", names(fielding_renamed))
  # Replace special characters with _
  names(fielding_renamed) <- gsub("[^a-z0-9_]", "_", names(fielding_renamed))
  # Remove multiple underscores
  names(fielding_renamed) <- gsub("_+", "_", names(fielding_renamed))
  # Remove trailing underscores
  names(fielding_renamed) <- gsub("_$", "", names(fielding_renamed))
}

# ============================================================================
# WRITE TO DATABASE
# ============================================================================

# Write batting data
if (nrow(batting_renamed) > 0) {
  cat("Writing to fg_batting_leaders table...\n")
  dbExecute(con, "TRUNCATE TABLE fg_batting_leaders")
  
  chunk_size <- 5000
  total_rows <- nrow(batting_renamed)
  
  for (i in seq(1, total_rows, chunk_size)) {
    end_idx <- min(i + chunk_size - 1, total_rows)
    chunk <- batting_renamed[i:end_idx, ]
    dbWriteTable(con, "fg_batting_leaders", chunk, append = TRUE, row.names = FALSE)
    cat("Batting: Wrote rows", i, "to", end_idx, "\n")
  }
}

# Write pitching data
if (nrow(pitching_renamed) > 0) {
  cat("Writing to fg_pitching_leaders table...\n")
  dbExecute(con, "TRUNCATE TABLE fg_pitching_leaders")
  
  chunk_size <- 5000
  total_rows <- nrow(pitching_renamed)
  
  for (i in seq(1, total_rows, chunk_size)) {
    end_idx <- min(i + chunk_size - 1, total_rows)
    chunk <- pitching_renamed[i:end_idx, ]
    dbWriteTable(con, "fg_pitching_leaders", chunk, append = TRUE, row.names = FALSE)
    cat("Pitching: Wrote rows", i, "to", end_idx, "\n")
  }
}

# Write fielding data
if (nrow(fielding_renamed) > 0) {
  cat("Writing to fg_fielding_leaders table...\n")
  dbExecute(con, "TRUNCATE TABLE fg_fielding_leaders")
  
  chunk_size <- 5000
  total_rows <- nrow(fielding_renamed)
  
  for (i in seq(1, total_rows, chunk_size)) {
    end_idx <- min(i + chunk_size - 1, total_rows)
    chunk <- fielding_renamed[i:end_idx, ]
    dbWriteTable(con, "fg_fielding_leaders", chunk, append = TRUE, row.names = FALSE)
    cat("Fielding: Wrote rows", i, "to", end_idx, "\n")
  }
}

# ============================================================================
# VERIFICATION
# ============================================================================

cat("Verification:\n")

# Batting verification
batting_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM fg_batting_leaders")
cat("Batting rows:", batting_count$count, "\n")

# Pitching verification
pitching_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM fg_pitching_leaders")
cat("Pitching rows:", pitching_count$count, "\n")

# Fielding verification
fielding_count <- dbGetQuery(con, "SELECT COUNT(*) as count FROM fg_fielding_leaders")
cat("Fielding rows:", fielding_count$count, "\n")

# Year ranges
if (batting_count$count > 0) {
  year_range <- dbGetQuery(con, "SELECT MIN(season) as min_year, MAX(season) as max_year FROM fg_batting_leaders")
  cat("Batting year range:", year_range$min_year, "-", year_range$max_year, "\n")
  
  top_war <- dbGetQuery(con, "SELECT player_name, season, war FROM fg_batting_leaders ORDER BY war DESC LIMIT 5")
  cat("Top 5 batting WAR seasons:\n")
  print(top_war)
}

dbDisconnect(con)
cat("FanGraphs ETL complete!\n")
cat("Imported:", nrow(all_batting), "batting,", nrow(all_pitching), "pitching,", nrow(all_fielding), "fielding records\n")