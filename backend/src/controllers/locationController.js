const db = require('../config/db');

/**
 * Updates or inserts a user's latest live GPS coordinate.
 */
async function updateLocation(userId, userName, userColor, roomId, latitude, longitude, speed = 0.0) {
  // 1. Ensure Room exists
  await db.query(
    `INSERT INTO rooms (id, name) VALUES ($1, $2) ON CONFLICT (id) DO NOTHING`,
    [roomId, `Room ${roomId}`]
  );

  // 2. Ensure User exists
  await db.query(
    `INSERT INTO users (id, name, color) VALUES ($1, $2, $3)
     ON CONFLICT (id) DO UPDATE SET name = $2, color = $3`,
    [userId, userName || 'Friend', userColor || '#38BDF8']
  );

  // 3. Upsert live location
  await db.query(
    `INSERT INTO live_locations (user_id, room_id, latitude, longitude, speed, updated_at)
     VALUES ($1, $2, $3, $4, $5, NOW())
     ON CONFLICT (user_id, room_id) 
     DO UPDATE SET latitude = $3, longitude = $4, speed = $5, updated_at = NOW()`,
    [userId, roomId, latitude, longitude, speed]
  );

  // 4. Log to history trail
  await db.query(
    `INSERT INTO location_history (user_id, room_id, latitude, longitude, speed, recorded_at)
     VALUES ($1, $2, $3, $4, $5, NOW())`,
    [userId, roomId, latitude, longitude, speed]
  );
}

/**
 * Retrieves all active friends in a specific room.
 */
async function getRoomFriends(roomId) {
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
 * Removes a user's live marker when they leave or pause.
 */
async function removeUserFromRoom(userId, roomId) {
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
