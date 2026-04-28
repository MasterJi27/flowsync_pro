# FlowSync Pro 🚛⚡

**A real-time logistics execution platform** that brings transparency, accountability, and speed to multi-party shipment workflows — from broker dispatch to final delivery.

Built for the **Google Solution Challenge 2026**.

🎥 **[Demo Video](https://youtu.be/oIVx235czr8)**

---

## 🌍 UN Sustainable Development Goal

<table>
<tr>
<td width="80">🏭</td>
<td>
<strong>SDG 9 — Industry, Innovation & Infrastructure</strong><br>
FlowSync Pro builds resilient logistics infrastructure by digitizing fragmented shipment coordination. It replaces manual phone/WhatsApp-based tracking with a real-time, multi-party platform — reducing delays, improving transporter accountability, and enabling data-driven dispatch decisions for more efficient supply chains.
</td>
</tr>
</table>

---

## 🎯 Problem Statement

In traditional logistics, shipment coordination between **brokers**, **transporters**, **clients**, and **authorities** is fragmented — relying on phone calls, WhatsApp, and manual tracking. This leads to:

- ❌ Delayed confirmations and missed handoffs  
- ❌ No single source of truth for shipment status  
- ❌ Escalation gaps when steps aren't confirmed on time  
- ❌ Zero visibility into transporter reliability  

**FlowSync Pro** solves this by providing a **unified, role-based platform** with real-time updates, automated escalations, and dispatch intelligence.

---

## ✨ Key Features

### 🔐 Role-Based Authentication
- Firebase Auth with **Google Sign-In** and email/password login
- Four distinct roles: **Broker**, **Client**, **Transporter**, **Authority**
- Each role gets a tailored dashboard view (Broker Control Tower, Client Visibility, Transporter Desk, Authority Queue)

### 📦 Shipment Lifecycle Management
- Full CRUD for shipments with **reference numbers**, origin/destination, transport type (Road, Air, Sea, Rail, Multimodal)
- Multi-step workflow tracking with **sequence-ordered steps** (e.g., Pickup → Loading → In-Transit → Customs → Delivery)
- Step-level status: `PENDING` → `IN_PROGRESS` → `NEEDS_CONFIRMATION` → `COMPLETED`
- Shipment statuses: `PLANNED`, `IN_TRANSIT`, `NEEDS_CONFIRMATION`, `ESCALATED`, `DELAYED`, `COMPLETED`, `CANCELLED`
- Priority levels: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`

### ⚡ Real-Time Updates
- **Socket.IO** powered live notifications across all connected clients
- Instant status change broadcasting when steps are confirmed or escalated
- Polling fallback every 10 seconds for reliability

### 🤖 Dispatch Advisor (Smart Recommendations)
- Backend intelligence service that evaluates shipment & step status to provide:
  - **Dispatch timing recommendations** (e.g., "Wait 15 minutes before dispatch")
  - **Risk level assessment** (`low` / `medium` / `high`)
  - **Delay impact estimation** with potential cost calculations (₹/hour)
  - **Transport readiness scoring** (0–100)
  - **Best contact identification** based on trust scores

### 🔄 Escalation Engine
- Automated escalation when steps remain unconfirmed past their expected time
- Sequential contact-chain escalation (ordered by `escalation_order`)
- Tracks escalation attempts with statuses: `PENDING`, `NOTIFIED`, `RESPONDED`, `SKIPPED`, `EXPIRED`
- Confirmation sweep job runs periodically to trigger escalations

### 📊 Analytics Dashboard (Broker-Only)
- **Delay analytics**: delay percentage, average delay minutes, unconfirmed steps count
- **Execution performance**: active vs. completed shipments, completion rate, escalation frequency — visualized with interactive **bar charts** (FL Chart)
- **Transporter reliability**: per-transporter reliability scores with progress bars

### 👥 Participant & Contact Management
- Invite-based participant onboarding with **invite tokens** (phone-based)
- Per-participant **reliability scoring** and **response rate** tracking
- Contact trust scores for escalation prioritization

### 🗺️ Transport & Map Features
- Interactive **shipment map** view with location tracking
- Transport assignment management (truck ID, driver details, dispatch/arrival times)
- Advanced transport cards with flow timeline visualization

### 🔒 Security & Reliability
- **Helmet** for HTTP security headers
- **Rate limiting** (API-wide + stricter on auth routes)
- **Zod** schema validation on all inputs
- Immutable audit logs for every shipment action
- CORS with configurable allowed origins

---

## 🛠️ Tech Stack

| Layer        | Technology                                                  |
| ------------ | ----------------------------------------------------------- |
| **Frontend** | Flutter 3.x, Riverpod (state), GoRouter (navigation)       |
| **UI/UX**    | Glassmorphism, Lottie animations, FL Chart, Google Fonts    |
| **Backend**  | Node.js, Express, TypeScript                                |
| **ORM**      | Prisma with PostgreSQL                                      |
| **Database** | Supabase (hosted PostgreSQL) + Edge Functions               |
| **Auth**     | Firebase Authentication + Google Sign-In                    |
| **Realtime** | Socket.IO (WebSocket) + polling fallback                    |
| **Analytics**| Firebase Analytics                                          |
| **Hosting**  | Azure App Service (backend) + Firebase (frontend config)    |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│            Flutter Mobile App           │
│  (Riverpod + GoRouter + Glassmorphism)  │
└────────────────┬────────────────────────┘
                 │  REST API + Socket.IO
                 ▼
┌─────────────────────────────────────────┐
│     Express + TypeScript Backend        │
│  ┌──────────┬───────────┬────────────┐  │
│  │   Auth   │ Shipments │ Transport  │  │
│  │  Module  │  Module   │  Advisor   │  │
│  ├──────────┼───────────┼────────────┤  │
│  │  Steps   │   Logs    │ Escalation │  │
│  │  Module  │  Module   │   Engine   │  │
│  ├──────────┼───────────┼────────────┤  │
│  │ Contacts │Participants│ Analytics │  │
│  └──────────┴───────────┴────────────┘  │
└────────────────┬────────────────────────┘
                 │  Prisma ORM
                 ▼
┌─────────────────────────────────────────┐
│     Supabase PostgreSQL + Auth          │
│     + Edge Functions                    │
└─────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
flowsync_pro/
├── backend/                    # Node.js + Express + TypeScript API
│   ├── src/
│   │   ├── config/             # Environment, Firebase, Prisma, Logger
│   │   ├── middleware/         # Auth guard, rate limiter, validation, error handler
│   │   ├── modules/
│   │   │   ├── auth/           # Register, login, Firebase token verify
│   │   │   ├── shipments/      # CRUD + status management
│   │   │   ├── steps/          # Step progression + confirmation
│   │   │   ├── participants/   # Invite + join flow
│   │   │   ├── contacts/       # Trust-scored contact management
│   │   │   ├── escalations/    # Escalation attempts + resolution
│   │   │   ├── logs/           # Immutable audit trail
│   │   │   ├── analytics/      # Delay, performance, reliability metrics
│   │   │   └── transport/      # Dispatch advisor + assignment
│   │   ├── realtime/           # Socket.IO event broadcasting
│   │   ├── services/           # Transport advisor intelligence
│   │   ├── jobs/               # Confirmation sweep (cron)
│   │   └── shared/             # Error classes, pagination, async handler
│   └── prisma/                 # Schema (10 models) + migrations + seed
│
├── frontend/                   # Flutter mobile app
│   └── lib/
│       ├── core/
│       │   ├── auth/           # Firebase Auth service
│       │   ├── config/         # API base URL, Supabase config
│       │   ├── network/        # Dio HTTP client with auth interceptor
│       │   ├── realtime/       # Socket.IO client wrapper
│       │   ├── router/         # GoRouter with auth redirect guards
│       │   ├── storage/        # Hive local store + Supabase service
│       │   └── theme/          # Material 3 light/dark themes
│       ├── features/
│       │   ├── auth/           # Login, signup, forgot password, profile
│       │   ├── dashboard/      # Role-based dashboard with metrics grid
│       │   ├── shipments/      # List, detail, step timeline, status updates
│       │   ├── transport/      # Map view, dispatch advisor, transport cards
│       │   └── analytics/      # Charts, reliability scores, KPI cards
│       └── shared/widgets/     # GlassCard, GradientButton, StatusBadge, etc.
│
└── supabase/                   # Supabase edge functions + migrations
    ├── functions/api/          # Serverless API alternative
    └── migrations/             # Auth activity + analytics RPC
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Node.js ≥ 18
- PostgreSQL database (or Supabase project)
- Firebase project with Auth enabled

### Backend Setup

```bash
cd backend
cp .env.example .env            # Configure DATABASE_URL, JWT_SECRET, Firebase credentials
npm install
npx prisma db push              # Create database tables
npm run seed                    # Seed demo data (optional)
npm run dev                     # Start dev server with hot reload
```

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run                     # Runs on connected device/emulator
```

### Environment Variables

See `backend/.env.example` for required backend configuration:
- `DATABASE_URL` — PostgreSQL connection string
- `JWT_SECRET` — Token signing secret
- `FIREBASE_*` — Firebase Admin SDK credentials
- `CORS_ORIGINS` — Allowed frontend origins

---

## 🔑 Google Technologies Used

| Technology              | Usage in FlowSync Pro                                     |
| ----------------------- | --------------------------------------------------------- |
| **Firebase Auth**       | Secure user authentication with email/password and Google SSO |
| **Firebase Analytics**  | In-app usage tracking, event logging, and user behavior insights |
| **Google Sign-In**      | One-tap authentication for seamless mobile onboarding     |
| **Firebase Realtime Config** | App configuration and Firebase project initialization |
| **Supabase (PostgreSQL)** | Cloud-hosted database with edge functions              |

> **Backend hosting**: Azure App Service (`flowsyncpro-final.azurewebsites.net`)

---

## 📱 App Screens

| Screen               | Description                                             |
| --------------------- | ------------------------------------------------------- |
| **Splash**            | Animated loading with auth state check                  |
| **Login**             | Glassmorphism login with Google Sign-In + email          |
| **Dashboard**         | Role-based metrics, quick actions, recent shipments     |
| **Shipment Detail**   | Step timeline, participant list, escalation history      |
| **Analytics**         | Bar charts, reliability scores, delay KPIs (Broker only)|
| **Profile**           | User info, login activity, role management               |
| **Map View**          | Interactive shipment location tracking                   |

---

## 📄 License

This project is built for the **Google Solution Challenge 2026**.
