# Revora — Two-Way Car Marketplace
### Phase-by-Phase Implementation Plan

---

## What We Are Building

**Revora** is a demand-driven car marketplace where **customers post requirements** and **dealers compete** with offers — not the other way around.

| Flow | Customer Action | Dealer Action |
|---|---|---|
| **Buy** | Post car requirement (model, year, budget, city) | Dealer sees matching req → sends quote with car + price |
| **Sell** | Post car for sale (make, year, km, price) | Dealer sees it → makes a purchase offer |

**Core Insight:** Instead of 1,000 listings the buyer must search through, the buyer posts once and relevant dealers come to them.

---

## Tech Stack Decision (Free Hosting)

| Layer | Technology | Free Hosting |
|---|---|---|
| **Mobile App** | Flutter (Android + iOS) | — |
| **Web Admin Panel** | Flutter Web | Firebase Hosting (free tier) |
| **Backend API** | FastAPI (Python) | Render.com (free tier) |
| **Database** | PostgreSQL | Supabase (free 500MB) |
| **File Storage** | Images/docs | Supabase Storage (free 1GB) |
| **Push Notifications** | Firebase Cloud Messaging | Free |
| **Real-time / Chat** | Supabase Realtime (WebSocket) | Free |
| **Auth** | FastAPI JWT + Supabase Auth | Free |
| **CI/CD** | GitHub Actions | Free (2000 min/month) |

> **Why Supabase?** It gives us free PostgreSQL + Realtime WebSocket + File Storage — replacing 3 paid services in one. The existing SQLite backend migrates cleanly.

> **Why Render?** Free FastAPI hosting with auto-deploy from GitHub. Sleeps after 15 min of inactivity (free tier), acceptable for MVP.

---

## User Roles & Permissions

```
Customer
  ├── Post Buy Requirement
  ├── Post Sell Listing
  ├── View & Compare Dealer Quotes/Offers
  ├── Chat with Dealers
  ├── Accept/Reject Offers
  └── Rate Dealers

Dealer
  ├── Add & Manage Car Inventory
  ├── Receive Matching Buy Requirements
  ├── Send Quotes on Buy Requirements
  ├── View & Make Offers on Sell Listings
  ├── Manage Leads (accept/decline/chat)
  └── View Analytics (leads received, conversion)

Admin
  ├── Manage Users (customers + dealers)
  ├── Manage Dealers (approve/suspend)
  ├── View All Requirements & Listings
  ├── View All Quotes & Offers
  ├── Reports & Analytics Dashboard
  └── Push Notification Broadcasts
```

---

## Database Schema (High-Level)

```
users                      → id, name, phone, email, role, city, created_at
dealers                    → id, user_id, business_name, gstin, address, verified, rating
cars_inventory             → id, dealer_id, make, model, year, fuel, transmission, km, price, images[], status
buy_requirements           → id, customer_id, make, model, year_min, budget, fuel, transmission, city, status
sell_listings              → id, customer_id, make, model, year, fuel, km, expected_price, images[], status
dealer_quotes              → id, dealer_id, requirement_id, car_inventory_id, quoted_price, message, status
dealer_purchase_offers     → id, dealer_id, sell_listing_id, offered_price, message, status
conversations              → id, customer_id, dealer_id, context_type (buy/sell), context_id
messages                   → id, conversation_id, sender_id, text, image_url, created_at
notifications              → id, user_id, title, body, type, ref_id, read, created_at
```

---

## Phase Overview

| Phase | Name | Duration | Output |
|---|---|---|---|
| **Phase 1** | Foundation & Architecture Reset | Week 1–2 | Project skeleton, DB, Auth |
| **Phase 2** | Backend Core APIs | Week 2–3 | All REST endpoints |
| **Phase 3** | Customer App — Buy Flow | Week 3–4 | Post requirement, view quotes |
| **Phase 4** | Customer App — Sell Flow | Week 4–5 | Post sell listing, view offers |
| **Phase 5** | Dealer App | Week 5–7 | Inventory, leads, quotes, offers |
| **Phase 6** | Chat & Real-time | Week 7–8 | In-app messaging (Supabase Realtime) |
| **Phase 7** | Notifications | Week 8 | FCM push, in-app feed |
| **Phase 8** | Admin Web Panel | Week 9–10 | Flutter Web admin dashboard |
| **Phase 9** | Polish, Testing & Launch | Week 11–12 | QA, Play Store / App Store |

---

---

