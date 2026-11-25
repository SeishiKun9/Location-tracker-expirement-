const db = require('../config/db');

// shortcut: in-memory room fallback when PostgreSQL is offline; start PostgreSQL for persistent history
const memoryRooms = new Map();

function isValidCoord(lat, lng) {
  return (
    typeof lat === 'number' &&
    typeof lng === 'number' &&
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

/**
 * Updates or inserts a user's latest live GPS coordinate.
 */
async function updateLocation(userId, userName, userColor, roomId, latitude, longitude, speed = 0.0) {
  if (!userId || !roomId || !isValidCoord(latitude, longitude)) {
    throw new Error('Invalid location payload');
  }

  const safeName = userName || 'Friend';
  const safeColor = userColor || '#38BDF8';
  const safeSpeed = typeof speed === 'number' && Number.isFinite(speed) ? speed : 0.0;

  if (!memoryRooms.has(roomId)) memoryRooms.set(roomId, new Map());
  memoryRooms.get(roomId).set(userId, {
    id: userId,
    name: safeName,
    color: safeColor,
    latitude,
    longitude,
    speed: safeSpeed,
    updated_at: new Date().toISOString(),
  });

  if (!db.isReady()) return;

  await db.query(
    `INSERT INTO rooms (id, name) VALUES ($1, $2) ON CONFLICT (id) DO NOTHING`,
    [roomId, `Room ${roomId}`]
  );

  await db.query(
    `INSERT INTO users (id, name, color) VALUES ($1, $2, $3)
     ON CONFLICT (id) DO UPDATE SET name = $2, color = $3`,
    [userId, safeName, safeColor]
  );

  await db.query(
    `INSERT INTO live_locations (user_id, room_id, latitude, longitude, speed, updated_at)
     VALUES ($1, $2, $3, $4, $5, NOW())
     ON CONFLICT (user_id, room_id)
     DO UPDATE SET latitude = $3, longitude = $4, speed = $5, updated_at = NOW()`,
    [userId, roomId, latitude, longitude, safeSpeed]
  );

  await db.query(
    `INSERT INTO location_history (user_id, room_id, latitude, longitude, speed, recorded_at)
     VALUES ($1, $2, $3, $4, $5, NOW())`,
    [userId, roomId, latitude, longitude, safeSpeed]
  );
}

/**
 * Retrieves all active friends in a specific room.
 */
async function getRoomFriends(roomId) {
  if (!roomId) return [];

  if (!db.isReady()) {
    const room = memoryRooms.get(roomId);
    return room ? Array.from(room.values()) : [];
  }

  const result = await db.query(
    `SELECT
        u.id,
        u.name,
        u.color,
        l.latitude,
        l.longitude,
        l.speed,
        l.updated_at
     FROM live_locations l
     JOIN users u ON l.user_id = u.id
     WHERE l.room_id = $1
     ORDER BY l.updated_at DESC`,
    [roomId]
  );
  return result.rows;
}

/**
 * Removes a user's live marker when they leave or disconnect.
 */
async function removeUserFromRoom(userId, roomId) {
  if (!userId || !roomId) return;

  const room = memoryRooms.get(roomId);
  if (room) {
    room.delete(userId);
    if (room.size === 0) memoryRooms.delete(roomId);
  }

  if (!db.isReady()) return;

  await db.query(
    `DELETE FROM live_locations WHERE user_id = $1 AND room_id = $2`,
    [userId, roomId]
  );
}

module.exports = {
  updateLocation,
  getRoomFriends,
  removeUserFromRoom,
};
