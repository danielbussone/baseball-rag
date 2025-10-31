# Phase 2.5: Percentile Rankings & Visualization - Implementation TODOs

**Status:** Ready to Begin (Post-MVP, requires Statcast data)  
**Estimated Time:** 2-3 weeks  
**Prerequisites:** ✅ MVP Complete, Phase 2.4 Statcast Data Integration

---

## Overview

This phase adds Baseball Savant-style percentile visualizations showing where players rank across key skills. Users asking "Tell me about Mookie Betts" will see both narrative summaries and color-coded percentile bars.

---

## Phase 2.5.1: Database & ETL (Week 1)

### A. Database Schema Changes

- [ ] **Create `stat_percentiles` table**
  ```sql
  CREATE TABLE stat_percentiles (
      id SERIAL PRIMARY KEY,
      stat_name VARCHAR(50) NOT NULL,
      year INTEGER NOT NULL,
      scope VARCHAR(20) NOT NULL, -- 'season', 'career', 'peak7'
      min_pa INTEGER NOT NULL,
      qualified_count INTEGER NOT NULL,
      
      -- Percentile thresholds
      p1 NUMERIC, p5 NUMERIC, p10 NUMERIC, p25 NUMERIC, p40 NUMERIC,
      p50 NUMERIC, p60 NUMERIC, p75 NUMERIC, p90 NUMERIC, p95 NUMERIC, p99 NUMERIC,
      
      -- Summary stats
      mean NUMERIC, stddev NUMERIC, min_value NUMERIC, max_value NUMERIC,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(stat_name, year, scope)
  );
  
  CREATE INDEX idx_stat_percentiles_lookup ON stat_percentiles(stat_name, year, scope);
  ```

- [ ] **Add percentile columns to `fg_season_stats`**
  ```sql
  ALTER TABLE fg_season_stats ADD COLUMN IF NOT EXISTS
      overall_percentile NUMERIC(5,2),
      offense_percentile NUMERIC(5,2),
      power_percentile NUMERIC(5,2),
      hit_percentile NUMERIC(5,2),
      discipline_percentile NUMERIC(5,2),
      contact_percentile NUMERIC(5,2),
      speed_percentile NUMERIC(5,2),
      fielding_percentile NUMERIC(5,2),
      hard_contact_percentile NUMERIC(5,2),
      exit_velo_percentile NUMERIC(5,2),
      barrel_percentile NUMERIC(5,2),
      chase_percentile NUMERIC(5,2);
  
  -- Indexes for percentile filtering
  CREATE INDEX idx_fg_season_overall_pct ON fg_season_stats(overall_percentile);
  CREATE INDEX idx_fg_season_power_pct ON fg_season_stats(power_percentile);
  ```

- [ ] **Add temporary grade columns for evaluation**
  ```sql
  ALTER TABLE fg_season_stats ADD COLUMN IF NOT EXISTS
      power_grade_pct INTEGER,  -- Percentile-based grades
      power_grade_sd INTEGER,   -- Standard deviation-based grades
      hit_grade_pct INTEGER,
      hit_grade_sd INTEGER;
      -- (repeat for all grade types)
  ```

### B. R ETL Enhancements

- [ ] **Create `calculate_percentiles.R` script**
  - [ ] Function: `calculate_season_percentiles(season_stats, min_pa = 502)`
    - Filter to qualified players (PA >= min_pa)
    - Group by year
    - Calculate p1, p5, p10, p25, p40, p50, p60, p75, p90, p95, p99 for each stat
    - Store mean, stddev, min, max
    - Return tibble with percentile thresholds
  
  - [ ] Function: `calculate_career_percentiles(season_stats, min_pa = 3000)`
    - Group by player (fangraphs_id)
    - Calculate weighted career averages (weighted by PA)
    - Filter to players with total PA >= min_pa
    - Calculate percentiles from career averages
    - Return tibble with percentile thresholds (year = 0)
  
  - [ ] Function: `calculate_peak7_percentiles(season_stats, min_pa = 3500)`
    - For each player, calculate 7-year rolling averages
    - Find best 7-year window (highest WAR)
    - Filter to players with 7-year total PA >= min_pa
    - Calculate percentiles from peak windows
    - Return tibble with percentile thresholds (year = 0)

- [ ] **Stats to track** (add to ETL config)
  ```r
  stats_for_percentiles <- c(
    # Overall
    "war", "wrc_plus",
    
    # Power
    "iso", "hr", "barrel_pct", "ev90", "hard_pct", "maxev",
    
    # Plate Discipline  
    "bb_pct", "k_pct", "o_swing_pct", "swstr_pct",
    
    # Contact
    "avg", "contact_pct", "z_contact_pct",
    
    # Speed
    "sb", "sprint_speed", "bolts"
  )
  ```

- [ ] **Upsert percentiles to database**
  ```r
  upsert_percentiles <- function(percentiles_df, scope) {
    dbExecute(con, "
      INSERT INTO stat_percentiles 
        (stat_name, year, scope, min_pa, qualified_count, 
         p1, p5, p10, p25, p40, p50, p60, p75, p90, p95, p99,
         mean, stddev, min_value, max_value)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (stat_name, year, scope) 
      DO UPDATE SET ...
    ")
  }
  ```

