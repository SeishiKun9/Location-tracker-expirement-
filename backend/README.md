# 🐘 Friend Tracker - Node.js & PostgreSQL Backend

Real-time backend for the **Friend Tracker** app using **Express**, **Socket.io**, and **PostgreSQL**.

---

## 🚀 Features

- **PostgreSQL Database (`pg` pool):** Stores user profiles, rooms, live coordinate records, and historical breadcrumb paths.
- **Real-Time WebSockets (`socket.io`):** Instant < 50ms location broadcast to all connected friends in the same room.
- **REST Endpoints:** Query active friends and room states.

---

## 🛠️ Quick Start

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Database
Update credentials in `backend/.env` if your PostgreSQL username or password differs:
```env
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=friend_tracker
PG_USER=postgres
PG_PASSWORD=your_password
PORT=3000
```

### 3. Start the Server
```bash
npm start
```
The server will automatically verify tables and start listening on `http://localhost:3000`.
