# FanGraphs ETL Pipeline

R-based data pipeline that extracts batting statistics from FanGraphs, calculates scouting grades, and loads data into PostgreSQL.

## Overview

- **Data Source**: FanGraphs leaderboards via `baseballr` package
- **Coverage**: 1988-2025 batting statistics
- **Output**: PostgreSQL tables with normalized stats and 20-80 scouting grades
- **Update Strategy**: Incremental upserts (preserves manual corrections)

## Quick Start

```bash
# Install R dependencies (run once)
Rscript -e "install.packages(c('baseballr', 'DBI', 'RPostgres', 'dplyr'))"

# Run ETL pipeline
Rscript batter_leaderboard_etl.r
```

## Database Schema

### Tables Created
- **`fg_players`** - Player dimension (one row per player)
- **`fg_season_stats`** - Season-level batting stats with grades
- **`fg_batter_pitches_faced`** - Pitch-level data (optional)
- **`fg_career_stats`** - View with career aggregations

### Key Features
- **Scouting Grades**: 20-80 scale calculated from era-adjusted stats
- **Incremental Updates**: Only processes new/changed data
- **Data Validation**: Checks for statistical outliers and missing seasons

## Grade Calculation

Grades use the traditional 20-80 scouting scale:
- **80 (Elite)**: Top 1% of players
- **70 (Plus-Plus)**: Top 10% 
- **60 (Plus)**: Top 25%
- **50 (Average)**: League average
- **40 (Fringe)**: Bottom 25%
- **30 (Poor)**: Bottom 10%
- **20 (Very Poor)**: Bottom 1%

### Methodology
Currently uses era-adjusted "plus" stats (e.g., `iso_plus` where 100 = league average) with standard deviation thresholds. Future versions will migrate to percentile-based calculation.

### Grade Types
- `overall_grade` - WAR-based overall rating
- `offense_grade` - wRC+ based hitting
- `power_grade` - ISO+ based power
- `hit_grade` - AVG+ based contact
- `discipline_grade` - BB%+ based plate discipline
- `contact_grade` - K%+ based (inverse: lower K% = higher grade)
- `speed_grade` - SB/600PA based
- `fielding_grade` - Era/position adjusted

## Configuration

Edit these variables in `batter_leaderboard_etl.r`:

```r
# Database connection
DB_HOST <- "localhost"
DB_PORT <- 5432
DB_NAME <- "postgres"
DB_USER <- "postgres"
DB_PASSWORD <- "your_password_here"

# Data range
START_YEAR <- 1988
END_YEAR <- 2025
MIN_PA <- 50  # Minimum plate appearances
```

## Performance

- **Runtime**: ~5-10 minutes for full historical load
- **Incremental**: ~30 seconds for current season update
- **Records**: ~50,000 player-seasons (1988-2025)
- **API Calls**: ~40 requests to FanGraphs (rate-limited)

## Troubleshooting

### Common Issues

**Database Connection Error**
```
Error: could not connect to server
```
- Ensure PostgreSQL is running: `docker ps`
- Check connection details in script
- Verify pgvector extension is installed

**Missing Seasons**
```
Warning: No data returned for year XXXX
```
- FanGraphs API occasionally fails for specific years
- Re-run script to retry failed years
- Check FanGraphs website for data availability

**Grade Distribution Warnings**
```
Warning: Power grade distribution seems off
```
- Validates that ~10% of players get 70+ grades
- May indicate calculation error or unusual season
- Review grade thresholds if persistent

### Data Quality Checks

```sql
-- Verify record counts
SELECT COUNT(*) FROM fg_players;
SELECT COUNT(*) FROM fg_season_stats;

-- Check grade distributions (should be ~10% with 70+ grades)
SELECT 
  overall_grade,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as pct
FROM fg_season_stats 
WHERE pa >= 502 
GROUP BY overall_grade 
ORDER BY overall_grade DESC;

-- Top players by WAR
SELECT p.player_name, s.year, s.war, s.overall_grade
FROM fg_season_stats s
JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
ORDER BY s.war DESC
LIMIT 10;
```

## Future Enhancements

- **Percentile-based grades** - More statistically accurate than current method
- **Pitcher data** - Expand beyond batting statistics  
- **Baseball Reference integration** - Add biographical data
- **Statcast metrics** - Exit velocity, launch angle, etc.
- **Automated scheduling** - Daily/weekly updates during season