- [ ] **Validate percentile distributions**
  ```r
  validate_percentiles <- function(percentiles_df) {
    # Check that percentiles are monotonically increasing
    # Verify p50 is close to mean (for normal distributions)
    # Check that qualified_count is reasonable
    # Print summary for manual review
  }
  ```

### C. Player Percentile Calculation

- [ ] **Function: `interpolate_percentile(value, percentile_thresholds)`**
  ```r
  # Given player's stat value and percentile thresholds for that stat/year
  # Return the player's percentile (0-100)
  # Use linear interpolation between stored thresholds
  # Handle edge cases (value < p1 or value > p99)
  ```

- [ ] **Calculate percentiles for all players**
  ```r
  season_stats_with_percentiles <- season_stats %>%
    left_join(stat_percentiles, by = c("year", ...)) %>%
    rowwise() %>%
    mutate(
      power_percentile = interpolate_percentile(iso, iso_percentiles),
      hit_percentile = interpolate_percentile(avg, avg_percentiles),
      # ... for all stats
    )
  ```

- [ ] **Handle inverse stats (K%, Chase%)**
  ```r
  # For "lower is better" stats, invert percentile
  # If player has 20% K rate at p40 (worse than 40% of players)
  # Store as "better_than_percentile" = 60
  ```

### D. Grade Calculation - Two Methods

- [ ] **Implement percentile-based grade calculation**
  ```r
  percentile_to_grade_pct <- function(percentile) {
    case_when(
      percentile >= 99 ~ 80,
      percentile >= 95 ~ 75,
      percentile >= 90 ~ 70,
      percentile >= 80 ~ 65,
      percentile >= 75 ~ 60,
      percentile >= 60 ~ 55,
      percentile >= 50 ~ 50,
      percentile >= 40 ~ 45,
      percentile >= 25 ~ 40,
      percentile >= 15 ~ 35,
      percentile >= 10 ~ 30,
      percentile >= 5 ~ 25,
      TRUE ~ 20
    )
  }
  ```

- [ ] **Implement SD-based grade calculation**
  ```r
  percentile_to_grade_sd <- function(percentile) {
    case_when(
      percentile >= 99.7 ~ 80,  # μ + 3σ
      percentile >= 97.7 ~ 70,  # μ + 2σ
      percentile >= 84.1 ~ 60,  # μ + 1σ
      percentile >= 69.1 ~ 55,  # μ + 0.5σ
      percentile >= 50.0 ~ 50,  # μ
      percentile >= 30.9 ~ 45,  # μ - 0.5σ
      percentile >= 15.9 ~ 40,  # μ - 1σ
      percentile >= 2.3 ~ 30,   # μ - 2σ
      TRUE ~ 20
    )
  }
  ```

- [ ] **Calculate both grade sets for comparison**
  ```r
  season_stats_with_grades <- season_stats_with_percentiles %>%
    mutate(
      # Percentile-based grades
      power_grade_pct = percentile_to_grade_pct(power_percentile),
      hit_grade_pct = percentile_to_grade_pct(hit_percentile),
      
      # SD-based grades
      power_grade_sd = percentile_to_grade_sd(power_percentile),
      hit_grade_sd = percentile_to_grade_sd(hit_percentile),
      
      # ... for all stats
    )
  ```

### E. Validation & Analysis

- [ ] **Test normality of each stat**
  ```r
  library(moments)
  
  test_stat_normality <- function(stat_data) {
    shapiro_test <- shapiro.test(sample(stat_data, min(5000, length(stat_data))))
    skewness_val <- skewness(stat_data, na.rm = TRUE)
    kurtosis_val <- kurtosis(stat_data, na.rm = TRUE)
    
    tibble(
      is_normal = shapiro_test$p.value > 0.05,
      skewness = skewness_val,
      kurtosis = kurtosis_val
    )
  }
  ```

- [ ] **Compare grade distributions**
  ```r
  grade_comparison <- season_stats_with_grades %>%
    summarise(
      # Percentile approach
      pct_70plus_pct = mean(power_grade_pct >= 70, na.rm = TRUE),
      pct_60plus_pct = mean(power_grade_pct >= 60, na.rm = TRUE),
      
      # SD approach
      pct_70plus_sd = mean(power_grade_sd >= 70, na.rm = TRUE),
      pct_60plus_sd = mean(power_grade_sd >= 60, na.rm = TRUE)
    )
  
  # Expected: pct_70plus_pct ≈ 10%, pct_70plus_sd ≈ 2.3%
  ```

- [ ] **Eye test with known players**
  ```r
  # Check grades for peak Bonds, Trout, etc.
  # Do they feel right?
  test_players <- c("Barry Bonds", "Mike Trout", "Aaron Judge")
  ```

- [ ] **Decide final methodology**
  - [ ] Analyze which approach gives more "accurate" grades
  - [ ] Consider hybrid: SD for normal stats, percentile for skewed
  - [ ] Document decision with data/rationale
  - [ ] Drop temporary grade columns, keep chosen method
  - [ ] Update `power_grade`, `hit_grade` etc. with final values

