# Revora — Product Plan, Part 3: Screens & UX, Technical Impact, Roadmap, Skills, Metrics, Compliance, Monetization

Planning only. Awaiting approval before any implementation.

---

## Decisions needed from you (D1–D8)

| ID | Decision | Recommendation |
|---|---|---|
| D1 | One auth system. Today: Supabase Auth in Flutter **and** FastAPI JWT. | **Supabase Auth for identity (phone OTP, email, Google), FastAPI verifies the Supabase JWT** and owns roles/permissions in its own DB. Removes custom password/reset/verify code. Alternative: keep FastAPI auth and drop Supabase Auth (more code to maintain, no phone OTP). |
| D2 | Database | PostgreSQL (Supabase) in all environments, Alembic migrations. Retire SQLite and `create_all`. |
| D3 | Primary keys | UUID everywhere (matches the SQL file and Flutter String ids). |
| D4 | Money | Integer rupees (paise not needed); format in UI. |
| D5 | Launch city and dealer count | One city, 15–25 dealers. Which city? |
| D6 | Payments in MVP | Record-only (no money held). |
| D7 | Inspection | Dealer-inspection first; partner inspection in P1. |
| D8 | Languages | English first; structure for Hindi/regional (ARB files) from slice 0. |

---

## Deliverable 5 — Screen requirements

Common states for **every** list screen: *Loading* = shimmer skeletons (never a bare spinner); *Empty* = illustration + one-sentence reason + primary action; *Error* = message + Retry (+ offline banner); *Success* = inline confirmation, not just a snackbar.
MVP = M, consolidate = C, later = L.

### Customer
| Screen | Rel. | Purpose / actions | Key data & inputs | Validation | Navigation / APIs |
|---|---|---|---|---|---|
| Splash + onboarding (3 cards) | M | Explain "post once, dealers compete"; choose Buy/Sell | none | – | → Login |
| Register/Login (phone OTP, email) | M | Auth | phone, OTP, name, city | phone format, OTP 6 digits, resend timer | Auth API |
| Home | M | Two big actions; active requests with quote counts; expiring quotes | requests, listings, unread | – | `GET /requirements`, `/sell-listings` |
| Buy: Step 1 What | M | Make, model, variant, year range, body type | dependent dropdowns; "I'm flexible" toggle | model requires make | master data API |
| Buy: Step 2 Budget & place | M | Budget min/max, fuel, transmission, city, radius, urgency | slider with ₹ lakh labels | min ≤ max, > 0 | – |
| Buy: Step 3 Preferences (optional, collapsed) | M | Km max, owners, colour, first-owner, certified, service history; each marked Must/Nice | chips with Must/Nice toggle | – | – |
| Buy: Review & post | M | Summary, estimated dealers, expiry | – | duplicate-request warning | `POST /requirements` |
| Request detail + quotes | M | Quote list, countdown, filters (in stock / sourced), shortlist, compare, edit/pause/close | quote cards | – | `GET /requirements/{id}/quotes` |
| Quote detail | M | Itemised price, vehicle, dealer, validity, DealScore, counter, accept, chat | – | – | quote API |
| Compare (2–4 quotes) | M | Side-by-side total cost, differences highlighted | – | max 4 | – |
| Counteroffer sheet | M | Price + note | price within 50–100% of quote | numeric | negotiation API |
| Accept confirmation | M | Shows locked terms, price lock period, what happens next | checkbox consent | – | `POST /quotes/{id}/accept` |
| Sell: Details, Condition, Photos, Price (4 steps) | M | Reg no., make/model/year, km, owners, insurance, loan, accident, service, photos (min 5), expected price | – | reg no. pattern, km plausibility, photo count | `POST /sell-listings`, upload |
| Listing detail + offers | M | Offers list, accept, inspection request, close | – | – | offers API |
| Test drive / inspection booking | P1 | Pick slot | calendar | future slot only | appointment API |
| Transaction tracker | P1 | Timeline of milestones and checklist | – | – | transaction API |
| Activity | M | Unified timeline (C: replaces separate quote/offer/appointment history) | – | – | – |
| Notifications | M | Feed + preferences | – | – | notifications API |
| Chat | P1 | Per-deal thread | – | – | Realtime |
| Disputes, Support | P1 | Raise and track | category, description, evidence | required fields | dispute API |
| Profile & settings | M | Details, cities, notifications, privacy, delete account | – | – | – |
| Shortlist, Car Passport, FairPrice, ExchangeMatch | L | | | | |

