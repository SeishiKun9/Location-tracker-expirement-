-- ====================================================================
-- FRIEND TRACKER - POSTGRESQL DATABASE SCHEMA
-- ====================================================================

-- 1. Rooms Table (Tracks active sharing sessions)
CREATE TABLE IF NOT EXISTS rooms (
    id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Users Table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(20) DEFAULT '#38BDF8',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Live Locations (Current latest pin for each user in a room)
CREATE TABLE IF NOT EXISTS live_locations (
    user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
    room_id VARCHAR(20) REFERENCES rooms(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    speed DOUBLE PRECISION DEFAULT 0.0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, room_id)
);

-- 4. Location History (Breadcrumb trail / route history over time)
CREATE TABLE IF NOT EXISTS location_history (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
    room_id VARCHAR(20) REFERENCES rooms(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    speed DOUBLE PRECISION DEFAULT 0.0,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Indexes for fast geospatial lookup & real-time querying
CREATE INDEX IF NOT EXISTS idx_live_locations_room ON live_locations(room_id);
CREATE INDEX IF NOT EXISTS idx_location_history_user_room ON location_history(user_id, room_id, recorded_at DESC);
