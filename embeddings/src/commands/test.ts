import { pool } from '../config/database.js';
import { generateEmbedding } from '../services/embedding.js';

export async function testSimilaritySearch(queryText: string, limit: number = 10) {
  console.log(`\nSearching for: "${queryText}"\n`);

  // Generate query embedding
  const queryEmbedding = await generateEmbedding(queryText);

  // Search database
  const query = `
    SELECT
      summary_text,
      metadata,
      1 - (embedding <=> $1::vector) AS similarity
    FROM player_embeddings
    WHERE embedding_type = 'season_summary'
    ORDER BY embedding <=> $1::vector
    LIMIT $2
  `;

  const result = await pool.query(query, [
    JSON.stringify(queryEmbedding),
    limit
  ]);

  console.log('Top results:\n');
  result.rows.forEach((row, idx) => {
    console.log(`${idx + 1}. (${(row.similarity * 100).toFixed(1)}% match)`);
    console.log(`   ${row.summary_text}\n`);
  });
}
