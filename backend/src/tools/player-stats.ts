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

  console.log(`Get Player Stats Query: ${sql}`);
  
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
    avgWRCPlus: number;
    peakWAR: number;
    peakYear: number;
  };
}> {
  const seasons = await getPlayerStats(playerName);
  
  if (seasons.length === 0) {
    throw new Error(`No stats found for player: ${playerName}`);
  } else {
    console.log(`Found ${seasons.length} seasons`);
  }

  const totalWAR = seasons.reduce((sum, s) => sum + Number(s.war), 0)
  const totalWARStr = Number(totalWAR).toFixed(1)
  const peakWAR = Math.max(...seasons.map(s => Number(s.war)))
  const peakYear = seasons.find(s => Number(s.war) === peakWAR)?.year || 0

  console.log(`Total WAR ${totalWARStr}, Peak WAR ${peakWAR}, Peak Year ${peakYear}`)
  
  const totals = {
    seasons: seasons.length,
    games: seasons.reduce((sum, s) => sum + Number(s.g), 0),
    pa: seasons.reduce((sum, s) => sum + Number(s.pa), 0),
    hr: seasons.reduce((sum, s) => sum + Number(s.hr), 0),
    sb: seasons.reduce((sum, s) => sum + Number(s.sb), 0),
    totalWAR: totalWAR,
    avgWRCPlus: seasons.reduce((sum, s) => sum + Number(s.wrc_plus), 0) / seasons.length,
    peakWAR: peakWAR,
    peakYear: peakYear
  };

  console.log(`Seasons: ${JSON.stringify(seasons, null, 2)}`);

  console.log(`Totals: ${JSON.stringify(totals, null, 2)}`);
  
  return { seasons, totals };
}