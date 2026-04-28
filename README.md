# FlowSync Pro 🚛

**Real-time logistics execution platform** — Track shipments, manage transport dispatches, and gain operational analytics — all in one place.

Built for the **Google Solution Challenge 2026**.

---

## 📋 Overview

FlowSync Pro is an end-to-end logistics management solution designed to streamline supply-chain operations. It provides real-time shipment tracking, intelligent dispatch recommendations, and comprehensive analytics dashboards for logistics managers.

### Key Features

- 🔐 **Authentication** — Firebase Auth with Google Sign-In and email/password
- 📦 **Shipment Management** — Create, track, and update shipments in real-time
- 🗺️ **Live Tracking** — Interactive map view with real-time location updates
- 📊 **Analytics Dashboard** — Visual KPIs, charts, and operational insights
- ⚡ **Real-time Updates** — WebSocket-powered live notifications via Socket.IO
- 🤖 **Dispatch Advisor** — Smart transport dispatch recommendations
- ☁️ **Cloud-Ready** — Supabase + Firebase integration

---

## 🛠️ Tech Stack

| Layer     | Technology                                       |
| --------- | ------------------------------------------------ |
| Frontend  | Flutter 3.x, Riverpod, GoRouter, FL Chart        |
| Backend   | Node.js, Express, TypeScript, Prisma ORM         |
| Database  | Supabase (PostgreSQL)                            |
| Auth      | Firebase Authentication, Google Sign-In          |
| Realtime  | Socket.IO                                        |
| Analytics | Firebase Analytics                               |
| Cloud     | Google Cloud / Firebase                          |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Node.js ≥ 18
- npm or yarn
- Firebase project configured
- Supabase project (optional)

### Backend Setup

```bash
cd backend
cp .env.example .env          # fill in your credentials
npm install
npx prisma db push
npm run dev
```

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
flowsync_pro/
├── backend/                # Node.js + Express + TypeScript API
│   ├── src/
│   │   ├── modules/        # Feature modules (shipments, auth, etc.)
│   │   ├── middleware/      # Auth, rate-limiting, etc.
│   │   ├── realtime/       # Socket.IO event handlers
│   │   ├── services/       # Business logic services
│   │   └── config/         # App configuration
│   ├── prisma/             # Database schema & migrations
│   └── scripts/            # Utility scripts
├── frontend/               # Flutter mobile application
│   ├── lib/
│   │   ├── core/           # Config, routing, theme, network
│   │   ├── features/       # Feature modules
│   │   │   ├── auth/       # Authentication screens & logic
│   │   │   ├── dashboard/  # Dashboard UI
│   │   │   ├── shipments/  # Shipment CRUD & detail views
│   │   │   ├── transport/  # Transport cards, maps, dispatch
│   │   │   └── analytics/  # Analytics charts & data
│   │   └── shared/         # Reusable widgets
│   └── android/            # Android platform config
└── supabase/               # Supabase config & edge functions
```

---

## 🔑 Google Technologies Used

- **Firebase Authentication** — Secure user sign-in
- **Firebase Analytics** — Usage tracking and insights
- **Google Sign-In** — One-tap authentication
- **Google Cloud** — Backend hosting and infrastructure

---

## 📄 License

This project is built for the Google Solution Challenge 2026.
