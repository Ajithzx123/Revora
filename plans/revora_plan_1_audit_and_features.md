# Revora — Product Plan, Part 1: Audit, Feature Catalogue, Priorities, Vision

Status: PLANNING ONLY. No source code, database, config or UI was changed. Implementation starts only after approval.
Evidence rule: every "exists / missing" statement below was checked in the repository. Items marked **(verify)** were not fully read and must be confirmed before work starts.

---

## Deliverable 1 — Existing project assessment

### 1.1 What exists (repository evidence)

**Backend** (`backend/`, FastAPI + SQLModel, ~1,300 lines)
- Auth: signup, login, refresh, logout, logout-all, forgot/reset password, email verification, session list/revoke, `/me` (`auth_api.py`, `auth_service.py` 406 lines). JWT access + refresh, role claim.
- Roles enum: CUSTOMER, DEALER, USER, ADMIN, ROOT_ADMIN. Dependencies: `require_auth`, `require_admin`, `require_root_admin`.
- Marketplace tables: Dealer, CarInventory, BuyRequirement, SellListing, DealerQuote, DealerOffer (`marketplace_models.py`).
- Endpoints: requirements (create/list/get/quotes/close), sell-listings (create/list/get/offers/close), dealer (inventory add/list, leads buy/sell, send quote, make offer), admin (metrics, dealers list, verify).
- DB: SQLite by default, Postgres via `DATABASE_URL`. Tables created by `create_all` at startup. `schema_supabase.sql` exists separately.
- Email service is an 8-line stub.

**Frontend** (`frontend/lib`, Flutter, ~5,700 lines of screens)
- Riverpod, go_router, Dio, supabase_flutter, firebase_core/messaging, local notifications declared in `pubspec.yaml`.
- Module layout: `auth`, `customer`, `dealer`, `admin`, `splash`, plus `shared/widgets` (cards, chips, KPI tile, responsive table, adaptive shell, sidebar).
- Screens present: login, register, splash; customer home/buy/sell/activity/profile, post-buy, post-sell, my requirements, requirement details, listing details, quote comparison; dealer home/inventory/leads (buy+sell tabs)/activity/profile, add car, send quote, make offer; admin shell/dashboard/dealer verification/requirements/vehicles; shared chat screen.
- Theme, spacing, text styles, price formatter (lakh), validators, car constants (makes, fuels, transmissions).
- Every module uses a `Mock*Repository` behind an abstract repository interface, switched by `AppConfig.useMockData`.

**Docs**: `README.md` (one line), `plans/implementation_plan.md` (a 9-phase roadmap written before the current code).
**Tests**: `frontend/test/` 2 files, 137 lines. No backend tests.

### 1.2 What works vs. what does not

| Area | Truth |
|---|---|
| Backend auth | Looks complete; never exercised by the app. |
| Backend marketplace CRUD | Basic create/list works in isolation; shallow data model. |
| Frontend UI | Navigable demo on mock data. Not connected to any API. |
| Frontend ↔ backend | **Not connected.** Dio client exists; no feature calls it. |
| Post-requirement form | A stub `Stepper`; submit just pops the screen (`post_buy_requirement_screen.dart`). |
| Chat | One screen, fixed id `'default'`. No backend. |
| Notifications | Packages declared; no event system or backend. |

### 1.3 Architectural observations (confirmed)

1. **Two identity systems.** Flutter signs in with Supabase Auth (`SupabaseAuthRepository`), while the backend issues its own JWTs. They are not bridged. One must be chosen (see decision D1).
2. **Schema drift.** SQLModel uses integer ids; `schema_supabase.sql` uses UUIDs and has a role CHECK of only CUSTOMER/DEALER/ADMIN. The Flutter entities use `String` ids and a min/max budget, the backend uses a single `budget`. Three different contracts.
3. **No migrations.** `create_all` only. No Alembic. Schema changes would silently not apply to existing databases.
4. **Images as CSV strings** (`images_csv`). No upload endpoint, no storage integration.
5. **Money as `int`** (rupees) on backend, `double` on frontend. Needs one rule (integer rupees).
6. **Route duplication** in `route_initializer.dart` (`/post-requirement` and `/customer/post-buy`, `/send-quote/:id` and `/dealer/send-quote/:id`, `/add-inventory` and `/dealer/add-car`). No role-based redirect or auth guard on any route.
7. **Hard-coded values**: nav badge counts (3, 2), Supabase URL default in `environment.dart`.

