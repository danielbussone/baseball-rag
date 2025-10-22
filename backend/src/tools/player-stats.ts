import { pool } from '../services/database.js';
import { CareerStats, SeasonStats } from '../types/index.js';

export async function getPlayerStats(
  playerName: string, 
  year?: number
): Promise<SeasonStats[]> {
  let sql = `
    SELECT s.*
    FROM fg_season_stats s
    JOIN fg_players p ON s.fangraphs_id = p.fangraphs_id
    WHERE p.player_name ILIKE $1
  `;
  
  const params: any[] = [`%${playerName}%`];
  
  if (year) {
    sql += ` AND s.year = $2`;
    params.push(year);
  }
  
  sql += ` ORDER BY s.year DESC`;

  console.log(`Get Player Stats Query: ${sql}`);
  
  const result = await pool.query(sql, params);
  return result.rows;
}

export async function getPlayerCareerStats(playerName: string): Promise<CareerStats | undefined> {
  let sql = `
    SELECT *
    FROM fg_career_stats
    WHERE player_name ILIKE $1
  `;
  
  const params: any[] = [`%${playerName}%`];

  console.log(`Get Player Career Stats Query: ${sql}`);
  
  const result = await pool.query(sql, params);
  return result.rows[0];
}

export async function getCareerSummary(playerName: string): Promise<{
  seasons: SeasonStats[];
  career: CareerStats | undefined;
}> {
  const seasons = await getPlayerStats(playerName);
  
  const career = await getPlayerCareerStats(playerName);

  console.log(`Seasons: ${JSON.stringify(seasons, null, 2)}`);

  console.log(`Career: ${JSON.stringify(career, null, 2)}`);
  
  return { seasons, career };
}