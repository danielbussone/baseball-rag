import { getCareerSummary } from './player-stats.js';

export async function comparePlayers(player1: string, player2: string) {
  const [career1, career2] = await Promise.all([
    getCareerSummary(player1),
    getCareerSummary(player2)
  ]);
  
  return {
    player1: {
      name: career1.seasons[0]?.player_name || player1,
      career: career1.totals,
      bestSeason: career1.seasons.find(s => s.war === career1.totals.peakWAR)
    },
    player2: {
      name: career2.seasons[0]?.player_name || player2,
      career: career2.totals,
      bestSeason: career2.seasons.find(s => s.war === career2.totals.peakWAR)
    },
    comparison: {
      warDiff: career1.totals.totalWAR - career2.totals.totalWAR,
      longevityDiff: career1.totals.seasons - career2.totals.seasons,
      peakDiff: career1.totals.peakWAR - career2.totals.peakWAR
    }
  };
}