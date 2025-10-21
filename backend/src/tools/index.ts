import { searchSimilarPlayers } from './search.js';
import { getPlayerStats, getCareerSummary } from './player-stats.js';
import { comparePlayers } from './compare.js';

export const toolExecutors = {
  search_similar_players: searchSimilarPlayers,
  get_player_stats: getPlayerStats,
  get_career_summary: getCareerSummary,
  compare_players: comparePlayers
};

export { toolDefinitions } from './definitions.js';