### Dealer
| Screen | Rel. | Notes |
|---|---|---|
| Onboarding + document upload | M | Steps: business → owner → documents → bank (later) → submit. Status banner: Pending / Needs changes / Approved / Suspended. Limited access until approved. |
| Dashboard | M | First screen shows, in order: (1) new matched leads with deadlines, (2) quotes awaiting customer, (3) offers needing action (inspection due, expiring), (4) accepted deals, (5) small KPI strip (response time, win rate). Inventory ageing and margin below. |
| Inventory list / add / edit / detail | M | Photo-first form, registration/VIN duplicate check, min price (private), status. Bulk import = L. |
| Buy leads | M | Cards: requirement summary, match score, deadline, urgency, Exact/Alt tags. Filters. Assign to staff = P1. |
| Quote builder | M | Pick inventory car or "sourced", itemised price, warranty, delivery, validity; live "customer sees" preview. |
| Sell leads + procurement calculator | M | Photos/docs, offer price, refurbishment, margin, resale estimate. |
| Offer builder + inspection scheduling | M | Initial → schedule → final with reason codes. |
| My quotes/offers (C: one tab view) | M | Status filters, revise, withdraw. |
| Active deals / transactions | P1 | Milestones, documents. |
| Staff & branches, analytics, billing | P1/L | |
| Profile & verification | M | |

### Admin (web)
| Screen | Rel. |
|---|---|
| Dashboard (funnel, liquidity map, alerts) | M |
| Dealer applications + document review (approve/reject/request more, with reasons) | M |
| Dealers & customers (suspend/reactivate with reason) | M |
| Requests/listings moderation, quote/offer monitor (read-only + void) | M |
| Audit log | M |
| Master data (makes, models, variants, cities) | M |
| Dispute centre, fraud flags | P1 |
| Reports/exports, notifications broadcast, revenue, platform settings | P1/L |

---

## UI/UX direction

**Principles**: calm, trustworthy, price-first. Never show a number without its meaning (e.g. "On-road price" vs "Vehicle price").
- **Design system** (first deliverable of slice 0): extend existing `app_colors/app_text_styles/app_spacing` to tokens with light/dark, 4/8px spacing scale, 48dp tap targets, 12–16 radius, elevation levels; one set of components: button, input, chip, price tag, status badge, quote card, car card, stepper, bottom sheet, empty/error/skeleton. Document in a Widgetbook or a `/design` page.
- **Trust cues**: verified badge only for admin-approved dealers; source labels on every vehicle claim ("Owner declared", "Dealer claim", "Verified").
- **Money**: Indian grouping and lakh/crore, always one canonical formatter (`price_formatter.dart` exists).
- **Customer navigation (bottom bar, 4 tabs)**: Home · Activity · Notifications · Profile; Buy/Sell are the two large home actions (the current 5-tab bar splits Buy/Sell/Activity — consolidate).
- **Dealer navigation**: Dashboard · Leads · Inventory · Deals · More.
- **Web/tablet**: existing adaptive shell + sidebar is kept for admin and dealer web.
- **Forms**: progressive disclosure (3 steps, optional section collapsed), autosave drafts, inline validation, numeric keypads, sliders with text fallback.
- **Motion**: subtle (page transitions, quote arrival animation); respect reduced-motion.
- **Accessibility**: WCAG 2.1 AA contrast, semantic labels, text scale to 200%, no colour-only status. Localisation-ready strings.
- **Content**: plain language via the UX-copy skill; error messages state what happened and what to do.

---

## Deliverable 7 — Technical impact analysis

### Confirmed existing architecture (keep)
FastAPI + SQLModel, Postgres-compatible, Flutter + Riverpod + go_router + Dio, repository interfaces with mock implementations, shared widgets, adaptive shell.

### Proposed changes
**Database (new/changed entities)** — all UUID PKs, `created_at/updated_at`, soft delete where noted.