- [ ] **Re-run full ETL to backfill all seasons**

---

## Phase 2.5.2: Backend API (Week 1-2)

### A. Percentile Calculation Service

- [ ] **Create `src/services/percentileService.ts`**
  ```typescript
  interface PercentileThresholds {
    stat_name: string;
    year: number;
    scope: 'season' | 'career' | 'peak7';
    p1: number;
    p5: number;
    // ... through p99
    mean: number;
    stddev: number;
  }
  
  class PercentileService {
    async getThresholds(
      statName: string, 
      year: number, 
      scope: string
    ): Promise<PercentileThresholds>;
    
    calculatePercentile(
      value: number, 
      thresholds: PercentileThresholds
    ): number;
  }
  ```

- [ ] **Implement linear interpolation**
  ```typescript
  calculatePercentile(value: number, thresholds: PercentileThresholds): number {
    // Handle edge cases
    if (value <= thresholds.p1) return 1;
    if (value >= thresholds.p99) return 99;
    
    // Binary search or linear interpolation
    const percentiles = [1, 5, 10, 25, 40, 50, 60, 75, 90, 95, 99];
    const values = [thresholds.p1, thresholds.p5, /* ... */, thresholds.p99];
    
    // Find bracketing percentiles
    // Linear interpolate between them
    return interpolatedPercentile;
  }
  ```

- [ ] **Add caching for percentile thresholds**
  ```typescript
  // Percentiles rarely change, cache in memory
  private thresholdsCache = new Map<string, PercentileThresholds>();
  ```

### B. LLM Tools

- [ ] **Tool: `get_player_percentiles`**
  ```typescript
  {
    name: "get_player_percentiles",
    description: "Get percentile rankings for a player's stats, showing where they rank compared to other players",
    parameters: {
      type: "object",
      properties: {
        player_name: {
          type: "string",
          description: "Player's full name"
        },
        year: {
          type: "number",
          description: "Season year (defaults to most recent)"
        },
        scope: {
          type: "string",
          enum: ["season", "career", "peak7"],
          description: "Percentile scope: season (single year), career (entire career), peak7 (best 7 years)"
        }
      },
      required: ["player_name"]
    }
  }
  ```

- [ ] **Implement tool handler**
  ```typescript
  async function handleGetPlayerPercentiles(args: {
    player_name: string;
    year?: number;
    scope?: 'season' | 'career' | 'peak7';
  }) {
    // 1. Fetch player stats from database
    const stats = await db.getPlayerStats(args.player_name, args.year);
    
    // 2. Get percentile thresholds
    const scope = args.scope || 'season';
    const year = args.year || stats.year;
    
    // 3. Calculate percentiles for each stat
    const percentiles = [];
    for (const stat of STATS_TO_SHOW) {
      const thresholds = await percentileService.getThresholds(stat, year, scope);
      const percentile = percentileService.calculatePercentile(
        stats[stat], 
        thresholds
      );
      
      percentiles.push({
        stat,
        display_name: STAT_DISPLAY_NAMES[stat],
        category: STAT_CATEGORIES[stat],
        value: stats[stat],
        percentile,
        qualified: stats.pa >= thresholds.min_pa,
        color: getPercentileColor(percentile, isInverseStat(stat)),
        inverse: isInverseStat(stat)
      });
    }
    
    return {
      player: args.player_name,
      year,
      scope,
      pa: stats.pa,
      percentiles
    };
  }
  ```

- [ ] **Tool: `compare_player_percentiles`**
  ```typescript
  {
    name: "compare_player_percentiles",
    description: "Compare percentile rankings of two players side-by-side",
    parameters: {
      player1: string,
      player2: string,
      scope?: 'season' | 'career' | 'peak7'
    }
  }
  ```

- [ ] **Implement comparison handler**
  ```typescript
  async function handleComparePlayerPercentiles(args: {
    player1: string;
    player2: string;
    scope?: string;
  }) {
    const p1 = await handleGetPlayerPercentiles({ 
      player_name: args.player1, 
      scope: args.scope 
    });
    const p2 = await handleGetPlayerPercentiles({ 
      player_name: args.player2, 
      scope: args.scope 
    });
    
    // Calculate differences, highlight biggest gaps
    const comparison = p1.percentiles.map((stat1, i) => {
      const stat2 = p2.percentiles[i];
      return {
        ...stat1,
        player2_percentile: stat2.percentile,
        difference: Math.abs(stat1.percentile - stat2.percentile),
        advantage: stat1.percentile > stat2.percentile ? args.player1 : args.player2
      };
    });
    
    return { player1: p1, player2: p2, comparison };
  }
  ```

### C. Stat Configuration

