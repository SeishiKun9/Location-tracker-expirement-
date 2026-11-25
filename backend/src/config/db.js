const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.PG_HOST || 'localhost',
  port: parseInt(process.env.PG_PORT || '5432', 10),
  database: process.env.PG_DATABASE || 'friend_tracker',
  user: process.env.PG_USER || 'postgres',
  password: process.env.PG_PASSWORD || 'postgres',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

let connected = false;

pool.on('error', (err) => {
  connected = false;
  console.error('⚠️ Unexpected PostgreSQL idle client error:', err.message);
});

/**
 * Initializes database connection and verifies table structures and indexes.
 */
async function initDatabase() {
  try {
    const client = await pool.connect();
    try {
      await client.query(`
        CREATE TABLE IF NOT EXISTS rooms (
            id VARCHAR(20) PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS users (
            id VARCHAR(50) PRIMARY KEY,
            name VARCHAR(50) NOT NULL,
            color VARCHAR(20) DEFAULT '#38BDF8',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS live_locations (
            user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
            room_id VARCHAR(20) REFERENCES rooms(id) ON DELETE CASCADE,
            latitude DOUBLE PRECISION NOT NULL,
            longitude DOUBLE PRECISION NOT NULL,
            speed DOUBLE PRECISION DEFAULT 0.0,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            PRIMARY KEY (user_id, room_id)
        );

        CREATE TABLE IF NOT EXISTS location_history (
            id BIGSERIAL PRIMARY KEY,
            user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
            room_id VARCHAR(20) REFERENCES rooms(id) ON DELETE CASCADE,
            latitude DOUBLE PRECISION NOT NULL,
            longitude DOUBLE PRECISION NOT NULL,
            speed DOUBLE PRECISION DEFAULT 0.0,
            recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_live_locations_room
            ON live_locations(room_id);
        CREATE INDEX IF NOT EXISTS idx_location_history_user_room
            ON location_history(user_id, room_id, recorded_at DESC);
      `);
      connected = true;
      console.log('✅ PostgreSQL connected and tables verified.');
    } finally {
      client.release();
    }
  } catch (err) {
    connected = false;
    console.warn('⚠️ PostgreSQL unavailable; running with in-memory fallback:', err.message || 'connection failed');
  }
}

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
  initDatabase,
  isReady: () => connected,
};
