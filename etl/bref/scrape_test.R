library(polite)
library(rvest)
library(dplyr)

# 1. BOW to the website
url <- "https://www.baseball-reference.com"

session <- bow(
  url = url,
  user_agent = "Baseball stats research - danielbussone@gmail.com"
)

# Check if we're allowed to scrape
print(session)

# 2. SCRAPE the page
player_page <- polite::nod(session, path = "/players/t/troutmi01.shtml")
page <- polite::scrape(player_page)

# 3. EXTRACT data using rvest functions
# Get player name
player_name <- page %>%
  html_node("h1[itemprop='name']") %>%
  html_text(trim = TRUE)

cat("Player:", player_name, "\n\n")

player_bio <- polite::nod(session, path = "/bullpen/Mike_Trout")
bio_page <- polite::scrape(player_bio)

# Use nod() to navigate to the 2024 New York Yankees page
yankees_2024_session <- polite::nod(session, "teams/NYY/2024.shtml")

# Scrape the page content
yankees_2024_page <- polite::scrape(yankees_2024_session)

# Find and extract the table with team statistics using rvest
yankees_stats_table <- yankees_2024_page %>%
  html_element("#teams_standard_batting") %>% # Use the correct HTML ID or CSS selector
  html_table()

# View the extracted data
print(yankees_stats_table)