- [ ] **Create `src/config/percentileStats.ts`**
  ```typescript
  export const PERCENTILE_STATS = [
    // Power
    { stat: 'barrel_pct', display: 'Barrel %', category: 'Power', inverse: false },
    { stat: 'iso', display: 'ISO', category: 'Power', inverse: false },
    { stat: 'ev90', display: 'Exit Velo (90th)', category: 'Power', inverse: false },
    { stat: 'hard_pct', display: 'Hard Hit %', category: 'Power', inverse: false },
    
    // Plate Discipline
    { stat: 'bb_pct', display: 'BB%', category: 'Plate Discipline', inverse: false },
    { stat: 'k_pct', display: 'K%', category: 'Plate Discipline', inverse: true },
    { stat: 'o_swing_pct', display: 'Chase %', category: 'Plate Discipline', inverse: true },
    { stat: 'swstr_pct', display: 'Whiff %', category: 'Plate Discipline', inverse: true },
    
    // Contact
    { stat: 'avg', display: 'Batting Avg', category: 'Contact', inverse: false },
    { stat: 'contact_pct', display: 'Contact %', category: 'Contact', inverse: false },
    
    // Speed
    { stat: 'sprint_speed', display: 'Sprint Speed', category: 'Speed', inverse: false },
    { stat: 'sb', display: 'Stolen Bases', category: 'Speed', inverse: false },
    
    // Overall
    { stat: 'wrc_plus', display: 'wRC+', category: 'Overall', inverse: false },
    { stat: 'war', display: 'WAR', category: 'Overall', inverse: false }
  ];
  
  export function isInverseStat(stat: string): boolean {
    return ['k_pct', 'o_swing_pct', 'swstr_pct'].includes(stat);
  }
  
  export function getPercentileColor(percentile: number, inverse: boolean): string {
    // Blue (poor) → Gray (average) → Red (elite)
    // Invert for "lower is better" stats
    const adjusted = inverse ? (100 - percentile) : percentile;
    
    if (adjusted >= 90) return '#ef4444'; // red-500
    if (adjusted >= 75) return '#f97316'; // orange-500
    if (adjusted >= 60) return '#eab308'; // yellow-500
    if (adjusted >= 40) return '#6b7280'; // gray-500
    if (adjusted >= 25) return '#60a5fa'; // blue-400
    return '#3b82f6'; // blue-500
  }
  ```

### D. API Routes

- [ ] **Add route: `POST /api/player-percentiles`**
  ```typescript
  app.post('/api/player-percentiles', async (req, res) => {
    const { player_name, year, scope } = req.body;
    const result = await handleGetPlayerPercentiles({ player_name, year, scope });
    res.json(result);
  });
  ```

- [ ] **Add route: `POST /api/compare-percentiles`**

---

## Phase 2.5.3: Frontend Visualization (Week 2)

### A. React Component Structure

- [ ] **Create `components/PercentileProfile.tsx`**
  ```tsx
  interface PercentileData {
    stat: string;
    display_name: string;
    category: string;
    value: number;
    percentile: number;
    qualified: boolean;
    color: string;
    inverse: boolean;
  }
  
  interface PercentileProfileProps {
    player: string;
    year: number;
    scope: 'season' | 'career' | 'peak7';
    percentiles: PercentileData[];
    pa: number;
    minPA: number;
  }
  ```

- [ ] **Component: `<PercentileBar>`**
  ```tsx
  interface PercentileBarProps {
    stat: PercentileData;
    showTooltip?: boolean;
  }
  
  function PercentileBar({ stat, showTooltip = true }: PercentileBarProps) {
    const [isHovered, setIsHovered] = useState(false);
    
    return (
      <div className="percentile-bar-container">
        <div className="stat-label">
          {stat.display_name}
          {!stat.qualified && <span className="text-gray-400">*</span>}
        </div>
        
        <div 
          className="percentile-bar-track"
          onMouseEnter={() => setIsHovered(true)}
          onMouseLeave={() => setIsHovered(false)}
        >
          <div 
            className="percentile-bar-fill"
            style={{
              width: `${stat.percentile}%`,
              backgroundColor: stat.color,
              opacity: stat.qualified ? 1 : 0.5
            }}
          />
        </div>
        
        {isHovered && showTooltip && (
          <PercentileTooltip stat={stat} />
        )}
      </div>
    );
  }
  ```

- [ ] **Component: `<PercentileTooltip>`**
  ```tsx
  function PercentileTooltip({ stat }: { stat: PercentileData }) {
    const displayPercentile = stat.inverse 
      ? `Better than ${100 - stat.percentile}%`
      : `${stat.percentile}th percentile`;
    
    return (
      <div className="tooltip">
        <div className="font-semibold">{stat.display_name}</div>
        <div>Value: {stat.value.toFixed(1)}</div>
        <div>{displayPercentile}</div>
        {!stat.qualified && (
          <div className="text-xs text-gray-400">
            Below minimum PA for official ranking
          </div>
        )}
      </div>
    );
  }
  ```

