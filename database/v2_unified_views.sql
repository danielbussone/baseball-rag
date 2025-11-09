-- Unified Views Combining FanGraphs + Lahman Data

-- ============================================================================
-- UNIFIED BATTING SEASONS VIEW
-- ============================================================================

CREATE OR REPLACE VIEW batting_seasons_unified AS
SELECT
    pm.player_id,
    pm.name_first || ' ' || pm.name_last AS player_name,

    -- Season identifiers
    COALESCE(fg.season, lb.year_id) AS season,
    COALESCE(fg.team_name_abb, lb.team_id) AS team,

    -- Basic counting stats (prefer FanGraphs, fallback to Lahman)
    COALESCE(fg.g, lb.g) AS games,
    COALESCE(fg.pa, lb.ab + lb.bb + COALESCE(lb.hbp,0) + COALESCE(lb.sf,0)) AS plate_appearances,
    COALESCE(fg.ab, lb.ab) AS at_bats,
    COALESCE(fg.h, lb.h) AS hits,
    COALESCE(fg.singles, lb.h - COALESCE(lb.x2b,0) - COALESCE(lb.x3b,0) - COALESCE(lb.hr,0)) AS singles,
    COALESCE(fg.doubles, lb.x2b) AS doubles,
    COALESCE(fg.triples, lb.x3b) AS triples,
    COALESCE(fg.hr, lb.hr) AS home_runs,
    COALESCE(fg.rbi, lb.rbi) AS rbi,
    COALESCE(fg.sb, lb.sb) AS stolen_bases,
    COALESCE(fg.cs, lb.cs) AS caught_stealing,
    COALESCE(fg.bb, lb.bb) AS walks,
    COALESCE(fg.so, lb.so) AS strikeouts,

    -- Rate stats (FanGraphs preferred for precision)
    COALESCE(fg.average, ROUND(lb.h::numeric / NULLIF(lb.ab, 0), 3)) AS batting_avg,
    fg.obp,
    fg.slg,
    fg.ops,

    -- Advanced metrics (FanGraphs only)
    fg.w_oba,
    fg.babip,
    fg.iso,
    fg.bb_pct,
    fg.k_pct,
    fg.bb_k,
    fg.tto_pct,

    -- Value metrics (FanGraphs only)
    fg.batting,
    fg.fielding,
    fg.replacement,
    fg.positional,
    fg.spd,
    fg.offense,
    fg.defense,
    fg.base_running,
    fg.war,

    -- Plus stats (FanGraphs only)
    fg.w_rc_plus,
    fg.avg_plus,
    fg.bb_pct_plus,
    fg.k_pct_plus,
    fg.obp_plus,
    fg.slg_plus,
    fg.iso_plus,
    fg.babip_plus,
    fg.ld_pct_plus,
    fg.gb_pct_plus,
    fg.fb_pct_plus,
    fg.hrfb_pct_plus,
    fg.pull_pct_plus,
    fg.cent_pct_plus,
    fg.oppo_pct_plus,
    fg.soft_pct_plus,
    fg.med_pct_plus,
    fg.hard_pct_plus,

    -- Batted ball metrics (FanGraphs only)
    fg.gb_pct,
    fg.fb_pct,
    fg.ld_pct,
    fg.pull_pct,
    fg.hard_pct,

    -- StatCast metrics (FanGraphs 2015+)
    fg.ev AS avg_exit_velocity,
    fg.ev90 AS exit_velocity_90_percentile,
    fg.la AS launch_angle,
    fg.barrel_pct,
    fg.hard_hit_pct,

    -- Biographical context (Lahman)
    pm.birth_year,
    pm.bats,
    pm.throws,

    -- Data source tracking
    CASE
        WHEN fg.playerid IS NOT NULL AND lb.player_id IS NOT NULL THEN 'Both'
        WHEN fg.playerid IS NOT NULL THEN 'FanGraphs'
        WHEN lb.player_id IS NOT NULL THEN 'Lahman'
        END AS data_source,

    -- Age calculation
    COALESCE(fg.age, COALESCE(fg.season, lb.year_id) - pm.birth_year) AS age

FROM players_master pm
         LEFT JOIN fg_batting_leaders fg ON pm.fangraphs_id = fg.playerid
         LEFT JOIN lahman_batting lb ON pm.lahman_id = lb.player_id
            AND (fg.season = lb.year_id OR fg.season IS NULL)
WHERE COALESCE(fg.season, lb.year_id) IS NOT null;

COMMENT ON VIEW batting_seasons_unified IS 'Unified batting seasons combining FanGraphs advanced metrics with Lahman biographical data';

-- ============================================================================
-- UNIFIED PITCHING SEASONS VIEW
-- ============================================================================