| Entity | Purpose | Key fields | Needed |
|---|---|---|---|
| `user` (exists) | Identity link | supabase_id, role, status | Now (change) |
| `customer_profile` | Preferences, cities | user_id, cities, notification_prefs | Now |
| `dealer` (exists) | Business | status enum (DRAFT/PENDING/APPROVED/REJECTED/SUSPENDED/RESTRICTED), verified_at | Now (change) |
| `dealer_document` | KYC docs | dealer_id, type, file_path, status, expires_on, reviewed_by | Now |
| `dealer_branch`, `dealer_member` | Branches, staff roles | role, permissions | P1 |
| `vehicle` (replaces `car_inventory`) | Dealer stock | reg_no, vin, variant, owners, km, price, min_price, status, branch_id | Now (change) |
| `vehicle_media` | Photos/video | vehicle_id, url, kind, order | Now |
| `buy_request` (changes `buy_requirement`) | Demand | ranges, strict flags JSON, urgency, radius, expires_at, status | Now |
| `sell_listing` (change) | Supply | reg_no, owners, insurance, loan, accident, docs, status | Now |
| `match_record` | Who was notified | request/listing id, dealer_id, score, tier, notified_at, responded_at | Now |
| `quote` + `quote_revision` | Offers to buyers | line items, availability_type, valid_until, status | Now |
| `purchase_offer` + `offer_revision` | Offers to sellers | stage, reason_code, valid_until | Now |
| `negotiation_round` | Counteroffers | parent id, by, price, note, valid_until | Now |
| `audit_event` | Append-only history | actor, action, entity, before/after, reason | Now |
| `notification_event`, `notification_delivery`, `device_token` | Messaging | | Now |
| `appointment` (test drive/inspection) | Scheduling | type, slot, status | P1 |
| `booking`, `transaction`, `transaction_milestone`, `payment_record`, `ownership_transfer` | Deal tracking | | P1 |
| `conversation`, `message` | Chat | | P1 |
| `dispute`, `dispute_evidence`, `report` | Trust | | P1 |
| `dealer_metric_snapshot` | Reliability | rolling windows | P1 |
| `subscription`, `car_passport`, `price_observation` | | | P2 |

Constraints: unique active quote per (dealer, request); unique `(request_id, dealer_id)` in `match_record`; check constraints on status enums; indexes on (city, make, model, status), `valid_until`.

**API** (REST, `/api/v1`): keep existing route prefixes; add role guards (`require_role`), proper ownership checks, pagination, filter params, idempotency keys; new groups: `/dealers/me`, `/dealers/me/documents`, `/vehicles`, `/matches`, `/quotes`, `/offers`, `/negotiations`, `/appointments`, `/transactions`, `/notifications`, `/admin/*`, `/master-data`. Existing `/leads/*` becomes matched-only.

**Background jobs**: expiry sweeper (5 min), matcher (on create + rematch), reminder sender, document-expiry check, metric snapshots. Start with APScheduler or Postgres-backed worker in-process (no new infrastructure); move to a queue only if needed.

**File storage**: Supabase Storage with private buckets for documents (signed URLs), public CDN for vehicle photos; type/size validation, EXIF stripping, virus scan hook (later), image compression on client.

**Frontend**: implement `Api*Repository` for each existing repository interface (mocks remain for tests/demos), Dio interceptor refresh, typed errors, go_router `redirect` role guards, remove duplicate routes, replace stub forms, add drafts, localisation scaffolding, Freezed models matching API schema (OpenAPI → models).

**Security**: role-based authorization on every endpoint; object-level ownership checks; row-level security on Supabase if clients query directly (prefer API only); rate limits (slowapi) on auth/OTP/quote; no customer phone before acceptance; PII encrypted at rest for documents; secrets from env only; CORS restricted; dependency scanning; remove client demo-role login.

**Third-party**: Supabase (auth, storage, realtime), FCM, SMS/OTP provider (DLT-registered in India), email provider, later payment gateway, RC/VAHAN/challan via **authorised data providers only** (no free public API assumed), insurance/PUC validation partners. Each needs a legal/partnership review.

**Testing**: pytest + httpx for API (auth, permissions matrix, state transitions, concurrency accept test, matching unit tests); Flutter unit (validators, formatters, controllers), widget tests (forms, empty/error states), integration tests for the 2 core journeys; golden tests for key components; CI (GitHub Actions: analyze, format, test, coverage threshold).

