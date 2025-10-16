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
