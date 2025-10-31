# Baseball RAG - LLM Tool Enhancements Todo List

**Context:** MVP is working. These enhancements add smart data formatting, variable detail levels, and better token efficiency.

---

## 1. Smart Data Format Selection (JSON vs CSV)

### 1.1 Format Selection Logic
- [ ] Create `utils/formatSelector.ts`
  - [ ] Implement `chooseFormat(numRows, numCols)` function
    ```typescript
    // Rules:
    // - Single row + ≤25 cols → pure JSON
    // - 10+ rows OR 25+ cols → CSV wrapper in JSON
    // - Else → pure JSON (default)
    ```
  - [ ] Add token estimation function for debugging
  - [ ] Export constants for thresholds (make tunable)

### 1.2 CSV Wrapper Implementation
- [ ] Create `utils/csvWrapper.ts`
  - [ ] `convertToCSV(rows: any[], columns: string[]): string`
    - Handle null values (empty string)
    - Escape commas in string values
    - Consistent number formatting
  - [ ] CSV wrapper response format:
    ```typescript
    {
      format: 'csv',
      columns: string[],
      csv_data: string,
      column_groups?: Record<string, string[]>,  // Optional categorization
      legend: Record<string, string>,
      summary?: string  // Human-readable summary
    }
    ```

### 1.3 Update Existing Tools
- [ ] Modify `searchSimilarPlayers()` to use smart formatting
  - Expected: 10-20 rows → use CSV wrapper
- [ ] Modify `getPlayerSeasons()` to use CSV wrapper
  - Expected: 5-20 rows → use CSV wrapper
- [ ] Keep `getCareerSummary()` as pure JSON
  - Always 1 row of aggregates
- [ ] Keep `getPlayerStats()` (single season) as pure JSON
  - Always 1 row

---

## 2. Variable Detail Levels

### 2.1 Column Set Definitions
- [ ] Create `config/statColumns.ts` with tiered column sets
  - [ ] **Summary** (12 columns):
    ```typescript
    ['player_name', 'year', 'age', 'team', 'position', 'pa',
     'war', 'wrc_plus', 'hr', 'avg', 'obp', 'slg']
    ```
  - [ ] **Standard** (20 columns):
    ```typescript
    // Summary + advanced hitting + grades
    [...summary,
     'iso', 'babip', 'bb_pct', 'k_pct', 'woba',
     'overall_grade', 'power_grade', 'hit_grade', 'speed_grade', 'fielding_grade',
     'sb', 'rbi', 'r']
    ```
  - [ ] **Full** (60+ columns):
    ```typescript
    // Standard + batted ball + discipline + Statcast + WAR components
    [...standard,
     'gb_pct', 'fb_pct', 'ld_pct', 'pull_pct', 'hard_pct',
     'o_swing_pct', 'z_swing_pct', 'contact_pct', 'zone_pct',
     'ev', 'ev90', 'la', 'barrel_pct', 'maxev', 'hardhit_pct',
     'batting', 'fielding', 'baserunning', 'positional', 'rar',
     /* ... all other columns */]
    ```

### 2.2 Column Descriptions (Legends)
- [ ] Create `config/statDescriptions.ts`
  - [ ] Summary-level descriptions:
    ```typescript
    {
      war: "Wins Above Replacement (2=starter, 5=all-star, 8+=MVP)",
      wrc_plus: "Offensive production, era-adjusted (100=avg, 130+=elite)",
      hr: "Home Runs",
      avg: "Batting Average"
    }
    ```
  - [ ] Standard-level descriptions (adds to summary):
    ```typescript
    {
      iso: "Isolated Power (SLG-AVG, 0.200+=good, 0.250+=elite)",
      bb_pct: "Walk rate (10%+ elite discipline)",
      k_pct: "Strikeout rate (lower better, <20% elite)",
      overall_grade: "20-80 scouting scale (50=avg, 60=plus, 70=elite)",
      power_grade: "Power tool grade (20-80 scale)"
    }
    ```
  - [ ] Full-level descriptions (adds to standard):
    ```typescript
    {
      barrel_pct: "Optimal contact quality (8%+ elite)",
      o_swing_pct: "Chase rate - swings outside zone (lower better)",
      ev90: "90th percentile exit velocity (>100 mph excellent)",
      gb_pct: "Ground ball percentage",
      batting: "Batting runs above average (WAR component)"
    }
    ```

