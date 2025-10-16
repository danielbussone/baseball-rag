import { pipeline } from '@xenova/transformers';
import pkg from 'pg';
const { Pool } = pkg;
import { fileURLToPath } from 'url';
import { resolve } from 'path';

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface SeasonStats {
  player_season_id: string;
  fangraphs_id: number;
  player_name: string;
  year: number;
  age: number;
  team: string;
  position: string;
  
  // Basic stats
  g: number;
  pa: number;
  hr: number;
  sb: number;
  war: number;
  wrc_plus: number;
  
  // Fielding
  fielding: number | null;
  
  // Statcast (2015+)
  ev90?: number;
  
  // Pre-calculated grades (from R ETL)
  overall_grade: number;
  offense_grade: number;
  power_grade: number;
  hit_grade: number;
  discipline_grade: number;
  contact_grade: number;
  speed_grade: number;
  fielding_grade: number | null;
  hard_contact_grade?: number;
  exit_velo_grade?: number;
}

interface PlayerGrades {
  overall: number;
  overallOffense: number;
  power: number;
  hit: number;
  discipline: number;
  contact: number;
  speed: number;
  fielding: number | null;
  position: string;
  isPremiumPosition: boolean;
  hardContact?: number;
  exitVelo?: number;
}

interface EmbeddingRecord {
  player_season_id: string;
  fangraphs_id: number;
  year: number;
  embedding_type: string;
  summary_text: string;
  embedding: number[];
  metadata: Record<string, any>;
}

// ============================================================================
// GRADING CONSTANTS
// ============================================================================

const GRADE_DESCRIPTORS: Record<number, string> = {
  80: "elite",
  70: "exceptional",
  60: "plus",
  55: "above average",
  50: "average",
  45: "fringe average",
  40: "below average",
  30: "poor",
  20: "extremely poor"
} as const;

const GRADE_DESCRIPTORS_VERBOSE: Record<number, string> = {
  80: "generational, elite, otherworldly, best in baseball",
  70: "exceptional, plus-plus, excellent, fantastic",
  60: "strong, plus, very good",
  55: "solid, above average, good",
  50: "average, league average, MLB regular",
  45: "slight negative, fringe average, fringey",
  40: "below average, replacement level, questionable, negative",
  30: "poor, well below MLB standard, bad",
  20: "extremely poor, unplayable, terrible"
} as const;

const FIELDING_DESCRIPTORS: Record<number, string> = {
  80: "all-time great defender, defensive wizard",
  70: "Gold Glove caliber defender",
  60: "one of the better defenders at his position",
  55: "above average defender",
  50: "solid defender, average",
  45: "adequate defender, fringy",
  40: "below average defender, questionable",
  30: "poor defender, liability",
  20: "extremely poor defender, unplayable"
} as const;

// ============================================================================
// POSITION HELPERS
// ============================================================================

function getPositionDescription(position: string): string {
  const posMap: Record<string, string> = {
    'C': 'at catcher',
    'SS': 'at shortstop',
    'CF': 'in center field',
    '2B': 'at second base',
    '3B': 'at third base',
    'RF': 'in right field',
    'LF': 'in left field',
    '1B': 'at first base',
    'DH': 'as a designated hitter',
    'SS/2B': 'as a middle infielder',
    '2B/SS': 'as a middle infielder',
    'SS/2B/CF': 'as an up the middle defender',
    'CF/SS/2B': 'as an up the middle defender',
    '1B/3B': 'as a corner infielder',
    '3B/1B': 'as a corner infielder',
    '1B/2B/3B/SS': 'as a utility infielder',
    '2B/3B/SS/1B': 'as a utility infielder',
    '1B/3B/OF': 'as a corner guy',
    '3B/1B/OF': 'as a corner guy',
    '1B/OF': 'as a corner guy',
    'OF/1B': 'as a corner guy',
    '2B/3B/OF': 'as a utility player',
    '3B/2B/OF': 'as a utility player',
    'OF': 'as an outfielder',
    'IF': 'as an infielder',
  };
  
  return posMap[position] || position.toLowerCase();
}

