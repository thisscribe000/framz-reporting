import { Pool } from 'pg';
import initSqlJs, { Database } from 'sql.js';
import path from 'path';
import fs from 'fs';

const isPostgres = !!process.env.DATABASE_URL || !!process.env.PGHOST;

let pgPool: Pool | null = null;
let sqlJsDb: Database | null = null;

const dbDir = path.join(__dirname, '../../data');
const sqliteFilePath = path.join(dbDir, 'framz_local.sqlite');

export async function getDb(): Promise<Database> {
  if (sqlJsDb) return sqlJsDb;

  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
  }

  const SQL = await initSqlJs();
  if (fs.existsSync(sqliteFilePath)) {
    const fileBuffer = fs.readFileSync(sqliteFilePath);
    sqlJsDb = new SQL.Database(fileBuffer);
  } else {
    sqlJsDb = new SQL.Database();
  }
  return sqlJsDb;
}

export function persistLocalDb() {
  if (!isPostgres && sqlJsDb) {
    const data = sqlJsDb.export();
    const buffer = Buffer.from(data);
    fs.writeFileSync(sqliteFilePath, buffer);
  }
}

if (isPostgres) {
  pgPool = new Pool({
    connectionString:
      process.env.DATABASE_URL ||
      `postgres://${process.env.PGUSER || 'postgres'}:${process.env.PGPASSWORD || 'postgres'}@${
        process.env.PGHOST || 'localhost'
      }:${process.env.PGPORT || '5432'}/${process.env.PGDATABASE || 'framz_db'}`,
  });
  console.log('[DB] Configured for PostgreSQL production database.');
} else {
  console.log(`[DB] Configured with pure SQL.js SQLite engine at ${sqliteFilePath}`);
}

export async function query(sql: string, params: any[] = []): Promise<any[]> {
  if (isPostgres && pgPool) {
    let pgSql = sql;
    let paramIdx = 1;
    while (pgSql.includes('?')) {
      pgSql = pgSql.replace('?', `$${paramIdx++}`);
    }
    const res = await pgPool.query(pgSql, params);
    return res.rows;
  }

  // Pure SQLite execution via sql.js
  const db = await getDb();
  const cleanSql = sql.trim();

  // Convert PostgreSQL specific types to SQLite syntax
  const sqliteSql = cleanSql
    .replace(/SERIAL PRIMARY KEY/gi, 'INTEGER PRIMARY KEY AUTOINCREMENT')
    .replace(/TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP/gi, 'DATETIME DEFAULT CURRENT_TIMESTAMP')
    .replace(/NUMERIC\(\d+,\s*\d+\)/gi, 'REAL')
    .replace(/GENERATED ALWAYS AS \(.*?\) STORED/gi, '');

  try {
    const stmt = db.prepare(sqliteSql);
    if (params && params.length > 0) {
      stmt.bind(params);
    }

    const rows: any[] = [];
    while (stmt.step()) {
      rows.push(stmt.getAsObject());
    }
    stmt.free();

    // Check if it's a write statement and persist
    const upper = cleanSql.toUpperCase();
    if (
      upper.startsWith('INSERT') ||
      upper.startsWith('UPDATE') ||
      upper.startsWith('DELETE') ||
      upper.startsWith('CREATE') ||
      upper.startsWith('ALTER')
    ) {
      persistLocalDb();
      if (upper.startsWith('INSERT')) {
        const lastIdRes = db.exec('SELECT last_insert_rowid() as id');
        const lastId = lastIdRes[0]?.values[0]?.[0] || 1;
        return [{ id: lastId }];
      }
    }

    return rows;
  } catch (err: any) {
    // If it's multiple DDL statements (like schema initialization)
    if (cleanSql.includes(';')) {
      db.run(sqliteSql);
      persistLocalDb();
      return [];
    }
    throw err;
  }
}

export async function initDb() {
  const possiblePaths = [
    path.join(__dirname, 'schema.sql'),
    path.join(__dirname, '../src/db/schema.sql'),
    path.join(__dirname, '../../src/db/schema.sql'),
    path.join(process.cwd(), 'src/db/schema.sql'),
    path.join(process.cwd(), 'backend/src/db/schema.sql'),
  ];
  let schemaSql = '';
  for (const p of possiblePaths) {
    if (fs.existsSync(p)) {
      schemaSql = fs.readFileSync(p, 'utf8');
      break;
    }
  }

  if (!schemaSql) {
    console.warn('[DB] schema.sql not found, skipping schema initialization.');
    return;
  }

  if (isPostgres && pgPool) {
    await pgPool.query(schemaSql);
    console.log('[DB] PostgreSQL schema initialized.');
  } else {
    const db = await getDb();
    const statements = schemaSql
      .replace(/GENERATED ALWAYS AS \(.*?\) STORED/gi, '')
      .replace(/SERIAL PRIMARY KEY/gi, 'INTEGER PRIMARY KEY AUTOINCREMENT')
      .replace(/TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP/gi, 'DATETIME DEFAULT CURRENT_TIMESTAMP')
      .replace(/NUMERIC\(\d+,\s*\d+\)/gi, 'REAL')
      .split(';')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    for (const statement of statements) {
      try {
        db.run(statement);
      } catch (err: any) {
        if (!err.message?.includes('already exists')) {
          console.warn('[DB Init Warning]', err.message);
        }
      }
    }
    persistLocalDb();
    console.log('[DB] SQLite schema initialized via sql.js.');
  }
}