CREATE OR REPLACE VIEW pitching_seasons_unified AS
SELECT
    pm.player_id,
    pm.name_first || ' ' || pm.name_last AS player_name,

    -- Season identifiers
    COALESCE(fg.season, lp.year_id) AS season,
    COALESCE(fg.team_name_abb, lp.team_id) AS team,

    -- Basic pitching stats (prefer FanGraphs, fallback to Lahman)
    COALESCE(fg.g, lp.g) AS games,
    COALESCE(fg.gs, lp.gs) AS games_started,
    COALESCE(fg.ip, lp.ipouts / 3.0) AS innings_pitched,
    COALESCE(fg.w, lp.w) AS wins,
    COALESCE(fg.l, lp.l) AS losses,
    COALESCE(fg.sv, lp.sv) AS saves,
    fg.hld AS holds,
    fg.bs AS blown_saves,
    COALESCE(fg.h, lp.h) AS hits_allowed,
    COALESCE(fg.r, lp.r) AS runs_allowed,
    COALESCE(fg.er, lp.er) AS earned_runs,
    COALESCE(fg.hr, lp.hr) AS home_runs_allowed,
    COALESCE(fg.bb, lp.bb) AS walks_allowed,
    COALESCE(fg.so, lp.so) AS strikeouts,
    COALESCE(fg.hbp, lp.hbp) AS hit_by_pitch,
    COALESCE(fg.wp, lp.wp) AS wild_pitches,
    COALESCE(fg.bk, lp.bk) AS balks,

    -- Rate stats (FanGraphs preferred for precision)
    COALESCE(fg.era, ROUND((lp.er * 9.0) / NULLIF(lp.ipouts / 3.0, 0), 2)) AS era,
    COALESCE(fg.whip, ROUND((lp.h + lp.bb)::numeric / NULLIF(lp.ipouts / 3.0, 0), 3)) AS whip,
    fg.fip,
    fg.x_fip,
    fg.siera,
    fg.k_9,
    fg.bb_9,
    fg.h_9,
    fg.hr_9,
    fg.k_bb,
    fg.babip,
    fg.lob_pct,

    -- Advanced metrics (FanGraphs only)
    fg.k_pct,
    fg.bb_pct,
    fg.k_minus_bb_pct,
    fg.gb_pct,
    fg.fb_pct,
    fg.ld_pct,
    fg.hr_fb,
    fg.pull_pct,
    fg.hard_pct,

    -- Value metrics (FanGraphs only)
    fg.war,
    fg.rar,
    fg.era_minus,
    fg.fip_minus,
    fg.x_fip_minus,

    -- Plus stats (FanGraphs only)
    fg.k_9_plus,
    fg.bb_9_plus,
    fg.k_bb_plus,
    fg.h_9_plus,
    fg.hr_9_plus,
    fg.avg_plus,
    fg.whip_plus,
    fg.babip_plus,
    fg.lob_pct_plus,

    -- Role classification
    fg.starting,
    fg.relieving,
    fg.start_ip,
    fg.relief_ip,
    fg.qs AS quality_starts,

    -- StatCast metrics (FanGraphs 2015+)
    fg.ev AS avg_exit_velocity,
    fg.ev90 AS exit_velocity_90_percentile,
    fg.la AS launch_angle,
    fg.barrel_pct,
    fg.hard_hit_pct,

    -- Stuff+ metrics (FanGraphs modern)
    fg.sp_stuff,
    fg.sp_location,
    fg.sp_pitching,

    -- Biographical context (Lahman)
    pm.birth_year,
    pm.bats,
    pm.throws,

    -- Data source tracking
    CASE
        WHEN fg.playerid IS NOT NULL AND lp.player_id IS NOT NULL THEN 'Both'
        WHEN fg.playerid IS NOT NULL THEN 'FanGraphs'
        WHEN lp.player_id IS NOT NULL THEN 'Lahman'
        END AS data_source,

    -- Age calculation
    COALESCE(fg.age, COALESCE(fg.season, lp.year_id) - pm.birth_year) AS age

FROM players_master pm
         LEFT JOIN fg_pitching_leaders fg ON pm.fangraphs_id = fg.playerid
         LEFT JOIN lahman_pitching lp ON pm.lahman_id = lp.player_id
            AND (fg.season = lp.year_id OR fg.season IS NULL)
WHERE COALESCE(fg.season, lp.year_id) IS NOT null;

COMMENT ON VIEW pitching_seasons_unified IS 'Unified pitching seasons combining FanGraphs advanced metrics with Lahman biographical data';

-- ============================================================================
-- UNIFIED FIELDING SEASONS VIEW
-- ============================================================================

