import type { SearchFilters } from '../types/SearchFilters.js';
import { pool } from '../config/database.js';
import { generateEmbedding } from '../services/embedding.js';

export async function hybridSearch(
  queryText: string,
  filters: SearchFilters = {},
  limit: number = 10
) {
  console.log(`\nHybrid Search for: "${queryText}"`);
  if (Object.keys(filters).length > 0) {
    console.log(`Filters: ${JSON.stringify(filters, null, 2)}`);
  }
  console.log();

  // Generate query embedding
  const queryEmbedding = await generateEmbedding(queryText);

  // Build WHERE clause from filters
  const whereClauses: string[] = ["embedding_type = 'season_summary'"];
  const params: any[] = [JSON.stringify(queryEmbedding), limit];
  let paramIndex = 3;

  if (filters.position) {
    whereClauses.push(`s.position ILIKE \$${paramIndex}`);
    params.push(`%${filters.position}%`)
    paramIndex++;
  }

  if (filters.minWAR !== undefined) {
    whereClauses.push(`s.war >= \$${paramIndex}`);
    params.push(filters.minWAR)
    paramIndex++;
  }

  if (filters.maxWAR !== undefined) {
    whereClauses.push(`s.war <= \$${paramIndex}`);
    params.push(filters.maxWAR)
    paramIndex++;
  }

  if (filters.minOverallGrade !== undefined) {
    whereClauses.push(`s.overall_grade >= \$${paramIndex}`);
    params.push(filters.minOverallGrade)
    paramIndex++;
  }

  if (filters.maxOverallGrade !== undefined) {
    whereClauses.push(`s.overall_grade <= \$${paramIndex}`);
    params.push(filters.maxOverallGrade)
    paramIndex++;
  }

  if (filters.minHitGrade !== undefined) {
    whereClauses.push(`s.hit_grade >= \$${paramIndex}`);
    params.push(filters.minHitGrade)
    paramIndex++;
  }

  if (filters.maxHitGrade !== undefined) {
    whereClauses.push(`s.hit_grade <= \$${paramIndex}`);
    params.push(filters.maxHitGrade)
    paramIndex++;
  }

  if (filters.minPowerGrade !== undefined) {
    whereClauses.push(`s.power_grade >= \$${paramIndex}`);
    params.push(filters.minPowerGrade)
    paramIndex++;
  }

  if (filters.maxPowerGrade !== undefined) {
    whereClauses.push(`s.power_grade <= \$${paramIndex}`);
    params.push(filters.maxPowerGrade)
    paramIndex++;
  }

  if (filters.minFieldingGrade !== undefined) {
    whereClauses.push(`s.fielding_grade >= \$${paramIndex}`);
    params.push(filters.minFieldingGrade)
    paramIndex++;
  }

  if (filters.maxFieldingGrade !== undefined) {
    whereClauses.push(`s.fielding_grade <= \$${paramIndex}`);
    params.push(filters.maxFieldingGrade)
    paramIndex++;
  }

  if (filters.minSpeedGrade !== undefined) {
    whereClauses.push(`s.speed_grade >= \$${paramIndex}`);
    params.push(filters.minSpeedGrade)
    paramIndex++;
  }

  if (filters.maxSpeedGrade !== undefined) {
    whereClauses.push(`s.speed_grade <= \$${paramIndex}`);
    params.push(filters.maxSpeedGrade)
    paramIndex++;
  }

  if (filters.yearRange) {
    whereClauses.push(`year BETWEEN \$${paramIndex} AND \$${paramIndex + 1}`);
    params.push(filters.yearRange[0], filters.yearRange[1])
    paramIndex++;
  }

  const whereClause = whereClauses.join(' AND ');

  console.log(`WHERE: ${whereClause}`)

  const query = `
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
    ORDER BY embedding <=> $1::vector
    LIMIT $2
  `;

  const result = await pool.query(query, params);

  if (result.rows.length === 0) {
    console.log('No results found with the given filters. Try relaxing your constraints.\n');
    return;
  }

  console.log('Top results:\n');
  result.rows.forEach((row, idx) => {
    console.log(`${idx + 1}. (${(row.similarity * 100).toFixed(1)}% match)`);
    console.log(`   WAR: ${row.war} | Position: ${row.position} | Grades: Overall=${row.overall_grade}, Hit=${row.hit_grade}, Power=${row.power_grade}, Fielding=${row.fielding_grade}, Speed=${row.speed_grade}`);
    console.log(`   ${row.summary_text}\n`);
  });
}

export function parseHybridSearchArgs(args: string[]): { query: string; filters: SearchFilters } {
  const query = args[1] || 'power hitter';
  const filters: SearchFilters = {};

  for (let i = 2; i < args.length; i++) {
    const arg = args[i];
    if (arg.startsWith('--')) {
      const [key, value] = arg.substring(2).split('=');

      if (key === 'position') {
        filters.position = value;
      } else if (key === 'minWAR') {
        filters.minWAR = parseFloat(value);
      } else if (key === 'maxWAR') {
        filters.maxWAR = parseFloat(value);
      } else if (key === 'minOverallGrade') {
        filters.minOverallGrade = parseInt(value);
      } else if (key === 'maxOverallGrade') {
        filters.maxOverallGrade = parseInt(value);
      } else if (key === 'minPowerGrade') {
        filters.minPowerGrade = parseInt(value);
      } else if (key === 'maxPowerGrade') {
        filters.maxPowerGrade = parseInt(value);
      } else if (key === 'minFieldingGrade') {
        filters.minFieldingGrade = parseInt(value);
      } else if (key === 'maxFieldingGrade') {
        filters.maxFieldingGrade = parseInt(value);
      } else if (key === 'minSpeedGrade') {
        filters.minSpeedGrade = parseInt(value);
      } else if (key === 'maxSpeedGrade') {
        filters.maxSpeedGrade = parseInt(value);
      } else if (key === 'yearStart' || key === 'yearEnd') {
        if (!filters.yearRange) filters.yearRange = [1988, 2025];
        if (key === 'yearStart') filters.yearRange[0] = parseInt(value);
        if (key === 'yearEnd') filters.yearRange[1] = parseInt(value);
      }
    }
  }

  return { query, filters };
}
