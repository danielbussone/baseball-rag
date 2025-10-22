export interface SeasonStats {
  player_season_id: string;
  fangraphs_id: number;
  player_name: string;
  year: number;
  age: number;
  team: string;
  position: string;
  g: number;
  pa: number;
  hr: number;
  sb: number;
  war: number;
  wrc_plus: number;
  avg: number;
  obp: number;
  slg: number;
  ops: number;
  fielding: number | null;
  ev90?: number;
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

export interface SearchFilters {
  position?: string;
  minWAR?: number;
  maxWAR?: number;
  minOverallGrade?: number;
  maxOverallGrade?: number;
  minHitGrade?: number;
  maxHitGrade?: number;
  minPowerGrade?: number;
  maxPowerGrade?: number;
  minFieldingGrade?: number;
  maxFieldingGrade?: number;
  minSpeedGrade?: number;
  maxSpeedGrade?: number;
  yearRange?: [number, number];
}

export interface ToolCall {
  type: string
  function: {
    name: string
    arguments: Record<string, any>
  }
}

export interface ChatMessage {
  role: 'user' | 'assistant' | 'tool' | 'system';
  content: string;
  tool_calls?: ToolCall[];
}