### 1.4 Security and trust defects (confirmed in code)

| # | Finding | Where | Severity |
|---|---|---|---|
| S1 | A dealer record is auto-created with `verified=True`, business name "Authorized Partner", city "Mumbai" on first quote. Any logged-in user can act as a verified dealer. | `dealer_api.py` `send_quote` | Critical |
| S2 | Dealer endpoints only check "authenticated", not role DEALER. A customer can post quotes/inventory. | `dealer_api.py` | Critical |
| S3 | `GET /admin/metrics` has no `require_admin` dependency in its signature. **(verify the other admin routes)** | `admin_api.py` | Critical |
| S4 | `GET /leads/buy` has no auth at all and returns all active requirements (includes `customer_id`). | `dealer_api.py` | High |
| S5 | Client-side demo login: an email containing "dealer" or "admin" becomes that role when Supabase is not initialised. Must never ship. | `auth_repository.dart` | High |
| S6 | Default `SECRET_KEY` string in config; CORS `allow_origins=["*"]` with credentials. | `config.py`, `main.py` | High |
| S7 | `/admin/metrics` loads whole tables to count them. | `admin_api.py` | Medium |
| S8 | Token `sub` is used directly as an integer foreign key. Confirm type handling. **(verify)** | `requirements_api.py` | Medium |
| S9 | No ownership checks on quote/offer ownership beyond what was read. **(verify `leads/sell`, close endpoints)** | various | Medium |

### 1.5 Technical debt summary
No migrations; no tests; no CI; mock-only frontend; contract drift; stubbed email; duplicated routes; password hashing/session code is well-structured but untested; README is empty.

### 1.6 Feature assessment map

| Module | Existing implementation | Status | Gap | Recommendation | Priority |
|---|---|---|---|---|---|
| Customer auth | Email/password (backend + Supabase) | Partially implemented | No phone OTP, no bridge between two auth systems | Pick one auth system (D1); add phone OTP | P0 |
| Dealer onboarding | `verified` boolean; admin verify endpoint | Needs improvement | No documents, no states, auto-verified bug | Application → documents → review → approve | P0 |
| Buy requirement | 8 fields, create/list/get/close | Partially implemented | Missing variant, max year, km, owners, radius, urgency, hard/soft flags, edit, pause, repost | Extend model; stepper form | P0 |
| Sell listing | 9 fields, create/list/get/close | Partially implemented | No registration no., owners, insurance, loan, accident, docs, photos, price edit | Extend model + upload | P0 |
| Dealer inventory | add/list, status text | Partially implemented | No edit/delete, photos, VIN/reg, min price, ageing, branch | Complete CRUD + media | P0 |
| Matching | None (`leads` returns everything) | Missing | Core feature absent | Rule-based matcher + MatchRecord | P0 |
| Quotes | Price + message only | Needs improvement | No price breakup, validity, revision, withdraw, availability type | New quote model + states | P0 |
| Purchase offers | Price + message only | Needs improvement | No inspection-based revision, validity, withdraw | Offer model + states | P0 |
| Accept/reject | None | Missing | Cannot close a deal | Accept/reject with concurrency lock | P0 |
| Negotiation | None | Missing | | Counteroffer thread | P0 |
| Chat | Single UI screen | Partially implemented | No backend | Per-quote/offer conversation | P1 |
| Notifications | Packages only | Missing | | Event system, in-app + push | P0 (essential) |
| Image/doc upload | None | Missing | | Supabase Storage + signed URLs | P0 |
| Admin | Metrics, dealer list/verify, 4 mock screens | Partially implemented | Unprotected, thin | Control centre | P0/P1 |
| Audit trail | None | Missing | | Append-only audit table | P0 |
| Test drives/inspection/booking/transactions/payments | None | Missing | | Phased | P1 |
| Disputes | None | Missing | | Phased | P1 |
| Dealer staff/branches | None | Missing | | Phased | P1 |
| Tests/CI | 2 frontend tests | Missing | | Add from slice 0 | P0 |