CREATE OR REPLACE VIEW fielding_seasons_unified AS
SELECT
    pm.player_id,
    pm.name_first || ' ' || pm.name_last AS player_name,

    -- Season identifiers
    COALESCE(fg.season, lf.year_id) AS season,
    COALESCE(fg.team_name_abb, lf.team_id) AS team,
    COALESCE(fg.pos, lf.pos) AS position,

    -- Basic fielding stats (prefer FanGraphs, fallback to Lahman)
    COALESCE(fg.g, lf.g) AS games,
    COALESCE(fg.gs, lf.gs) AS games_started,
    COALESCE(fg.inn, lf.inn_outs / 3.0) AS innings,
    COALESCE(fg.po, lf.po) AS putouts,
    COALESCE(fg.a, lf.a) AS assists,
    COALESCE(fg.e, lf.e) AS errors,
    COALESCE(fg.dp, lf.dp) AS double_plays,
    COALESCE(fg.fp, ROUND(NULLIF(lf.po + lf.a, 0)::numeric / NULLIF(lf.po + lf.a + lf.e, 0), 3)) AS fielding_pct,

    -- Advanced fielding metrics (FanGraphs only)
    fg.rng_r AS range_runs,
    fg.err_r AS error_runs,
    fg.arm,

    -- Catcher specific (both sources)
    COALESCE(fg.pb, lf.pb) AS passed_balls,
    COALESCE(fg.sb, lf.sb) AS stolen_bases_allowed,
    COALESCE(fg.cs, lf.cs) AS caught_stealing,
    fg.cframing AS framing_runs,

    -- Position-specific metrics (FanGraphs)
    fg.oaa AS outs_above_average,
    fg.rzr AS revised_zone_rating,
    fg.plays,
    fg.biz AS balls_in_zone,
    fg.ooz AS out_of_zone,

    -- Value metrics (FanGraphs)
    fg.tz,
    fg.uzr,
    fg.uzr_150,
    fg.drs,
    fg.frp,
    fg.defense,
    COALESCE(fg.defense, COALESCE(fg.uzr, COALESCE(fg.tz, fg.drs))) as total_defense,
    CASE
        WHEN fg.defense IS NOT NULL THEN 'FG Defense'
        WHEN fg.uzr IS NOT NULL THEN 'UZR'
        WHEN fg.tz IS NOT NULL THEN 'TZ'
        WHEN fg.drs IS NOT NULL THEN 'DRS'
        ELSE 'None'
END AS total_defense_metric_type,

    -- Statcast catch probability metrics
    -- Performance on hard plays (0-40% catch probability)
	NULLIF(fg.prob0 + fg.prob10 + fg.prob40, 0) hard_play_opportunities,
	ROUND(
	    (fg.made0 * fg.prob0 + fg.made10 * fg.prob10)::numeric / NULLIF(fg.prob0 + fg.prob10, 0), 3
	) AS hard_play_success_rate,

	-- Performance on 50/50 plays (40-60%)
	NULLIF(fg.prob40 + fg.prob60, 0) fifty_fifty_opportunities,
	ROUND(
	    (fg.made40 * fg.prob40 + fg.made60 * fg.prob60) / NULLIF(fg.prob40 + fg.prob60, 0), 3
	) AS fifty_fifty_success_rate,

	-- Performance on routine plays (90-100%)
	NULLIF(fg.prob90 + fg.prob100, 0) routine_play_opportunities,
	ROUND(
	    (fg.made90 * fg.prob90 + fg.made100 * fg.prob100) / NULLIF(fg.prob90 + fg.prob100, 0), 3
	) AS routine_play_success_rate,

    -- Biographical context (Lahman)
    pm.birth_year,
    pm.bats,
    pm.throws,

    -- Data source tracking
    CASE
        WHEN fg.playerid IS NOT NULL AND lf.player_id IS NOT NULL THEN 'Both'
        WHEN fg.playerid IS NOT NULL THEN 'FanGraphs'
        WHEN lf.player_id IS NOT NULL THEN 'Lahman'
END AS data_source,

    -- Age calculation
    COALESCE(fg.season - pm.birth_year, lf.year_id - pm.birth_year) AS age

FROM players_master pm
         LEFT JOIN fg_fielding_leaders fg ON pm.fangraphs_id = fg.playerid
         LEFT JOIN lahman_fielding lf ON pm.lahman_id = lf.player_id
            AND (fg.season = lf.year_id OR fg.season IS NULL)
            AND (fg.pos = lf.pos OR fg.pos IS NULL)
WHERE COALESCE(fg.season, lf.year_id) IS NOT null;

COMMENT ON VIEW fielding_seasons_unified IS 'Unified fielding seasons combining FanGraphs advanced metrics with Lahman biographical data';

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_career_stats_unified_player_id ON career_stats_unified(player_id);
CREATE INDEX IF NOT EXISTS idx_career_stats_unified_total_jaws ON career_stats_unified(total_jaws DESC);

