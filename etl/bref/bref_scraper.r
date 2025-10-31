# Baseball Reference Web Scraper
# Respects robots.txt (3-second crawl delay)
# Extracts biographical info and standard batting stats

library(rvest)
library(polite)
library(httr)
library(dplyr)
library(stringr)
library(logger)
library(glue)

# Setup polite session (respects robots.txt)
session <- bow(
  url = "https://www.baseball-reference.com/",
  user_agent = "Baseball RAG Research Bot (daniel.bussone@example.com)",
  delay = 3  # 3-second delay per robots.txt
)

# Extract biographical information
extract_biography <- function(page) {
  tryCatch({
    meta_section <- page %>% html_element("#meta")
    
    # Full name
    full_name <- meta_section %>% 
      html_element("h1") %>% 
      html_text2() %>%
      str_trim()
    
    # Birth information
    birth_info <- meta_section %>%
      html_elements("p") %>%
      html_text2() %>%
      str_subset("Born:") %>%
      first()
    
    birth_date <- NULL
    birth_city <- NULL
    birth_state <- NULL
    birth_country <- NULL
    
    if (!is.na(birth_info) && length(birth_info) > 0) {
      # Parse birth date (format: "Born: August 7, 1991 in Vineland, NJ")
      date_match <- str_extract(birth_info, "Born:\\s*([^\\s]+\\s+\\d+,\\s+\\d{4})")
      if (!is.na(date_match)) {
        birth_date <- str_remove(date_match, "Born:\\s*") %>% str_trim()
      }
      
      # Parse birth location
      location_match <- str_extract(birth_info, "in\\s+(.+)$")
      if (!is.na(location_match)) {
        location <- str_remove(location_match, "in\\s+") %>% str_trim()
        location_parts <- str_split(location, ",")[[1]] %>% str_trim()
        
        if (length(location_parts) >= 2) {
          birth_city <- location_parts[1]
          # Handle US states vs countries
          if (str_length(location_parts[2]) == 2) {
            birth_state <- location_parts[2]
            birth_country <- "USA"
          } else {
            birth_country <- location_parts[2]
          }
        }
      }
    }
    
    # Physical stats
    height <- NULL
    weight <- NULL
    bats <- NULL
    throws <- NULL
    
    physical_info <- meta_section %>%
      html_elements("p") %>%
      html_text2() %>%
      str_subset("(ft|lbs|Bats:|Throws:)")
    
    for (info in physical_info) {
      # Height (e.g., "6-2, 235lb")
      height_match <- str_extract(info, "\\d+-\\d+")
      if (!is.na(height_match)) height <- height_match
      
      # Weight
      weight_match <- str_extract(info, "(\\d+)lb")
      if (!is.na(weight_match)) weight <- as.numeric(str_extract(weight_match, "\\d+"))
      
      # Bats/Throws
      if (str_detect(info, "Bats:")) {
        bats <- str_extract(info, "Bats:\\s*([LRS])") %>% str_extract("[LRS]")
      }
      if (str_detect(info, "Throws:")) {
        throws <- str_extract(info, "Throws:\\s*([LR])") %>% str_extract("[LR]")
      }
    }
    
    # Draft information
    draft_year <- NULL
    draft_round <- NULL
    draft_pick <- NULL
    draft_team <- NULL
    
    draft_info <- meta_section %>%
      html_elements("p") %>%
      html_text2() %>%
      str_subset("Draft") %>%
      first()
    
    if (!is.na(draft_info) && length(draft_info) > 0) {
      # Parse draft info (format varies)
      year_match <- str_extract(draft_info, "\\b(19|20)\\d{2}\\b")
      if (!is.na(year_match)) draft_year <- as.numeric(year_match)
      
      round_match <- str_extract(draft_info, "Round\\s+(\\d+)")
      if (!is.na(round_match)) draft_round <- as.numeric(str_extract(round_match, "\\d+"))
      
      pick_match <- str_extract(draft_info, "Pick\\s+(\\d+)")
      if (!is.na(pick_match)) draft_pick <- as.numeric(str_extract(pick_match, "\\d+"))
    }
    
    # Career dates
    debut_date <- NULL
    final_date <- NULL
    
    career_info <- meta_section %>%
      html_elements("p") %>%
      html_text2() %>%
      str_subset("(Debut|Last Game)")
    
    for (info in career_info) {
      if (str_detect(info, "Debut")) {
        debut_match <- str_extract(info, "Debut:\\s*([^\\(]+)")
        if (!is.na(debut_match)) {
          debut_date <- str_remove(debut_match, "Debut:\\s*") %>% str_trim()
        }
      }
      if (str_detect(info, "Last Game")) {
        final_match <- str_extract(info, "Last Game:\\s*([^\\(]+)")
        if (!is.na(final_match)) {
          final_date <- str_remove(final_match, "Last Game:\\s*") %>% str_trim()
        }
      }
    }
    
    return(data.frame(
      full_name = full_name %||% NA,
      birth_date = birth_date %||% NA,
      birth_city = birth_city %||% NA,
      birth_state = birth_state %||% NA,
      birth_country = birth_country %||% NA,
      height = height %||% NA,
      weight = weight %||% NA,
      bats = bats %||% NA,
      throws = throws %||% NA,
      draft_year = draft_year %||% NA,
      draft_round = draft_round %||% NA,
      draft_pick = draft_pick %||% NA,
      debut_date = debut_date %||% NA,
      final_date = final_date %||% NA,
      stringsAsFactors = FALSE
    ))
  }, error = function(e) {
    log_error("Error extracting biography: {e$message}")
    return(data.frame(
      full_name = NA, birth_date = NA, birth_city = NA, birth_state = NA,
      birth_country = NA, height = NA, weight = NA, bats = NA, throws = NA,
      draft_year = NA, draft_round = NA, draft_pick = NA,
      debut_date = NA, final_date = NA,
      stringsAsFactors = FALSE
    ))
  })
}