function isPremiumDefensivePosition(position: string): boolean {
  const premium = ['C', 'SS', 'CF', '2B'];
  return premium.some(p => position.includes(p));
}

function getFieldingDescription(
  grade: number | null,
  position: string,
  fieldingRuns: number
): string {
  if (grade === null) {
    return "did not field (DH)";
  }
  
  const posDesc = getPositionDescription(position);
  
  if (grade >= 80) {
    return `all-time great defender ${posDesc} (+${fieldingRuns.toFixed(1)} outs above average)`;
  } else if (grade >= 70) {
    return `Gold Glove caliber ${posDesc} (+${fieldingRuns.toFixed(1)} outs above average)`;
  } else if (grade >= 60) {
    return `one of the better defenders ${posDesc} (+${fieldingRuns.toFixed(1)} outs above average)`;
  } else if (grade >= 55) {
    return `slightly above average defender ${posDesc} (+${fieldingRuns.toFixed(1)} outs above average)`;
  } else if (grade >= 50) {
    return `solid defender ${posDesc} (${fieldingRuns.toFixed(1)} outs above average)`;
  } else if (grade >= 45) {
    return `fringy defender ${posDesc} (${fieldingRuns.toFixed(1)} outs above average)`;
  } else if (grade >= 40) {
    return `below average defender ${posDesc} (${fieldingRuns.toFixed(1)} outs above average)`;
  } else if (grade >= 30) {
    return `defensive liability ${posDesc} (${fieldingRuns.toFixed(1)} outs above average)`;
  } else {
    return `extremely poor, borderline unplayable defender ${posDesc} (${fieldingRuns.toFixed(1)} outs above average)`;
  }
}

// ============================================================================
// wRC+ HELPER
// ============================================================================

function getWRCPlusDescription(wrc_plus: number, wrc_plus_grade: number): string {
  const wrcDesc = GRADE_DESCRIPTORS[wrc_plus_grade];
  if(wrc_plus > 100) {
    const pct_above_avg = wrc_plus - 100;
    return `Posted ${wrcDesc} offensive production (${wrc_plus} wRC+ or ${pct_above_avg}% better than league average).`
  } else if(wrc_plus === 100) {
    return `Posted ${wrcDesc} offensive production (${wrc_plus} wRC+ or exactly league average).`
  } else {
    const pct_below_avg = 100 - wrc_plus;
    return `Posted ${wrcDesc} offensive production (${wrc_plus} wRC+ or ${pct_below_avg}% worse than league average).`
  }
}

// ============================================================================
// PLAYER GRADE EXTRACTION (from pre-calculated grades)
// ============================================================================

function getPlayerGrades(season: SeasonStats): PlayerGrades {
  return {
    overall: season.overall_grade,
    overallOffense: season.offense_grade,
    power: season.power_grade,
    hit: season.hit_grade,
    discipline: season.discipline_grade,
    contact: season.contact_grade,
    speed: season.speed_grade,
    fielding: season.fielding_grade,
    position: season.position || 'DH',
    isPremiumPosition: isPremiumDefensivePosition(season.position || ''),
    hardContact: season.hard_contact_grade,
    exitVelo: season.exit_velo_grade
  };
}

// ============================================================================
// SUMMARY GENERATION
// ============================================================================

function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

