# 🎯 Baseball Reference Web Scraping - TODO List

**Project Phase:** 2.1 - Baseball Reference Integration  
**Estimated Duration:** 4 weeks  
**Status:** Not Started  
**Last Updated:** October 25, 2025

---

## 📋 Overview

This TODO list guides the implementation of web scraping for Baseball Reference to add biographical data, career narratives, and awards to the Baseball RAG system.

**Goals:**
- Extract player biographical information (birth date/place, draft info, physical stats)
- Capture career narratives and context
- Collect awards and honors (MVP, All-Star, Gold Glove, etc.)
- Integrate with existing FanGraphs data and embedding system
- Respect robots.txt and scrape responsibly

**Key Constraints:**
- Must respect 3-second crawl delay (robots.txt requirement)
- Target `/players/` pages only (clearly allowed)
- Avoid `/bullpen/`, `/play-index/`, search tools (disallowed)
- Use R for consistency with existing ETL pipeline

---

## 📅 Week 1: Research & Prototype

### Day 1-2: Manual Exploration & Documentation

#### 🔍 Explore Player Pages
- [ ] Visit 10 diverse player pages:
  - [ ] **Recent stars:** Mike Trout, Shohei Ohtani, Aaron Judge, Mookie Betts
  - [ ] **Retired legends:** Ken Griffey Jr, Barry Bonds, Derek Jeter, Cal Ripken Jr
  - [ ] **Different eras:** 1980s (Ripken), 1990s (Bonds), 2000s (Jeter), 2010s (Trout), 2020s (Ohtani)
  - [ ] **Edge cases:** Players with no awards, short careers, multiple teams

#### 📝 Document URL Patterns
- [ ] Confirm URL structure: `https://www.baseball-reference.com/players/{first_letter}/{playerid}.shtml`
- [ ] Examples:
  - [ ] Mike Trout: `/players/t/troutmi01.shtml`
  - [ ] Shohei Ohtani: `/players/o/ohtansh01.shtml`
  - [ ] Ken Griffey Jr: `/players/g/griffke02.shtml`
- [ ] Note ID format: `{last5}{first2}{number}`
- [ ] Document numbering for duplicate names (01, 02, 03)

#### 🎨 Inspect HTML Structure
- [ ] Right-click → Inspect Element on each page
- [ ] Identify key sections and their selectors:
  - [ ] Biographical header: ID/class (likely `#meta` or `#info`)
  - [ ] Name and vital stats: selectors
  - [ ] Birth information: location in DOM
  - [ ] Draft information: section/paragraph
  - [ ] Career dates: debut/final game
  - [ ] Awards section: list structure
  - [ ] Career summary/narrative: paragraph location
  - [ ] Physical stats: height, weight, bats/throws
- [ ] Check for JavaScript-rendered content:
  - [ ] Open browser console
  - [ ] Disable JavaScript, reload page
  - [ ] Verify data still visible (should be static HTML)
- [ ] Note any era-specific differences:
  - [ ] Do 1980s players have different HTML structure?
  - [ ] Is Statcast era (2015+) data formatted differently?

#### 📄 Create Documentation
- [ ] Create file: `bref_html_structure.md`
- [ ] Document CSS selectors for each data point:
  ```markdown
  ## Player Name
  - Selector: `#meta h1`
  - Example: "Mike Trout"
  
  ## Birth Date
  - Selector: `#meta p:contains("Born") strong:contains("Born:") ~ text`
  - Example: "August 7, 1991"
  
  ## Awards
  - Selector: `#content p:contains("All-Star")`
  - Format: List or inline text
  ```
- [ ] Include screenshots of key HTML sections
- [ ] Note any inconsistencies or edge cases
- [ ] List fields that may be missing (e.g., draft info for pre-draft era players)

---

### Day 3: Legal & Ethical Review

#### 📜 Review robots.txt
- [ ] Re-read: `https://www.baseball-reference.com/robots.txt`
- [ ] Confirm findings:
  - [ ] ✅ `/players/` pages are allowed (not in Disallow list)
  - [ ] ✅ `Crawl-delay: 3` is required
  - [ ] ❌ `/bullpen/` is restricted (Teoma bot)
  - [ ] ❌ `/play-index/` is disallowed
  - [ ] ❌ `/player_search.cgi` is disallowed
  - [ ] ❌ `/friv/compare.cgi` is disallowed
- [ ] Document in project notes

#### 📋 Review Terms of Service
- [ ] Read Baseball Reference ToS: `https://www.sports-reference.com/termsofuse.html`
- [ ] Key points to check:
  - [ ] Any explicit scraping prohibitions?
  - [ ] Attribution requirements?
  - [ ] Commercial use restrictions?
  - [ ] Data ownership clauses?
- [ ] Document any relevant restrictions
- [ ] Save copy of ToS for reference (dated)

#### 🤝 Plan Respectful Scraping
- [ ] Design scraping approach:
  - [ ] 3-second minimum delay between requests (robots.txt)
  - [ ] Consider 5-second delay to be extra respectful
  - [ ] User-Agent with project name and contact email
  - [ ] Retry logic with exponential backoff for errors
  - [ ] Cache responses to avoid re-scraping
- [ ] Error handling strategy:
  - [ ] 429 (Too Many Requests): Back off, increase delay
  - [ ] 404 (Not Found): Log but don't retry (player doesn't exist)
  - [ ] 500s (Server Error): Retry with backoff, max 5 attempts
  - [ ] Network timeouts: Retry with backoff
- [ ] Monitoring plan:
  - [ ] Log all requests with timestamps
  - [ ] Track success/failure rates
  - [ ] Alert if failure rate >10%
  - [ ] Monitor for any 429 responses (indicates too aggressive)

---

### Day 4-5: Build Single-Player Prototype

#### 🔧 Setup Development Environment
- [ ] Create new R script: `bref_scraper_prototype.r`
- [ ] Install required packages:
  ```r
  install.packages(c(
    "rvest",      # HTML parsing
    "polite",     # Respectful scraping
    "httr",       # HTTP requests
    "glue",       # String interpolation
    "logger",     # Logging
    "dplyr",      # Data manipulation
    "stringr",    # String operations
    "jsonlite"    # JSON handling for awards
  ))
  ```
- [ ] Load libraries and test imports

#### 🌐 Set Up Polite Session
- [ ] Create polite session:
  ```r
  library(polite)
  
  session <- bow(
    url = "https://www.baseball-reference.com/",
    user_agent = "Baseball RAG Research Bot (your.email@example.com)",
    delay = 3  # 3-second delay per robots.txt
  )
  ```
- [ ] Test session creation
- [ ] Verify `session$robotstxt` shows allowed paths
- [ ] Confirm delay is set correctly

#### 🔨 Build Core Extraction Functions

##### Function 1: Extract Biography
- [ ] Create `extract_biography(page)`:
  ```r
  extract_biography <- function(page) {
    bio_section <- page %>% html_element("#meta")
    
    # Extract individual fields
    full_name <- bio_section %>% html_element("h1") %>% html_text2()
    
    # Birth date (handle various formats)
    birth_text <- bio_section %>% 
      html_elements("p") %>%
      html_text2() %>%
      str_subset("Born:")
    
    # Parse birth date, city, state, country
    # ... parsing logic
    
    return(list(
      full_name = full_name,
      birth_date = birth_date,
      birth_city = birth_city,
      birth_state = birth_state,
      birth_country = birth_country
    ))
  }
  ```
- [ ] Test with Mike Trout
- [ ] Handle missing fields gracefully (return NULL)
- [ ] Add error handling (tryCatch)

##### Function 2: Extract Physical Stats
- [ ] Create `extract_physical_stats(page)`:
  ```r
  extract_physical_stats <- function(page) {
    # Height, weight, bats, throws
    # Parse from meta section
    # Return list
  }
  ```
