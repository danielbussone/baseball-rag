import { fileURLToPath } from 'url';
import { resolve } from 'path';
import { pool } from './config/database.js';
import { initializeEmbedder } from './services/embedding.js';
import { generateAllEmbeddings } from './commands/generate.js';
import { testSimilaritySearch } from './commands/test.js';
import { hybridSearch, parseHybridSearchArgs } from './commands/hybrid.js';
import { generateSampleSummaries } from './commands/sample.js';

// Re-export public API
export { generateSeasonSummary } from './services/summary.js';
export { getPlayerGrades } from './utils/grading.js';
export { generateEmbedding } from './services/embedding.js';
export type { SeasonStats, PlayerGrades, EmbeddingRecord, SearchFilters } from './types/index.js';


async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  
  try {
    if (command === 'generate') {
      const batchSize = parseInt(args[1]) || 100;
      await generateAllEmbeddings(batchSize);
    } else if (command === 'test') {
      const query = args.slice(1).join(' ') || 'elite power hitter with great plate discipline';
      await initializeEmbedder();
      await testSimilaritySearch(query);
    } else if (command === 'hybrid') {
      const { query, filters } = parseHybridSearchArgs(args);
      await initializeEmbedder();
      await hybridSearch(query, filters);
    } else if (command === 'sample') {
      await generateSampleSummaries();
    } else {
      console.log(`
Baseball Player Embedding Generation System

Usage:
  npm start generate [batchSize]                    - Generate embeddings for all seasons
  npm start test [query]                             - Test basic similarity search
  npm start hybrid "query" [--filters]               - Hybrid search with filters
  npm start sample                                   - Show sample summaries

Hybrid Search Filters:
  --position=POS           Position (1B, 2B, SS, 3B, C, OF, DH)
  --minWAR=X               Minimum WAR
  --maxWAR=X               Maximum WAR
  --minOverallGrade=X      Minimum overall grade (20-80 scale)
  --maxOverallGrade=X      Maximum overall grade
  --minHitGrade=X          Minimum hit grade
  --maxHitGrade=X          Maximum hit grade
  --minPowerGrade=X        Minimum power grade
  --maxPowerGrade=X        Maximum power grade
  --minFieldingGrade=X     Minimum fielding grade
  --maxFieldingGrade=X     Maximum fielding grade (use for poor defense)
  --minSpeedGrade=X        Minimum speed grade
  --maxSpeedGrade=X        Maximum speed grade
  --yearStart=YYYY         Start year
  --yearEnd=YYYY           End year

Examples:
  npm start generate 100
  npm start test "elite power hitter with great defense"
  npm start -- hybrid "power hitter" --position=1B --maxFieldingGrade=40
  npm start -- hybrid "slugging first baseman with poor defense" --position=1B --minPowerGrade=70 --maxFieldingGrade=30
  npm start -- hybrid "elite shortstop defender" --position=SS --minFieldingGrade=70
  npm start -- hybrid "five tool player" --minOverallGrade=60 --minHitGrade=60 --minPowerGrade=60 --minFieldingGrade=60 --minSpeedGrade=60
  npm start -- hybrid "one of the best power speed seasons on record" --minPowerGrade=70 --minSpeedGrade=70
  npm start sample
      `);
    }
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await pool.end();
  }
}

// Run if called directly
const currentFile = fileURLToPath(import.meta.url);
const calledFile = resolve(process.argv[1]);

if (currentFile === calledFile) {
  main();
}