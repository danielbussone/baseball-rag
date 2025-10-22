import pkg from 'pg';
import { env } from '../config/env.js';
import { createModuleLogger } from '../config/logger.js';

const { Pool } = pkg;
const logger = createModuleLogger('Database');

export const pool = new Pool({
  host: env.db.host,
  port: env.db.port,
  database: env.db.database,
  user: env.db.user,
  password: env.db.password,
});

// Log connection events
pool.on('connect', () => {
  logger.debug('New database connection established');
});

pool.on('error', (err) => {
  logger.error({ err }, 'Unexpected database error');
});

// Test connection on startup
pool.query('SELECT NOW()')
  .then(() => {
    logger.info(
      {
        host: env.db.host,
        port: env.db.port,
        database: env.db.database,
      },
      'Database connection pool initialized'
    );
  })
  .catch((err) => {
    logger.error({ err }, 'Failed to initialize database connection');
  });