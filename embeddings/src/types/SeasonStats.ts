export interface SeasonStats {
  player_season_id: string;
  fangraphs_id: number;
  player_name: string;
  year: number;
  age: number;
  team: string;
  position: string;

  // Basic stats
  g: number;
  pa: number;
  hr: number;
  sb: number;
  war: number;
  wrc_plus: number;

  // Triple slash
  avg: number;
  obp: number;
  slg: number;
  ops: number;

  // Fielding
  fielding: number | null;

  // Statcast (2015+)
  ev90?: number;

  // Pre-calculated grades (from R ETL)
  overall_grade: number;
  offense_grade: number;
  power_grade: number;
  hit_grade: number;
  discipline_grade: number;
  contact_grade: number;
  speed_grade: number;
  fielding_grade: number | null;
  hard_contact_grade?: number;
  exit_velo_grade?: number;
}