### 2.3 Update Tool Parameters
- [ ] Add `detailLevel` parameter to `getPlayerStats()`
  ```typescript
  async function getPlayerStats(
    playerName: string,
    year: number,
    detailLevel: 'summary' | 'standard' | 'full' = 'standard'
  )
  ```
- [ ] Add `detailLevel` parameter to `getPlayerSeasons()`
- [ ] Update tool definitions in Ollama integration
  ```typescript
  {
    name: "get_player_stats",
    description: `
      Get player statistics for a specific season.
      
      Detail levels:
      - summary: Core stats (WAR, wRC+, AVG, HR) - 12 columns
      - standard: Common analysis stats with grades - 20 columns [DEFAULT]
      - full: Everything (batted ball, Statcast, WAR breakdown) - 60+ columns
      
      Returns JSON for summary/standard, CSV for full (token efficiency).
    `,
    parameters: {
      player_name: { type: "string" },
      year: { type: "integer" },
      detail_level: {
        type: "string",
        enum: ["summary", "standard", "full"],
        default: "standard"
      }
    }
  }
  ```

### 2.4 Dynamic Column Selection
- [ ] Modify database queries to select columns dynamically
  ```typescript
  const columns = STAT_COLUMNS[detailLevel];
  const query = `
    SELECT ${columns.join(', ')}
    FROM fg_season_stats s
    JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
    WHERE p.player_name = $1 AND s.year = $2
  `;
  ```
- [ ] Handle missing columns gracefully (e.g., Statcast data pre-2015)
  - Return null for unavailable stats
  - Note in response: `"statcast_available": false`

---

## 3. Progressive Disclosure (Upgrade Hints)

### 3.1 Availability Hints in Responses
- [ ] Add `available_upgrades` field to summary/standard responses
  ```typescript
  {
    player: "Mike Trout",
    year: 2019,
    detail_level: "summary",
    data: { /* ... */ },
    legend: { /* ... */ },
    
    // Hint about what else is available
    available_upgrades: {
      standard: "Adds grades, ISO, BB%/K%, BABIP (8 more stats)",
      full: "Adds batted ball, Statcast, WAR components (50+ more stats)"
    }
  }
  ```
- [ ] For 'standard' level, only show 'full' upgrade option
- [ ] For 'full' level, omit upgrade hints (already at max)

### 3.2 Missing Data Notifications
- [ ] Check for Statcast availability (2015+)
  ```typescript
  if (year < 2015 && detailLevel === 'full') {
    return {
      /* ... */,
      warnings: [
        "Statcast metrics (barrel%, EV, launch angle) unavailable before 2015"
      ],
      statcast_available: false
    }
  }
  ```
- [ ] Note when pitch-level data is unavailable
- [ ] Suggest alternative stats for older eras

---

## 4. Column Grouping for Wide Tables

### 4.1 Define Stat Categories
- [ ] Create `config/statCategories.ts`
  ```typescript
  export const STAT_CATEGORY_MAPPINGS = {
    core: ['pa', 'war', 'wrc_plus', 'avg', 'obp', 'slg'],
    power: ['hr', 'iso', 'barrel_pct', 'ev90', 'maxev', 'power_grade'],
    contact: ['avg', 'k_pct', 'contact_pct', 'babip', 'hit_grade'],
    discipline: ['bb_pct', 'o_swing_pct', 'z_swing_pct', 'zone_pct', 'discipline_grade'],
    batted_ball: ['gb_pct', 'fb_pct', 'ld_pct', 'pull_pct', 'hard_pct'],
    speed: ['sb', 'cs', 'speed_grade'],
    defense: ['position', 'fielding', 'defense', 'fielding_grade'],
    statcast: ['ev', 'ev90', 'la', 'barrel_pct', 'barrels', 'maxev', 'hardhit_pct'],
    war_components: ['batting', 'fielding', 'baserunning', 'positional', 'rar']
  };
  ```

### 4.2 Include Category Mappings in CSV Responses
- [ ] Add `column_groups` to 'full' detail responses
  ```typescript
  {
    format: 'csv',
    columns: [...all 60 columns...],
    column_groups: STAT_CATEGORY_MAPPINGS,  // Helps LLM parse sections
    csv_data: "...",
    legend: { /* ... */ }
  }
  ```
