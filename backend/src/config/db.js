const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.PG_HOST || 'localhost',
  port: parseInt(process.env.PG_PORT || '5432', 10),
  database: process.env.PG_DATABASE || 'friend_tracker',
  user: process.env.PG_USER || 'postgres',
  password: process.env.PG_PASSWORD || 'postgres',
  max: 20, // Connection pool size
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

pool.on('error', (err) => {
  console.error('⚠️ Unexpected PostgreSQL idle client error:', err.message);
});

/**
 * Initializes database connection and verifies table structures.
 */
async function initDatabase() {
  try {
    const client = await pool.connect();
    console.log('✅ Connected to PostgreSQL database successfully.');
    
    // Auto-create schema tables
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
    `);
    
    client.release();
    console.log('✅ PostgreSQL tables verified.');
  } catch (err) {
    console.warn('⚠️ Could not connect to PostgreSQL immediately:', err.message);
    console.warn('   Ensure PostgreSQL service is running and credentials in backend/.env match.');
  }
}

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
  initDatabase,
};
