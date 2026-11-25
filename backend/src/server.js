const http = require('http');
const express = require('express');
const cors = require('cors');
const { Server } = require('socket.io');
require('dotenv').config();

const { initDatabase, isReady } = require('./config/db');
const locationController = require('./controllers/locationController');
const setupTrackerSocket = require('./sockets/trackerSocket');

const app = express();
const server = http.createServer(app);

app.use(cors({ origin: '*' }));
app.use(express.json());

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

setupTrackerSocket(io);

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Friend Tracker Backend',
    storage: isReady() ? 'postgresql' : 'memory',
  });
});

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
