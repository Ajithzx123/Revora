# Revora — Full Project Review (2026-11-15)

Scope: everything built through S6 (backend, Flutter app, process, product idea). Done read-only: no code was changed.
Method: automated counts and greps, targeted code reading, the existing test suites, a throw-away text-scaling sweep (deleted afterwards), and the Flutter web build run in a real browser at phone and tablet/desktop widths.

**Not covered (be aware):** the dealer and admin screens were not viewed in a browser; the app was never run against a live backend or Postgres; no dark-mode check; no load test; no real-device test; no external security scan or dependency audit.

---

## 0. Update — P0 fix pass (2026-11-15, same day)

| # | P0 item | Status |
|---|---------|--------|
| 1 | S6 offer card crushed on phones | **Fixed.** Buttons now stack on narrow cards (`ActionBar`). New regression tests measure the button at 375px and at larger text; against the old code 7 of 9 fail ("squeezed to 35px"). |
| 2 | Admin screens showed demo data | **Fixed.** New `GET /admin/requirements`, `GET /admin/vehicles` and real figures in `GET /admin/metrics` (deal value counts the lowered final price when one was accepted). Overview, Requirements and Vehicles now load real data with loading/empty/error states; the fake "+12 this month" trends and fake "Verified" column are gone; the activity trail is the real audit log. The dealer's private minimum price is never exposed. |
| 3 | `ENVIRONMENT` defaulted to dev | **Fixed.** Unset now means production and refuses to start without Postgres, Supabase and CORS origins. SQL logging is opt-in (`SQL_ECHO=1`). Local dev must set `ENVIRONMENT=dev`. |
| 4 | Never run on Postgres | **Fixed and it found three real bugs:** (a) no synchronous Postgres driver in `requirements.txt` (production could not connect); (b) **two simultaneous accepts deadlocked on Postgres** (loser got a 500) because rows were locked in opposite orders: now the shared request/listing row is locked first (a repeated race test fails on the old order with `DeadlockDetected`); (c) deleting a car with photos or matches violated a foreign key. The whole suite (315 tests, including a migration-on-Postgres test) now passes on Postgres 16 and SQLite, and CI runs both. **The CI workflow itself has not run on GitHub yet.** |
| 5 | No rate limiting | **Fixed (single-process).** Per-user limits on every write endpoint (429 with `Retry-After`); generous so only scripts hit them. In-memory, so move to Redis before running more than one server process. |
| 6 | Compliance (consent, privacy, deletion, phone OTP, KYC storage) | **Not fixed here: needs your decisions and credentials.** See section 5a below. |

---

## 1. Verdict in one paragraph

The backend is the strongest part: clear domain rules, atomic accepts, sealed bidding, audit trail, and 296 passing tests. The weak spots are (a) **honesty of the UI** (admin screens always show demo data; a fake chat and fake settings are reachable), (b) **mobile layout** (the main S6 action button is unusable on a phone, and 8 main screens break at 200% text size), (c) **production readiness** (never run on Postgres, no rate limiting, unpaginated lists (8), dev-by-default config), and (d) **the business idea has no revenue, no real dealer-reach channel and no legal/consent layer yet**. None of these is hard to fix, but several should be fixed before any real user sees the app.

---

## 2. Findings by severity

### P0 — fix before anyone real uses it

