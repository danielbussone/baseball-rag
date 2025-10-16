import type { SeasonStats } from '../types/SeasonStats.js';
import type { PlayerGrades } from '../types/PlayerGrades.js';
import { GRADE_DESCRIPTORS } from '../constants/grading.js';
import { isPremiumDefensivePosition } from './position.js';

export function getWARDescription(war: number, war_grade: number): string {
  if (war_grade >= 80) {
    return `All-time great season with ${war} WAR`;
  } else if (war_grade >= 70) {
    return `MVP worthy season with ${war} WAR`;
  } else if (war_grade >= 60) {
    return `All star caliber season with ${war} WAR`;
  } else if (war_grade >= 55) {
    return `An above average campaign with ${war} WAR`;
  } else if (war_grade >= 50) {
    return `Average contribution with ${war} WAR`;
  } else if (war_grade >= 45) {
    return `A replacement level season with ${war} WAR`;
  } else if (war_grade >= 40) {
    return `A negative season with ${war} WAR`;
  } else if (war_grade >= 30) {
    return `A very bad season with ${war} WAR`;
  } else {
    return `Disaster of a season with ${war} WAR`;
  }
}

export function getWRCPlusDescription(ops: number, wrc_plus: number, wrc_plus_grade: number): string {
  const wrcDesc = GRADE_DESCRIPTORS[wrc_plus_grade];
  if(wrc_plus > 100) {
    const pct_above_avg = wrc_plus - 100;
    return `Posted ${wrcDesc} offensive production with a ${ops} OPS (${wrc_plus} wRC+ or ${pct_above_avg}% better than league average).`
  } else if(wrc_plus === 100) {
    return `Posted ${wrcDesc} offensive production with a ${ops} OPS (${wrc_plus} wRC+ or exactly league average).`
  } else {
    const pct_below_avg = 100 - wrc_plus;
    return `Posted ${wrcDesc} offensive production with a ${ops} OPS (${wrc_plus} wRC+ or ${pct_below_avg}% worse than league average).`
  }
}

export function getPlayerGrades(season: SeasonStats): PlayerGrades {
  return {
    overall: season.overall_grade,
    overallOffense: season.offense_grade,
    power: season.power_grade,
    hit: season.hit_grade,
    discipline: season.discipline_grade,
    contact: season.contact_grade,
    speed: season.speed_grade,
    fielding: season.fielding_grade,
    position: season.position || 'DH',
    isPremiumPosition: isPremiumDefensivePosition(season.position || ''),
    hardContact: season.hard_contact_grade,
    exitVelo: season.exit_velo_grade
  };
}
