# 📱 Task Management App (Offline-First Architecture)

A full-stack Task Management application built using **Flutter (Clean Architecture + Riverpod + GoRouter)** and **Node.js (Express + JWT Authentication)**.

This project demonstrates:

- JWT authentication
- Protected APIs
- Offline-first architecture
- Local caching with Hive
- Auto synchronization on connectivity restore
- Clean and scalable architecture

---

# 🚀 Tech Stack

## 🔹 Frontend (Flutter)

- Flutter
- Riverpod (State Management)
- GoRouter (Routing & Auth Guard)
- Dio (Networking)
- Hive (Local Database)
- Flutter Secure Storage (JWT storage)
- Connectivity Plus (Network detection)

## 🔹 Backend (Node.js)

- Node.js
- Express.js
- JWT Authentication
- Modular architecture (Routes, Controllers, Middleware)

---

# 🏗 Architecture Overview

## 🔹 Backend Structure

```
backend/
 ├── src/
 │    ├── config/
 │    ├── controllers/
 │    ├── middleware/
 │    ├── routes/
 │    ├── data/
 │    ├── app.js
 │    ├── server.js
 ├── .env
```

- JWT-based authentication
- Protected task routes
- In-memory data store (easily replaceable with MongoDB)

---

## 🔹 Flutter Structure (Clean Architecture)

```
flutter_app/lib/
 ├── core/
 │    ├── network/
 │    ├── services/
 │
 ├── features/
 │    ├── auth/
 │    │     ├── domain/
 │    │     ├── presentation/
 │    │
 │    ├── tasks/
 │          ├── domain/
 │          ├── presentation/
 │
 ├── router/
 ├── main.dart
```

The app follows a feature-first clean architecture approach.

---

# 🔐 Authentication Flow

1. User logs in with email & password
2. Backend returns JWT token
3. Token is stored securely using `FlutterSecureStorage`
4. Dio interceptor automatically attaches token to protected API calls
5. GoRouter redirect logic ensures authenticated navigation

---

# 📋 Features Implemented

## ✅ Core Features

- JWT login
- Persist login across restarts
- Task list screen
- Task detail screen
- Update task status
- Update remarks
- Loading and error states

---

# 🌐 Offline-First Architecture (Key Feature)

The app follows an **Offline-First Approach**.

## How It Works

### 1️⃣ Local Caching

- Tasks are stored locally using Hive.
- App always reads from local database first.

### 2️⃣ Online Mode

- Fetch tasks from API
- Cache tasks locally
- Update "Last Synced" timestamp

### 3️⃣ Offline Mode

- Show cached tasks
- Allow task updates
- Mark updated tasks as `isSynced = false`

### 4️⃣ Auto Sync

- Connectivity listener detects network restore
- Unsynced tasks are automatically pushed to backend
- Marked as synced after successful update

This ensures **eventual consistency** between client and server.

---

# 🔄 API Endpoints

## Login

```
POST /api/login
```

Body:
```json
{
  "email": "abhiraj@gmail.com",
  "password": "112233"
}
```

---

## Get Tasks

```
GET /api/tasks
```

Header:
```
Authorization: Bearer <token>
```

---

## Update Task

```
PUT /api/tasks/:id
```

Body:
```json
{
  "status": "completed",
  "remarks": "Done successfully"
}
```

---

# ▶️ How To Run The Project

## 🔹 Backend

```bash
cd backend
npm install
npm start
```

Server runs at:

```
http://localhost:5000
```

---

## 🔹 Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

If using Android Emulator, base URL must be:

```
http://10.0.2.2:5000/api
```

---

# 🎯 Assignment Highlights

- Clean architecture implementation
- Offline-first system
- JWT-secured backend
- State management with Riverpod
- Route guarding using GoRouter
- Sync strategy implementation
- Modular and scalable codebase

---

# 🧠 Design Decisions

- Used Riverpod for scalable and testable state management
- Used Hive for lightweight local persistence
- Used GoRouter for declarative navigation and auth guards
- Backend structured with modular Express architecture
- In-memory DB used for simplicity (can be extended to MongoDB)

---


# 👨‍💻 Author

Abhiaj  
Flutter Developer | Full-Stack Mobile Developer

---