- [ ] Test extraction
- [ ] Handle various formats (6-2, 6'2", 6 ft 2 in)

##### Function 3: Extract Draft Info
- [ ] Create `extract_draft_info(page)`:
  ```r
  extract_draft_info <- function(page) {
    # Draft year, round, pick, team
    # Handle undrafted players (NULL)
    # Return list
  }
  ```
- [ ] Test with drafted player
- [ ] Test with undrafted player
- [ ] Test with pre-draft era player (before 1965)

##### Function 4: Extract Career Dates
- [ ] Create `extract_career_dates(page)`:
  ```r
  extract_career_dates <- function(page) {
    # Debut date, final game date
    # Parse date strings
    # Return list
  }
  ```
- [ ] Test extraction
- [ ] Handle active players (NULL final date)

##### Function 5: Extract Awards
- [ ] Create `extract_awards(page)`:
  ```r
  extract_awards <- function(page) {
    # Find awards section
    # Parse MVP, All-Star, Gold Glove, Silver Slugger, etc.
    # Extract years for each award
    # Return structured list (will convert to JSONB)
    
    # Example output:
    # [
    #   {award: "MVP", years: [2014, 2016, 2019]},
    #   {award: "All-Star", years: [2012, 2013, 2014, 2015, ...]},
    #   {award: "Silver Slugger", years: [2012, 2013, 2014]}
    # ]
  }
  ```
- [ ] Test with award-heavy player (Mike Trout, Barry Bonds)
- [ ] Test with player with no awards
- [ ] Handle various award name formats

##### Function 6: Extract Career Summary
- [ ] Create `extract_career_summary(page)`:
  ```r
  extract_career_summary <- function(page) {
    # Find introductory paragraph or career highlights
    # Extract narrative text (first 500-1000 characters)
    # Return text string
  }
  ```
- [ ] Test extraction
- [ ] Handle missing summaries

#### 🧪 Test Prototype with Multiple Players
- [ ] Test with Mike Trout (`troutmi01`)
  - [ ] Print all extracted data
  - [ ] Verify accuracy against website
  - [ ] Check data types (dates as Date, numbers as numeric)
- [ ] Test with 5 more diverse players:
  - [ ] Ken Griffey Jr (`griffke02`) - Retired, many awards
  - [ ] Shohei Ohtani (`ohtansh01`) - Active, recent awards
  - [ ] Cal Ripken Jr (`ripkeca01`) - 1980s player
  - [ ] Obscure player with minimal data
  - [ ] Recently debuted player (2023-2024)
- [ ] Document any failures or edge cases
- [ ] Refine extraction functions based on findings

#### 📊 Validate Prototype
- [ ] Run prototype on 20 random players
- [ ] Calculate success rate (% with all fields extracted)
- [ ] Identify systematic failures
- [ ] Document any HTML structure variations
- [ ] Decide on acceptable data completeness threshold (e.g., 80% of fields)

---

## 📅 Week 2: ID Mapping & Database Schema

### Day 1-2: Solve ID Mapping Problem

#### 🗺️ Understand Baseball Reference ID Format
- [ ] Research ID structure:
  - [ ] Pattern: `{last_name_5_chars}{first_name_2_chars}{number}`
  - [ ] Examples:
    - Mike Trout → `troutmi01`
    - Shohei Ohtani → `ohtansh01`
    - Ken Griffey Jr → `griffke02` (02 because Ken Griffey Sr exists)
- [ ] Document numbering rules:
  - [ ] 01 for first player with that name combo
  - [ ] 02, 03, etc. for duplicates
  - [ ] How are Jr/Sr handled?

#### 📊 Choose ID Mapping Strategy

**Option A: Chadwick Bureau Register (RECOMMENDED)**
- [ ] Download register: `https://github.com/chadwickbureau/register`
- [ ] Clone repo or download `people.csv`:
  ```bash
  wget https://raw.githubusercontent.com/chadwickbureau/register/master/data/people.csv
  ```
- [ ] Load into R:
  ```r
  chadwick <- read_csv("people.csv")
  ```
- [ ] Explore columns:
  - [ ] Identify FanGraphs ID column: `key_fangraphs`
  - [ ] Identify Baseball Reference ID column: `key_bbref`
  - [ ] Check for missing mappings
- [ ] Create mapping function:
  ```r
  get_bref_id <- function(fangraphs_id, chadwick) {
    match <- chadwick %>% 
      filter(key_fangraphs == fangraphs_id) %>%
      pull(key_bbref)
    
    if (length(match) == 0) return(NA)
    return(match[1])
  }
  ```
- [ ] Test mapping accuracy:
  - [ ] Map 100 known players
  - [ ] Manually verify 10 random mappings
  - [ ] Calculate success rate

**Option B: Algorithmic ID Generation (Fallback)**
- [ ] Create function to generate likely Baseball Reference ID:
  ```r
  generate_bref_id <- function(player_name) {
    # Split name
    parts <- str_split(player_name, " ")[[1]]
    last <- parts[length(parts)]
    first <- parts[1]
    
    # Take first 5 of last name, first 2 of first name
    bref_id <- paste0(
      str_sub(str_to_lower(last), 1, 5),
      str_sub(str_to_lower(first), 1, 2),
      "01"  # Assume 01, may need adjustment
    )
    
    return(bref_id)
  }
  ```
- [ ] Test with known players
- [ ] Note limitations (duplicate names)

**Option C: Hybrid Approach**
- [ ] Use Chadwick Bureau as primary source
- [ ] Fall back to algorithmic generation if not found
- [ ] Validate generated IDs by attempting to scrape page
- [ ] Manual review of uncertain mappings

#### 💾 Create ID Mapping Table in Database
- [ ] Add to schema:
  ```sql
  CREATE TABLE IF NOT EXISTS player_id_mapping (
    fangraphs_id INTEGER PRIMARY KEY REFERENCES fg_players(fangraphs_id),
    bref_id VARCHAR(20) UNIQUE,
    mapping_method VARCHAR(20), -- 'chadwick', 'generated', 'manual'
    confidence VARCHAR(10),      -- 'high', 'medium', 'low'
    verified BOOLEAN DEFAULT FALSE,
    mapped_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
  );
  
  CREATE INDEX idx_mapping_bref ON player_id_mapping(bref_id);
  CREATE INDEX idx_mapping_confidence ON player_id_mapping(confidence);
  ```
- [ ] Run schema update:
  ```bash
  psql -h localhost -U postgres -d postgres -f id_mapping_schema.sql
  ```

#### 🔨 Build ID Mapping Script
- [ ] Create script: `map_fangraphs_to_bref.r`
- [ ] Load all FanGraphs players from database
- [ ] Map each player to Baseball Reference ID
- [ ] Store in `player_id_mapping` table
- [ ] Log mapping statistics:
  - [ ] Total players
  - [ ] Successfully mapped (high confidence)
  - [ ] Generated IDs (medium confidence)
  - [ ] Failed mappings (low confidence / NULL)
- [ ] Export list of failed mappings for manual review

#### ✅ Validate Mappings
- [ ] Query sample of mappings:
  ```sql
  SELECT p.player_name, m.bref_id, m.confidence
  FROM fg_players p
  JOIN player_id_mapping m ON p.fangraphs_id = m.fangraphs_id
  ORDER BY RANDOM()
  LIMIT 50;
  ```
- [ ] Manually verify 20 random mappings against Baseball Reference
- [ ] Calculate mapping accuracy
- [ ] For low-confidence mappings:
  - [ ] Review manually
  - [ ] Correct errors
  - [ ] Update confidence level
  - [ ] Add notes

#### 📝 Document ID Mapping Process
- [ ] Success rate by method (Chadwick vs generated)
- [ ] Common failure modes
- [ ] List of manually corrected mappings
- [ ] Recommendations for future mappings

---

### Day 3: Create Database Schema

#### 🗄️ Design `bref_players` Table
- [ ] Create schema in `fangraphs_schema.sql`:
  ```sql
  -- ============================================================================
  -- BASEBALL REFERENCE PLAYERS TABLE
  -- ============================================================================
  -- Biographical and career information from Baseball Reference
  
  CREATE TABLE IF NOT EXISTS bref_players (
    bref_id VARCHAR(20) PRIMARY KEY,
    fangraphs_id INTEGER UNIQUE REFERENCES fg_players(fangraphs_id) ON DELETE CASCADE,
    
    -- Biographical Information
    full_name VARCHAR(255),
    nickname VARCHAR(255),
    birth_date DATE,
    birth_city VARCHAR(100),
    birth_state VARCHAR(50),
    birth_country VARCHAR(50),
    
    -- Physical Stats
    height_inches INTEGER,        -- Total height in inches
    weight_lbs INTEGER,
    bats VARCHAR(5),               -- L, R, S (may differ from FanGraphs)
    throws VARCHAR(5),             -- L, R
    
    -- Draft Information
    draft_year INTEGER,
    draft_round INTEGER,
    draft_pick INTEGER,            -- Overall pick number
    draft_team VARCHAR(100),
    
    -- Career Dates
    debut_date DATE,
    final_game_date DATE,          -- NULL for active players
    
    -- Narrative Content
    career_summary TEXT,           -- Introductory paragraph/highlights
    
    -- Awards (JSONB for flexibility)
    -- Structure: [{"award": "MVP", "years": [2014, 2016, 2019]}, ...]
    awards JSONB,
    
    -- Metadata
    scraped_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Data Quality Flags
    has_complete_bio BOOLEAN GENERATED ALWAYS AS (
      birth_date IS NOT NULL AND 
      birth_city IS NOT NULL AND 
      height_inches IS NOT NULL
    ) STORED,
    
    has_draft_info BOOLEAN GENERATED ALWAYS AS (
      draft_year IS NOT NULL
    ) STORED
  );
  
  COMMENT ON TABLE bref_players IS 'Player biographical data scraped from Baseball Reference';
  COMMENT ON COLUMN bref_players.bref_id IS 'Baseball Reference player ID (e.g., troutmi01)';
  COMMENT ON COLUMN bref_players.awards IS 'JSONB array of awards with years: [{"award": "MVP", "years": [2014, 2016]}]';
  COMMENT ON COLUMN bref_players.career_summary IS 'Narrative text from Baseball Reference player page';
  
  -- ============================================================================
  -- INDEXES
  -- ============================================================================
  
  CREATE INDEX idx_bref_players_fangraphs ON bref_players(fangraphs_id);
  CREATE INDEX idx_bref_players_debut ON bref_players(debut_date);
  CREATE INDEX idx_bref_players_birth_date ON bref_players(birth_date);
  CREATE INDEX idx_bref_players_draft_year ON bref_players(draft_year);
  CREATE INDEX idx_bref_players_scraped ON bref_players(scraped_at);
  
  -- GIN index for JSONB awards column (allows querying within awards)
  CREATE INDEX idx_bref_players_awards ON bref_players USING gin(awards);
  
  -- Partial indexes for data quality
  CREATE INDEX idx_bref_missing_bio ON bref_players(bref_id) 
    WHERE NOT has_complete_bio;
  CREATE INDEX idx_bref_missing_draft ON bref_players(bref_id) 
    WHERE NOT has_draft_info AND draft_year >= 1965;  -- Draft started 1965
  
  -- ============================================================================
  -- TRIGGER FOR updated_at
  -- ============================================================================
  
  CREATE TRIGGER update_bref_players_updated_at 
    BEFORE UPDATE ON bref_players
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
  
  -- ============================================================================
  -- VIEWS
  -- ============================================================================
  
  -- Combined player information (FanGraphs + Baseball Reference)
  CREATE OR REPLACE VIEW player_full_profile AS
  SELECT 
    p.fangraphs_id,
    p.player_name,
    p.bats AS fg_bats,
    p.first_season,
    p.last_season,
    bp.bref_id,
    bp.full_name,
    bp.nickname,
    bp.birth_date,
    bp.birth_city,
    bp.birth_state,
    bp.birth_country,
    bp.height_inches,
    bp.weight_lbs,
    bp.draft_year,
    bp.draft_round,
    bp.draft_pick,
    bp.draft_team,
    bp.debut_date,
    bp.final_game_date,
    bp.career_summary,
    bp.awards,
    bp.scraped_at AS bref_scraped_at,
    cs.total_war,
    cs.avg_wrc_plus,
    cs.peak_war
  FROM fg_players p
  LEFT JOIN bref_players bp ON p.fangraphs_id = bp.fangraphs_id
  LEFT JOIN fg_career_stats cs ON p.fangraphs_id = cs.fangraphs_id;
  
  COMMENT ON VIEW player_full_profile IS 'Combined FanGraphs and Baseball Reference player data';
  ```

#### 🚀 Deploy Schema
- [ ] Review schema for completeness
- [ ] Run on database:
  ```bash
  psql -h localhost -U postgres -d postgres -f fangraphs_schema.sql
  ```
- [ ] Verify table created:
  ```sql
  \d bref_players
  ```
- [ ] Verify indexes created:
  ```sql
  \di bref_players*
  ```
- [ ] Verify view created:
  ```sql
  SELECT * FROM player_full_profile LIMIT 5;
  ```

#### 📊 Test Schema
- [ ] Insert test data manually:
  ```sql
  INSERT INTO bref_players (
    bref_id, fangraphs_id, full_name, birth_date,
    career_summary, awards, scraped_at
  ) VALUES (
    'troutmi01', 10155, 'Mike Trout', '1991-08-07',
    'Widely considered the best player of his generation...',
    '[{"award": "MVP", "years": [2014, 2016, 2019]}, {"award": "All-Star", "years": [2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2021, 2022]}]'::jsonb,
    CURRENT_TIMESTAMP
  );
  ```
- [ ] Query test data:
  ```sql
  SELECT * FROM bref_players WHERE bref_id = 'troutmi01';
  ```
- [ ] Test JSONB queries:
  ```sql
  -- Find players who won MVP
  SELECT full_name, awards
  FROM bref_players
  WHERE awards @> '[{"award": "MVP"}]'::jsonb;
  ```
- [ ] Test view:
  ```sql
  SELECT * FROM player_full_profile WHERE bref_id = 'troutmi01';
  ```
- [ ] Delete test data:
  ```sql
  DELETE FROM bref_players WHERE bref_id = 'troutmi01';
  ```

---

### Day 4: Build Upsert Logic

#### 🔨 Create Upsert Function
- [ ] Create function in R: `upsert_bref_player(player_data, con)`
  ```r
  upsert_bref_player <- function(player_data, con) {
    # Convert awards list to JSON
    awards_json <- if (!is.null(player_data$awards)) {
      jsonlite::toJSON(player_data$awards, auto_unbox = TRUE)
    } else {
      NULL
    }
    
    # Prepare SQL
    sql <- "
      INSERT INTO bref_players (
        bref_id, fangraphs_id, full_name, nickname,
        birth_date, birth_city, birth_state, birth_country,
        height_inches, weight_lbs, bats, throws,
        draft_year, draft_round, draft_pick, draft_team,
        debut_date, final_game_date, career_summary, awards,
        scraped_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
        $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21
      )
      ON CONFLICT (bref_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        nickname = EXCLUDED.nickname,
        birth_date = EXCLUDED.birth_date,
        birth_city = EXCLUDED.birth_city,
        birth_state = EXCLUDED.birth_state,
        birth_country = EXCLUDED.birth_country,
        height_inches = EXCLUDED.height_inches,
        weight_lbs = EXCLUDED.weight_lbs,
        bats = EXCLUDED.bats,
        throws = EXCLUDED.throws,
        draft_year = EXCLUDED.draft_year,
        draft_round = EXCLUDED.draft_round,
        draft_pick = EXCLUDED.draft_pick,
        draft_team = EXCLUDED.draft_team,
        debut_date = EXCLUDED.debut_date,
        final_game_date = EXCLUDED.final_game_date,
        career_summary = EXCLUDED.career_summary,
        awards = EXCLUDED.awards,
        scraped_at = EXCLUDED.scraped_at,
        updated_at = CURRENT_TIMESTAMP
      RETURNING bref_id;
    "
    
    # Execute
    result <- DBI::dbExecute(con, sql, params = list(
      player_data$bref_id,
      player_data$fangraphs_id,
      player_data$full_name,
      player_data$nickname,
      player_data$birth_date,
      player_data$birth_city,
      player_data$birth_state,
      player_data$birth_country,
      player_data$height_inches,
      player_data$weight_lbs,
      player_data$bats,
      player_data$throws,
      player_data$draft_year,
      player_data$draft_round,
      player_data$draft_pick,
      player_data$draft_team,
      player_data$debut_date,
      player_data$final_game_date,
      player_data$career_summary,
      awards_json,
      player_data$scraped_at
    ))
    
    return(result)
  }
  ```

#### 🧪 Test Upsert Function
- [ ] Test INSERT (new player):
  ```r
  test_player <- list(
    bref_id = "troutmi01",
    fangraphs_id = 10155,
    full_name = "Mike Trout",
    birth_date = as.Date("1991-08-07"),
    # ... other fields
    scraped_at = Sys.time()
  )
  
  result <- upsert_bref_player(test_player, con)
  ```
- [ ] Verify insert:
  ```r
  dbGetQuery(con, "SELECT * FROM bref_players WHERE bref_id = 'troutmi01'")
  ```
- [ ] Test UPDATE (existing player):
  ```r
  test_player$career_summary <- "Updated summary..."
  result <- upsert_bref_player(test_player, con)
  ```
- [ ] Verify update:
  ```r
  dbGetQuery(con, "
    SELECT career_summary, scraped_at, updated_at 
    FROM bref_players 
    WHERE bref_id = 'troutmi01'
  ")
  # Should show updated summary and updated_at timestamp
  ```
- [ ] Test with NULL fields:
  ```r
  test_player_minimal <- list(
    bref_id = "testpl01",
    fangraphs_id = 99999,
    full_name = "Test Player",
    birth_date = NULL,
    draft_year = NULL,
    # ... mostly NULL
    scraped_at = Sys.time()
  )
  
  result <- upsert_bref_player(test_player_minimal, con)
  ```
- [ ] Verify NULL handling works correctly
- [ ] Clean up test data:
  ```r
  dbExecute(con, "DELETE FROM bref_players WHERE bref_id IN ('troutmi01', 'testpl01')")
  ```

---

### Day 5: Incremental Update Strategy

#### 🔍 Design Update Logic
- [ ] Define update rules:
  - **Never scraped:** MUST scrape
  - **Active players:** Re-scrape if >30 days old
  - **Recently retired:** Re-scrape if >90 days old
  - **Long retired:** Re-scrape if >1 year old
  - **Hall of Fame players:** Re-scrape if >6 months old (awards/bio may be updated)

#### 🔨 Create Query Function
- [ ] Implement `get_players_to_scrape(con)`:
  ```r
  get_players_to_scrape <- function(con) {
    query <- "
      SELECT 
        p.fangraphs_id,
        p.player_name,
        m.bref_id,
        bp.scraped_at,
        p.last_season,
        EXTRACT(YEAR FROM CURRENT_DATE) AS current_year,
        CASE 
          WHEN bp.scraped_at IS NULL THEN 'never_scraped'
          WHEN p.last_season >= EXTRACT(YEAR FROM CURRENT_DATE) - 1 
            THEN 'active'
          WHEN p.last_season >= EXTRACT(YEAR FROM CURRENT_DATE) - 3 
            THEN 'recently_retired'
          ELSE 'long_retired'
        END AS player_status
      FROM fg_players p
      JOIN player_id_mapping m ON p.fangraphs_id = m.fangraphs_id
      LEFT JOIN bref_players bp ON p.fangraphs_id = bp.fangraphs_id
      WHERE 
        m.bref_id IS NOT NULL  -- Only players with mapped IDs
        AND (
          bp.scraped_at IS NULL  -- Never scraped
          OR (
            p.last_season >= EXTRACT(YEAR FROM CURRENT_DATE) - 1  -- Active
            AND bp.scraped_at < CURRENT_DATE - INTERVAL '30 days'
          )
          OR (
            p.last_season BETWEEN EXTRACT(YEAR FROM CURRENT_DATE) - 3 
                            AND EXTRACT(YEAR FROM CURRENT_DATE) - 2  -- Recently retired
            AND bp.scraped_at < CURRENT_DATE - INTERVAL '90 days'
          )
          OR (
            p.last_season < EXTRACT(YEAR FROM CURRENT_DATE) - 3  -- Long retired
            AND bp.scraped_at < CURRENT_DATE - INTERVAL '1 year'
          )
        )
      ORDER BY 
        CASE 
          WHEN bp.scraped_at IS NULL THEN 1  -- Never scraped first
          WHEN p.last_season >= EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN 2  -- Active
          ELSE 3  -- Retired
        END,
        p.last_season DESC,  -- Recent players first within each group
        bp.scraped_at ASC NULLS FIRST  -- Oldest scrapes first
    "
    
    players <- dbGetQuery(con, query)
    
    log_info(glue("Found {nrow(players)} players needing update"))
    log_info(glue("  Never scraped: {sum(players$player_status == 'never_scraped')}"))
    log_info(glue("  Active players: {sum(players$player_status == 'active')}"))
    log_info(glue("  Recently retired: {sum(players$player_status == 'recently_retired')}"))
    log_info(glue("  Long retired: {sum(players$player_status == 'long_retired')}"))
    
    return(players)
  }
  ```

#### 🧪 Test Query Function
- [ ] Connect to database
- [ ] Run query:
  ```r
  players_to_scrape <- get_players_to_scrape(con)
  head(players_to_scrape, 20)
  ```
- [ ] Verify priorities:
  - [ ] Never-scraped players appear first
  - [ ] Active players prioritized over retired
  - [ ] Within groups, sorted by recency
- [ ] Check edge cases:
  - [ ] Players with NULL last_season
  - [ ] Players without mapped bref_id (should be excluded)

#### 📝 Document Update Strategy
- [ ] Create documentation: `bref_update_strategy.md`
- [ ] Explain update frequency by player status
- [ ] Document query logic
- [ ] Note exceptions (e.g., manual update triggers)
- [ ] List cron schedule recommendations:
  ```
  Daily: Active players (during season)
  Weekly: Recently retired
  Monthly: Long retired
  ```

---

## 📅 Week 3: Batch Scraper & Production

### Day 1: Build Batch Scraper Core

#### 🔨 Create Production Script
- [ ] Create file: `bref_batch_scraper.r`
- [ ] Add header and configuration:
  ```r
  #!/usr/bin/env Rscript
  # Baseball Reference Batch Scraper
  # Scrapes biographical data from Baseball Reference player pages
  # Respects robots.txt (3-second crawl delay)
  
  # Load libraries
  suppressPackageStartupMessages({
    library(rvest)
    library(polite)
    library(httr)
    library(dplyr)
    library(glue)
    library(logger)
    library(RPostgres)
    library(jsonlite)
  })
  
  # Configuration
  SCRAPE_DELAY <- 3  # Seconds (robots.txt requirement)
  MAX_RETRIES <- 5
  USER_AGENT <- "Baseball RAG Research Bot (your.email@example.com)"
  
  # Database configuration (from environment variables)
  DB_HOST <- Sys.getenv("DB_HOST", "localhost")
  DB_NAME <- Sys.getenv("DB_NAME", "postgres")
  DB_USER <- Sys.getenv("DB_USER", "postgres")
  DB_PASSWORD <- Sys.getenv("DB_PASSWORD")
  
  # Logging configuration
  log_threshold(INFO)
  log_appender(appender_tee("bref_scraper.log"))
  log_layout(layout_glue_colors)
  ```

#### 🔨 Implement Core Scraping Function
- [ ] Create `scrape_player_bio(player_name, bref_id, session)`:
  ```r
  scrape_player_bio <- function(player_name, bref_id, session) {
    url <- glue("players/{substr(bref_id, 1, 1)}/{bref_id}.shtml")
    
    tryCatch({
      log_debug(glue("Scraping {player_name} ({bref_id})"))
      
      # Scrape page (polite handles delay automatically)
      page <- scrape(session, url)
      
      # Extract all data using helper functions
      bio <- extract_biography(page)
      physical <- extract_physical_stats(page)
      draft <- extract_draft_info(page)
      career_dates <- extract_career_dates(page)
      awards <- extract_awards(page)
      summary <- extract_career_summary(page)
      
      # Combine into single data structure
      player_data <- list(
        bref_id = bref_id,
        # ... all fields from extraction functions
        scraped_at = Sys.time(),
        success = TRUE,
        error = NULL
      )
      
      log_info(glue("✓ {player_name}"))
      return(player_data)
      
    }, error = function(e) {
      log_warn(glue("✗ {player_name}: {e$message}"))
      return(list(
        bref_id = bref_id,
        player_name = player_name,
        success = FALSE,
        error = e$message,
        scraped_at = Sys.time()
      ))
    })
  }
  ```

#### 🔨 Add Helper Functions from Prototype
- [ ] Copy all extraction functions from prototype:
  - [ ] `extract_biography()`
  - [ ] `extract_physical_stats()`
  - [ ] `extract_draft_info()`
  - [ ] `extract_career_dates()`
  - [ ] `extract_awards()`
  - [ ] `extract_career_summary()`
- [ ] Ensure all have error handling (tryCatch)
- [ ] Add logging to each function

---

### Day 2: Error Handling & Retry Logic

#### 🔧 Implement Exponential Backoff
- [ ] Create `scrape_with_backoff()`:
  ```r
  scrape_with_backoff <- function(session, url, max_retries = 5) {
    for (attempt in 1:max_retries) {
      result <- tryCatch({
        scrape(session, url)
      }, error = function(e) {
        # Check if rate limited
        if (grepl("429", e$message)) {
          wait_time <- 2^attempt  # 2, 4, 8, 16, 32 seconds
          log_warn(glue("Rate limited on attempt {attempt}. Waiting {wait_time}s..."))
          Sys.sleep(wait_time)
          return(NULL)
        }
        
        # Check if temporary server error
        if (grepl("50[0-9]", e$message)) {
          wait_time <- 2^attempt
          log_warn(glue("Server error on attempt {attempt}. Waiting {wait_time}s..."))
          Sys.sleep(wait_time)
          return(NULL)
        }
        
        # Check if timeout
        if (grepl("timeout", e$message, ignore.case = TRUE)) {
          wait_time <- 2^attempt
          log_warn(glue("Timeout on attempt {attempt}. Waiting {wait_time}s..."))
          Sys.sleep(wait_time)
          return(NULL)
        }
        
        # Other errors - don't retry
        stop(e)
      })
      
      if (!is.null(result)) {
        if (attempt > 1) {
          log_info(glue("Success after {attempt} attempts"))
        }
        return(result)
      }
    }
    
    stop(glue("Max retries ({max_retries}) exceeded"))
  }
  ```

#### 🔧 Add Error Classification
- [ ] Create `classify_error()`:
  ```r
  classify_error <- function(error_message) {
    if (grepl("404", error_message)) {
      return("not_found")  # Player page doesn't exist
    } else if (grepl("429", error_message)) {
      return("rate_limited")
    } else if (grepl("50[0-9]", error_message)) {
      return("server_error")
    } else if (grepl("timeout", error_message, ignore.case = TRUE)) {
      return("timeout")
    } else if (grepl("parse|extract", error_message, ignore.case = TRUE)) {
      return("parse_error")  # HTML structure issue
    } else {
      return("unknown")
    }
  }
  ```

#### 🔧 Enhance Scraping Function with Retry
- [ ] Update `scrape_player_bio()` to use backoff:
  ```r
  scrape_player_bio <- function(player_name, bref_id, session) {
    url <- glue("players/{substr(bref_id, 1, 1)}/{bref_id}.shtml")
    
    tryCatch({
      log_debug(glue("Scraping {player_name} ({bref_id})"))
      
      # Use backoff for scraping
      page <- scrape_with_backoff(session, url)
      
      # ... rest of extraction
      
    }, error = function(e) {
      error_type <- classify_error(e$message)
      log_warn(glue("✗ {player_name} [{error_type}]: {e$message}"))
      
      return(list(
        bref_id = bref_id,
        player_name = player_name,
        success = FALSE,
        error = e$message,
        error_type = error_type,
        scraped_at = Sys.time()
      ))
    })
  }
  ```

#### 🧪 Test Error Handling
- [ ] Test with non-existent player (404):
  ```r
  test_result <- scrape_player_bio("Fake Player", "fakepl99", session)
  # Should return success=FALSE, error_type="not_found"
  ```
- [ ] Test with network timeout (simulate):
  ```r
  # Temporarily set very short timeout
  httr::set_config(httr::timeout(0.1))
  test_result <- scrape_player_bio("Mike Trout", "troutmi01", session)
  # Should retry with backoff, eventually fail
  httr::reset_config()
  ```
- [ ] Verify backoff works (check logs for wait times)

---

### Day 3: Disk Caching Implementation

#### 📁 Set Up Cache Directory
- [ ] Create cache directory structure:
  ```bash
  mkdir -p bref_cache
  ```
- [ ] Add to `.gitignore`:
  ```
  bref_cache/
  *.log
  ```

#### 🔧 Implement Cache Functions
- [ ] Create `cache_page()`:
  ```r
  cache_page <- function(bref_id, html_content, cache_dir = "bref_cache") {
    cache_file <- file.path(cache_dir, paste0(bref_id, ".html"))
    
    # Create directory if doesn't exist
    if (!dir.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
    
    # Write HTML to disk
    writeLines(as.character(html_content), cache_file)
    log_debug(glue("Cached {bref_id}"))
  }
  ```
- [ ] Create `load_cached_page()`:
  ```r
  load_cached_page <- function(bref_id, cache_dir = "bref_cache", max_age_days = 30) {
    cache_file <- file.path(cache_dir, paste0(bref_id, ".html"))
    
    # Check if cache file exists
    if (!file.exists(cache_file)) {
      log_debug(glue("No cache for {bref_id}"))
      return(NULL)
    }
    
    # Check cache age
    file_age_days <- as.numeric(difftime(Sys.time(), file.info(cache_file)$mtime, units = "days"))
    if (file_age_days > max_age_days) {
      log_debug(glue("Cache expired for {bref_id} ({round(file_age_days, 1)} days old)"))
      return(NULL)
    }
    
    # Load and parse cached HTML
    log_debug(glue("Using cached {bref_id}"))
    html_content <- read_html(cache_file)
    return(html_content)
  }
  ```

#### 🔧 Integrate Caching into Scraper
- [ ] Update `scrape_player_bio()` to use cache:
  ```r
  scrape_player_bio <- function(player_name, bref_id, session, use_cache = TRUE) {
    url <- glue("players/{substr(bref_id, 1, 1)}/{bref_id}.shtml")
    
    tryCatch({
      log_debug(glue("Scraping {player_name} ({bref_id})"))
      
      # Try cache first
      page <- NULL
      if (use_cache) {
        page <- load_cached_page(bref_id)
      }
      
      # If no cache, scrape fresh
      if (is.null(page)) {
        page <- scrape_with_backoff(session, url)
        
        # Cache the result
        if (use_cache) {
          cache_page(bref_id, page)
        }
      }
      
      # ... rest of extraction
      
    }, error = function(e) {
      # ... error handling
    })
  }
  ```

#### 🧪 Test Caching
- [ ] Test cache write:
  ```r
  result <- scrape_player_bio("Mike Trout", "troutmi01", session, use_cache = TRUE)
  # Check cache file exists
  file.exists("bref_cache/troutmi01.html")  # Should be TRUE
  ```
- [ ] Test cache read:
  ```r
  # Scrape again - should use cache
  result2 <- scrape_player_bio("Mike Trout", "troutmi01", session, use_cache = TRUE)
  # Check logs - should say "Using cached troutmi01"
  ```
- [ ] Test cache expiration:
  ```r
  # Manually set old timestamp
  Sys.setFileTime("bref_cache/troutmi01.html", Sys.time() - (31 * 24 * 3600))
  result3 <- scrape_player_bio("Mike Trout", "troutmi01", session, use_cache = TRUE)
  # Should re-scrape (cache expired)
  ```

#### 📝 Document Cache Strategy
- [ ] Add to README:
  - Cache location: `bref_cache/`
  - Max age: 30 days
  - Size estimation: ~50KB per player × 2000 = ~100MB
  - When to clear cache: If HTML structure changes
  - How to disable: `use_cache = FALSE`

---

### Day 4: Main Execution Loop & Progress Tracking

#### 🔧 Implement Main Function
- [ ] Create `main()`:
  ```r
  main <- function(use_cache = TRUE, max_players = NULL) {
    log_info("=" %s_rep% 60)
    log_info("Baseball Reference Batch Scraper")
    log_info("=" %s_rep% 60)
    
    start_time <- Sys.time()
    
    # Database connection
    log_info("Connecting to database...")
    con <- dbConnect(
      RPostgres::Postgres(),
      host = DB_HOST,
      dbname = DB_NAME,
      user = DB_USER,
      password = DB_PASSWORD
    )
    on.exit(dbDisconnect(con), add = TRUE)
    
    # Get players needing scraping
    log_info("Identifying players to scrape...")
    players <- get_players_to_scrape(con)
    
    if (!is.null(max_players) && nrow(players) > max_players) {
      log_info(glue("Limiting to first {max_players} players (testing mode)"))
      players <- head(players, max_players)
    }
    
    log_info(glue("Found {nrow(players)} players to scrape"))
    
    # Set up polite session
    log_info(glue("Initializing scraper (delay: {SCRAPE_DELAY}s)..."))
    session <- bow(
      url = "https://www.baseball-reference.com/",
      user_agent = USER_AGENT,
      delay = SCRAPE_DELAY
    )
    
    # Scrape all players
    log_info("Starting scrape...")
    results <- vector("list", nrow(players))
    success_count <- 0
    error_count <- 0
    error_summary <- list()
    
    for (i in seq_len(nrow(players))) {
      player <- players[i, ]
      
      # Scrape
      result <- scrape_player_bio(
        player$player_name,
        player$bref_id,
        session,
        use_cache = use_cache
      )
      
      results[[i]] <- result
      
      # Track success/failure
      if (result$success) {
        success_count <- success_count + 1
        
        # Save to database
        tryCatch({
          upsert_bref_player(result, con)
        }, error = function(e) {
          log_error(glue("DB error for {player$player_name}: {e$message}"))
        })
      } else {
        error_count <- error_count + 1
        error_type <- result$error_type %||% "unknown"
        error_summary[[error_type]] <- (error_summary[[error_type]] %||% 0) + 1
      }
      
      # Progress update every 50 players
      if (i %% 50 == 0) {
        elapsed <- difftime(Sys.time(), start_time, units = "mins")
        rate <- i / as.numeric(elapsed)
        remaining <- (nrow(players) - i) / rate
        
        log_info(glue(
          "Progress: {i}/{nrow(players)} ({round(100*i/nrow(players), 1)}%) | ",
          "Success: {success_count} | Errors: {error_count} | ",
          "Rate: {round(rate, 1)}/min | ETA: {round(remaining, 1)} min"
        ))
      }
    }
    
    # Final summary
    duration <- difftime(Sys.time(), start_time, units = "mins")
    
    log_info("=" %s_rep% 60)
    log_info("SCRAPING COMPLETE")
    log_info("=" %s_rep% 60)
    log_info(glue("Total players: {nrow(players)}"))
    log_info(glue("Successful: {success_count} ({round(100*success_count/nrow(players), 1)}%)"))
    log_info(glue("Failed: {error_count} ({round(100*error_count/nrow(players), 1)}%)"))
    log_info(glue("Duration: {round(duration, 1)} minutes"))
    log_info(glue("Rate: {round(nrow(players)/as.numeric(duration), 1)} players/min"))
    
    if (error_count > 0) {
      log_info("Error breakdown:")
      for (error_type in names(error_summary)) {
        log_info(glue("  {error_type}: {error_summary[[error_type]]}"))
      }
    }
    
    log_info("=" %s_rep% 60)
    
    # Return results for analysis
    invisible(results)
  }
  ```

#### 🔧 Add Command-Line Interface
- [ ] Add argument parsing:
  ```r
  # Parse command-line arguments
  args <- commandArgs(trailingOnly = TRUE)
  
  use_cache <- !("--no-cache" %in% args)
  max_players <- NULL
  
  if ("--test" %in% args) {
    max_players <- 10
    log_info("TEST MODE: Limiting to 10 players")
  } else if ("--limit" %in% args) {
    limit_idx <- which(args == "--limit") + 1
    max_players <- as.integer(args[limit_idx])
    log_info(glue("LIMIT MODE: Processing {max_players} players"))
  }
  
  # Run
  if (!interactive()) {
    main(use_cache = use_cache, max_players = max_players)
  }
  ```

#### 🧪 Test Batch Scraper
- [ ] Test with 10 players:
  ```bash
  Rscript bref_batch_scraper.r --test
  ```
- [ ] Verify:
  - [ ] Progress updates appear
  - [ ] Success/error counts tracked
  - [ ] Database inserts succeed
  - [ ] Final summary printed
  - [ ] Log file created
- [ ] Test with 100 players:
  ```bash
  Rscript bref_batch_scraper.r --limit 100
  ```
- [ ] Monitor:
  - [ ] ~5 minutes duration (100 × 3s = 300s)
  - [ ] Success rate >90%
  - [ ] No rate limiting (no 429 errors)
  - [ ] Database records match success count

---

### Day 5: Production Scrape & Validation

#### 🚀 Prepare for Full Scrape
- [ ] Check database connection stable
- [ ] Verify disk space for cache (~100MB)
- [ ] Set up monitoring:
  ```bash
  # Terminal 1: Run scraper
  Rscript bref_batch_scraper.r
  
  # Terminal 2: Monitor logs
  tail -f bref_scraper.log
  
  # Terminal 3: Monitor database
  watch -n 60 'psql -h localhost -U postgres -d postgres -c "SELECT COUNT(*) FROM bref_players"'
  ```
- [ ] Schedule for off-hours (e.g., overnight)

#### 🚀 Run Full Scrape
- [ ] Start scrape:
  ```bash
  nohup Rscript bref_batch_scraper.r > scrape_output.txt 2>&1 &
  ```
- [ ] Monitor progress periodically
- [ ] Estimated duration: ~100 minutes (2000 players × 3s)
- [ ] Check for issues:
  - [ ] No spike in error rate
  - [ ] No 429 rate limit errors
  - [ ] Database growing steadily

#### ✅ Post-Scrape Validation

##### Database Validation
- [ ] Check total records:
  ```sql
  SELECT COUNT(*) FROM bref_players;
  -- Should be close to number of fg_players
  ```
- [ ] Check data completeness:
  ```sql
  SELECT 
    COUNT(*) as total,
    COUNT(birth_date) as has_birth_date,
    COUNT(birth_city) as has_birth_city,
    COUNT(career_summary) as has_summary,
    COUNT(awards) as has_awards,
    COUNT(draft_year) as has_draft_year,
    AVG(CASE WHEN has_complete_bio THEN 1 ELSE 0 END) * 100 as pct_complete_bio
  FROM bref_players;
  ```
- [ ] Find players without Baseball Reference data:
  ```sql
  SELECT p.player_name, p.fangraphs_id, p.last_season
  FROM fg_players p
  LEFT JOIN bref_players bp ON p.fangraphs_id = bp.fangraphs_id
  WHERE bp.bref_id IS NULL
  ORDER BY p.last_season DESC
  LIMIT 50;
  ```
- [ ] Check for recent errors:
  ```sql
  SELECT player_name, error_type, COUNT(*) as count
  FROM scrape_errors
  WHERE scraped_at > CURRENT_TIMESTAMP - INTERVAL '1 day'
  GROUP BY player_name, error_type
  ORDER BY count DESC;
  -- Note: Requires creating scrape_errors table to track failures
  ```

##### Manual Spot Checks
- [ ] Query 20 random players:
  ```sql
  SELECT * FROM player_full_profile
  ORDER BY RANDOM()
  LIMIT 20;
  ```
- [ ] For each player:
  - [ ] Visit their Baseball Reference page
  - [ ] Compare scraped data to website
  - [ ] Check biographical accuracy
  - [ ] Verify awards data (JSONB structure)
  - [ ] Confirm draft information
  - [ ] Validate career dates
- [ ] Note any systematic issues or patterns

##### Data Quality Metrics
- [ ] Calculate metrics:
  ```sql
  -- Coverage rate
  SELECT 
    COUNT(DISTINCT bp.fangraphs_id) * 100.0 / COUNT(DISTINCT p.fangraphs_id) as coverage_pct
  FROM fg_players p
  LEFT JOIN bref_players bp ON p.fangraphs_id = bp.fangraphs_id;
  
  -- Completeness by field
  SELECT 
    'birth_date' as field,
    COUNT(birth_date) * 100.0 / COUNT(*) as pct_complete
  FROM bref_players
  UNION ALL
  SELECT 'draft_year', COUNT(draft_year) * 100.0 / COUNT(*) FROM bref_players
  UNION ALL
  SELECT 'career_summary', COUNT(career_summary) * 100.0 / COUNT(*) FROM bref_players
  UNION ALL
  SELECT 'awards', COUNT(awards) * 100.0 / COUNT(*) FROM bref_players;
  
  -- Active vs retired coverage
  SELECT 
    CASE 
      WHEN p.last_season >= EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN 'Active'
      ELSE 'Retired'
    END as status,
    COUNT(p.fangraphs_id) as total_players,
    COUNT(bp.bref_id) as scraped,
    COUNT(bp.bref_id) * 100.0 / COUNT(p.fangraphs_id) as coverage_pct
  FROM fg_players p
  LEFT JOIN bref_players bp ON p.fangraphs_id = bp.fangraphs_id
  GROUP BY status;
  ```
- [ ] Document metrics in validation report

##### Error Analysis
- [ ] Review scraper logs:
  ```bash
  # Count errors by type
  grep "✗" bref_scraper.log | grep -oP '\[\w+\]' | sort | uniq -c | sort -rn
  
  # Find most common errors
  grep "✗" bref_scraper.log | head -50
  ```
- [ ] Investigate systematic failures:
  - [ ] Do certain player IDs consistently fail?
  - [ ] Are there era-specific issues (1980s vs 2020s)?
  - [ ] Are parsing errors due to HTML structure changes?
- [ ] Document findings and potential fixes

#### 📝 Create Validation Report
- [ ] Create file: `bref_scrape_validation_report.md`
- [ ] Include:
  - [ ] Scrape start/end times
  - [ ] Total players attempted
  - [ ] Success/failure counts
  - [ ] Coverage rate (% of fg_players with bref_players data)
  - [ ] Data completeness by field
  - [ ] Error breakdown by type
  - [ ] Manual validation results (spot checks)
  - [ ] Known limitations
  - [ ] Recommendations for improvement

---

## 📅 Week 4: Integration & Testing

### Day 1: Integrate with Embedding System

#### 📝 Update TypeScript Embedding Generation

##### Add Database Query for Baseball Reference Data
- [ ] Create new query function in `index.ts`:
  ```typescript
  async function getBrefBio(fangraphsId: number): Promise<BrefBio | null> {
    const result = await pool.query(`
      SELECT 
        bp.full_name,
        bp.nickname,
        bp.birth_date,
        bp.birth_city,
        bp.birth_state,
        bp.career_summary,
        bp.awards
      FROM bref_players bp
      WHERE bp.fangraphs_id = $1
    `, [fangraphsId]);
    
    if (result.rows.length === 0) return null;
    return result.rows[0] as BrefBio;
  }
  ```
- [ ] Add TypeScript interface:
  ```typescript
  interface BrefBio {
    full_name: string;
    nickname?: string;
    birth_date?: Date;
    birth_city?: string;
    birth_state?: string;
    career_summary?: string;
    awards?: Award[];
  }
  
  interface Award {
    award: string;
    years: number[];
  }
  ```

##### Update Summary Generation
- [ ] Modify `generatePlayerSeasonSummary()`:
  ```typescript
  async function generatePlayerSeasonSummary(
    playerSeasonId: string
  ): Promise<string> {
    const stats = await getPlayerStats(playerSeasonId);
    const bio = await getBrefBio(stats.fangraphs_id);  // NEW
    
    let summary = `${stats.player_name}`;
    
    // Add biographical context if available
    if (bio?.birth_city && bio?.birth_state) {
      summary += ` (born in ${bio.birth_city}, ${bio.birth_state})`;
    }
    
    summary += `, age ${stats.age}, `;
    
    // Add career narrative snippet
    if (bio?.career_summary) {
      // Take first sentence or first 150 characters
      const snippet = bio.career_summary
        .split('.')[0]
        .substring(0, 150);
      summary += `${snippet}... `;
    }
    
    // Add season-specific awards
    if (bio?.awards) {
      const seasonAwards = bio.awards
        .filter(a => a.years.includes(stats.year))
        .map(a => a.award);
      
      if (seasonAwards.length > 0) {
        summary += `${stats.year} awards: ${seasonAwards.join(', ')}. `;
      }
    }
    
    // Add statistics (as before)
    summary += `In ${stats.year}, played ${stats.position} for ${stats.team}. `;
    summary += `Posted ${stats.war} WAR with ${stats.wrc_plus} wRC+. `;
    
    // ... rest of stats description
    
    return summary;
  }
  ```

#### 🧪 Test Enhanced Summaries
- [ ] Generate summaries for test players:
  ```typescript
  // Test with award-heavy player
  const trout2019 = await generatePlayerSeasonSummary("10155_2019");
  console.log(trout2019);
  // Should mention MVP award
  
  // Test without Bio data
  const obscure = await generatePlayerSeasonSummary("12345_2010");
  console.log(obscure);
  // Should still generate valid summary
  ```
- [ ] Compare before/after:
  - [ ] Save old summaries
  - [ ] Generate new summaries
  - [ ] Manually review improvements
  - [ ] Check length (should be longer but not excessive)

#### 🔄 Re-generate Embeddings (Subset)
- [ ] Choose test set:
  - [ ] All MVP winners (2000-2024)
  - [ ] Hall of Fame players
  - [ ] Top 100 players by career WAR
  - [ ] ~500 players total
- [ ] Clear old embeddings:
  ```sql
  DELETE FROM player_embeddings
  WHERE player_season_id IN (
    SELECT player_season_id 
    FROM fg_season_stats s
    JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
    WHERE p.player_name IN (/* list of test players */)
  );
  ```
- [ ] Regenerate:
  ```bash
  npm run generate -- --players="MVP winners, Hall of Fame"
  ```
- [ ] Verify new embeddings use biographical context

---

### Day 2: Create LLM Tool for Biographical Queries

#### 🔨 Define Tool Schema
- [ ] Create tool definition for Ollama:
  ```typescript
  const playerBioTool = {
    type: "function",
    function: {
      name: "get_player_bio",
      description: "Get comprehensive biographical information, career narrative, and awards for a baseball player. Use this when users ask about a player's background, personal life, draft history, or career highlights.",
      parameters: {
        type: "object",
        properties: {
          player_name: {
            type: "string",
            description: "The full name of the player (e.g., 'Mike Trout', 'Ken Griffey Jr')"
          }
        },
        required: ["player_name"]
      }
    }
  };
  ```

#### 🔨 Implement Tool Handler
- [ ] Create handler function:
  ```typescript
  async function getPlayerBio(playerName: string): Promise<BioData> {
    const result = await pool.query(`
      SELECT 
        p.player_name,
        p.bats as fg_bats,
        p.first_season,
        p.last_season,
        bp.bref_id,
        bp.full_name,
        bp.nickname,
        bp.birth_date,
        bp.birth_city,
        bp.birth_state,
        bp.birth_country,
        bp.height_inches,
        bp.weight_lbs,
        bp.draft_year,
        bp.draft_round,
        bp.draft_pick,
        bp.draft_team,
        bp.debut_date,
        bp.final_game_date,
        bp.career_summary,
        bp.awards,
        cs.total_war,
        cs.total_games,
        cs.peak_war,
        cs.peak_year
      FROM fg_players p
      LEFT JOIN bref_players bp ON p.fangraphs_id = bp.fangraphs_id
      LEFT JOIN fg_career_stats cs ON p.fangraphs_id = cs.fangraphs_id
      WHERE p.player_name ILIKE $1
      LIMIT 1
    `, [`%${playerName}%`]);
    
    if (result.rows.length === 0) {
      throw new Error(`Player "${playerName}" not found`);
    }
    
    const player = result.rows[0];
    
    // Format response
    return {
      name: player.full_name || player.player_name,
      nickname: player.nickname,
      biographical: {
        birth_date: player.birth_date,
        birth_place: player.birth_city && player.birth_state 
          ? `${player.birth_city}, ${player.birth_state}`
          : null,
        birth_country: player.birth_country,
        height: player.height_inches 
          ? `${Math.floor(player.height_inches / 12)}'${player.height_inches % 12}"`
          : null,
        weight: player.weight_lbs ? `${player.weight_lbs} lbs` : null,
        bats: player.fg_bats
      },
      draft: player.draft_year ? {
        year: player.draft_year,
        round: player.draft_round,
        pick: player.draft_pick,
        team: player.draft_team,
        description: `Drafted in ${player.draft_year}, Round ${player.draft_round}, Pick ${player.draft_pick} by ${player.draft_team}`
      } : null,
      career: {
        debut: player.debut_date,
        final_game: player.final_game_date,
        years_active: `${player.first_season}-${player.last_season}`,
        total_war: player.total_war,
        total_games: player.total_games,
        peak_season: {
          year: player.peak_year,
          war: player.peak_war
        },
        summary: player.career_summary
      },
      awards: player.awards || [],
      bref_url: player.bref_id 
        ? `https://www.baseball-reference.com/players/${player.bref_id.charAt(0)}/${player.bref_id}.shtml`
        : null
    };
  }
  ```

#### 🔨 Register Tool with LLM
- [ ] Add to tool registry:
  ```typescript
  const tools = [
    searchSimilarPlayersTool,
    getPlayerStatsTool,
    comparePlayersTool,
    getCareerSummaryTool,
    playerBioTool  // NEW
  ];
  ```
- [ ] Add to tool executor:
  ```typescript
  async function executeTool(toolName: string, args: any): Promise<any> {
    switch (toolName) {
      case "search_similar_players":
        return await searchSimilarPlayers(args);
      case "get_player_stats":
        return await getPlayerStats(args);
      case "compare_players":
        return await comparePlayers(args);
      case "get_career_summary":
        return await getCareerSummary(args);
      case "get_player_bio":  // NEW
        return await getPlayerBio(args.player_name);
      default:
        throw new Error(`Unknown tool: ${toolName}`);
    }
  }
  ```

#### 🧪 Test Tool
- [ ] Test with known players:
  ```typescript
  // Mike Trout
  const troutBio = await getPlayerBio("Mike Trout");
  console.log(JSON.stringify(troutBio, null, 2));
  // Should return full bio with awards
  
  // Historical player
  const bondsBio = await getPlayerBio("Barry Bonds");
  console.log(JSON.stringify(bondsBio, null, 2));
  // Should include career summary
  
  // Fuzzy match
  const griffeyBio = await getPlayerBio("griffey");
  console.log(JSON.stringify(griffeyBio, null, 2));
  // Should find Ken Griffey Jr
  ```
- [ ] Test error cases:
  ```typescript
  // Non-existent player
  try {
    await getPlayerBio("Fake Player");
  } catch (e) {
    console.log("Correctly threw error:", e.message);
  }
  ```

---

### Day 3: LLM Integration Testing

#### 🧪 Test Biographical Queries

##### Setup Test Environment
- [ ] Start Ollama server:
  ```bash
  ollama serve
  ```
- [ ] Load model:
  ```bash
  ollama pull llama3.1:8b
  ```
- [ ] Start backend server:
  ```bash
  npm run dev
  ```

##### Test Query Types

**Background/Biography Queries**
- [ ] "Tell me about Mike Trout's background"
  - [ ] Verify LLM calls `get_player_bio`
  - [ ] Check response includes birth place, draft info
  - [ ] Confirm narrative is coherent
- [ ] "Where was Shohei Ohtani born?"
  - [ ] Should call `get_player_bio`
  - [ ] Response should mention Japan
- [ ] "How tall is Aaron Judge?"
  - [ ] Should extract height from bio tool

**Draft-Related Queries**
- [ ] "Who were the top draft picks in 2009?"
  - [ ] Should query multiple players
  - [ ] May call `get_player_bio` for each
  - [ ] Response should mention Strasburg (#1), Trout (#25)
- [ ] "Where was Ken Griffey Jr drafted?"
  - [ ] Should call bio tool
  - [ ] Mention 1987, 1st round, 1st overall, Mariners

**Award Queries**
- [ ] "What awards has Mookie Betts won?"
  - [ ] Should extract awards from JSONB
  - [ ] List MVP years, All-Star selections, Gold Gloves
- [ ] "Show me MVP winners from the 2010s"
  - [ ] Should query by decade
  - [ ] Filter awards JSONB for MVP
  - [ ] List players with years

**Career Narrative Queries**
- [ ] "Give me a summary of Derek Jeter's career"
  - [ ] Should call bio tool for narrative
  - [ ] Also call career stats tool
  - [ ] Combine narrative with statistics
- [ ] "What is Mike Trout known for?"
  - [ ] Use career summary from Baseball Reference
  - [ ] Augment with statistical achievements

##### Verify Tool Selection
- [ ] Check logs for tool calls:
  ```typescript
  // Should see:
  // [LLM] Calling tool: get_player_bio with args: {player_name: "Mike Trout"}
  // [Tool] get_player_bio returned: {...}
  // [LLM] Response: Mike Trout was born in Vineland, NJ...
  ```
- [ ] Confirm LLM chooses correct tool:
  - [ ] Uses `get_player_bio` for biographical questions
  - [ ] Uses `get_player_stats` for statistical questions
  - [ ] Combines tools when appropriate

##### Test Error Handling
- [ ] Query for player without Bio data:
  - [ ] "Tell me about [obscure player]"
  - [ ] Should gracefully handle missing data
  - [ ] Provide stats even if bio missing
- [ ] Misspelled player name:
  - [ ] "Tell me about Mkie Trut"
  - [ ] Fuzzy matching should find Mike Trout
  - [ ] Or LLM should ask for clarification

---

### Day 4: End-to-End Testing

#### 🧪 Complex Multi-Tool Queries

##### Career Comparisons with Context
- [ ] "Compare the careers of Mike Trout and Ken Griffey Jr"
  - [ ] Should call `get_player_bio` for both
  - [ ] Call `compare_players` for stats
  - [ ] Weave biographical context into comparison:
    - Draft positions (Griffey #1, Trout #25)
    - Career arcs (Griffey's injuries, Trout's consistency)
    - Awards and recognition
  - [ ] Verify narrative quality
  - [ ] Check citations accurate

##### Era-Based Queries
- [ ] "Who were the best power hitters in the steroid era?"
  - [ ] Define era (1990s-early 2000s)
  - [ ] Search for high power grades
  - [ ] Augment with biographical context
  - [ ] Mention controversies (Bonds, Sosa, McGwire)
- [ ] "Show me Hall of Fame players from the 1990s"
  - [ ] Filter by debut decade
  - [ ] Check awards for Hall of Fame status
  - [ ] Provide career summaries

##### Biographical Similarity
- [ ] "Find players similar to Mike Trout's background"
  - [ ] Challenging query (semantic search on bio?)
  - [ ] Could search: California-born, high draft picks, similar age
  - [ ] Test LLM's ability to decompose query

##### Award-Focused Queries
- [ ] "List all players who won both MVP and Gold Glove in the same year"
  - [ ] Query awards JSONB
  - [ ] Find overlap in years
  - [ ] Return list with years
- [ ] "How many All-Star selections does Derek Jeter have?"
  - [ ] Parse awards array
  - [ ] Count years for All-Star award
  - [ ] Should be 14

#### ✅ Validate Response Quality

##### Accuracy Checklist
- [ ] Biographical facts correct:
  - [ ] Cross-reference 10 random players with Baseball Reference website
  - [ ] Check birth dates, places, draft info
  - [ ] Verify award years
- [ ] Citations present and accurate:
  - [ ] LLM attributes info to Baseball Reference when using bio tool
  - [ ] Cites FanGraphs for statistical claims
- [ ] No hallucinations:
  - [ ] Check for invented awards or achievements
  - [ ] Verify numbers match database
  - [ ] Confirm narratives align with career summaries

##### Context Integration
- [ ] Biographical context enhances responses:
  - [ ] Compare response with and without Bio data
  - [ ] Should be richer, more engaging
  - [ ] Still accurate and citation-backed
- [ ] LLM uses context appropriately:
  - [ ] Doesn't over-rely on biographical fluff
  - [ ] Balances narrative with statistics
  - [ ] Prioritizes user's question focus

#### 📊 Performance Testing
- [ ] Measure query latency:
  - [ ] Simple bio query: <2 seconds
  - [ ] Complex comparison: <5 seconds
  - [ ] Multi-player queries: <10 seconds
- [ ] Database query performance:
  - [ ] Check `EXPLAIN ANALYZE` for slow queries
  - [ ] Verify indexes being used
  - [ ] Optimize if needed

---

### Day 5: Documentation & Scheduling

#### 📝 Update Project Specification
- [ ] Mark Phase 2.1 as ✅ COMPLETE
- [ ] Update `PROJECT_SPEC.md`:
  ```markdown
  ### Phase 2.1: Baseball Reference Integration ✅ COMPLETE
  **Completion Date:** [Date]
  **Duration:** 4 weeks
  
  #### Achievements:
  - [x] Successfully scraped biographical data for 2000+ players
  - [x] Created `bref_players` table with comprehensive schema
  - [x] Mapped FanGraphs IDs to Baseball Reference IDs (95% coverage)
  - [x] Integrated biographical context into embedding generation
  - [x] Created `get_player_bio` LLM tool
  - [x] Validated data quality (manual spot-checks)
  - [x] Implemented incremental update logic
  
  #### Metrics:
  - Coverage: XX% of players have Baseball Reference data
  - Data completeness: XX% have birth date, XX% have career summary
  - Scraping success rate: XX%
  - Query enhancement: Biographical context added to embeddings
  
  #### Known Limitations:
  - Pre-1965 players lack draft information (draft didn't exist)
  - Some obscure players missing from Baseball Reference
  - Career summaries vary in quality and length
  - International players may have limited biographical data
  ```
- [ ] Add lessons learned section:
  ```markdown
  #### Phase 2.1 Lessons Learned:
  1. **Polite package is excellent**: Automated robots.txt compliance
  2. **Caching crucial for development**: Avoid re-scraping during debugging
  3. **JSONB for awards is flexible**: Easy to query, extend
  4. **Error classification helps debugging**: Group errors by type
  5. **Incremental updates work well**: Active players need frequent updates
  6. **Biographical context enriches responses**: Adds narrative depth
  7. **HTML structure is stable**: Few parsing issues across eras
  8. **ID mapping is challenging**: Chadwick Bureau register essential
  9. **Manual validation catches edge cases**: Spot-checks revealed issues
  10. **Progress logging is motivating**: Clear feedback during long scrapes
  ```

#### 📝 Create Comprehensive README
- [ ] Create file: `bref_scraper_README.md`
- [ ] Include sections:
  
  **Installation**
  ```markdown
  ## Installation
  
  ### Requirements
  - R 4.x+
  - PostgreSQL 16+ with data loaded
  - Required R packages:
    ```r
    install.packages(c(
      "rvest", "polite", "httr", "dplyr", 
      "glue", "logger", "RPostgres", "jsonlite"
    ))
    ```
  
  ### Setup
  1. Ensure database is running and populated with FanGraphs data
  2. Set environment variables:
     ```bash
     export DB_PASSWORD="your_password"
     export DB_HOST="localhost"
     ```
  3. Map FanGraphs IDs to Baseball Reference IDs:
     ```bash
     Rscript map_fangraphs_to_bref.r
     ```
  ```
  
  **Usage**
  ```markdown
  ## Usage
  
  ### First-Time Scrape (All Players)
  ```bash
  Rscript bref_batch_scraper.r
  ```
  This will scrape all players that haven't been scraped yet.
  Duration: ~100 minutes for 2000 players.
  
  ### Incremental Update
  ```bash
  Rscript bref_batch_scraper.r
  ```
  Only re-scrapes players that need updates (active players >30 days old, etc.)
  
  ### Test Mode
  ```bash
  Rscript bref_batch_scraper.r --test
  ```
  Scrapes only 10 players for testing.
  
  ### Disable Cache
  ```bash
  Rscript bref_batch_scraper.r --no-cache
  ```
  Forces fresh scraping (ignores cached HTML).
  ```
  
  **Troubleshooting**
  ```markdown
  ## Troubleshooting
  
  ### "Rate limited (429)" errors
  - Increase SCRAPE_DELAY in script (default: 3s)
  - Check if another scraper is running
  - Wait 1 hour, then retry
  
  ### "Player not found (404)" errors
  - Normal for some players (not in Baseball Reference)
  - Check ID mapping is correct
  - May need manual correction in player_id_mapping table
  
  ### Database connection errors
  - Verify DB_PASSWORD environment variable
  - Check PostgreSQL is running: `pg_isready`
  - Test connection: `psql -h localhost -U postgres`
  
  ### Parsing errors
  - HTML structure may have changed
  - Update extraction functions in script
  - Report issue with specific player ID
  ```
  
  **Maintenance**
  ```markdown
  ## Maintenance
  
  ### Recommended Schedule
  - **Daily** (during season): Update active players
  - **Weekly**: Update recently retired players
  - **Monthly**: Update all players (full incremental)
  
  ### Cache Management
  - Cache location: `bref_cache/`
  - Max age: 30 days (auto-expires)
  - Clear cache: `rm -rf bref_cache/`
  - Estimated size: ~100MB for 2000 players
  
  ### Database Cleanup
  ```sql
  -- Find players with very old scrape data
  SELECT player_name, scraped_at
  FROM bref_players bp
  JOIN fg_players p ON bp.fangraphs_id = p.fangraphs_id
  WHERE scraped_at < CURRENT_DATE - INTERVAL '1 year'
  ORDER BY scraped_at;
  ```
  ```

#### ⏰ Set Up Scheduled Scraping

##### Linux/Mac (Cron)
- [ ] Create cron job:
  ```bash
  crontab -e
  ```
- [ ] Add entries:
  ```cron
  # Baseball Reference incremental scrape
  # Daily at 3 AM
  0 3 * * * cd /path/to/baseball-rag && /usr/bin/Rscript bref_batch_scraper.r >> logs/bref_cron.log 2>&1
  
  # Full validation monthly (first Sunday at 4 AM)
  0 4 * * 0 [ $(date +\%d) -le 7 ] && cd /path/to/baseball-rag && /usr/bin/Rscript bref_validation.r >> logs/bref_validation.log 2>&1
  ```
- [ ] Verify cron syntax:
  ```bash
  crontab -l
  ```

##### Windows (Task Scheduler)
- [ ] Open Task Scheduler
- [ ] Create Basic Task:
  - [ ] Name: "Baseball Reference Scraper"
  - [ ] Trigger: Daily at 3:00 AM
  - [ ] Action: Start a program
    - Program: `Rscript.exe`
    - Arguments: `bref_batch_scraper.r`
    - Start in: `C:\path\to\baseball-rag`
  - [ ] Settings:
    - [ ] Run whether user is logged on or not
    - [ ] Run with highest privileges
    - [ ] If task fails, restart every 1 hour (max 3 attempts)

##### Docker (Optional)
- [ ] Create `Dockerfile.scraper`:
  ```dockerfile
  FROM r-base:4.3.0
  
  WORKDIR /app
  
  # Install R packages
  RUN R -e "install.packages(c('rvest', 'polite', 'httr', 'dplyr', 'glue', 'logger', 'RPostgres', 'jsonlite'))"
  
  # Copy scripts
  COPY bref_batch_scraper.r .
  COPY bref_extraction_functions.r .
  
  CMD ["Rscript", "bref_batch_scraper.r"]
  ```
- [ ] Create `docker-compose.yml` entry:
  ```yaml
  services:
    bref-scraper:
      build:
        context: .
        dockerfile: Dockerfile.scraper
      environment:
        - DB_HOST=postgres
        - DB_PASSWORD=${DB_PASSWORD}
      volumes:
        - ./bref_cache:/app/bref_cache
        - ./logs:/app/logs
      depends_on:
        - postgres
      # Run daily at 3 AM (managed externally or via cron)
  ```

#### 📊 Create Monitoring Dashboard (Optional)
- [ ] Simple SQL queries for monitoring:
  ```sql
  -- Create monitoring view
  CREATE OR REPLACE VIEW bref_scrape_status AS
  SELECT 
    COUNT(*) as total_players,
    COUNT(bp.bref_id) as scraped_players,
    COUNT(bp.bref_id) * 100.0 / COUNT(*) as coverage_pct,
    MAX(bp.scraped_at) as last_scrape,
    MIN(bp.scraped_at) as oldest_scrape,
    COUNT(*) FILTER (WHERE bp.scraped_at > CURRENT_DATE - INTERVAL '7 days') as scraped_this_week,
    COUNT(*) FILTER (WHERE bp.scraped_at IS NULL) as never_scraped
  FROM fg_players p
  LEFT JOIN bref_players bp ON p.fangraphs_id = bp.fangraphs_id;
  ```
- [ ] Create alert script: `bref_health_check.r`
  ```r
  # Check scraping health
  # Send email/Slack if:
  # - Last scrape > 2 days ago
  # - Coverage drops below 90%
  # - Error rate > 15%
  ```

---

## ✅ Final Acceptance Criteria

Before marking Phase 2.1 as complete, verify ALL criteria are met:

### Data Quality
- [ ] ≥90% of FanGraphs players have Baseball Reference data
- [ ] ≥80% of players have complete biographical info (birth date, city, state)
- [ ] ≥70% of players have career summaries
- [ ] ≥60% of recent players (2000+) have draft information
- [ ] Manual validation shows <5% data errors

### Technical Implementation
- [ ] Scraper respects robots.txt (3-second delay)
- [ ] No IP bans or sustained rate limiting (429 errors)
- [ ] Error handling robust (handles 404, 500, timeout gracefully)
- [ ] Caching implemented and working
- [ ] Incremental updates functional
- [ ] Database schema properly indexed
- [ ] JSONB awards queryable

### Integration
- [ ] `get_player_bio` LLM tool functional
- [ ] Embedding generation includes biographical context
- [ ] LLM responses enriched with Baseball Reference data
- [ ] Citations accurate and appropriate

### Documentation
- [ ] README with installation, usage, troubleshooting
- [ ] Project specification updated with completion status
- [ ] Lessons learned documented
- [ ] Known limitations listed
- [ ] Validation report created

### Automation
- [ ] Scheduled scraping configured (cron or Task Scheduler)
- [ ] Monitoring/health checks in place
- [ ] Logs rotated/managed

### Performance
- [ ] Full scrape completes in ≤2 hours
- [ ] Incremental updates complete in ≤30 minutes
- [ ] Bio query latency <500ms
- [ ] No database performance degradation

---

## 📊 Success Metrics Summary

| Metric | Target | Achieved |
|--------|--------|----------|
| Player Coverage | ≥90% | __%  |
| Biographical Completeness | ≥80% | __%  |
| Career Summary Coverage | ≥70% | __%  |
| Manual Validation Accuracy | ≥95% | __%  |
| Scraping Success Rate | ≥95% | __%  |
| Full Scrape Duration | ≤120 min | __ min |
| Query Latency | <500ms | __ ms |
| Zero Rate Limit Errors | Yes | Yes/No |

---

## 🎉 Completion Checklist

- [ ] All Week 1 tasks complete
- [ ] All Week 2 tasks complete
- [ ] All Week 3 tasks complete
- [ ] All Week 4 tasks complete
- [ ] All acceptance criteria met
- [ ] Documentation finalized
- [ ] Monitoring in place
- [ ] Scheduled jobs configured
- [ ] Validation report reviewed
- [ ] Project specification updated
- [ ] Ready for Phase 2.2 (Advanced Query Tools)

---

**Congratulations! Phase 2.1 Complete! 🎊**

**Next Phase:** 2.2 - Advanced Query Tools (Era-based filtering, Position-based search, Multi-year aggregations)
