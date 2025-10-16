import { fetchSeasons } from '../services/database.js';
import { generateSeasonSummary } from '../services/summary.js';

export async function generateSampleSummaries() {
  console.log('Generate sample summaries');
  const seasons = await fetchSeasons(100);
  if (seasons.length > 0) {
    console.log('\nSample Summaries:\n');
    seasons.forEach((season, idx) => {
      const summary = generateSeasonSummary(season);
      console.log(`${idx + 1}. ${summary}\n`);
    });
  } else {
    console.log('No seasons found');
  }
}