function generateSeasonSummary(season: SeasonStats): string {
  const grades = getPlayerGrades(season);
  const parts: string[] = [];
  
  parts.push(
    `${season.player_name}, ${season.year} season ` +
    `(age ${season.age}, ${grades.position}, ${season.team}):`
  );
  
  // Overall performance
  const overallDesc = GRADE_DESCRIPTORS[grades.overall];
  parts.push(`${capitalize(overallDesc)} performance with ${season.war.toFixed(1)} WAR.`);
  
  // Offensive production
  if (season.wrc_plus) {
    const wrcDesc = getWRCPlusDescription(season.wrc_plus, grades.overallOffense);
    parts.push(wrcDesc);
  }
  
  // Offensive tools (60+ grade)
  const tools: string[] = [];
  
  if (grades.power >= 60) {
    const powerDesc = GRADE_DESCRIPTORS[grades.power];
    tools.push(`${powerDesc} power`);
  }
  
  if (grades.hit >= 60) {
    const hitDesc = GRADE_DESCRIPTORS[grades.hit];
    tools.push(`${hitDesc} hit tool`);
  }
  
  if (grades.discipline >= 60) {
    const discDesc = GRADE_DESCRIPTORS[grades.discipline];
    tools.push(`${discDesc} plate discipline`);
  }
  
  if (grades.contact >= 60) {
    const contactDesc = GRADE_DESCRIPTORS[grades.contact];
    tools.push(`${contactDesc} contact ability`);
  }
  
  if (grades.speed >= 60) {
    const speedDesc = GRADE_DESCRIPTORS[grades.speed];
    tools.push(`${speedDesc} speed (${season.sb} SB)`);
  }
  
  if (tools.length > 0) {
    parts.push(`Demonstrated ${tools.join(', ')}.`);
  }
  
  // Fielding - mention if notable or premium position
  if (grades.fielding !== null) {
    const fieldingGrade = grades.fielding;
    const shouldMentionDefense =
      fieldingGrade >= 60 ||
      fieldingGrade <= 40 ||
      (grades.isPremiumPosition && fieldingGrade >= 45);
    
    if (shouldMentionDefense) {
      const fieldingDesc = getFieldingDescription(
        grades.fielding,
        grades.position,
        season.fielding!
      );
      parts.push(capitalize(fieldingDesc) + '.');
    }
  }
  
  // Statcast (modern only, 55+ grade)
  if (grades.exitVelo && grades.exitVelo >= 55) {
    const evDesc = GRADE_DESCRIPTORS[grades.exitVelo];
    parts.push(
      `${capitalize(evDesc)} bat speed with ${season.ev90!.toFixed(1)} mph 90th percentile exit velocity.`
    );
  }
  
  return parts.join(' ');
}

// ============================================================================
// DATABASE SETUP
// ============================================================================

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'KenGriffeyJr.24PG'  // CHANGE THIS
});

async function ensureEmbeddingTableExists() {
  const createTableSQL = `
    CREATE TABLE IF NOT EXISTS player_embeddings (
      id SERIAL PRIMARY KEY,
      player_season_id VARCHAR(50) NOT NULL,
      fangraphs_id INTEGER NOT NULL,
      year INTEGER NOT NULL,
      embedding_type VARCHAR(50) NOT NULL,
      summary_text TEXT NOT NULL,
      embedding vector(768),
      metadata JSONB,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(player_season_id, embedding_type)
    );
    
    CREATE INDEX IF NOT EXISTS idx_player_embeddings_vector 
      ON player_embeddings USING hnsw (embedding vector_cosine_ops);
    
    CREATE INDEX IF NOT EXISTS idx_player_embeddings_type 
      ON player_embeddings(embedding_type);
    
    CREATE INDEX IF NOT EXISTS idx_player_embeddings_player 
      ON player_embeddings(fangraphs_id);
    
    CREATE INDEX IF NOT EXISTS idx_player_embeddings_year 
      ON player_embeddings(year);
    
    CREATE INDEX IF NOT EXISTS idx_player_embeddings_metadata 
      ON player_embeddings USING gin(metadata);
  `;
  
  await pool.query(createTableSQL);
  console.log('✓ Embedding table created/verified');
}

// ============================================================================
// EMBEDDING GENERATION
// ============================================================================

let embedder: any = null;

async function initializeEmbedder() {
  console.log('Loading embedding model (all-mpnet-base-v2)...');
  embedder = await pipeline(
    'feature-extraction',
    'Xenova/all-mpnet-base-v2'
  );
  console.log('✓ Embedding model loaded');
}