# PHASE 1 — Foundation & Architecture Reset
**Duration:** Week 1–2

## Goals
- Rename/rebrand project from Free-LX to Revora
- Migrate from SQLite to PostgreSQL (Supabase)
- Set up infrastructure: Supabase project, Render backend, Firebase project
- Establish correct folder architecture for a 3-role app
- Implement shared design system (colors, typography, components)

## 1.1 — Infrastructure Setup

### Supabase
1. Create project at supabase.com (free)
2. Run migration SQL to create all tables (schema above)
3. Enable Row Level Security (RLS) policies per role
4. Enable Supabase Realtime on `messages` table
5. Configure Supabase Storage bucket: `car-images` (public read)

### Firebase
1. Create Firebase project
2. Add Android app (package: `com.revora.app`)
3. Add iOS app (Bundle ID: `com.revora.app`)
4. Download `google-services.json` + `GoogleService-Info.plist`
5. Enable Firebase Cloud Messaging

### Render
1. Connect GitHub repo to Render
2. Create Web Service pointing to `backend/`
3. Set environment variables: `SUPABASE_URL`, `SUPABASE_KEY`, `JWT_SECRET`
4. Enable auto-deploy on `main` branch push

### Firebase Hosting (Admin Web Panel)
1. Enable Firebase Hosting in Firebase console
2. Will be deployed in Phase 8

## 1.2 — Backend: Migrate to PostgreSQL + Supabase

### Files to modify: `backend/`
- Replace SQLite `database.py` with `asyncpg` + Supabase client
- Replace all SQLAlchemy SQLite models with new PostgreSQL models
- Update `requirements.txt`:
  ```
  fastapi
  uvicorn
  asyncpg
  supabase-py
  python-jose[cryptography]
  passlib[bcrypt]
  python-multipart
  Pillow
  ```
- Update `main.py` with CORS, lifespan, health check endpoint

## 1.3 — Flutter: Architecture Reset

### Rename & Rebrand
- Update `pubspec.yaml`: `name: revora`, `description: Two-Way Car Marketplace`
- Update Android `AndroidManifest.xml` package name
- Update iOS `Info.plist` bundle ID

### New Folder Structure
```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── config/
│   │   ├── app_config.dart           ← baseUrl, supabase URL/key
│   │   ├── environment.dart
│   │   └── constants.dart
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── api_endpoints.dart        ← all route paths
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       └── logger_interceptor.dart
│   ├── supabase/
│   │   ├── supabase_client.dart      ← NEW: Supabase Dart client init
│   │   └── realtime_service.dart     ← NEW: WebSocket subscription helpers
│   ├── theme/
│   │   ├── app_colors.dart           ← Revora brand palette
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   └── utils/
│       ├── validators.dart
│       ├── helpers.dart
│       ├── price_formatter.dart      ← Indian ₹ formatting (lakhs/crores)
│       └── storage_helper.dart
│
├── shared/
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── custom_loader.dart
│   │   ├── custom_app_bar.dart
│   │   ├── car_card.dart             ← NEW: shared car display card
│   │   ├── offer_card.dart           ← NEW: quote/offer display card
│   │   ├── dealer_chip.dart          ← NEW: dealer avatar + name chip
│   │   ├── price_tag.dart            ← NEW: ₹ formatted price badge
│   │   ├── status_badge.dart         ← NEW: open/closed/accepted/expired
│   │   ├── empty_state_widget.dart
│   │   └── error_widget.dart
│   └── providers/
│       ├── connectivity_provider.dart
│       └── auth_state_provider.dart  ← global auth state (role-aware)
│
├── modules/
│   ├── splash/
│   ├── auth/                         ← Phase 1
│   ├── customer/                     ← Phase 3 & 4
│   │   ├── buy/                      ← post requirement, view quotes
│   │   ├── sell/                     ← post car, view offers
│   │   ├── home/
│   │   └── profile/
│   ├── dealer/                       ← Phase 5
│   │   ├── inventory/
│   │   ├── leads/
│   │   ├── quotes/
│   │   └── profile/
│   └── chat/                         ← Phase 6
│
└── init/
    ├── dependency_injection.dart
    ├── app_initializer.dart
    └── route_initializer.dart        ← role-aware routing
```

### Design System — Revora Brand

