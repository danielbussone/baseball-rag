# Embedding Generation System

TypeScript-based system that generates semantic embeddings for baseball player seasons using transformers.js and stores them in PostgreSQL with pgvector.

## Overview

- **Model**: `all-mpnet-base-v2` (768 dimensions, ~420MB)
- **Input**: Natural language player season summaries
- **Output**: Vector embeddings stored in PostgreSQL
- **Search**: Hybrid semantic + SQL filtering

## Quick Start

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Generate embeddings for all seasons (~15-20 minutes)
npm run generate

# Test semantic search
npm start test "elite power hitter"

# Test hybrid search with filters
npm start hybrid "slugging first baseman" --position=1B --minPowerGrade=60
```

## Architecture

### Modular TypeScript Structure
```
src/
├── types/           # TypeScript interfaces
├── constants/       # Grade descriptors, position mappings
├── config/          # Database configuration
├── utils/           # Helper functions (grading, positions, text)
├── services/        # Core services (embedding, database, summary)
└── commands/        # CLI commands (generate, test, hybrid)
```

### Key Components

**Summary Generation** (`services/summary.ts`)
- Template-based player descriptions
- Incorporates stats, grades, and context
- Consistent format for embedding quality

**Embedding Service** (`services/embedding.ts`)
- Loads transformers.js model locally
- Batches processing for performance
- Handles model caching and memory management

**Database Service** (`services/database.ts`)
- PostgreSQL connection with pgvector
- Upsert logic for incremental updates
- Hybrid search queries (semantic + filters)

## Player Summary Templates

Generates natural language descriptions like:

> "Mike Trout had an elite 2019 season at center field for the Angels. At age 27 with 600 PA, he showed elite overall performance (80 grade) with elite power (75 grade), plus hitting (65 grade), and elite plate discipline (80 grade). His 45.4 WAR and 185 wRC+ demonstrate exceptional offensive production."

### Template Components
- **Context**: Player, year, age, team, position
- **Performance**: Overall grade and WAR
- **Skills**: Power, hitting, discipline grades with descriptors
- **Stats**: Key metrics (wRC+, HR, etc.)
- **Fielding**: Position-specific defensive context

## Search Capabilities

### Semantic Search
```bash
# Find similar players by description
npm start test "contact hitter with speed"
npm start test "defensive specialist shortstop"
npm start test "power hitter with strikeout issues"
```

### Hybrid Search (Semantic + Filters)
```bash
# Position filtering
npm start hybrid "elite defender" --position=SS

# Grade filtering  
npm start hybrid "power hitter" --minPowerGrade=70 --maxContactGrade=40

# Year filtering
npm start hybrid "steroid era slugger" --startYear=1995 --endYear=2005

# Multiple filters
npm start hybrid "five tool player" --minOverallGrade=60 --minPowerGrade=60 --minFieldingGrade=60
```

### Filter Options
- `--position` - Position filter (1B, SS, OF, etc.)
- `--minPowerGrade` / `--maxPowerGrade` - Power grade range (20-80)
- `--minHitGrade` / `--maxHitGrade` - Contact grade range
- `--minFieldingGrade` / `--maxFieldingGrade` - Defense grade range
- `--minOverallGrade` / `--maxOverallGrade` - Overall grade range
- `--startYear` / `--endYear` - Year range
- `--limit` - Number of results (default: 10)

## Performance

### Generation
- **Full generation**: ~15-20 minutes for all seasons
- **Incremental**: ~30 seconds for new seasons
- **Batch size**: 100 summaries per batch
- **Memory usage**: ~2GB peak (model + batches)

### Search
- **Semantic search**: ~50-100ms
- **Hybrid search**: ~100-200ms (includes SQL filters)
- **Index type**: HNSW for fast approximate search
- **Accuracy**: >95% for similar player queries

## Database Schema

### `player_embeddings` Table
```sql
CREATE TABLE player_embeddings (
    id SERIAL PRIMARY KEY,
    player_season_id VARCHAR(50) NOT NULL,
    fangraphs_id INTEGER NOT NULL,
    year INTEGER NOT NULL,
    embedding_type VARCHAR(50) NOT NULL,
    summary_text TEXT NOT NULL,
    embedding vector(768) NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX ON player_embeddings USING hnsw (embedding vector_cosine_ops);
CREATE INDEX ON player_embeddings (fangraphs_id, year);
CREATE INDEX ON player_embeddings (embedding_type);
```

## Configuration

### Database Connection
```typescript
// config/database.ts
export const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'postgres',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'baseball123'
};
```

### Model Settings
```typescript
// services/embedding.ts
const MODEL_NAME = 'Xenova/all-mpnet-base-v2';
const BATCH_SIZE = 100;
const MAX_LENGTH = 512;  // Token limit
```

## Troubleshooting

### Model Loading Issues
```
Error: Could not load model
```
- Ensure internet connection for first download
- Model cached in `~/.cache/huggingface/transformers`
- Clear cache if corrupted: `rm -rf ~/.cache/huggingface`

### Memory Issues
```
Error: JavaScript heap out of memory
```
- Reduce batch size in `services/embedding.ts`
- Increase Node.js memory: `node --max-old-space-size=4096`
- Process in smaller chunks

### Search Quality Issues
```
Results don't match query semantically
```
- Check summary quality with `npm start sample`
- Verify grade calculations in source data
- Consider query expansion or reranking (Phase 2)

### Database Connection
```
Error: Connection refused
```
- Ensure PostgreSQL is running
- Verify pgvector extension: `SELECT * FROM pg_extension WHERE extname = 'vector';`
- Check connection parameters

## Development

### Adding New Embedding Types
1. Add type to `types/EmbeddingRecord.ts`
2. Create summary generator in `services/summary.ts`
3. Update generation logic in `commands/generate.ts`

### Improving Search Quality
1. **Better summaries**: Enhance templates in `services/summary.ts`
2. **Query expansion**: Add synonyms and baseball terminology
3. **Reranking**: Implement cross-encoder for Phase 2
4. **Filters**: Add new grade/stat filters in `commands/hybrid.ts`

### Testing Changes
```bash
# Generate sample summaries
npm start sample --limit=5

# Test specific player
npm start test "Mike Trout 2019"

# Compare before/after changes
npm start hybrid "power hitter" --limit=20
```

## Future Enhancements

- **Cross-encoder reranking** - Better precision for complex queries
- **Full-text search integration** - Keyword matching for short queries
- **Career embeddings** - Multi-season player profiles
- **Pitch-level embeddings** - Detailed pitcher analysis
- **Dynamic summaries** - LLM-generated descriptions vs templates