async function generateEmbedding(text: string): Promise<number[]> {
  if (!embedder) {
    await initializeEmbedder();
  }
  
  const output = await embedder(text, { pooling: 'mean', normalize: true });
  return Array.from(output.data);
}

async function generateEmbeddingsBatch(texts: string[]): Promise<number[][]> {
  if (!embedder) {
    await initializeEmbedder();
  }
  
  const embeddings: number[][] = [];
  for (const text of texts) {
    const embedding = await generateEmbedding(text);
    embeddings.push(embedding);
  }
  return embeddings;
}

// ============================================================================
// MAIN PIPELINE
// ============================================================================

async function fetchSeasons(limit?: number): Promise<SeasonStats[]> {
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
    ORDER BY s.year DESC, s.war DESC
    ${limit ? `LIMIT ${limit}` : ''}
  `;
  
  const result = await pool.query(query);
  return result.rows;
}

async function saveEmbeddings(records: EmbeddingRecord[]) {
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

async function generateAllEmbeddings(batchSize: number = 100) {
  console.log('Starting embedding generation pipeline...\n');
  
  // Ensure table exists
  await ensureEmbeddingTableExists();
  
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

// ============================================================================
// TESTING / DEMO
// ============================================================================

interface SearchFilters {
  position?: string;
  minWAR?: number;
  maxWAR?: number;
  minOverallGrade?: number;
  maxOverallGrade?: number;
  minPowerGrade?: number;
  maxPowerGrade?: number;
  minFieldingGrade?: number;
  maxFieldingGrade?: number;
  yearRange?: [number, number];
}

async function hybridSearch(
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
    console.log(`   WAR: ${row.war} | Position: ${row.position} | Grades: Overall=${row.overall_grade}, Power=${row.power_grade}, Hit=${row.hit_grade}`);
    console.log(`   ${row.summary_text}\n`);
  });
}

async function testSimilaritySearch(queryText: string, limit: number = 10) {
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

// ============================================================================
// CLI INTERFACE
// ============================================================================

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
      // Parse hybrid search arguments
      // Format: npm start hybrid "query text" --position=1B --minWAR=3 --maxFieldingGrade=40
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
          } else if (key === 'yearStart' || key === 'yearEnd') {
            if (!filters.yearRange) filters.yearRange = [1988, 2025];
            if (key === 'yearStart') filters.yearRange[0] = parseInt(value);
            if (key === 'yearEnd') filters.yearRange[1] = parseInt(value);
          }
        }
      }
      
      await initializeEmbedder();
      await hybridSearch(query, filters);
    } else if (command === 'sample') {
      // Generate sample summaries
      console.log('Generate sample summaries')
      const seasons = await fetchSeasons(100);
      if (seasons.length > 0) {
        console.log('\nSample Summaries:\n');
        seasons.forEach((season, idx) => {
          const summary = generateSeasonSummary(season);
          console.log(`${idx + 1}. ${summary}\n`);
        });
      } else {
        console.log('No seasons found')
      }
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
  --minPowerGrade=X        Minimum power grade
  --maxPowerGrade=X        Maximum power grade
  --minFieldingGrade=X     Minimum fielding grade
  --maxFieldingGrade=X     Maximum fielding grade (use for poor defense)
  --yearStart=YYYY         Start year
  --yearEnd=YYYY           End year

Examples:
  npm start generate 100
  npm start test "elite power hitter with great defense"
  npm start hybrid "power hitter" --position=1B --maxFieldingGrade=40
  npm start hybrid "slugging first baseman with poor defense" --position=1B --minPowerGrade=60 --maxFieldingGrade=40
  npm start hybrid "elite shortstop defender" --position=SS --minFieldingGrade=70
  npm start hybrid "five tool player" --minOverallGrade=60 --minPowerGrade=60 --minFieldingGrade=60
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

export { generateSeasonSummary, getPlayerGrades, generateEmbedding };