```dart
// Revora Palette
class AppColors {
  static const primary       = Color(0xFF1A237E); // deep navy blue
  static const primaryLight  = Color(0xFF3949AB);
  static const accent        = Color(0xFFFF6F00); // vibrant orange
  static const accentLight   = Color(0xFFFFB74D);
  static const success       = Color(0xFF2E7D32);
  static const warning       = Color(0xFFF57F17);
  static const error         = Color(0xFFC62828);
  static const background    = Color(0xFFF8F9FA);
  static const surface       = Color(0xFFFFFFFF);
  static const surfaceDark   = Color(0xFF121212);
  static const textPrimary   = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF6B7280);
}
```

Font: **Outfit** (Google Fonts) — modern, bold, premium feel.

---

# PHASE 2 — Backend Core APIs
**Duration:** Week 2–3

## Goals
Complete all REST API endpoints for the 3-role system.

## API Modules

### `POST /api/auth/*`  (already exists — adapt)
```
POST /api/auth/register        → customer or dealer registration
POST /api/auth/login           → returns JWT access + refresh tokens
POST /api/auth/logout
POST /api/auth/refresh
POST /api/auth/verify-email
POST /api/auth/forgot-password
POST /api/auth/reset-password
```

### `GET|POST|PATCH /api/requirements/*`  (Customer Buy)
```
POST   /api/requirements               → customer posts buy requirement
GET    /api/requirements               → customer gets their requirements
GET    /api/requirements/{id}          → requirement detail + quotes received
PATCH  /api/requirements/{id}/close    → customer closes requirement
DELETE /api/requirements/{id}
```

### `GET|POST|PATCH /api/sell-listings/*`  (Customer Sell)
```
POST   /api/sell-listings              → customer posts car for sale
GET    /api/sell-listings              → customer gets their sell listings
GET    /api/sell-listings/{id}         → listing detail + offers received
PATCH  /api/sell-listings/{id}/close   → customer closes listing
DELETE /api/sell-listings/{id}
```

### `GET|POST|PATCH /api/inventory/*`  (Dealer)
```
POST   /api/inventory                  → dealer adds a car
GET    /api/inventory                  → dealer gets their inventory
GET    /api/inventory/{id}             → car detail
PATCH  /api/inventory/{id}             → update car details
DELETE /api/inventory/{id}
POST   /api/inventory/{id}/images      → upload car images (multipart)
```

### `POST|GET|PATCH /api/quotes/*`  (Dealer → Customer Buy Requirement)
```
GET    /api/leads/buy                  → dealer sees matching buy requirements
POST   /api/quotes                     → dealer sends quote on a requirement
GET    /api/quotes/{requirement_id}    → all quotes for a requirement (customer view)
PATCH  /api/quotes/{id}/accept         → customer accepts a quote
PATCH  /api/quotes/{id}/reject         → customer rejects a quote
```

### `POST|GET|PATCH /api/offers/*`  (Dealer → Customer Sell Listing)
```
GET    /api/leads/sell                 → dealer sees sell listings matching their interest
POST   /api/offers                     → dealer makes purchase offer
GET    /api/offers/{listing_id}        → all offers for a listing (customer view)
PATCH  /api/offers/{id}/accept         → customer accepts an offer
PATCH  /api/offers/{id}/reject         → customer rejects an offer
```

### `GET|POST /api/chat/*`  (via Supabase Realtime)
```
POST   /api/conversations              → create or get conversation
GET    /api/conversations              → list user's conversations
GET    /api/conversations/{id}/messages → paginated messages
POST   /api/conversations/{id}/messages → send message (also inserts to Supabase for realtime)
```

### `GET|POST /api/notifications/*`
```
GET    /api/notifications              → user's notification feed (paginated)
POST   /api/notifications/mark-read    → mark as read
```

### `GET|POST|PATCH /api/admin/*`
```
GET    /api/admin/users                → list all users
PATCH  /api/admin/dealers/{id}/verify  → approve dealer
PATCH  /api/admin/dealers/{id}/suspend → suspend dealer
GET    /api/admin/requirements         → all requirements
GET    /api/admin/listings             → all sell listings
GET    /api/admin/analytics            → counts, trends
POST   /api/admin/broadcast            → push notification to all
```

## Matching Logic (Backend Service)
When a **buy requirement** is posted:
1. Query `cars_inventory` for dealers in same city with matching make/model
2. Filter by fuel, transmission, year range, price ≤ budget
3. Create `RequirementMatch` records for each matching dealer
4. Send FCM push to each matched dealer