| # | Area | Finding | Evidence |
|---|------|---------|----------|
| 1 | UI | **"Accept offer" is crushed into a sliver of stacked letters on a 375px phone** (the primary action of the selling journey). The seller offer card puts three buttons in one `Row`. | Seen in the browser at 375×600; failing at 145% and 200% text in the sweep (`listing offers`). The existing smoke test passed it only because it shrinks text to 0.55×. |
| 2 | UI honesty | **Admin Overview, Requirements and Vehicles always show hard-coded demo data**, even with a live backend: `adminRepositoryProvider` returns `MockAdminRepository()` unconditionally. An admin would make decisions from fake numbers. | `admin_providers.dart:10`; the backend has no list endpoints for these screens. |
| 3 | Config | **`ENVIRONMENT` defaults to `dev`.** Forgetting the variable in production leaves SQL echo on (logs emails, phones, tokens in parameters), skips the production config checks and the CORS allow-list. Secure-by-default is inverted. | `config.py` default, `connection.py` `echo=...=="dev"`. |
| 4 | Data layer | **Never run on Postgres** (the stated production target). CI and every test use SQLite; migrations were only ever applied to SQLite (`batch_alter_table`, naive datetimes, SQLite-style concurrency). | `ci.yml` has no Postgres service. |
| 5 | Abuse | **No rate limiting anywhere** (quotes, offers, uploads, notifications, profile). Our own rule requires it. | grep: no limiter, no idempotency key. |
| 6 | Compliance | **No consent, privacy or deletion layer** (India's DPDP Act: consent capture, purpose, retention, deletion, grievance contact). Dealer KYC documents are stored on local disk. Phone numbers are not verified (no OTP), yet they are released to dealers after accept. | No terms/consent screens; `UPLOAD_DIR` is a local path; `plans/revora_plan_1` lists phone OTP as planned. |

### P1 — important, fix soon

**Backend / data**
- **8 list endpoints are unpaginated:** admin dealer list, dealer buyer leads, my quotes, my offers, dealer inventory, my requirements, quotes for a request, offers for a listing. (Sell leads, my listings, the audit log and the admin quote/offer monitors are paged.) Our rule says paginate every list.
- **No idempotency key on accept.** Accept is safely repeatable (status check + atomic update), but the rule asks for an `Idempotency-Key`.
- **Matching does N+1 queries** per dealer (responsiveness, daily cap, cars), and a background job re-matches every open request every 10 minutes. Fine for a pilot, expensive at scale.
- **Missing indexes** on the fields the scheduled jobs filter by: `status` and `valid_until` / `expires_at` on quotes, offers, listings and rounds.
- **Background loops run inside the web process** (matching, expiry, push). With more than one worker they run twice; push delivery has no row lock, so duplicates are possible. Move to one scheduler/worker before scaling out.
- **Status fields for quotes, offers and listings are free strings**, not enums, with checks scattered across service functions. Dealer and request already have transition tables; these should too, so an illegal transition cannot be added by accident.
- **Naive UTC datetimes and 46 uses of `datetime.utcnow()`** (deprecated; will break on a future Python). Use timezone-aware `timestamptz`.
- **Dependencies are unpinned (`>=`)** in `requirements.txt`; builds are not reproducible and no audit runs in CI.
- **`create_profile` race:** two simultaneous calls return a 500 (unique constraint) instead of 409.
- **Email-verified is not checked** in `create_profile`; it relies on Supabase "confirm email" being switched on.

**Flutter**
- **Text scaling rule fails on 8 main screens.** At 375px and 200% text: admin dashboard/requirements/vehicles/shell, customer home/shell, dealer home/profile/shell, and the S6 offers screen (also at 145%).
- **Fake or no-op things reachable in the live app:** a static chat screen ("Prime Motors") behind the home "Connect" button, dealer profile toggles/tiles that do nothing ("Instant Lead Alerts", "Operating Locations", a hard-coded "Mumbai (Andheri, Bandra)"), customer profile "Mumbai (MMR)".
- **The two wizards look like different apps:** the buy flow is a polished single-page flow with a progress bar; the sell wizard (S6b) is the stock Material Stepper.
- **Design-token rule broken ~541 times** (`Color(0x…)` / `Colors.*` outside `lib/core/theme`), **~173+ hard-coded strings, no localisation setup**, no offline banner, no form drafts.
- **The tests mostly use mock repositories.** Nothing checks that Flutter's JSON parsers match what the API really returns, so a renamed field would pass every test and break the app. No end-to-end run exists.
- **Mock mode is the default in debug/profile builds** (`USE_MOCK_DATA` defaults to true). A developer or demo pointed at a real backend must remember `--dart-define=USE_MOCK_DATA=false`. Release builds refuse mocks, which is right.

**Process**
- Branch `s0-security-foundation` now holds S0–S6 and has never been merged to `main` (PR #1 open). The name is stale and it is the largest single integration risk.
- CI's format check is non-blocking, and CI has no security, coverage or Postgres job.

### P2 — improvements

- Dead code: `customerActivitiesProvider`, `dealerActivitiesProvider`, `ui/tabs/buy_leads_tab.dart` and `dealer_inventory_tab.dart` (fake data), old mock activity models.
- Very large files: `add_car_to_inventory_screen.dart` (1,020 lines), `post_buy_requirement_screen.dart` (890). Split into step widgets.
- Customer `create`/profile has no phone verification, no avatar handling, no account deletion.
- The mock login shows demo accounts with a published password (`password123`); only in non-release builds, but keep it out of any shared build.
- No analytics events (plan says instrument from S0): the pilot would produce no funnel data.
- No admin bootstrap flow documented (admins are created by hand in the database).
- Docs: the plan files predate the built design in places (e.g. Postgres vs SQLite statements); keep `plans/revora_progress.md` as the single source.

---

## 3. Product and idea review

**What is strong**
- A clear, defensible wedge for India: demand-first ("post once, dealers compete"), sealed bidding, verified dealers only, capped fan-out (15 dealers per request, 10 per listing) so dealers are not spammed.
- Trust mechanics are unusually thorough for an MVP: admin-only verification with audit, contact hidden until accept, no admin price edits, a final-offer rule after inspection (reason code, evidence above 5% drop, free decline, listing reopens) that directly addresses the bait-and-switch problem sellers hate.
- Both sides of the market are covered (buy and sell), with negotiation limits and expiries that keep deals moving.

**Risks and gaps in the idea**
1. **Liquidity / cold start.** A two-sided market dies without supply. Nothing yet supports a city-by-city launch beyond the admin liquidity endpoint. Plan: launch in one city (e.g. Bengaluru), recruit 20–30 dealers by hand first, and post the first buyers yourself (concierge).
2. **No revenue path.** Subscriptions are deliberately excluded from ranking, and payments/escrow are out of MVP. The natural, rule-compatible options: a lead/contact-release fee charged when the customer accepts, or a flat dealer subscription that never touches ranking. Decide before the pilot.
3. **Disintermediation.** Once the contact is released at accept, the deal can leave the platform. Without payment or transfer tracking (S8) there is nothing to bring users back. Keep the post-accept steps (inspection, documents, transfer) inside the app.
4. **Dealer reach.** Notifications are in-app only (push is a stub; WhatsApp/SMS are not built). Dealers in India work in WhatsApp; a lead they never see is a dead lead. This is the biggest adoption risk after liquidity.
5. **The selling journey ends at "final price accepted".** Documents, payment, pickup and transfer are not built, so the most important trust moment is still outside the product.
6. **Verification depth.** Dealer documents are reviewed by hand; GSTIN is not validated; vehicle details are owner-declared (labelled as such, good) with no RC/VAHAN check; phone is unverified. Plan for an authorised data provider before volume.
7. **Pricing guidance.** Sellers get no price help and "no offers" has no guidance yet (planned later). Without it, sellers anchor too high and the listing expires.
8. **No real-user validation yet.** A lot of backend has been built before one real dealer or buyer has used it. The fastest learning now is a small concierge pilot, not more features.

---

## 4. Thinking and process review

**Good habits to keep:** slice-by-slice delivery, tests with every slice, a written progress record, evidence-before-claims, personal-vs-office identity care, commit/push only at the end of a feature.

**Habits to change**
- **Mock-first UI hides gaps.** Admin screens, the chat screen and several settings "work" only because they are fake. Rule: a screen is not done until it runs against the real API once.
- **Test blind spots:** the 0.55× text hack, mock-only Flutter tests, SQLite-only backend tests. Each gave a false green that the review then found real problems behind.
- **Long-lived branch.** Merge each finished slice (or at least merge `main` weekly).
- **One decision pending:** the calculator question (loan and challans as seller liabilities vs dealer costs) is still open.

---

## 5. Recommended order of work

1. **Fix list (small, high value):**
   a. S6 offer card and counter/final-offer rows: use `Wrap` / stack on narrow screens; re-run the text-scale sweep.
   b. Admin screens: connect to real endpoints (add the missing list endpoints) or hide until connected; remove the fake chat and no-op tiles.
   c. Flip `ENVIRONMENT` default to production-safe; stop SQL echo outside dev.
2. **Production-readiness slice:** Postgres in CI (service container) and run migrations on it; pagination everywhere; rate limiting; `Idempotency-Key` on accept; indexes; timezone-aware datetimes; pinned dependencies; move background jobs out of the web process.
3. **Contract tests:** generate or snapshot the API schema and test the Flutter parsers against real responses.
4. **UI consistency slice:** one wizard pattern for buy and sell, tokens instead of hard-coded colours, ARB localisation, offline banner, a proper 200%-text check and dark mode.
5. **Pilot enablers:** WhatsApp/SMS delivery, consent and privacy screens with deletion, phone OTP, analytics events, revenue decision, then S7–S9.
6. **Merge the branch** into `main` as soon as (1) is done.

---

## 5a. What the compliance item needs from you (P0-6)

1. **Terms of Service and Privacy Policy text** (and a grievance contact), from a lawyer or a trusted template; the app can then record each user's consent and the version they accepted.
2. **Retention and deletion policy:** what is deleted when a user closes an account, and what must be kept (audit events, accepted deals) and for how long.
3. **Phone verification:** turn on Supabase phone OTP (needs an SMS provider, DLT-registered for India) and decide whether a verified phone is required to post or only to be shown to dealers.
4. **KYC document storage:** a Supabase Storage bucket (private) and its key, so documents leave local disk.
5. A privacy review of what dealers can see (today: first name and city before accept; full contact after accept).

Once these exist, it is one slice: consent records + screens, account deletion/export, phone OTP, private storage.

---

## 6. Evidence appendix

- Backend routes: 85 across 10 routers; 296 tests passing.
- Unpaginated list endpoints (8): admin dealers, buyer leads, quotes mine, offers mine, inventory, my requirements, quotes for a request, offers for a listing.
- Flutter: 180 tests passing; analyze and format clean.
- Text-scale sweep failures (375px): 145% — admin ×4, listing offers; 200% — those plus customer home/shell, dealer home/profile/shell.
- Largest files: `add_car_to_inventory_screen.dart` 1,020 lines; `post_buy_requirement_screen.dart` 890; `admin_api.py` 503; `offer_service.py` 500.
