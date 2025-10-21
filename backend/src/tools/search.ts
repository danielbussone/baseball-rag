import { pool } from '../services/database.js';
import { SeasonStats, SearchFilters } from '../types/index.js';

export async function searchSimilarPlayers(
  query: string, 
  filters: SearchFilters = {},
  limit: number = 10
): Promise<SeasonStats[]> {
  let sql = `
    SELECT DISTINCT s.*
    FROM player_embeddings e
    JOIN fg_season_stats s ON e.player_season_id = s.player_season_id
    JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
    WHERE e.embedding_type = 'season_summary'
  `;
  
  const params: any[] = [];
  let paramCount = 0;

  // Apply filters
  if (filters.position) {
    sql += ` AND s.position ILIKE $${++paramCount}`;
    params.push(`%${filters.position}%`);
  }
  
  if (filters.minOverallGrade) {
    sql += ` AND s.overall_grade >= $${++paramCount}`;
    params.push(filters.minOverallGrade);
  }
  
  if (filters.minPowerGrade) {
    sql += ` AND s.power_grade >= $${++paramCount}`;
    params.push(filters.minPowerGrade);
  }
  
  if (filters.maxFieldingGrade) {
    sql += ` AND s.fielding_grade <= $${++paramCount}`;
    params.push(filters.maxFieldingGrade);
  }
  
  if (filters.yearRange) {
    sql += ` AND s.year BETWEEN $${++paramCount} AND $${++paramCount}`;
    params.push(filters.yearRange[0], filters.yearRange[1]);
  }

  sql += ` ORDER BY s.war DESC LIMIT $${++paramCount}`;
  params.push(limit);

  const result = await pool.query(sql, params);
  return result.rows;
}