When a **sell listing** is posted:
1. Query active dealers in same city
2. Filter dealers who have expressed interest in that make/model (preference table)
3. Notify those dealers

---

# PHASE 3 — Customer App: Buy Flow
**Duration:** Week 3–4

## Screens

### Customer Home (`/customer/home`)
- Welcome header with name
- Two prominent action cards:
  - 🚗 **"I want to Buy a Car"** → `/customer/buy/post`
  - 💰 **"I want to Sell my Car"** → `/customer/sell/post`
- Active Requirements list (compact cards)
- Active Sell Listings list (compact cards)
- Recent dealer quotes/offers badge count

### Post Buy Requirement (`/customer/buy/post`)
Multi-step form (3 steps):

**Step 1 — Car Details**
- Make (dropdown: Maruti, Hyundai, Honda, Toyota...)
- Model (dependent dropdown based on make)
- Year range: Min year slider
- Fuel type (Petrol / Diesel / CNG / Electric / Hybrid) — chips
- Transmission (Manual / Automatic) — toggle

**Step 2 — Budget & Location**
- Budget range (₹ slider: 1L to 50L with ₹ formatting)
- City (searchable dropdown: Bengaluru, Mumbai, Delhi...)
- Preferred condition (New / Used / Any)
- Additional notes (optional text)

**Step 3 — Preview & Submit**
- Summary card of requirement
- "Post Requirement" button → API call → success animation

### My Requirements (`/customer/buy/requirements`)
- List of posted requirements with status badges (Open / Closed / Expired)
- Each card shows: car name, budget, quotes received count, time ago
- Tap → Requirement Detail

### Requirement Detail + Quotes (`/customer/buy/requirements/:id`)
- Requirement summary at top
- **"Quotes Received" section** — list of dealer cards showing:
  - Dealer name, rating, verified badge
  - Car details (year, km, color)
  - Quoted price (highlighted in accent orange)
  - "View Details" → expands full car info
  - "Chat with Dealer" button
  - "Accept Quote" button (with confirm dialog)
- Compare mode: select 2–3 quotes → side-by-side comparison screen

---

# PHASE 4 — Customer App: Sell Flow
**Duration:** Week 4–5

## Screens

### Post Sell Listing (`/customer/sell/post`)
Multi-step form (4 steps):

**Step 1 — Car Details**
- Make, Model, Year (number input), Variant
- Fuel type, Transmission
- Color

**Step 2 — Condition**
- Odometer reading (km driven)
- Number of owners
- Accident history (Y/N)
- Insurance valid till (date picker)
- RTO registration city

**Step 3 — Photos**
- ImagePicker grid (up to 8 photos)
- Upload progress to Supabase Storage
- Thumbnails shown inline

**Step 4 — Price & Submit**
- Expected price (₹ input with L/Cr toggle)
- "Negotiate?" checkbox
- Preview → Submit

### My Sell Listings (`/customer/sell/listings`)
- Cards: car name, year, km, asking price, offers received count
- Tap → Listing Detail

### Listing Detail + Offers (`/customer/sell/listings/:id`)
- Car details + photos carousel at top
- **"Purchase Offers" section** — dealer offer cards:
  - Dealer name, rating, verified badge
  - Offered price (green if above expected, red if below)
  - "Chat" button, "Accept Offer" button
- Accept flow: confirmation → mark listing sold → dealer notified

---

# PHASE 5 — Dealer App
**Duration:** Week 5–7

## Dealer has a completely separate navigation shell

### Dealer Home / Dashboard (`/dealer/home`)
- Stats row: Active Inventory | New Leads Today | Quotes Sent | Accepted Deals
- New Buy Requirements (matching today) — horizontal scroll list
- New Sell Listings near you — horizontal scroll list
- Quick action: "Add Car to Inventory"

### Inventory Management (`/dealer/inventory`)
- Grid of cars with status (Available / Sold / Reserved)
- FAB: Add Car → multi-step form
  - Make, Model, Year, Fuel, Transmission, Color, Variant
  - Km driven, Number of owners, Condition
  - Asking Price, Negotiable toggle
  - Upload photos (up to 10)
- Edit / Delete / Mark as Sold actions

### Buy Leads (`/dealer/leads/buy`)
- List of customer buy requirements that match dealer's inventory
- Filter: city, make, budget range
- Each lead card shows:
  - Car requirement summary
  - Customer's budget
  - Posted time ago
  - "Send Quote" CTA button