- [ ] **Component: `<PercentileProfile>` (Main)**
  ```tsx
  function PercentileProfile({ player, year, scope, percentiles, pa, minPA }: PercentileProfileProps) {
    // Group percentiles by category
    const grouped = groupBy(percentiles, 'category');
    
    return (
      <div className="percentile-profile">
        <div className="header">
          <h3>{player} - {year}</h3>
          <div className="scope-badge">{scope}</div>
          {pa < minPA && (
            <div className="warning">
              * Below minimum {minPA} PA for official ranking (has {pa} PA)
            </div>
          )}
        </div>
        
        {Object.entries(grouped).map(([category, stats]) => (
          <div key={category} className="category-section">
            <h4>{category}</h4>
            {stats.map(stat => (
              <PercentileBar key={stat.stat} stat={stat} />
            ))}
          </div>
        ))}
        
        <PercentileLegend />
      </div>
    );
  }
  ```

- [ ] **Component: `<PercentileLegend>`**
  ```tsx
  function PercentileLegend() {
    return (
      <div className="legend">
        <div className="gradient-bar" />
        <div className="legend-labels">
          <span>1st (Poor)</span>
          <span>50th (Avg)</span>
          <span>99th (Elite)</span>
        </div>
      </div>
    );
  }
  ```

### B. Styling

- [ ] **Create `styles/percentileProfile.css`**
  ```css
  .percentile-profile {
    padding: 1.5rem;
    background: white;
    border-radius: 0.5rem;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  }
  
  .category-section {
    margin-bottom: 1.5rem;
  }
  
  .category-section h4 {
    font-size: 0.875rem;
    font-weight: 600;
    color: #6b7280;
    text-transform: uppercase;
    margin-bottom: 0.5rem;
  }
  
  .percentile-bar-container {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 0.75rem;
    position: relative;
  }
  
  .stat-label {
    width: 120px;
    font-size: 0.875rem;
    font-weight: 500;
  }
  
  .percentile-bar-track {
    flex: 1;
    height: 24px;
    background: #f3f4f6;
    border-radius: 4px;
    position: relative;
    overflow: hidden;
    cursor: pointer;
  }
  
  .percentile-bar-fill {
    height: 100%;
    transition: width 0.6s ease-out;
    border-radius: 4px;
  }
  
  .gradient-bar {
    height: 24px;
    background: linear-gradient(
      to right,
      #3b82f6 0%,    /* blue (1st) */
      #6b7280 50%,   /* gray (50th) */
      #ef4444 100%   /* red (99th) */
    );
    border-radius: 4px;
    margin-bottom: 0.5rem;
  }
  
  .tooltip {
    position: absolute;
    bottom: 100%;
    left: 50%;
    transform: translateX(-50%);
    background: #1f2937;
    color: white;
    padding: 0.5rem 0.75rem;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    white-space: nowrap;
    pointer-events: none;
    z-index: 10;
  }
  ```

- [ ] **Add animations**
  ```css
  @keyframes fillBar {
    from { width: 0; }
    to { width: var(--target-width); }
  }
  
  .percentile-bar-fill {
    animation: fillBar 0.6s ease-out;
  }
  ```

### C. Two-Player Comparison

- [ ] **Component: `<PercentileComparison>`**
  ```tsx
  function PercentileComparison({ player1, player2, comparison }: ComparisonProps) {
    return (
      <div className="percentile-comparison">
        <div className="comparison-header">
          <div>{player1.player}</div>
          <div>vs</div>
          <div>{player2.player}</div>
        </div>
        
        {comparison.map(stat => (
          <div key={stat.stat} className="comparison-row">
            <div className="player1-bar">
              <PercentileBar stat={stat} />
            </div>
            
            <div className="stat-name">{stat.display_name}</div>
            
            <div className="player2-bar">
              <PercentileBar stat={stat.player2_percentile} />
            </div>
            
            {stat.difference > 20 && (
              <div className="advantage-badge">
                {stat.advantage} +{stat.difference}
              </div>
            )}
          </div>
        ))}
      </div>
    );
  }
  ```

### D. Integration with Chat

- [ ] **Update chat response handler**
  ```tsx
  function ChatMessage({ message }: { message: Message }) {
    const hasPercentiles = message.tool_calls?.some(
      call => call.name === 'get_player_percentiles'
    );
    
    return (
      <div className="chat-message">
        <div className="narrative">{message.content}</div>
        
        {hasPercentiles && (
          <PercentileProfile 
            {...message.percentile_data} 
          />
        )}
      </div>
    );
  }
  ```

- [ ] **Add loading state**
  ```tsx
  {isLoadingPercentiles && (
    <div className="percentile-skeleton">
      {Array.from({ length: 12 }).map((_, i) => (
        <div key={i} className="skeleton-bar" />
      ))}
    </div>
  )}
  ```

---

## Phase 2.5.4: LLM Integration (Week 2)

### A. Smart Triggering

- [ ] **Update LLM system prompt**
  ```
  You have access to percentile visualization tools. Use these tools when:
  - User asks "Tell me about [player]"
  - User asks "Compare [player1] and [player2]"  
  - User asks about a player's strengths/weaknesses
  - User asks if a player is elite at a skill
  
  Always call get_player_percentiles for single player queries.
  Always call compare_player_percentiles for comparison queries.
  ```

