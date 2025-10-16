import type { SeasonStats } from '../types/SeasonStats.js';
import { GRADE_DESCRIPTORS } from '../constants/grading.js';
import { getPlayerGrades, getWARDescription, getWRCPlusDescription } from '../utils/grading.js';
import { getFieldingDescription } from '../utils/position.js';
import { capitalize } from '../utils/text.js';

export function generateSeasonSummary(season: SeasonStats): string {
  const grades = getPlayerGrades(season);
  const parts: string[] = [];

  parts.push(
    `${season.player_name}, ${season.year} season ` +
    `(age ${season.age}, ${grades.position}, ${season.team}):`
  );

  // Overall performance
  const overallDesc = getWARDescription(season.war, season.overall_grade);
  parts.push(overallDesc);

  // Offensive production
  if (season.wrc_plus) {
    const wrcDesc = getWRCPlusDescription(season.ops, season.wrc_plus, grades.overallOffense);
    parts.push(wrcDesc);
  }

  // Offensive tools (60+ grade)
  const tools: string[] = [];

  if (grades.power >= 60) {
    const powerDesc = GRADE_DESCRIPTORS[grades.power];
    tools.push(`${powerDesc} power with ${season.hr} home runs and a ${season.slg} slugging percentage`);
  }

  if (grades.hit >= 60) {
    const hitDesc = GRADE_DESCRIPTORS[grades.hit];
    tools.push(`${hitDesc} hitting with a ${season.avg} batting average`);
  }

  if (grades.discipline >= 60) {
    const discDesc = GRADE_DESCRIPTORS[grades.discipline];
    tools.push(`${discDesc} plate discipline with a ${season.obp} on base percentage`);
  }

  if (grades.contact >= 60) {
    const contactDesc = GRADE_DESCRIPTORS[grades.contact];
    tools.push(`${contactDesc} contact ability`);
  }

  if (grades.speed >= 60) {
    const speedDesc = GRADE_DESCRIPTORS[grades.speed];
    tools.push(`${speedDesc} speed with ${season.sb} stolen bases`);
  }

  if (tools.length > 0) {
    parts.push(`Demonstrated ${tools.join(', ')}.`);
  }

  // Fielding - mention if notable or premium position
  if (grades.fielding !== null) {
    const fieldingGrade = grades.fielding;
    const shouldMentionDefense =
      fieldingGrade >= 60 ||
      fieldingGrade <= 40 ||
      (grades.isPremiumPosition && fieldingGrade >= 45);

    if (shouldMentionDefense) {
      const fieldingDesc = getFieldingDescription(
        grades.fielding,
        grades.position,
        season.fielding!
      );
      parts.push(capitalize(fieldingDesc) + '.');
    }
  }

  // Statcast (modern only, 55+ grade)
  if (grades.exitVelo && grades.exitVelo >= 55) {
    const evDesc = GRADE_DESCRIPTORS[grades.exitVelo];
    parts.push(
      `${capitalize(evDesc)} bat speed with ${Number(season.ev90)!.toFixed(1)} mph 90th percentile exit velocity.`
    );
  }

  return parts.join(' ');
}
