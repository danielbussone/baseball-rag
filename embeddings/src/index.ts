// Baseball Player Embedding Generation System
// Generates natural language summaries and embeddings for player seasons

import { pipeline } from '@xenova/transformers';
import pkg from 'pg';
const { Pool } = pkg;

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
  ab: number;
  h: number;
  hr: number;
  sb: number;
  
  // Rate stats
  avg: number;
  obp: number;
  slg: number;
  ops: number;
  
  // Advanced stats
  war: number;
  wrc_plus: number;
  
  // Plus stats (era-adjusted)
  avg_plus?: number;
  bb_pct_plus?: number;
  k_pct_plus?: number;
  iso_plus?: number;
  obp_plus?: number;
  slg_plus?: number;
  
  // Plate discipline
  bb_pct: number;
  k_pct: number;
  
  // Fielding
  fielding: number | null;
  positional: number;
  
  // Statcast (2015+)
  ev?: number;
  ev90?: number;
  hardhit_pct?: number;
  hard_pct_plus?: number;
  barrel_pct?: number;
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

const GRADE_DESCRIPTORS = {
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

const GRADE_DESCRIPTORS_VERBOSE = {
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

const FIELDING_DESCRIPTORS = {
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
// GRADING FUNCTIONS
// ============================================================================

// WAR grading (revised thresholds)
function gradeWAR(war: number): number {
  if (war >= 9.0) return 80;
  if (war >= 7.0) return 70;
  if (war >= 5.0) return 60;
  if (war >= 3.0) return 55;
  if (war >= 2.0) return 50;
  if (war >= 1.0) return 45;
  if (war >= -0.3) return 40;
  if (war >= -1.0) return 30;
  return 20;
}

// Generic plus stat grading (100 = league average)
function gradePlusStat(plusStat: number): number {
  if (plusStat >= 180) return 80;
  if (plusStat >= 160) return 70;
  if (plusStat >= 140) return 60;
  if (plusStat >= 120) return 55;
  if (plusStat >= 90) return 50;
  if (plusStat >= 80) return 45;
  if (plusStat >= 70) return 40;
  if (plusStat >= 60) return 30;
  return 20;
}

// Speed grading (SB per 600 PA)
function gradeSpeed(sb: number, pa: number): number {
  const sbPer600 = (sb / pa) * 600;
  if (sbPer600 >= 50) return 80;
  if (sbPer600 >= 40) return 70;
  if (sbPer600 >= 30) return 60;
  if (sbPer600 >= 25) return 55;
  if (sbPer600 >= 15) return 50;
  if (sbPer600 >= 10) return 45;
  if (sbPer600 >= 5) return 40;
  if (sbPer600 >= 2) return 30;
  return 20;
}

// EV90 grading
function gradeEV90(ev90: number): number {
  if (ev90 >= 112.0) return 80;
  if (ev90 >= 110.0) return 70;
  if (ev90 >= 108.0) return 60;
  if (ev90 >= 107.0) return 55;
  if (ev90 >= 105.0) return 50;
  if (ev90 >= 103.0) return 45;
  if (ev90 >= 101.0) return 40;
  if (ev90 >= 99.0) return 30;
  return 20;
}

// Fielding grading (era-adjusted)
interface FieldingEra {
  startYear: number;
  endYear: number;
  catcher: { grade80: number; grade50: number; grade20: number };
  other: { grade80: number; grade50: number; grade20: number };
}

const FIELDING_ERAS: FieldingEra[] = [
  {
    startYear: 1988,
    endYear: 2001,
    catcher: { grade80: 15, grade50: 0, grade20: -15 },
    other: { grade80: 20, grade50: 0, grade20: -20 }
  },
  {
    startYear: 2002,
    endYear: 2015,
    catcher: { grade80: 30, grade50: 0, grade20: -30 },
    other: { grade80: 15, grade50: 0, grade20: -15 }
  },
  {
    startYear: 2016,
    endYear: 2030,
    catcher: { grade80: 30, grade50: 0, grade20: -30 },
    other: { grade80: 15, grade50: 0, grade20: -15 }
  }
];

function getFieldingEra(year: number): FieldingEra {
  return FIELDING_ERAS.find(
    era => year >= era.startYear && year <= era.endYear
  ) || FIELDING_ERAS[2];
}

function isCatcher(position: string): boolean {
  return position === 'C' || position.startsWith('C/') || position.includes('/C');
}

function gradeFielding(
  fielding: number | null,
  year: number,
  position: string
): number | null {
  if (fielding === null) return null;
  
  const era = getFieldingEra(year);
  const isCatch = isCatcher(position);
  const thresholds = isCatch ? era.catcher : era.other;
  
  const { grade80, grade50, grade20 } = thresholds;
  
  if (fielding >= grade80) return 80;
  if (fielding >= grade50) {
    const pct = (fielding - grade50) / (grade80 - grade50);
    return 50 + (pct * 30);
  }
  if (fielding >= grade20) {
    const pct = (fielding - grade20) / (grade50 - grade20);
    return 20 + (pct * 30);
  }
  return 20;
}

// Round grade to nearest standard grade
function roundToGrade(grade: number): 20 | 30 | 40 | 45 | 50 | 55 | 60 | 70 | 80 {
  if (grade >= 75) return 80;
  if (grade >= 65) return 70;
  if (grade >= 57.5) return 60;
  if (grade >= 52.5) return 55;
  if (grade >= 47.5) return 50;
  if (grade >= 42.5) return 45;
  if (grade >= 35) return 40;
  if (grade >= 25) return 30;
  return 20;
}

// ============================================================================
// POSITION HELPERS
// ============================================================================

function getPositionDescription(position: string): string {
  const posMap: Record<string, string> = {
    'C': 'catcher',
    'SS': 'shortstop',
    'CF': 'center field',
    '2B': 'second base',
    '3B': 'third base',
    'RF': 'right field',
    'LF': 'left field',
    '1B': 'first base',
    'DH': 'designated hitter',
    'SS/2B': 'middle infielder',
    '2B/SS': 'middle infielder',
    'SS/2B/CF': 'up the middle defender',
    'CF/SS/2B': 'up the middle defender',
    '1B/3B': 'corner infielder',
    '3B/1B': 'corner infielder',
    '1B/2B/3B/SS': 'utility infielder',
    '2B/3B/SS/1B': 'utility infielder',
    '1B/3B/OF': 'corner player',
    '3B/1B/OF': 'corner player',
    '1B/OF': 'corner player',
    'OF/1B': 'corner player',
    '2B/3B/OF': 'utility player',
    '3B/2B/OF': 'utility player',
    'OF': 'outfielder',
    'IF': 'infielder',
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
  
  const roundedGrade = roundToGrade(grade);
  const posDesc = getPositionDescription(position);
  
  if (roundedGrade >= 80) {
    return `all-time great defender at ${posDesc} (+${fieldingRuns.toFixed(1)} runs)`;
  } else if (roundedGrade >= 70) {
    return `Gold Glove caliber at ${posDesc} (+${fieldingRuns.toFixed(1)} runs)`;
  } else if (roundedGrade >= 60) {
    return `one of the better defenders at ${posDesc} (+${fieldingRuns.toFixed(1)} runs)`;
  } else if (roundedGrade >= 55) {
    return `above average defender at ${posDesc} (+${fieldingRuns.toFixed(1)} runs)`;
  } else if (roundedGrade >= 50) {
    return `solid defender at ${posDesc}`;
  } else if (roundedGrade >= 45) {
    return `adequate at ${posDesc}`;
  } else if (roundedGrade >= 40) {
    return `below average defender at ${posDesc} (${fieldingRuns.toFixed(1)} runs)`;
  } else if (roundedGrade >= 30) {
    return `defensive liability at ${posDesc} (${fieldingRuns.toFixed(1)} runs)`;
  } else {
    return `extremely poor defender at ${posDesc} (${fieldingRuns.toFixed(1)} runs)`;
  }
}

// ============================================================================
// GRADING SYSTEM
// ============================================================================

function gradePlayer(season: SeasonStats): PlayerGrades {
  const fieldingGrade = season.fielding !== null
    ? gradeFielding(season.fielding, season.year, season.position)
    : null;
  
  return {
    overall: gradeWAR(season.war),
    overallOffense: gradePlusStat(season.wrc_plus),
    power: season.iso_plus ? gradePlusStat(season.iso_plus) : 50,
    hit: season.avg_plus ? gradePlusStat(season.avg_plus) : 50,
    discipline: season.bb_pct_plus ? gradePlusStat(season.bb_pct_plus) : 50,
    contact: season.k_pct_plus ? gradePlusStat(season.k_pct_plus) : 50,
    speed: gradeSpeed(season.sb, season.pa),
    fielding: fieldingGrade,
    position: season.position || 'DH',
    isPremiumPosition: isPremiumDefensivePosition(season.position || ''),
    hardContact: season.hard_pct_plus ? gradePlusStat(season.hard_pct_plus) : undefined,
    exitVelo: season.ev90 ? gradeEV90(season.ev90) : undefined
  };
}

// ============================================================================
// SUMMARY GENERATION
// ============================================================================

function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

function generateSeasonSummary(season: SeasonStats): string {
  const grades = gradePlayer(season);
  const parts: string[] = [];
  
  // Header with position
  const posDesc = getPositionDescription(grades.position);
  parts.push(
    `${season.player_name}, ${season.year} season ` +
    `(age ${season.age}, ${posDesc}, ${season.team}):`
  );
  
  // Overall performance
  const overallDesc = GRADE_DESCRIPTORS_VERBOSE[roundToGrade(grades.overall)];
  parts.push(`${capitalize(overallDesc)} performance with ${season.war.toFixed(1)} WAR.`);
  
  // Offensive production
  if (season.wrc_plus) {
    const wrcGrade = roundToGrade(grades.overallOffense);
    const wrcDesc = GRADE_DESCRIPTORS[wrcGrade];
    parts.push(
      `Posted ${wrcDesc} offensive production (${season.wrc_plus} wRC+).`
    );
  }
  
  // Offensive tools (60+ grade)
  const tools: string[] = [];
  
  if (grades.power >= 60) {
    const powerDesc = GRADE_DESCRIPTORS[roundToGrade(grades.power)];
    tools.push(`${powerDesc} power`);
  }
  
  if (grades.hit >= 60) {
    const hitDesc = GRADE_DESCRIPTORS[roundToGrade(grades.hit)];
    tools.push(`${hitDesc} hit tool`);
  }
  
  if (grades.discipline >= 60) {
    const discDesc = GRADE_DESCRIPTORS[roundToGrade(grades.discipline)];
    tools.push(`${discDesc} plate discipline`);
  }
  
  if (grades.contact >= 60) {
    const contactDesc = GRADE_DESCRIPTORS[roundToGrade(grades.contact)];
    tools.push(`${contactDesc} contact ability`);
  }
  
  if (grades.speed >= 60) {
    const speedDesc = GRADE_DESCRIPTORS[roundToGrade(grades.speed)];
    tools.push(`${speedDesc} speed (${season.sb} SB)`);
  }
  
  if (tools.length > 0) {
    parts.push(`Demonstrated ${tools.join(', ')}.`);
  }
  
  // Fielding - mention if notable or premium position
  if (grades.fielding !== null) {
    const fieldingGrade = roundToGrade(grades.fielding);
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
    const evDesc = GRADE_DESCRIPTORS[roundToGrade(grades.exitVelo)];
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
  password: 'yourpassword'  // CHANGE THIS
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
      s.ab,
      s.h,
      s.hr,
      s.sb,
      s.avg,
      s.obp,
      s.slg,
      s.ops,
      s.war,
      s.wrc_plus,
      s.avg_plus,
      s.bb_pct_plus,
      s.k_pct_plus,
      s.iso_plus,
      s.obp_plus,
      s.slg_plus,
      s.bb_pct,
      s.k_pct,
      s.fielding,
      s.positional,
      s.ev,
      s.ev90,
      s.hardhit_pct,
      s.hard_pct_plus,
      s.barrel_pct
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
      const grades = gradePlayer(season);
      
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
          overall_grade: roundToGrade(grades.overall),
          power_grade: roundToGrade(grades.power),
          hit_grade: roundToGrade(grades.hit)
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
    } else if (command === 'sample') {
      // Generate sample summary
      const seasons = await fetchSeasons(1);
      if (seasons.length > 0) {
        const summary = generateSeasonSummary(seasons[0]);
        console.log('\nSample Summary:\n');
        console.log(summary);
        console.log('\n');
      }
    } else {
      console.log(`
Baseball Player Embedding Generation System

Usage:
  npm start generate [batchSize]  - Generate embeddings for all seasons
  npm start test [query]           - Test similarity search
  npm start sample                 - Show sample summary

Examples:
  npm start generate 100
  npm start test "elite power hitter with great defense"
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
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { generateSeasonSummary, gradePlayer, generateEmbedding };