- [ ] **Add percentile context to prompts**
  ```typescript
  const systemPrompt = `
  When you receive percentile data:
  - Highlight elite skills (90th+ percentile)
  - Note weaknesses (30th- percentile)
  - Use specific percentiles in your response
  - For comparisons, focus on biggest differences (>20 percentile points)
  
  Example: "Betts ranks in the 92nd percentile for barrel rate, 
  demonstrating elite power. However, his chase rate is concerning 
  at just the 28th percentile."
  `;
  ```

### B. Response Templates

- [ ] **Create percentile response helpers**
  ```typescript
  function getSkillDescription(percentile: number): string {
    if (percentile >= 95) return "elite";
    if (percentile >= 90) return "plus-plus";
    if (percentile >= 75) return "plus";
    if (percentile >= 60) return "above-average";
    if (percentile >= 40) return "average";
    if (percentile >= 25) return "below-average";
    if (percentile >= 10) return "fringe";
    return "poor";
  }
  
  function formatPercentileStatement(stat: PercentileData): string {
    const skill = getSkillDescription(stat.percentile);
    
    if (stat.inverse) {
      // For K%, Chase%, etc. where lower is better
      const betterThan = 100 - stat.percentile;
      return `${stat.display_name}: ${stat.value.toFixed(1)}% (better than ${betterThan}% of players - ${skill})`;
    }
    
    return `${stat.display_name}: ${stat.value.toFixed(1)} (${stat.percentile}th percentile - ${skill})`;
  }
  ```

- [ ] **Add to tool response**
  ```typescript
  // Include narrative hints in tool response
  return {
    player: args.player_name,
    percentiles,
    narrative_hints: {
      strengths: percentiles
        .filter(p => p.percentile >= 90)
        .map(p => formatPercentileStatement(p)),
      weaknesses: percentiles
        .filter(p => p.percentile <= 30)
        .map(p => formatPercentileStatement(p)),
      notable: percentiles
        .filter(p => p.percentile >= 75 || p.percentile <= 25)
        .sort((a, b) => Math.abs(50 - b.percentile) - Math.abs(50 - a.percentile))
    }
  };
  ```

### C. Contextual Usage

- [ ] **Career vs Season vs Peak7 logic**
  ```typescript
  // LLM should choose scope based on query context
  const scopeSelection = {
    "Tell me about Mookie Betts": "season", // Current form
    "How good was prime Barry Bonds?": "peak7", // Peak performance
    "Compare Mike Trout and Ken Griffey Jr careers": "career", // All-time
    "Is Aaron Judge having an elite season?": "season", // Current
  };
  ```

- [ ] **Multi-turn conversation support**
  ```typescript
  // Remember scope from previous turn
  if (previousTurn?.scope) {
    defaultScope = previousTurn.scope;
  }
  ```

---

## Phase 2.5.5: Testing & Validation (Week 2-3)

### A. Unit Tests

- [ ] **Test percentile calculation**
  ```typescript
  describe('PercentileService', () => {
    it('should interpolate percentiles correctly', () => {
      const thresholds = {
        p25: 10, p50: 20, p75: 30
      };
      expect(service.calculatePercentile(15, thresholds)).toBe(37.5);
    });
    
    it('should handle edge cases', () => {
      expect(service.calculatePercentile(-5, thresholds)).toBe(1);
      expect(service.calculatePercentile(999, thresholds)).toBe(99);
    });
    
    it('should handle inverse stats correctly', () => {
      // Lower K% should give higher percentile
    });
  });
  ```

- [ ] **Test grade calculation**
  ```typescript
  describe('Grade calculation', () => {
    it('should match percentile targets', () => {
      expect(percentileToGrade(90)).toBe(70); // Percentile method
      expect(percentileToGradeSD(97.7)).toBe(70); // SD method
    });
  });
  ```

### B. Integration Tests

- [ ] **Test end-to-end flow**
  ```typescript
  it('should return percentiles for player query', async () => {
    const response = await chatAPI.send("Tell me about Mike Trout");
    
    expect(response.tool_calls).toContainEqual({
      name: 'get_player_percentiles',
      args: { player_name: 'Mike Trout' }
    });
    
    expect(response.percentile_data).toBeDefined();
    expect(response.percentile_data.percentiles).toHaveLength(12);
  });
  ```

- [ ] **Test comparison flow**
  ```typescript
  it('should compare two players', async () => {
    const response = await chatAPI.send("Compare Mike Trout and Shohei Ohtani");
    
    expect(response.tool_calls).toContainEqual({
      name: 'compare_player_percentiles'
    });
  });
  ```

### C. Data Quality Validation

- [ ] **Verify percentile distributions**
  ```sql
  -- Check that percentiles are reasonable
  SELECT 
    stat_name,
    year,
    scope,
    qualified_count,
    p50,
    mean,
    ABS(p50 - mean) as median_mean_diff
  FROM stat_percentiles
  WHERE ABS(p50 - mean) > 5 -- Flag large discrepancies
  ORDER BY median_mean_diff DESC;
  ```

