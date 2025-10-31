# Lahman Database Integration Plan

**Goal:** Replace Baseball Reference scraping with Lahman database as foundation

## Phase 1: Core Integration (Immediate)

### 1.1 Data Import
- [x] Create Lahman ETL script (`etl/lahman/lahman_etl.r`)
- [x] Define core schema (`database/lahman_shema.sql`)
- [ ] Run ETL to populate database
- [ ] Verify data quality and completeness

### 1.2 Backend Integration
- [ ] Create Lahman service (`backend/src/services/lahman.ts`)
- [ ] Add biographical lookup tools
- [ ] Update existing tools to use Lahman + FanGraphs hybrid
- [ ] Add career timeline tools

### 1.3 Data Model Updates
- [ ] Create unified player profiles view
- [ ] Link Lahman playerID to FanGraphs data
- [ ] Add biographical embeddings for search

## Phase 2: Enhanced Features

### 2.1 Awards & Honors
- [ ] MVP/Cy Young/ROY tracking
- [ ] All-Star game appearances
- [ ] Hall of Fame status and voting
- [ ] Gold Glove/Silver Slugger awards

### 2.2 Career Context
- [ ] Team history and transactions
- [ ] Career milestones and achievements  
- [ ] Historical context (era adjustments)
- [ ] Playoff performance integration

### 2.3 Supplementary Data Sources
- [ ] Statcast (2015+) for modern metrics
- [ ] Baseball Savant for advanced data
- [ ] FanGraphs for sabermetric context
- [ ] Keep as supplementary, not primary

## Implementation Notes

**Advantages of Lahman:**
- Complete historical coverage (1871-present)
- No scraping restrictions
- Standardized, clean data format
- Includes biographical information
- Awards and honors included

**Integration Strategy:**
- Lahman as biographical foundation
- FanGraphs for advanced metrics overlay
- Statcast for modern player analysis
- Unified search across all sources

**Data Linking:**
- Use retroID/bbrefID for cross-referencing
- Fuzzy name matching as fallback
- Manual mapping for edge cases