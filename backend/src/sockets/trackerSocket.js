const locationController = require('../controllers/locationController');

function setupTrackerSocket(io) {
  io.on('connection', (socket) => {
    let currentRoomId = null;
    let currentUserId = null;

    console.log(`🔌 Client connected: ${socket.id}`);

    socket.on('join_room', async (payload = {}) => {
      const { roomId, userId, userName, userColor } = payload;
      if (!roomId || !userId) return;

      if (currentRoomId && currentRoomId !== roomId) {
        socket.leave(currentRoomId);
      }

      currentRoomId = String(roomId);
      currentUserId = String(userId);

      socket.join(currentRoomId);
      console.log(`👤 User "${userName || 'Friend'}" (${currentUserId}) joined room: ${currentRoomId}`);

      try {
        const activeFriends = await locationController.getRoomFriends(currentRoomId);
        socket.emit('room_state', activeFriends);
        socket.to(currentRoomId).emit('friend_joined', {
          userId: currentUserId,
          userName: userName || 'Friend',
          userColor: userColor || '#38BDF8',
        });
      } catch (err) {
        console.error('Error fetching room state:', err.message);
      }
    });

    socket.on('send_location', async (data = {}) => {
      const { userId, userName, userColor, roomId, latitude, longitude, speed } = data;
      const targetRoom = roomId || currentRoomId;
      const targetUser = userId || currentUserId;
      if (!targetRoom || !targetUser || typeof latitude !== 'number' || typeof longitude !== 'number') {
        return;
      }

      const safeSpeed = typeof speed === 'number' && Number.isFinite(speed) ? speed : 0.0;

      // Broadcast live update immediately so real-time tracking never stalls on DB latency
      socket.to(targetRoom).emit('location_updated', {
        id: targetUser,
        name: userName || 'Friend',
        color: userColor || '#38BDF8',
        latitude,
        longitude,
        speed: safeSpeed,
        updated_at: new Date().toISOString(),
      });

      try {
        await locationController.updateLocation(
          targetUser,
          userName,
          userColor,
          targetRoom,
          latitude,
          longitude,
          safeSpeed
        );
      } catch (err) {
        console.error('Error persisting location update:', err.message);
      }
    });

    socket.on('disconnect', async () => {
      console.log(`🔌 Client disconnected: ${socket.id}`);
      if (currentRoomId && currentUserId) {
        try {
          await locationController.removeUserFromRoom(currentUserId, currentRoomId);
        } catch (err) {
          console.error('Error removing disconnected user:', err.message);
        }
        socket.to(currentRoomId).emit('friend_left', { userId: currentUserId });
      }
    });
  });
}

module.exports = setupTrackerSocket;