### Send Quote (`/dealer/leads/buy/:requirement_id/quote`)
- Select car from own inventory OR manually enter details
- Set quoted price
- Add a personal message to customer
- "Send Quote" → API call → success

### Sell Leads (`/dealer/leads/sell`)
- Customer sell listings that might interest the dealer
- Filter: city, make, year, max price
- Each card: car summary, customer's expected price, km
- "Make Offer" CTA

### Make Offer (`/dealer/leads/sell/:listing_id/offer`)
- Enter offered purchase price
- Add message
- "Submit Offer" → API call → success

### My Quotes & Offers (`/dealer/activity`)
- Tabs: Quotes Sent | Offers Made
- Status filter: Pending / Accepted / Rejected / Expired
- Each item: customer context, price, status badge, "Chat" button

### Dealer Profile (`/dealer/profile`)
- Business name, GSTIN, address, logo
- Rating (from customer reviews)
- Verification status badge
- Edit details

---

# PHASE 6 — Chat & Real-time Messaging
**Duration:** Week 7–8

## Architecture
- Conversations are created when a customer taps "Chat" on a quote/offer
- Supabase Realtime broadcasts new messages via WebSocket
- Flutter Supabase client subscribes to `messages` channel filtered by `conversation_id`

## Screens

### Chat List (`/chat`)
- All conversations (both customer and dealer)
- Each item: other party's name, last message preview, unread count badge, timestamp
- Search conversations by name

### Chat Detail (`/chat/:conversation_id`)
- Bubble-style message thread
- Context bar at top (e.g., "Re: Honda City 2022 — ₹12.5L")
- Text input + send button
- Image send (camera or gallery)
- "View Requirement / Listing" link
- Real-time: new messages appear instantly via Supabase channel

## Supabase Realtime Integration
```dart
// Subscribe to new messages in a conversation
supabase
  .channel('messages:$conversationId')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'messages',
    filter: PostgresChangeFilter(
      type: FilterType.eq,
      column: 'conversation_id',
      value: conversationId,
    ),
    callback: (payload) { /* add to state */ },
  )
  .subscribe();
```

---

# PHASE 7 — Push Notifications
**Duration:** Week 8

## Notification Types

| Event | Recipient | Title | Body |
|---|---|---|---|
| New matching requirement | Dealer | "New Lead!" | "Customer wants a Honda City under ₹15L in Bengaluru" |
| Quote received | Customer | "Dealer responded!" | "XYZ Motors sent a quote for your Honda City requirement" |
| Offer received | Customer | "Purchase Offer!" | "ABC Auto offered ₹9.5L for your 2019 Creta" |
| Quote accepted | Dealer | "Quote Accepted 🎉" | "Your quote was accepted. Chat with customer now" |
| Offer accepted | Dealer | "Offer Accepted 🎉" | "Your offer was accepted. Finalize with customer" |
| New message | Both | "New message" | "[Name]: message preview..." |
| Quote/Offer expired | Both | "Update Required" | "Your requirement has been open for 7 days" |

## Implementation
- FCM token stored on login, updated on refresh
- Backend sends FCM via `firebase-admin` Python SDK
- Flutter: `firebase_messaging` handles foreground/background
- `flutter_local_notifications` for foreground display
- Notification tap → deep link to relevant screen via GoRouter

---

# PHASE 8 — Admin Web Panel (Flutter Web)
**Duration:** Week 9–10

## Deployment
Flutter Web built → deployed to **Firebase Hosting** (free)
URL: `https://revora-admin.web.app`

## Screens

### Dashboard
- KPI cards: Total Users, Active Requirements, Active Listings, Total Quotes
- Charts: Daily new requirements, quotes sent, conversions (using `fl_chart`)
- Recent activity feed

### User Management
- Paginated table: ID, Name, Phone, Role, City, Joined
- Actions: View, Suspend, Delete

### Dealer Management
- Paginated table: Business Name, GSTIN, City, Verified, Rating, Inventory Count
- Actions: Verify ✓, Suspend ✗, View Inventory, View Leads

### Requirements
- All customer buy requirements with status
- Filter by city, make, status, date

### Sell Listings
- All customer sell listings
- Filter by city, make, price range

### Reports
- Export CSV: requirements, listings, quotes, offers
- Date range picker

### Broadcast Notification
- Select audience: All / Customers / Dealers / City
- Compose title + body
- Preview → Send

---

# PHASE 9 — Polish, Testing & Launch
**Duration:** Week 11–12

## Quality Assurance

