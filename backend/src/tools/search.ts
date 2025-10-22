import { pool } from '../services/database.js';
import type { SearchFilters } from '../types';
import { generateEmbedding } from '../services/embedding.js';

export interface HybridSearchResult {
  summary_text: string;
  year: number;
  player_name: string;
  position: string;
  war: number;
  wrc_plus: number;
  overall_grade: number;
  power_grade: number;
  hit_grade: number;
  fielding_grade: number;
  speed_grade: number;
  similarity: number;
}

// Instead of positional: searchSimilarPlayers(filters, limit, queryText)
// Use object destructuring:
export async function searchSimilarPlayers({
                                             query,
                                             filters = {},
                                             limit = 10
                                           }: {
  query: string;
  filters?: SearchFilters;
  limit?: number;
}): Promise<HybridSearchResult[]>
 {
  // Generate query embedding
  const queryEmbedding = await generateEmbedding(query);
  console.log(`Query Text: ${query}`)
  console.log(`Search Filters: ${JSON.stringify(filters)}`)
  console.log(`Limit: ${limit}`)

  // Build WHERE clause from filters
  const whereClauses: string[] = ["embedding_type = 'season_summary'"];
  const params: any[] = [JSON.stringify(queryEmbedding), limit];
  let paramIndex = 3;

  if (filters.position) {
    whereClauses.push(`s.position ILIKE $${paramIndex}`);
    params.push(`%${filters.position}%`);
    paramIndex++;
  }

  if (filters.minWAR !== undefined) {
    whereClauses.push(`s.war >= $${paramIndex}`);
    params.push(filters.minWAR);
    paramIndex++;
  }

  if (filters.maxWAR !== undefined) {
    whereClauses.push(`s.war <= $${paramIndex}`);
    params.push(filters.maxWAR);
    paramIndex++;
  }

  if (filters.minOverallGrade !== undefined) {
    whereClauses.push(`s.overall_grade >= $${paramIndex}`);
    params.push(filters.minOverallGrade);
    paramIndex++;
  }

  if (filters.maxOverallGrade !== undefined) {
    whereClauses.push(`s.overall_grade <= $${paramIndex}`);
    params.push(filters.maxOverallGrade);
    paramIndex++;
  }

  if (filters.minHitGrade !== undefined) {
    whereClauses.push(`s.hit_grade >= $${paramIndex}`);
    params.push(filters.minHitGrade);
    paramIndex++;
  }

  if (filters.maxHitGrade !== undefined) {
    whereClauses.push(`s.hit_grade <= $${paramIndex}`);
    params.push(filters.maxHitGrade);
    paramIndex++;
  }

  if (filters.minPowerGrade !== undefined) {
    whereClauses.push(`s.power_grade >= $${paramIndex}`);
    params.push(filters.minPowerGrade);
    paramIndex++;
  }

  if (filters.maxPowerGrade !== undefined) {
    whereClauses.push(`s.power_grade <= $${paramIndex}`);
    params.push(filters.maxPowerGrade);
    paramIndex++;
  }

  if (filters.minFieldingGrade !== undefined) {
    whereClauses.push(`s.fielding_grade >= $${paramIndex}`);
    params.push(filters.minFieldingGrade);
    paramIndex++;
  }

  if (filters.maxFieldingGrade !== undefined) {
    whereClauses.push(`s.fielding_grade <= $${paramIndex}`);
    params.push(filters.maxFieldingGrade);
    paramIndex++;
  }

  if (filters.minSpeedGrade !== undefined) {
    whereClauses.push(`s.speed_grade >= $${paramIndex}`);
    params.push(filters.minSpeedGrade);
    paramIndex++;
  }

  if (filters.maxSpeedGrade !== undefined) {
    whereClauses.push(`s.speed_grade <= $${paramIndex}`);
    params.push(filters.maxSpeedGrade);
    paramIndex++;
  }

  if (filters.yearRange) {
    whereClauses.push(`s.year BETWEEN $${paramIndex} AND $${paramIndex + 1}`);
    params.push(filters.yearRange[0], filters.yearRange[1]);
    paramIndex += 2;
  }

  const whereClause = whereClauses.join(' AND ');

  const sql = `
    SELECT
      e.summary_text,
      s.year,
      p.player_name,
      s.position,
      s.war,
      s.wrc_plus,
      s.overall_grade,
      s.power_grade,
      s.hit_grade,
      s.fielding_grade,
      s.speed_grade,
      1 - (e.embedding <=> $1::vector) AS similarity
    FROM player_embeddings e
    JOIN fg_season_stats s ON e.player_season_id = s.player_season_id
    JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
    WHERE ${whereClause}
    ORDER BY e.embedding <=> $1::vector
    LIMIT $2
  `;

  console.log(`Query: ${sql}`)
  
  console.log(`Params: ${JSON.stringify(params)}`)

  const result = await pool.query(sql, params);
  return result.rows as HybridSearchResult[];
}