# ETL Improvements - Critical Fixes

# 1. Incremental updates instead of full reload
get_missing_years <- function(con, table_name) {
  existing_years <- dbGetQuery(con, paste("SELECT DISTINCT season FROM", table_name))$season
  all_years <- 1988:2025  # Reasonable range
  setdiff(all_years, existing_years)
}

# 2. Batch API calls by decade to reduce requests
get_decade_data <- function(start_year, end_year, data_type = "bat") {
  danny_batter_leaders(
    startseason = start_year,
    endseason = end_year,
    qual = 0
  )
}

# 3. Upsert instead of truncate
upsert_fangraphs_data <- function(con, table_name, data, key_cols) {
  temp_table <- paste0("temp_", table_name)
  dbWriteTable(con, temp_table, data, temporary = TRUE, overwrite = TRUE)
  
  # Use ON CONFLICT for upsert
  sql <- sprintf("
    INSERT INTO %s SELECT * FROM %s 
    ON CONFLICT (%s) DO UPDATE SET 
    war = EXCLUDED.war, updated_at = CURRENT_TIMESTAMP
  ", table_name, temp_table, paste(key_cols, collapse = ", "))
  
  dbExecute(con, sql)
}

# 4. Data validation
validate_fangraphs_data <- function(data) {
  required_cols <- c("season", "playerid", "player_name")
  missing_cols <- setdiff(required_cols, names(data))
  
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Check for reasonable data ranges
  if (any(data$season < 1871 | data$season > 2030, na.rm = TRUE)) {
    warning("Suspicious season values found")
  }
  
  return(TRUE)
}