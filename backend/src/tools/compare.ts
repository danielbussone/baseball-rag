import { getCareerSummary } from './player-stats.js';
import { createModuleLogger } from '../config/logger.js';

const logger = createModuleLogger('CompareTool');

export async function comparePlayers(player1: string, player2: string) {
  const [career1, career2] = await Promise.all([
    getCareerSummary(player1),
    getCareerSummary(player2)
  ]);

  const player1Summary = {
      name: career1.seasons[0]?.player_name || player1,
      career: career1.career,
      bestSeason: career1.career?.peak_year,
      bestWar: career1.career?.peak_war,
      peakYearsWar: career1.career?.peak_7yr_war
  };

  const player2Summary = {
      name: career2.seasons[0]?.player_name || player2,
      career: career2.career,
      bestSeason: career2.career?.peak_year,
      bestWar: career2.career?.peak_war,
      peakYearsWar: career2.career?.peak_7yr_war
  };

  const comparison = {
      warDiff: (career1.career?.total_war || 0) - (career2.career?.total_war || 0),
      longevityDiff: (career1.career?.seasons || 0) - (career2.career?.seasons || 0),
      peakDiff: (career1.career?.peak_7yr_war || 0) - (career2.career?.peak_7yr_war || 0),
      bestYearDiff: (career1.career?.peak_war || 0) - (career2.career?.peak_war || 0)
  };

  logger.debug(`Player 1: ${JSON.stringify(player1Summary)}`)
  logger.debug(`Player 2: ${JSON.stringify(player2Summary)}`)
  logger.debug(`Comparison: ${JSON.stringify(comparison)}`)
  
  return {
    player1: player1Summary,
    player2: player2Summary,
    comparison: comparison
  };
}