-- ============================================================================
-- CAREER STATS UNIFIED VIEW
-- ============================================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS career_stats_unified AS
WITH batting_careers AS (
    SELECT
        player_id,
        SUM(games) AS career_batting_games,
        SUM(plate_appearances) AS career_pa,
        SUM(hits) AS career_hits,
        SUM(home_runs) AS career_hr,
        ROUND(SUM(hits)::numeric / NULLIF(SUM(at_bats), 0), 3) AS career_avg,
        ROUND(SUM(war), 1) AS career_batting_war,
        MAX(war) AS peak_batting_war,
        ROUND((
            SELECT SUM(war)
            FROM (
                SELECT war
                FROM batting_seasons_unified b2
                WHERE b2.player_id = b1.player_id
                ORDER BY war DESC
                LIMIT 7
            ) top_seasons
        ), 1) AS seven_year_peak_batting_war
    FROM batting_seasons_unified b1
    GROUP BY player_id
),
     pitching_careers AS (
         SELECT
             player_id,
             SUM(games) AS career_pitching_games,
             SUM(innings_pitched) AS career_ip,
             SUM(wins) AS career_wins,
             SUM(strikeouts) AS career_strikeouts,
             ROUND(SUM(war), 1) AS career_pitching_war,
             MAX(war) AS peak_pitching_war,
             ROUND((
                 SELECT SUM(war)
                 FROM (
                     SELECT war
                     FROM pitching_seasons_unified p2
                     WHERE p2.player_id = p1.player_id
                     ORDER BY war DESC
                     LIMIT 7
                 ) top_seasons
             ), 1) AS seven_year_peak_pitching_war
         FROM pitching_seasons_unified p1
         GROUP BY player_id
     ),
     fielding_careers AS (
         SELECT
             player_id,
             COUNT(DISTINCT position) AS positions_played,
             STRING_AGG(DISTINCT position, ', ' ORDER BY position) AS positions_list,
             ROUND(AVG(total_defense), 1) AS avg_defensive_value,
             SUM(CASE WHEN position = 'P' THEN innings ELSE 0 END) AS pitcher_innings,
             SUM(CASE WHEN position != 'P' THEN innings ELSE 0 END) AS position_innings
         FROM fielding_seasons_unified
         WHERE total_defense IS NOT NULL
         GROUP BY player_id
     )
SELECT
    pm.player_id,
    pm.name_first || ' ' || pm.name_last AS player_name,
    pm.birth_year,
    pm.debut_date,
    pm.final_game_date,
    pm.bats,
    pm.throws,

    -- Career totals
    bc.career_batting_games,
    bc.career_pa,
    bc.career_hits,
    bc.career_hr,
    bc.career_avg,
    bc.career_batting_war,
    bc.peak_batting_war,

    pc.career_pitching_games,
    pc.career_ip,
    pc.career_wins,
    pc.career_strikeouts,
    pc.career_pitching_war,
    pc.peak_pitching_war,

    fc.positions_played,
    fc.positions_list,
    fc.avg_defensive_value,
    fc.pitcher_innings,
    fc.position_innings,

    -- Overall value
    ROUND(COALESCE(bc.career_batting_war, 0) + COALESCE(pc.career_pitching_war, 0), 1) AS career_total_war,
    
    -- JAWS calculations
    bc.seven_year_peak_batting_war,
    pc.seven_year_peak_pitching_war,
    ROUND(COALESCE(bc.seven_year_peak_batting_war, 0) + COALESCE(pc.seven_year_peak_pitching_war, 0), 1) AS seven_year_peak_total_war,
    ROUND((COALESCE(bc.career_batting_war, 0) + COALESCE(bc.seven_year_peak_batting_war, 0)) / 2.0, 1) AS batting_jaws,
    ROUND((COALESCE(pc.career_pitching_war, 0) + COALESCE(pc.seven_year_peak_pitching_war, 0)) / 2.0, 1) AS pitching_jaws,
    ROUND((
        COALESCE(bc.career_batting_war, 0) + COALESCE(pc.career_pitching_war, 0) +
        COALESCE(bc.seven_year_peak_batting_war, 0) + COALESCE(pc.seven_year_peak_pitching_war, 0)
    ) / 2.0, 1) AS total_jaws

FROM players_master pm
         LEFT JOIN batting_careers bc ON pm.player_id = bc.player_id
         LEFT JOIN pitching_careers pc ON pm.player_id = pc.player_id
         LEFT JOIN fielding_careers fc ON pm.player_id = fc.player_id
WHERE (bc.player_id IS NOT NULL OR pc.player_id IS NOT null)
order by career_total_war desc;

-- Refresh function
CREATE OR REPLACE FUNCTION refresh_career_stats() RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW career_stats_unified;
END;
$$ LANGUAGE plpgsql;

COMMENT ON MATERIALIZED VIEW career_stats_unified IS 'Materialized view of career statistics with JAWS calculations - refresh after data updates';