# Extract standard batting stats table
extract_batting_stats <- function(page) {
  tryCatch({
    # Find the standard batting table
    batting_table <- page %>% html_element("#batting_standard")
    
    if (is.na(batting_table)) {
      log_warn("No batting table found")
      return(data.frame())
    }
    
    # Extract table headers
    headers <- batting_table %>%
      html_elements("thead th") %>%
      html_text2() %>%
      str_trim()
    
    # Extract table rows
    rows <- batting_table %>%
      html_elements("tbody tr")
    
    # Process each row
    stats_list <- list()
    
    for (i in seq_along(rows)) {
      row <- rows[[i]]
      
      # Skip if it's a header row or total row
      row_class <- html_attr(row, "class")
      if (!is.na(row_class) && str_detect(row_class, "thead|partial_table")) {
        next
      }
      
      # Extract cell values
      cells <- row %>%
        html_elements("td, th") %>%
        html_text2() %>%
        str_trim()
      
      if (length(cells) > 0 && length(cells) == length(headers)) {
        # Create named list for this row
        row_data <- setNames(cells, headers)
        
        # Convert numeric columns
        numeric_cols <- c("Age", "G", "PA", "AB", "R", "H", "2B", "3B", "HR", 
                         "RBI", "SB", "CS", "BB", "SO", "BA", "OBP", "SLG", 
                         "OPS", "OPS+", "TB", "GDP", "HBP", "SH", "SF", "IBB")
        
        for (col in numeric_cols) {
          if (col %in% names(row_data)) {
            val <- row_data[[col]]
            if (val != "" && !is.na(val)) {
              row_data[[col]] <- as.numeric(val)
            } else {
              row_data[[col]] <- NA
            }
          }
        }
        
        stats_list[[i]] <- row_data
      }
    }
    
    if (length(stats_list) > 0) {
      # Combine into dataframe
      stats_df <- bind_rows(stats_list)
      return(stats_df)
    } else {
      return(data.frame())
    }
    
  }, error = function(e) {
    log_error("Error extracting batting stats: {e$message}")
    return(data.frame())
  })
}

# Scrape single player
scrape_player <- function(player_id) {
  log_info("Scraping player: {player_id}")
  
  # Construct URL
  first_letter <- str_sub(player_id, 1, 1)
  url <- glue("players/{first_letter}/{player_id}.shtml")
  log_info("Player URL: {url}")
  
  # Scrape with polite
  page <- scrape(session, url)
  
  if (is.null(page)) {
    log_error("Failed to scrape {url}")
    return(list(bio = data.frame(), stats = data.frame()))
  }
  
  # Extract data
  bio_data <- extract_biography(page)
  bio_data$player_id <- player_id
  
  stats_data <- extract_batting_stats(page)
  if (nrow(stats_data) > 0) {
    stats_data$player_id <- player_id
  }
  
  log_info("Successfully scraped {player_id}")
  
  return(list(
    bio = bio_data,
    stats = stats_data
  ))
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || is.na(x)) y else x

# Test with a few players
test_players <- c("troutmi01", "judgeaa01", "bettsmo01", "ramirjo01")

log_info("Starting Baseball Reference scraping test")

# Initialize result lists
all_bio_data <- list()
all_stats_data <- list()

# Scrape test players
for (player_id in test_players) {
  result <- scrape_player(player_id)
  
  if (nrow(result$bio) > 0) {
    all_bio_data[[player_id]] <- result$bio
  }
  
  if (nrow(result$stats) > 0) {
    all_stats_data[[player_id]] <- result$stats
  }
  
  # Respectful delay (already handled by polite, but being extra careful)
  Sys.sleep(1)
}

# Combine results into dataframes
if (length(all_bio_data) > 0) {
  bio_df <- bind_rows(all_bio_data)
  log_info("Created bio dataframe with {nrow(bio_df)} rows")
  print("Bio Data Structure:")
  print(str(bio_df))
  print("Sample Bio Data:")
  print(head(bio_df))
}

if (length(all_stats_data) > 0) {
  stats_df <- bind_rows(all_stats_data)
  log_info("Created stats dataframe with {nrow(stats_df)} rows")
  print("Stats Data Structure:")
  print(str(stats_df))
  print("Sample Stats Data:")
  print(head(stats_df))
}

log_info("Scraping test completed")