- [ ] This helps LLM understand semantic groupings in wide CSV data

---

## 5. Contextual Annotations

### 5.1 Season Note Generation
- [ ] Create `utils/generateSeasonNote.ts`
  - [ ] Detect MVP/award seasons (check if war > 8 and wrc_plus > 160)
  - [ ] Note rookie seasons (check if year == first_season)
  - [ ] Flag injury-shortened seasons (PA < 400)
  - [ ] Highlight league-leading stats
  - [ ] Examples:
    ```typescript
    "AL MVP, led league in AVG/SLG, Gold Glove RF"
    "Rookie season, 30 HR in 550 PA"
    "Injury-shortened (387 PA)"
    "Career-high 50 HR, led MLB"
    ```

### 5.2 Era Context
- [ ] Add era markers for historical context
  ```typescript
  {
    year: 2000,
    era_context: "Steroid Era - inflated offense league-wide",
    league_environment: "High scoring environment"
  }
  ```
- [ ] Flag dead-ball era (pre-1920)
- [ ] Flag steroid era (1994-2007)
- [ ] Flag modern Statcast era (2015+)

### 5.3 Style Notes for Unusual Players
- [ ] Detect and annotate player archetypes
  ```typescript
  // Contact hitter with low power
  if (avg > 0.300 && hr < 10) {
    style_note: "Contact hitter, not power. Elite speed..."
  }
  
  // Three-true-outcomes hitter
  if (bb_pct > 15 && k_pct > 25 && hr > 30) {
    style_note: "Three-true-outcomes profile: walks, strikeouts, power"
  }
  ```

---

## 6. Comparison Tool Enhancements

### 6.1 Pre-computed Insights
- [ ] Modify `comparePlayersQuery()` to calculate key differences
  ```typescript
  {
    comparison: {
      player1: { /* stats */ },
      player2: { /* stats */ },
      key_differences: [
        {
          stat: 'war_per_650',
          player1_value: 9.1,
          player2_value: 6.2,
          advantage: 'player1',
          magnitude: 'large',  // large if >30% diff, medium if 15-30%, small if <15%
          interpretation: "Trout's per-season peak was significantly higher"
        }
      ]
    }
  }
  ```
- [ ] Highlight stats where difference > 20%
- [ ] Flag inverted stats (K% - lower is better)

### 6.2 Statistical Significance Flags
- [ ] Note when differences are meaningful vs noise
  - Large: >30% difference or >15 grade points
  - Medium: 15-30% difference or 10-15 grade points
  - Small: <15% difference

---

## 7. Token Efficiency Optimizations

### 7.1 Measure and Log Token Usage
- [ ] Add token counting utility
  ```typescript
  function estimateTokens(text: string): number {
    // Rough estimate: ~4 chars per token
    return Math.ceil(text.length / 4);
  }
  ```
- [ ] Log token usage per tool call (for monitoring)
- [ ] Track JSON vs CSV savings

### 7.2 Conditional Legend Inclusion
- [ ] For CSV responses with 50+ columns, only include legends for categories
  ```typescript
  // Instead of 50 individual stat descriptions:
  legend: {
    _note: "Full descriptions available at detail_level='standard'",
    core: "PA, WAR, wRC+, slash line",
    statcast: "Barrel%, exit velo, launch angle (2015+)",
    batted_ball: "GB%, FB%, LD%, pull%, hard%"
  }
  ```
- [ ] Full legends only for summary/standard levels

---

## 8. Testing & Validation

### 8.1 Format Selection Tests
- [ ] Test that single-season queries use JSON
- [ ] Test that multi-season queries use CSV wrapper
- [ ] Test that 'full' detail level uses CSV wrapper
- [ ] Verify token savings (CSV should be ~40-50% fewer tokens)

### 8.2 Detail Level Tests
- [ ] Test summary level returns 12 columns
- [ ] Test standard level returns 20 columns
- [ ] Test full level returns 60+ columns
- [ ] Test upgrade hints appear correctly

### 8.3 Edge Cases
- [ ] Test with pre-2015 seasons (no Statcast)
- [ ] Test with rookie seasons (first_season == year)
- [ ] Test with injury-shortened seasons (low PA)
- [ ] Test with players who have missing data