- [ ] **Check grade distributions**
  ```sql
  -- Verify that ~10% of players have 70+ grades (percentile method)
  SELECT 
    COUNT(CASE WHEN power_grade >= 70 THEN 1 END) * 100.0 / COUNT(*) as pct_70_plus,
    COUNT(CASE WHEN power_grade >= 60 THEN 1 END) * 100.0 / COUNT(*) as pct_60_plus
  FROM fg_season_stats
  WHERE pa >= 502 AND year >= 2015;
  
  -- Expected: ~10% for 70+, ~25% for 60+ (percentile method)
  -- Expected: ~2.3% for 70+, ~16% for 60+ (SD method)
  ```

- [ ] **Validate known players**
  ```sql
  -- Peak Barry Bonds (2001-2004) should have elite percentiles
  SELECT 
    player_name, year, 
    power_percentile, hit_percentile, discipline_percentile,
    power_grade, hit_grade, discipline_grade
  FROM fg_season_stats s
  JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
  WHERE player_name = 'Barry Bonds' 
    AND year BETWEEN 2001 AND 2004
  ORDER BY year;
  
  -- Should see 95-99th percentiles, 70-80 grades
  ```

### D. User Acceptance Testing

- [ ] **Test queries**
  - "Tell me about Mookie Betts" → Should show percentile visualization
  - "Compare Mike Trout and Aaron Judge" → Side-by-side bars
  - "Who's the best defensive shortstop?" → Search + percentiles for top result
  - "Is Shohei Ohtani elite at power?" → Narrative with power percentile

- [ ] **Visual testing**
  - [ ] Color gradient looks good
  - [ ] Bars animate smoothly
  - [ ] Tooltips appear on hover
  - [ ] Asterisks show for non-qualified players
  - [ ] Mobile responsive

- [ ] **Edge cases**
  - [ ] Player with <502 PA → Shows with asterisk, faded bars
  - [ ] Pre-Statcast era player → Missing barrel%, ev90, etc. gracefully
  - [ ] Invalid player name → Error handling
  - [ ] Multi-team season → Aggregates correctly

---

## Phase 2.5.6: Documentation & Deployment (Week 3)

### A. Code Documentation

- [ ] **Document percentile calculation methodology**
  ```typescript
  /**
   * Calculates a player's percentile for a given stat.
   * 
   * Methodology:
   * - Season scope: Percentiles from qualified players each year (min 502 PA)
   * - Career scope: Percentiles from career weighted averages (min 3000 PA)
   * - Peak7 scope: Percentiles from best 7-year windows (min 3500 PA)
   * 
   * Uses linear interpolation between stored percentile thresholds.
   * 
   * @param value - Player's stat value
   * @param thresholds - Percentile thresholds for this stat/year/scope
   * @returns Percentile (0-100)
   */
  ```

- [ ] **Document grade methodology decision**
  ```markdown
  # Grade Calculation Methodology
  
  After analyzing the distribution of baseball statistics, we chose the
  [percentile/SD/hybrid] approach for the following reasons:
  
  ## Analysis Results
  - Normality tests: [results]
  - Grade distributions: [results]
  - Eye test validation: [results]
  
  ## Final Decision
  [Explain choice and rationale]
  ```

### B. User Documentation

- [ ] **Update README with percentile features**
  ```markdown
  ## Percentile Visualizations
  
  Ask about any player to see their percentile rankings:
  - "Tell me about Mookie Betts"
  - "Compare Mike Trout and Aaron Judge"
  - "Show me Shohei Ohtani's strengths"
  
  Percentiles show where players rank across key skills:
  - Power (Barrel %, ISO, Exit Velo)
  - Plate Discipline (BB%, K%, Chase%)
  - Contact (Batting Avg, Contact%)
  - Speed (Sprint Speed, Stolen Bases)
  ```

- [ ] **Add to API documentation**
  ```markdown
  ### GET /api/player-percentiles
  
  Returns percentile rankings for a player.
  
  **Parameters:**
  - `player_name` (required): Player's full name
  - `year` (optional): Season year, defaults to most recent
  - `scope` (optional): 'season', 'career', or 'peak7'
  
  **Response:**
  ```json
  {
    "player": "Mookie Betts",
    "year": 2024,
    "scope": "season",
    "pa": 609,
    "percentiles": [...]
  }
  ```
  ```

### C. Performance Monitoring

- [ ] **Add metrics**
  ```typescript
  metrics.track('percentile_calculation_time', duration);
  metrics.track('percentile_cache_hit_rate', hitRate);
  metrics.track('percentile_queries_per_day', count);
  ```

- [ ] **Add logging**
  ```typescript
  logger.info('Calculated percentiles', {
    player: args.player_name,
    year: args.year,
    scope: args.scope,
    duration_ms: duration
  });
  ```

### D. Deployment

- [ ] **Database migration**
  ```bash
  # Run schema updates
  psql -h localhost -U postgres -d postgres -f migrations/add_percentiles.sql
  
  # Run ETL to populate percentiles
  Rscript calculate_percentiles.R
  
  # Backfill player percentiles
  Rscript backfill_player_percentiles.R
  ```

- [ ] **Deploy backend**
  ```bash
  npm run build
  npm run deploy
  ```

- [ ] **Deploy frontend**
  ```bash
  cd frontend
  npm run build
  npm run deploy
  ```

