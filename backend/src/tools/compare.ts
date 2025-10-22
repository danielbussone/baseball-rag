import { getCareerSummary } from './player-stats.js';

export async function comparePlayers(player1: string, player2: string) {
  const [career1, career2] = await Promise.all([
    getCareerSummary(player1),
    getCareerSummary(player2)
  ]);
  
  return {
    player1: {
      name: career1.seasons[0]?.player_name || player1,
      career: career1.career,
      bestSeason: career1.career?.peak_year,
      bestWar: career1.career?.peak_war,
      peakYearsWar: career1.career?.peak_7yr_war
    },
    player2: {
      name: career2.seasons[0]?.player_name || player2,
      career: career2.career,
      bestSeason: career2.career?.peak_year,
      bestWar: career2.career?.peak_war,
      peakYearsWar: career2.career?.peak_7yr_war
    },
    comparison: {
      warDiff: (career1.career?.total_war || 0) - (career2.career?.total_war || 0),
      longevityDiff: (career1.career?.seasons || 0) - (career2.career?.seasons || 0),
      peakDiff: (career1.career?.peak_7yr_war || 0) - (career2.career?.peak_7yr_war || 0),
      bestYearDiff: (career1.career?.peak_war || 0) - (career2.career?.peak_war || 0)
    }
  };
}