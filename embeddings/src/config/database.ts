import pkg from 'pg';
const { Pool } = pkg;

export const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'baseball123'  // CHANGE THIS
});

export async function verifyEmbeddingTableExists() {
  try {
    const result = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = 'player_embeddings'
      );
    `);

    if (!result.rows[0].exists) {
      console.error('❌ Error: player_embeddings table does not exist. Please run the schema file to create it.');
      throw new Error('player_embeddings table does not exist');
    }

    console.log('✓ Embedding table verified');
  } catch (error) {
    console.error('❌ Error verifying embedding table:', error);
    throw error;
  }
}
