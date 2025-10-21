import { pool } from '../services/database.js';
import { SeasonStats } from '../types/index.js';

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
  
  const result = await pool.query(sql, params);
  return result.rows;
}

export async function getCareerSummary(playerName: string): Promise<{
  seasons: SeasonStats[];
  totals: {
    seasons: number;
    games: number;
    pa: number;
    hr: number;
    sb: number;
    totalWAR: number;
    avgWRC: number;
    peakWAR: number;
    peakYear: number;
  };
}> {
  const seasons = await getPlayerStats(playerName);
  
  if (seasons.length === 0) {
    throw new Error(`No stats found for player: ${playerName}`);
  }
  
  const totals = {
    seasons: seasons.length,
    games: seasons.reduce((sum, s) => sum + s.g, 0),
    pa: seasons.reduce((sum, s) => sum + s.pa, 0),
    hr: seasons.reduce((sum, s) => sum + s.hr, 0),
    sb: seasons.reduce((sum, s) => sum + s.sb, 0),
    totalWAR: seasons.reduce((sum, s) => sum + s.war, 0),
    avgWRC: seasons.reduce((sum, s) => sum + s.wrc_plus, 0) / seasons.length,
    peakWAR: Math.max(...seasons.map(s => s.war)),
    peakYear: seasons.find(s => s.war === Math.max(...seasons.map(s => s.war)))?.year || 0
  };
  
  return { seasons, totals };
}