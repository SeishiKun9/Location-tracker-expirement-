const http = require('http');
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
require('dotenv').config();

const { initDatabase } = require('./config/db');
const locationController = require('./controllers/locationController');
const setupTrackerSocket = require('./sockets/trackerSocket');

const app = express();
const server = http.createServer(app);

// Enable CORS for mobile app & web prototype
app.use(cors({ origin: '*' }));
app.use(express.json());

// Initialize Socket.io with permissive CORS
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

// Setup Real-time WebSockets
setupTrackerSocket(io);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'Friend Tracker PostgreSQL Backend' });
});

// REST API: Get active friends in a room
app.get('/api/rooms/:roomId/friends', async (req, res) => {
  try {
    const friends = await locationController.getRoomFriends(req.params.roomId);
    res.json({ success: true, friends });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

const PORT = process.env.PORT || 3000;

server.listen(PORT, async () => {
  console.log(`🚀 Friend Tracker Server running on port ${PORT}`);
  await initDatabase();
});
