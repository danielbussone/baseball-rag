import type { SeasonStats } from '../types/SeasonStats.js';
import type { EmbeddingRecord } from '../types/EmbeddingRecord.js';
import { pool } from '../config/database.js';

export async function fetchSeasons(limit?: number): Promise<SeasonStats[]> {
  const query = `
    SELECT
      s.player_season_id,
      s.fangraphs_id,
      p.player_name,
      s.year,
      s.age,
      s.team,
      s.position,
      s.g,
      s.pa,
      s.hr,
      s.sb,
      s.war,
      s.wrc_plus,
      s.avg,
      s.obp,
      s.slg,
      s.ops,
      s.fielding,
      s.ev90,
      s.overall_grade,
      s.offense_grade,
      s.power_grade,
      s.hit_grade,
      s.discipline_grade,
      s.contact_grade,
      s.speed_grade,
      s.fielding_grade,
      s.hard_contact_grade,
      s.exit_velo_grade
    FROM fg_season_stats s
    JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
    WHERE s.pa >= 50
    ORDER BY s.war DESC
    ${limit ? `LIMIT ${limit}` : ''}
  `;

  const result = await pool.query(query);
  return result.rows;
}

export async function saveEmbeddings(records: EmbeddingRecord[]) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    for (const record of records) {
      const query = `
        INSERT INTO player_embeddings
          (player_season_id, fangraphs_id, year, embedding_type, summary_text, embedding, metadata)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (player_season_id, embedding_type)
        DO UPDATE SET
          summary_text = EXCLUDED.summary_text,
          embedding = EXCLUDED.embedding,
          metadata = EXCLUDED.metadata,
          created_at = CURRENT_TIMESTAMP
      `;

      await client.query(query, [
        record.player_season_id,
        record.fangraphs_id,
        record.year,
        record.embedding_type,
        record.summary_text,
        JSON.stringify(record.embedding),
        JSON.stringify(record.metadata)
      ]);
    }

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
