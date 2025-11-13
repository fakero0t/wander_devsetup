import knex, { Knex } from 'knex';

let db: Knex | null = null;

export async function connectDatabase(): Promise<Knex> {
  if (db) {
    return db;
  }

  const host = process.env.POSTGRES_HOST || process.env.DATABASE_HOST || 'postgres';
  const port = parseInt(process.env.POSTGRES_PORT || process.env.DATABASE_PORT || '5432');
  const user = process.env.POSTGRES_USER || process.env.DATABASE_USER || 'postgres';
  const password = process.env.POSTGRES_PASSWORD || process.env.DATABASE_PASSWORD || 'postgres';
  const database = process.env.POSTGRES_DB || process.env.DATABASE_NAME || 'wander_dev';

  const config: Knex.Config = {
    client: 'pg',
    connection: { host, port, user, password, database },
    pool: {
      min: 2,
      max: 10,
    },
    migrations: {
      directory: './migrations',
      tableName: 'knex_migrations',
    },
  };

  db = knex(config);

  // Test connection
  try {
    await db.raw('SELECT 1');
  } catch (error) {
    console.error('Database connection failed:', error);
    throw error;
  }

  return db;
}

export function getDatabase(): Knex {
  if (!db) {
    throw new Error('Database not initialized. Call connectDatabase() first.');
  }
  return db;
}

