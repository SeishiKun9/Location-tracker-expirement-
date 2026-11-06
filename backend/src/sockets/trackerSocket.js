const locationController = require('../controllers/locationController');

function setupTrackerSocket(io) {
  io.on('connection', (socket) => {
    let currentRoomId = null;
    let currentUserId = null;

    console.log(`🔌 Client connected: ${socket.id}`);

    // Join tracking room
    socket.on('join_room', async ({ roomId, userId, userName, userColor }) => {
      currentRoomId = roomId;
      currentUserId = userId;

      socket.join(roomId);
      console.log(`👤 User "${userName}" (${userId}) joined room: ${roomId}`);

      try {
        // Fetch current active friends from PostgreSQL
        const activeFriends = await locationController.getRoomFriends(roomId);
        socket.emit('room_state', activeFriends);

        // Notify other room members
        socket.to(roomId).emit('friend_joined', { userId, userName, userColor });
      } catch (err) {
        console.error('Error fetching room state:', err.message);
      }
    });

    // Handle incoming live GPS update
    socket.on('send_location', async (data) => {
      const { userId, userName, userColor, roomId, latitude, longitude, speed } = data;

      try {
        // 1. Persist to PostgreSQL database
        await locationController.updateLocation(
          userId,
          userName,
          userColor,
          roomId,
          latitude,
          longitude,
          speed || 0.0
        );

        // 2. Broadcast to all friends in the room in real time
        socket.to(roomId).emit('location_updated', {
          id: userId,
          name: userName,
          color: userColor,
          latitude,
          longitude,
          speed,
          updated_at: new Date().toISOString(),
        });
      } catch (err) {
        console.error('Error handling location update:', err.message);
      }
    });

    // Handle user disconnecting
    socket.on('disconnect', async () => {
      console.log(`🔌 Client disconnected: ${socket.id}`);
      if (currentRoomId && currentUserId) {
        socket.to(currentRoomId).emit('friend_left', { userId: currentUserId });
      }
    });
  });
}

module.exports = setupTrackerSocket;