---

## Deliverable 2 — Feature catalogue
Legend: **E** existing, **P** partial, **M** missing, **I** needs improvement, **F** future.

**Customer**: email login E; phone OTP M; profile P; saved cities/addresses M; notification prefs M; delete account M; post buy requirement P; edit/pause/repost requirement M; post sell listing P; photo/video upload M; quote list P; quote compare P (UI mock only); counteroffer M; accept/reject M; shortlist M; test-drive booking M; activity timeline P; dispute M; rate dealer M.

**Dealer**: register P; document upload M; verification states I; inventory add/list P; inventory edit/delete/media M; bulk import F; ageing/margin F; buyer leads P; matching score M; sourced-vehicle proposal M; quote builder I; quote revision/withdraw M; seller leads P; procurement calculator M; inspection-based re-offer M; staff roles M; branches M; dashboard (mock) P; subscription F.

**Admin**: metrics P; dealer verification P; document review M; suspend/reactivate M; customer management M; listing moderation M; quote/offer monitoring M; dispute centre M; fraud flags M; audit log M; master data (makes/models/cities) M; analytics/liquidity M; settings M.

**Shared platform**: JWT auth E; role guards I; migrations M; file storage M; background jobs M; rate limiting M; search M (rule-based filters first); observability M.

**Trust and verification**: dealer verification I; document verification M; DealScore M; reliability score M; Car Passport F; FairPrice F; price lock P1.

**Matching and bidding**: matcher M; sealed bidding M; negotiation M; expiry M.

**Transaction management**: booking M; transaction milestones M; payments M (record-only first); ownership transfer checklist M.

**Analytics**: KPIs P (3 counts); funnel M; liquidity M; dealer performance M.

**Notifications**: all M.

**Monetization**: subscription F; transaction fee F; referrals F.

---

## Deliverable 3 — Prioritisation matrix

| Feature | Role | Pri | Value | Complexity | Dependencies | Release |
|---|---|---|---|---|---|---|
| Security fixes S1–S6 | All | P0 | Critical | S | none | R0 |
| Migrations, tests, CI, one contract | Platform | P0 | High | M | none | R0 |
| Auth decision + role guards + phone OTP | All | P0 | High | M | D1 | R1 |
| Dealer onboarding + docs + admin review | Dealer/Admin | P0 | High | M | storage | R1 |
| Image/doc upload | All | P0 | High | M | storage | R1 |
| Extended buy requirement + lifecycle | Customer | P0 | High | M | R1 | R2 |
| Dealer inventory CRUD + media | Dealer | P0 | High | M | storage | R2 |
| Rule-based matching + MatchRecord | Platform | P0 | Very high | M | inventory, requirement | R2 |
| Quote builder + revisions + expiry | Dealer | P0 | Very high | L | matching | R3 |
| Compare + accept/reject + concurrency | Customer | P0 | Very high | M | quotes | R3 |
| Negotiation (counteroffer thread) | Both | P0 | High | M | quotes | R3 |
| Sell listing extended + offers | Customer/Dealer | P0 | Very high | L | upload | R4 |
| Procurement calculator | Dealer | P0 | Medium | S | offers | R4 |
| Notifications (in-app + push) | All | P0 | High | M | events | R2–R4 |
| Admin control centre + audit log | Admin | P0 | High | M | audit | R3–R5 |
| Test drive + inspection scheduling | Both | P1 | High | M | accept flow | R5 |
| Booking + transaction milestones + payments (record) | Both | P1 | High | L | accept | R6 |
| Chat | Both | P1 | Medium | M | Realtime | R6 |
| DealScore | Customer | P1 | High | M | quote fields | R6 |
| Dealer reliability | Platform | P1 | High | M | history data | R7 |
| Disputes | All | P1 | High | M | transactions | R7 |
| Staff + branches | Dealer | P1 | Medium | M | roles | R7 |
| Fraud flags | Admin | P1 | Medium | M | audit | R7 |
| Car Passport | All | P2 | High | L | docs, integrations | R8+ |
| FairPrice | All | P2 | High | L | transaction data | R8+ |
| ExchangeMatch | Customer | P2 | High | L | buy+sell stable | R8+ |
| Demand intelligence | Dealer | P2 | Medium | M | data volume | R8+ |
| Finance/insurance/warranty | All | P2 | Medium | L | partners | R9+ |
| Subscriptions | Dealer | P2 | Medium | M | active dealers | R8+ |
| AI Car Finder, group buying, fleet | Customer | P3 | Speculative | XL | everything | later |