- [ ] **Verify deployment**
  - [ ] Test percentile queries in production
  - [ ] Check performance metrics
  - [ ] Verify data accuracy

---

## Acceptance Criteria Checklist

### Must Have ✅

- [ ] **Database**
  - [ ] `stat_percentiles` table exists with data for all years
  - [ ] Percentile columns added to `fg_season_stats`
  - [ ] Grade methodology chosen and documented

- [ ] **Backend**
  - [ ] `get_player_percentiles` tool works
  - [ ] Percentile calculation is accurate (±1 percentile point)
  - [ ] Handles qualified/non-qualified players correctly

- [ ] **Frontend**
  - [ ] Percentile bars render correctly
  - [ ] Color gradient (blue → gray → red)
  - [ ] Hover tooltips show value + percentile
  - [ ] Asterisks for non-qualified players
  - [ ] Stats grouped by category

- [ ] **LLM Integration**
  - [ ] LLM automatically calls percentile tool for player queries
  - [ ] Narrative includes percentile context
  - [ ] Elite skills (90+) highlighted
  - [ ] Weaknesses (30-) mentioned

- [ ] **Queries Work**
  - [ ] "Tell me about Mookie Betts" → Returns narrative + percentiles
  - [ ] "Compare Mike Trout and Aaron Judge" → Shows both players
  - [ ] Percentiles accurate to within ±1 percentile point

### Nice to Have 🎁

- [ ] Smooth bar animations
- [ ] Export percentile chart as PNG
- [ ] Historical sparklines (percentile over career)
- [ ] Position-adjusted percentiles
- [ ] Custom stat selection

---

## Estimated Timeline

**Week 1: Database & ETL**
- Days 1-2: Schema changes, percentile calculation logic
- Days 3-4: Grade methodology evaluation
- Day 5: Validation & backfill

**Week 2: Backend & Frontend**
- Days 1-2: Backend tools and API
- Days 3-4: React components
- Day 5: Integration & styling

**Week 3: Testing & Launch**
- Days 1-2: Testing & bug fixes
- Days 3-4: Documentation
- Day 5: Deployment & monitoring

---

## Dependencies

**Required:**
- ✅ MVP Complete (Phase 1.6)
- ⏳ Statcast data integrated (Phase 2.4)
  - barrel_pct, ev90, hard_pct, maxev
  - sprint_speed, bolts
  - o_swing_pct, swstr_pct

**Optional:**
- Advanced Statcast metrics (xwOBA, xBA, etc.)
- Fielding percentiles (OAA, DRS)

---

## Post-Launch

### Monitoring

- [ ] Track percentile query volume
- [ ] Monitor calculation performance
- [ ] Watch for errors/edge cases
- [ ] User feedback on grade accuracy

### Iteration

- [ ] A/B test percentile vs SD grades
- [ ] Add more stats as requested
- [ ] Consider position-adjusted percentiles
- [ ] Explore historical percentile trends

### Future Enhancements

- [ ] Pitcher percentiles (Phase 4.1)
- [ ] Team percentiles (Phase 4.2)
- [ ] Projected percentiles (with PECOTA data)
- [ ] Percentile-based player search ("Find me 90th+ percentile power hitters")

---

## Key Files to Create/Modify

### New Files
```
backend/
  src/services/percentileService.ts
  src/config/percentileStats.ts
  src/tools/getPlayerPercentiles.ts
  src/tools/comparePlayerPercentiles.ts

frontend/
  src/components/PercentileProfile.tsx
  src/components/PercentileBar.tsx
  src/components/PercentileTooltip.tsx
  src/components/PercentileComparison.tsx
  src/styles/percentileProfile.css

database/
  migrations/add_percentiles.sql

r/
  calculate_percentiles.R
  backfill_player_percentiles.R
  validate_percentiles.R
```

### Modified Files
```
backend/
  src/tools/index.ts (register new tools)
  src/prompts/system.ts (add percentile instructions)

frontend/
  src/components/ChatMessage.tsx (render percentiles)

database/
  fangraphs_schema.sql (add new tables/columns)
```

---

## Success Metrics

**Technical:**
- Percentile calculation accuracy: 99%+ within ±1 percentile point
- Query response time: <500ms for percentile lookup
- Grade distribution: Matches expected percentile targets

**User Experience:**
- Percentile queries work 95%+ of the time
- Visualization renders in <200ms
- Users report grades "feel right" for known players

**Adoption:**
- 50%+ of player queries trigger percentile tool
- Users engage with percentile visualization (hover, expand)
- Positive feedback on grade accuracy vs FanGraphs scouting reports

---

## Risk Mitigation

**Risk: Grade methodology debate**
- Mitigation: Implement both, test empirically, document decision

**Risk: Percentile calculation errors**
- Mitigation: Extensive validation, unit tests, known player checks

**Risk: Performance issues with large datasets**
- Mitigation: Aggressive caching, indexes, pagination

**Risk: Users confused by percentiles vs grades**
- Mitigation: Clear tooltips, documentation, both displayed together

---

**Ready to begin! Start with Phase 2.5.1 after completing Statcast integration.**