### Unit Tests
```bash
flutter test test/unit/
```
- Validators (price, phone, email)
- Price formatter (₹ lakh/crore)
- Requirement matching logic

### Integration Tests
```bash
flutter test integration_test/
```
- Customer: Post requirement → see dealer quotes
- Dealer: View lead → send quote
- Chat flow end-to-end
- Auth: register, login, logout

### Backend Tests
```bash
pytest backend/tests/
```
- All API endpoints (pytest + httpx)
- Matching algorithm unit tests

## Performance
- `RepaintBoundary` on car cards and offer cards
- `CachedNetworkImage` for all car photos
- Lazy loading all lists
- Supabase query optimization (indexes on city, make, model, status)

## Launch Checklist
- [ ] App signing (Android keystore, iOS distribution cert)
- [ ] Google Play Store listing (screenshots, description)
- [ ] App Store listing (screenshots, description)
- [ ] Privacy Policy + Terms of Service page
- [ ] Backend rate limiting (slowapi)
- [ ] Supabase RLS policies reviewed
- [ ] Error monitoring (Sentry free tier)
- [ ] Analytics events (Firebase Analytics)

---

# Free Hosting Summary

| Service | Provider | Free Tier Limit |
|---|---|---|
| Mobile App (Android) | Google Play Store | $25 one-time fee |
| Mobile App (iOS) | App Store | $99/year |
| Backend API | Render.com | 750 hr/month (enough for 1 service) |
| Database | Supabase | 500MB PostgreSQL, 2GB bandwidth |
| File Storage | Supabase Storage | 1GB |
| Realtime | Supabase Realtime | 200 concurrent connections |
| Push Notifications | Firebase FCM | Free (no limit) |
| Web Admin Hosting | Firebase Hosting | 10GB/month bandwidth |
| CI/CD | GitHub Actions | 2000 min/month |

> [!WARNING]
> **Render free tier caveat**: The backend service "sleeps" after 15 minutes of inactivity. First request after sleep takes ~30 seconds. This is acceptable for MVP but upgrade to paid ($7/month) for production.

> [!TIP]
> **Supabase upgrade path**: Free tier is enough for 0–1000 active users. At scale, upgrade to Pro ($25/month) for 8GB DB, 100GB storage, no sleep.

---

# What Exists vs What to Build

## Existing Code (Re-use)
| File | Status |
|---|---|
| `backend/app/api/auth_api.py` | ✅ Keep & adapt (add role field) |
| `backend/app/models/` | ⚠️ Rebuild for PostgreSQL + new schema |
| `frontend/pubspec.yaml` | ✅ Keep (add `supabase_flutter`) |
| `frontend/lib/core/` | ⚠️ Refactor (already structured, add supabase client) |
| `frontend/lib/init/` | ✅ Keep structure, update content |
| `frontend/lib/shared/widgets/` | ✅ Keep, add car-specific widgets |

## New Packages to Add to `pubspec.yaml`
```yaml
dependencies:
  supabase_flutter: ^2.8.0    # Supabase client (DB + Realtime + Storage)
  fl_chart: ^0.70.0           # Charts for admin dashboard
  photo_view: ^0.15.0         # Pinch-zoom car image gallery
  step_progress_indicator: ^1.0.2  # Multi-step form progress
  google_fonts: ^6.2.1        # Outfit font
  shimmer: ^3.0.0             # Loading skeleton effect
  lottie: ^3.1.2              # Success animations (Lottie JSON)
  url_launcher: ^6.3.1        # Open maps, phone calls to dealer
  share_plus: ^10.1.2         # Share requirement/listing link
  flutter_rating_bar: ^4.0.1  # Dealer rating display
  dropdown_search: ^6.0.1     # Searchable make/model dropdowns
```

---

# Immediate Next Steps (This Week)

1. **Create Supabase project** → run schema SQL → share credentials
2. **Create Firebase project** → download config files
3. **Rename Flutter project** to `revora`
4. **Add `supabase_flutter`** to `pubspec.yaml`
5. **Start Phase 1**: Update `AppColors` + `AppTheme` for Revora brand
6. **Start Phase 2**: Rewrite backend models for PostgreSQL

> [!IMPORTANT]
> **Decision needed**: Should we keep the existing FastAPI auth system or migrate fully to Supabase Auth? Supabase Auth gives us free OAuth (Google login) out of the box. The trade-off: we'd call Supabase Auth directly from Flutter and skip custom JWT logic.