---

## Deliverable 9 — Top 10 differentiators (ranked)

1. **Sealed competitive quotes with transparent total cost.** Gap: classifieds show asking prices that hide fees. How: quote must itemise ex-showroom/vehicle price, registration, insurance, delivery, warranty. Data: quote line items. Complexity M. Release R3.
2. **DealScore (rule-based, explainable).** Gap: customers can't compare unlike offers. Show three badges: Lowest price, Best value, Highest trust, each with a visible breakdown. Complexity M. R6.
3. **Price Lock with revision audit.** Gap: bait-and-switch after acceptance. Accepted terms valid N days; any change needs reason, evidence, customer approval. Complexity M. R6.
4. **Dealer Reliability score** with minimum-sample rule. Gap: ratings are unverifiable. Built from completion, cancellation, quote accuracy, response time. M. R7.
5. **Seller procurement-grade offers with inspection re-offer.** Gap: sellers get lowballed after inspection. Initial vs final offer, with a recorded reason for any drop. M. R4/R5.
6. **ExchangeMatch.** Gap: trade-in and purchase are negotiated separately. Two linked transactions with a dependency view. L. R8+.
7. **Car Passport with source labels** (owner-declared / dealer-claimed / third-party / official). Gap: unverified claims look verified. L. R8+.
8. **FairPrice range** (never a guaranteed price). Starts as a rule table, improves with Revora's own accepted prices. L. R8+.
9. **Demand Intelligence for dealers** (aggregated, no personal data). Gives dealers a reason to open the app daily. M. R8+.
10. **Liquidity-aware onboarding** (admin sees cities where demand exceeds dealers). Operational edge for scaling city by city. S–M. R5.

---

## Deliverable 10 — Product vision

**Positioning:** "Post once. Dealers compete. You choose." A demand-first car marketplace for India where verified dealers bid on what you actually want, and the true on-road price is visible up front.

**Value proposition**
- Customer: one request replaces visiting many dealers; comparable, itemised quotes; sellers get competing offers.
- Dealer: pre-qualified, intent-rich demand instead of anonymous traffic; tools to price and source.
- Admin/Platform: trust through verification, audit and dispute handling.

**MVP boundary (R0–R4):** secure auth and roles, dealer verification, buy and sell requests, inventory, rule-based matching, quotes, offers, comparison, counteroffer, accept/reject, in-app + push notifications, admin control with audit, status tracking. **Excluded from MVP:** payments, chat, car passport, FairPrice, ExchangeMatch, finance/insurance, subscriptions, AI.

**Expansion:** trust (R5–R7) → monetisation and data products (R8+) → innovation (P3).

**Launch strategy:** one city, 15–25 hand-verified dealers (supply first), then open to customers in a waitlist. Measure time-to-first-quote and quotes-per-request before adding cities. Free for customers; dealers free during pilot.

**Risks and mitigations**

| Risk | Mitigation |
|---|---|
| Dealers don't respond (empty marketplace) | Single-city launch, onboarding in person, response SLA, "sourced vehicle" quotes |
| Disintermediation (off-platform deals) | Mask contact until acceptance; value from comparison, price lock, disputes |
| Fake dealers / fraud | Document review, no auto-verify, admin audit, rate limits |
| Spam to dealers | Capped match count, hard-requirement filters, requirement expiry |
| Regulatory (data, RC/VAHAN, payments) | Legal review before integrations or holding money; record-only payments first |
| Scope creep | Slice roadmap, MVP boundary above |