### 8.4 LLM Integration Tests
- [ ] Ask for player stats → verify LLM uses 'standard' by default
- [ ] Ask for "detailed stats" → verify LLM upgrades to 'full'
- [ ] Ask for "quick overview" → verify LLM uses 'summary'
- [ ] Ask follow-up "show me more detail" → verify LLM upgrades level

---

## 9. Documentation

### 9.1 Update Tool Definitions
- [ ] Document detail levels in tool descriptions
- [ ] Document response formats (JSON vs CSV)
- [ ] Include examples in tool descriptions
  ```typescript
  examples: [
    {
      input: { player_name: "Mike Trout", year: 2019, detail_level: "summary" },
      output: { /* example JSON response */ }
    },
    {
      input: { player_name: "Mike Trout", detail_level: "full" },
      output_note: "Returns CSV format with 60+ columns"
    }
  ]
  ```

### 9.2 Update Project Specification
- [ ] Document column set definitions (summary/standard/full)
- [ ] Document format selection logic (JSON vs CSV)
- [ ] Document token efficiency improvements
- [ ] Add to "Lessons Learned" section:
  - "CSV wrapper saves ~45% tokens for wide tables"
  - "Tiered detail levels prevent overwhelming LLM with data"
  - "Upgrade hints guide LLM to request more detail when needed"

### 9.3 Code Comments
- [ ] Add JSDoc comments to all utility functions
- [ ] Document why certain thresholds were chosen
- [ ] Link to this discussion in key files

---

## 10. Future Enhancements (Post-MVP+)

### 10.1 Category-Based Selection (Phase 2)
- [ ] Add `categories` parameter to tools
  ```typescript
  categories?: ('core' | 'power' | 'contact' | 'discipline' | 'statcast')[]
  ```
- [ ] Allow LLM to request specific stat categories
- [ ] Example: "Show me power and Statcast metrics"

### 10.2 GraphQL-Style Field Selection (Phase 3)
- [ ] Add `fields` parameter for custom column selection
  ```typescript
  fields?: string[]  // ['war', 'hr', 'barrel_pct', 'ev90']
  ```
- [ ] Validate requested fields exist
- [ ] Return error with available fields if invalid

### 10.3 Adaptive Detail Levels
- [ ] LLM learns which detail level to use based on query
- [ ] Track which queries benefit from 'full' vs 'standard'
- [ ] Auto-suggest detail level based on query type

---

## Priority Order

**High Priority (Do First):**
1. Smart format selection (JSON vs CSV) - Section 1
2. Variable detail levels (summary/standard/full) - Section 2
3. Update tool parameters and definitions - Section 2.3, 2.4

**Medium Priority (MVP+):**
4. Progressive disclosure (upgrade hints) - Section 3
5. Column grouping for wide tables - Section 4
6. Contextual annotations - Section 5

**Lower Priority (Nice to Have):**
7. Comparison enhancements - Section 6
8. Token efficiency optimizations - Section 7
9. Category-based selection - Section 10.1

**Always:**
10. Testing & documentation - Sections 8, 9

---

## Estimated Effort

- **Sections 1-2:** ~6-8 hours (core formatting and detail levels)
- **Section 3:** ~2-3 hours (upgrade hints)
- **Section 4:** ~1-2 hours (column grouping)
- **Section 5:** ~3-4 hours (contextual annotations)
- **Section 8-9:** ~4-5 hours (testing and docs)

**Total: ~16-24 hours for high/medium priority items**

---

## Success Criteria

- [ ] LLM can request summary/standard/full detail levels
- [ ] Single-season queries return JSON (<300 tokens)
- [ ] Multi-season queries return CSV wrapper (~40% fewer tokens than JSON)
- [ ] Full detail level uses CSV wrapper (saves 500+ tokens vs JSON)
- [ ] Upgrade hints guide LLM to request more detail when appropriate
- [ ] Column legends are context-appropriate (brief for CSV, detailed for JSON)
- [ ] Pre-2015 seasons gracefully handle missing Statcast data
- [ ] All tools support detail level parameter
- [ ] Documentation updated in project spec

---

**Next Steps:** Start with Section 1 (format selection), then Section 2 (detail levels). These are the foundation for all other enhancements.