---

## Deliverable 8 — Implementation roadmap (independent, testable slices)

Critical path: **S0 → S1 → S2 → S3 → S4 → S5 → S6**. S7–S9 can run partly in parallel after S3.

| Slice | Objective | Backend | Frontend | DB | Done when |
|---|---|---|---|---|---|
| **S0 Foundation & safety** (1 wk) | Fix S1–S6, set up Alembic, CI, test harness, design tokens; decide D1–D8 | Remove auto-verify; `require_role`; protect admin & leads; env secrets; CORS | Remove demo-role login; route dedupe/guards; design system tokens | Alembic baseline | Permission-matrix tests green; CI green; app boots |
| **S1 Identity & dealer onboarding** | Single auth, roles, dealer application/review | Supabase JWT verify, profile endpoints, doc upload, admin review | Login/OTP, onboarding wizard, status banners; admin review screen | dealer status, dealer_document | New dealer can apply, admin approves/rejects, unapproved dealer blocked from quoting |
| **S2 Demand & supply data** | Real buy requests + inventory | Extended request model, master data, vehicle CRUD + media, uploads | Real 3-step form, inventory screens on API repos | buy_request, vehicle, vehicle_media | Customer posts request; dealer adds car with photos; both persisted |
| **S3 Matching** | Right dealers get leads | Matcher service, `match_record`, lead feed, caps, rematch job, audit | Lead cards with score/deadline | match_record | Matching unit tests (hard/soft, caps, no repeat) pass; dealer sees only matches |
| **S4 Quotes & decision** | Core marketplace loop | Quote + revisions, expiry job, compare data, accept/reject (atomic), negotiation rounds | Quote builder, quote list/compare/detail, counteroffer, accept flow | quote*, negotiation_round | Concurrency test; accept closes others; expired quotes can't be accepted |
| **S5 Notifications & admin core** | Keep users informed, give ops control | Event system, in-app feed, FCM, prefs; admin monitors, audit log, suspend/reactivate | Notification centre; admin dashboard & moderation | notification_*, audit_event | All P0 events delivered once (dedupe); every admin action audited |
| **S6 Selling journey** | Sell flow with offers | Extended listing, sell matching, offers with stages, inspection re-offer, accept | Sell wizard, offer list, dealer calculator & offer builder | sell_listing, purchase_offer* | Seller receives, compares, accepts offers; price-drop rules enforced |
| **MVP RELEASE (pilot)** | | | | | End-to-end pilot checklist, load sanity test, privacy review |
| S7 Appointments & inspection | Test drive + inspection | scheduling, reminders | calendar UIs | appointment | no double-booking, reminders sent |
| S8 Transactions & price lock | Close deals reliably | booking, milestones, payment records, lock | tracker | booking, transaction, payment_record | state machine tests, idempotent payment records |
| S9 Chat | Per-deal messaging | Realtime + moderation | chat UI | conversation, message | messages delivered, blocked after deal closes + 30d |
| S10 Trust | DealScore, reliability, disputes, fraud flags | scoring services, dispute workflow | score UI, dispute screens, admin dispute centre | metric_snapshot, dispute | explainable score breakdown; SLA timers |
| S11 Dealer business tools | Staff/branches, analytics, bulk import | RBAC | team UI | member, branch | permission tests |
| S12+ Expansion | Passport, FairPrice, ExchangeMatch, demand intel, finance/insurance, subscriptions | | | | per-feature specs after pilot data |

**User stories and acceptance criteria** for each slice will be written ticket-by-ticket on approval; examples:
- S3: *As a dealer I only see requests I can fulfil.* AC: a dealer with no Hyundai stock and no sourcing opt-in sees no i20 request; a request is never delivered to more than 15 dealers; the same dealer is never matched twice.
- S4: *As a customer I accept one quote safely.* AC: simultaneous accept calls result in one 200 and one 409; other quotes become NOT_SELECTED; accepted price equals displayed total.

---

## Skills and tooling

