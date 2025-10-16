import type { EmbeddingRecord } from '../types/EmbeddingRecord.js';
import { verifyEmbeddingTableExists } from '../config/database.js';
import { initializeEmbedder, generateEmbeddingsBatch } from '../services/embedding.js';
import { fetchSeasons, saveEmbeddings } from '../services/database.js';
import { generateSeasonSummary } from '../services/summary.js';
import { getPlayerGrades } from '../utils/grading.js';

export async function generateAllEmbeddings(batchSize: number = 100) {
  console.log('Starting embedding generation pipeline...\n');

  // Verify table exists
  await verifyEmbeddingTableExists();

  // Initialize embedder
  await initializeEmbedder();

  // Fetch all seasons
  console.log('Fetching player seasons...');
  const seasons = await fetchSeasons();
  console.log(`✓ Fetched ${seasons.length} player-seasons\n`);

  // Process in batches
  const totalBatches = Math.ceil(seasons.length / batchSize);

  for (let i = 0; i < seasons.length; i += batchSize) {
    const batchNum = Math.floor(i / batchSize) + 1;
    const batch = seasons.slice(i, i + batchSize);

    console.log(`Processing batch ${batchNum}/${totalBatches}...`);

    // Generate summaries
    const summaries = batch.map(generateSeasonSummary);

    // Generate embeddings
    const embeddings = await generateEmbeddingsBatch(summaries);

    // Prepare records
    const records: EmbeddingRecord[] = batch.map((season, idx) => {
      const grades = getPlayerGrades(season);

      return {
        player_season_id: season.player_season_id,
        fangraphs_id: season.fangraphs_id,
        year: season.year,
        embedding_type: 'season_summary',
        summary_text: summaries[idx],
        embedding: embeddings[idx],
        metadata: {
          war: season.war,
          wrc_plus: season.wrc_plus,
          position: season.position,
          age: season.age,
          overall_grade: grades.overall,
          power_grade: grades.power,
          hit_grade: grades.hit
        }
      };
    });

    // Save to database
    await saveEmbeddings(records);

    console.log(`✓ Saved ${records.length} embeddings`);
    console.log(`Progress: ${Math.min(i + batchSize, seasons.length)}/${seasons.length}\n`);
  }

  console.log('✅ Embedding generation complete!');
}
