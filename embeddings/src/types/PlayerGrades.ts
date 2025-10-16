export interface PlayerGrades {
  overall: number;
  overallOffense: number;
  power: number;
  hit: number;
  discipline: number;
  contact: number;
  speed: number;
  fielding: number | null;
  position: string;
  isPremiumPosition: boolean;
  hardContact?: number;
  exitVelo?: number;
}