**Already available in this session** (no install needed): design plugin (design-critique, accessibility-review, design-system, design-handoff, ux-copy, user-research, research-synthesis), engineering plugin (architecture, system-design, testing-strategy, code-review, debug, documentation, deploy-checklist, tech-debt), data plugin (SQL, dashboards, metrics), `artifact-design`, `security-review`, `simplify`, `claude-api`.

**Recommended installs** (cards shown in chat — you enable them):
1. **Dart and Flutter** (official): widget/integration tests, responsive layout, routing, serialization, static analysis, Dart MCP server.
2. **Flutter Skills** (community): Riverpod state, forms-and-input, ui-states-and-feedback, adaptive-layout, accessibility, performance, testing, design-system structure — matches the project's Riverpod stack.

**Not recommended:** Very Good AI Flutter (BLoC-centric, conflicts with Riverpod); ux-superpowers (privileged session hooks, not needed); mobile design plugins aimed at iOS-only.
**Later:** Mobile Release Check before store submission.

**Workflow per slice**: system-design/architecture → write acceptance tests → implement backend → implement Flutter → design-critique + accessibility review → code-review + security-review → deploy-checklist.

---

## Deliverable 14 — Metrics

| Metric | Definition | Source |
|---|---|---|
| Time to first quote | first `quote.submitted_at` − `buy_request.published_at` (median) | quote, request |
| Relevant quotes per request | submitted quotes not hidden/void ÷ requests older than 72h | quote |
| Shortlist rate | requests with ≥1 shortlist ÷ requests with ≥1 quote | shortlist |
| Acceptance rate | requests with accepted quote ÷ requests with ≥1 quote | request |
| Completion rate | completed transactions ÷ accepted | transaction |
| Dealer response time | median(`responded_at − notified_at`) | match_record |
| Quote submission rate | matches with quote ÷ matches notified | match_record |
| Win rate | accepted quotes ÷ submitted | quote |
| Cancellation rate | post-acceptance cancels ÷ accepted, by reason | transaction |
| Unmatched requests | requests with 0 matches after 24h | match_record |
| Liquidity (city/segment) | open requests ÷ active dealers who responded in 14d | request, dealer |
| Dispute rate | disputes ÷ completed + cancelled | dispute |
| Request→completion time | completed_at − published_at | transaction |
| Revenue per transaction | fees + subscriptions ÷ completed | billing |
| NPS/CSAT | post-deal survey | feedback |

Instrument events from S0 (`request_posted`, `match_notified`, `quote_submitted`, `quote_viewed`, `accepted`, …) so data exists at pilot.

---

## Security, compliance and integrations (items for professional review)

- **Data protection (DPDP Act 2023)**: consent capture, purpose limitation, retention schedule, deletion on request, breach process. *Needs legal review.*
- **Vehicle data**: RC/VAHAN, challan, insurance, PUC — use authorised aggregators or manual document verification; none assumed free or open. Consent from owner required.
- **Payments**: holding customer money may need RBI-regulated partner; start record-only.
- **Dealer authorisation**: collect GST, trade certificate; brand authorisation where claiming "authorised dealer".
- **Ownership transfer (Form 29/30 etc.), hypothecation removal**: checklist and document tracking only; Revora does not perform the legal transfer in MVP. *Confirm with counsel.*
- **Communications**: SMS DLT registration; WhatsApp business policy; marketing consent.
- **Phone privacy**: masked until acceptance; calls via in-app chat first.
- **Abuse controls**: rate limits, device/IP signals, duplicate detection, report buttons.

---

## Monetization (not in MVP)

| Tier | Price idea | Includes |
|---|---|---|
| Basic | Free (pilot), then low | Inventory, limited leads/day, standard quote tools |
| Professional | monthly | More leads/day, analytics, staff seats, bulk import, demand intelligence |
| Enterprise | custom | Multi-branch, API/DMS import, priority support, reporting |

Plus completed-transaction success fee, inspection commission, finance/insurance/warranty referrals, fleet services. **Rule: subscriptions never buy verification, matching rank, or quote ranking.** Sponsored placements (if ever) are clearly labelled and outside the quote comparison.

---

## Next step
Approve, or edit, the decisions D1–D8 and the MVP boundary. On approval I convert S0 into concrete tickets (with the security fixes first) and start implementation slice by slice.
