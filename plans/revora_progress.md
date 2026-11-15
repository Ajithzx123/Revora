# Revora — Progress, Process and Open Items

The single place to see where the project stands, how we work, and what is left.
Update it at the end of every feature (slice) and whenever a decision changes. Last updated: 2026-11-15 (end of day handoff).

## START HERE — where we stopped (handoff, 2026-11-15)

**If a new session asks "what's next?", answer from this section.**

### State of the code
- `main` on GitHub (`Ajithzx123/Revora`) contains **everything built so far: S0 through S6, the P0 fixes from the project review, and CI on Postgres.** PR #1 and PR #2 are both merged. **No PR is open.**
- All checks were green at the end: backend **315** tests (SQLite and Postgres 16), Flutter **194** tests, `flutter analyze` and `dart format` clean, CI passing (Flutter pinned to 3.44.0).
- The old branch name `s0-security-foundation` is stale (it held S0–S6). **Start the next work on a new, clearly named branch from `main`:** `git fetch && git checkout main && git pull && git checkout -b <short-name>`.
- Local clutter that can go: branch `backup-before-author-rewrite` (old commits with the office email, local only).

### What exists
Buy side (requests, matching, quotes, negotiation, atomic accept), sell side (listings, matching, offers, counter-offers, inspection final offer), dealer onboarding and admin verification, notifications (in-app complete, push is a stub), admin audit log / quote + offer monitors / real overview, rate limiting, secure config. Details by slice are in section 3.

### What to do next (recommended order)

**A. Things only the user can decide or provide (ask these first)**
1. **Compliance inputs (P0-6, the one P0 item left):** terms + privacy text and a grievance contact; account deletion/retention policy; phone OTP (Supabase phone auth needs an SMS provider, DLT-registered for India); a private Supabase Storage bucket + key for KYC documents. Full list in `plans/revora_review_2026-11-15.md` section 5a. Once provided it is one slice: consent records + screens, account deletion/export, phone OTP, private storage.
2. **Revenue model:** nothing earns money yet. Options that respect the rules: a fee when a customer accepts (contact release) or a flat dealer subscription that never affects ranking. Decide before any pilot.
3. **Procurement calculator question:** a running loan and pending challans are currently treated as the seller's liabilities paid out of the offer (they lower what the seller receives, not the dealer's cost). The plan lists them as dealer costs. Confirm which.
4. **Firebase project** (for real push) and a **WhatsApp/SMS provider** (dealers live in WhatsApp; today a lead is only visible in the app).

**B. Engineering work, in order (the P1 list from the review)**
1. **Production-readiness pass 2 (backend):** paginate the 8 unpaginated lists (admin dealers, dealer buyer leads, my quotes, my offers, inventory, my requirements, quotes for a request, offers for a listing); `Idempotency-Key` on accept endpoints; indexes on `status` / `valid_until` / `expires_at` for quotes, offers, listings, rounds; enums + transition tables for quote/offer/listing statuses; timezone-aware datetimes (replace 46 `utcnow()`); pin `requirements.txt`; move background jobs (matching, expiry, push) out of the web process (they run twice with several workers; push has no row lock); `create_profile` race should return 409; check `email_verified`; Redis-backed rate limits before running more than one process.
2. **Flutter pass:** 200%-text fixes on 8 screens at 375px (admin dashboard/requirements/vehicles/shell, customer home/shell, dealer home/profile/shell); remove the fake chat screen and no-op dealer profile tiles; one wizard pattern for buy and sell; replace ~541 hard-coded colours and ~173 strings with tokens and ARB localisation; offline banner; form drafts; contract tests that run Flutter parsers against real API responses; replace the 0.55× text hack in the screen sweep.
3. **Compliance slice** (after A1), then **pilot enablers:** WhatsApp/SMS delivery, analytics events, real FCM, an admin bootstrap flow.
4. **Roadmap slices:** S7 appointments and inspection scheduling, S8 transactions / price lock / payment records (the sell journey currently stops at "final price accepted"), S9 real chat, S10 trust and disputes, S11 dealer tools.
5. **Pilot:** the review recommends a small concierge pilot in one city (e.g. Bengaluru: recruit 20–30 dealers by hand, post first buyers yourself) as soon as A1, A2 and push/WhatsApp exist. No real user has used the product yet.

**C. Not yet verified (be honest about these)**
The app has never run against a live backend (Flutter was tested on mock repositories); dealer and admin screens were not viewed in a browser; no dark-mode pass; no load test; no real device; no external security scan or dependency audit; real FCM push untested.

### How to resume in a new session
1. Read this section, then `CLAUDE.md` (rules) and `plans/revora_review_2026-11-15.md` (findings).
2. Check identity before any git action: `git config user.email` must be `kumarajith577@gmail.com`; `gh auth status` must be `Ajithzx123`.
3. Run the checks in section 2 (note `ENVIRONMENT=dev` for the local server; Flutter is not on PATH).
4. Ask the user which item above to start, then plan first, build, test, and commit only when the slice is complete (or when the user says they are stopping).

## 1. How we work (the process)

1. **One slice at a time** (S0…S12 in `plans/revora_plan_3_screens_tech_roadmap.md`). Do not start the next slice until the user says so.
2. **Plan first.** For a slice: read the spec, survey the code, agree the breakdown, then build.
3. **Evidence before claims.** A slice is "done" only when tests pass and analyze/format are clean. Say what is unverified.
4. **Git policy (decided 2026-11-09):**
   - Do **not** commit or push after every small step.
   - Commit when a **feature/slice is complete**, or when the user says we are **stopping for the day** (then commit and push).
   - Never push, force-push, rewrite history or open/merge PRs without the user asking.
5. **Git identity:** this is a personal repo (`github.com/Ajithzx123/Revora`, public). Commits must use `kumarajith577@gmail.com`. Never the office email. Check `git config user.email` and `gh auth status` before any push.
6. **No secrets in the repo.** `.mcp.json`, `.env`, Firebase / service-account files stay untracked.
7. Project rules live in `CLAUDE.md` (product rules, backend rules, frontend rules, definition of done).

## 2. How to run and check things

| What | Command (from repo root unless noted) |
|---|---|
| Backend tests | `backend/.venv/bin/python -m pytest backend -q` |
| Backend server | `ENVIRONMENT=dev backend/.venv/bin/uvicorn backend.main:app --reload` (from repo root). **`ENVIRONMENT=dev` is now required locally**: an unset value means production and the server refuses to start without Postgres/Supabase/CORS config. `SQL_ECHO=1` turns on SQL logging (dev only). |
| Backend tests on Postgres | start a Postgres 16, then `TEST_DATABASE_URL=postgresql://user@127.0.0.1:PORT/revora_test backend/.venv/bin/python -m pytest backend -q`. CI runs both SQLite and Postgres. On this Mac use `brew install postgresql@16` and `LC_ALL=en_US.UTF-8`; stop and delete the scratch server afterwards. |
| New migration | add `backend/migrations/versions/000N_*.py`; `test_migrations.py` fails if models and migrations drift |
| Flutter version | **3.44.0** (stable). CI is pinned to it in `.github/workflows/ci.yml`. Newer Flutter (3.47+) deprecates `package:flutter/material.dart` in favour of `package:material_ui`; moving to it is a separate migration (every file imports material.dart). |
| Flutter SDK | `/Users/santhosh/work/softwares/flutter/bin` is **not on PATH**: `export PATH=/Users/santhosh/work/softwares/flutter/bin:$PATH` |
| Flutter checks (in `frontend/`) | `flutter analyze`, `dart format lib test`, `flutter test` |
| Mock vs live data | Flutter uses mock repositories by default in debug/test (`USE_MOCK_DATA`); release builds never use mocks |

Current numbers: backend **315** tests passing (on both SQLite and Postgres 16); Flutter **194** tests passing, analyze and format clean.

## 3. Status by slice

| Slice | What | State |
|---|---|---|
| S0 | Security fixes, test harness, CI, rules | Done |
| S1 | Supabase identity, UUID ids, Alembic, dealer onboarding + admin review | Done |
| S2 | Buy requests, vehicles + photos, privacy-safe leads | Done |
| S3 | Matching (hard filter, soft score, 15-dealer cap, no repeat) | Done |
| S4 | Quotes, revisions, negotiation, atomic accept | Done |
| S5a | Notification events, feed, preferences, devices, push delivery (migration 0005) | Done |
| S5b | Append-only audit trail, quote monitor, admin void, suspensions (migration 0006) | Done |
| S5c | Flutter notification centre + settings, admin Quote Monitor + Audit Log, push token registration | Done |
| S6 | Selling journey: richer listings, sell matching, offers (submit/revise/withdraw/expire), atomic accept, seller close / price change / sold elsewhere, seller + dealer counter-offers (max 5 rounds, 24h), inspection stage with final offer (same price confirms; lower needs a reason, >5% needs evidence; seller declines free and the listing reopens with other valid offers), admin void/freeze, suspension handling. Flutter: sell wizard, offers screen, dealer Cars to buy / My offers / offer builder + procurement calculator, final-offer dialog. Migrations 0007, 0008 | **Done** |
| S7–S12 | Appointments, transactions, chat, trust, dealer tools, expansion | Not started |

## 4. Git and PR state

- `main` = everything through S6 + P0 fixes + CI pinning. PR #1 (S0–S5c) and PR #2 (S6 + P0) are merged; no PR is open.
- **History worth knowing:** `main` once carried three older September UI commits from another line of work (new theme system, buy-flow screens, folder restructure). On 2026-11-09 we decided **to keep the latest** (the Showroom design and S1–S5c) and merged `main` with `git merge -s ours`, so those commits are in history but not in the code. They stay reachable if ever wanted.
- **Commit identity:** all commits use `kumarajith577@gmail.com`; the office email was removed from history on 2026-11-09 (old hashes may remain reachable on GitHub).
- **Lesson:** long-lived branches diverge. Merge each finished slice (or merge `main` in weekly) and use branch names that match the work.
- **CI:** `.github/workflows/ci.yml` runs the backend suite on SQLite and Postgres 16 and the Flutter job (pinned to 3.44.0; format check is blocking).

## 5. Open items and known gaps

**Project review (2026-11-15):** full findings and the recommended order are in `plans/revora_review_2026-11-15.md`. The P0 pass fixed five of six items the same day; the sixth (compliance) waits on your decisions (section 5a of that report). Still open from the review: P1/P2 items (pagination on 8 lists, idempotency keys, indexes, background jobs out of the web process, enums for statuses, 200% text on 8 screens, fake chat/settings, wizard consistency, hard-coded colours/strings, contract tests, branch merge).


**Decisions waiting on the user:** see "START HERE" (compliance inputs, revenue model, calculator semantics, Firebase and WhatsApp/SMS providers).

**Not verified**
- Real FCM push: no Firebase project is configured (no `google-services` files, no `Firebase.initializeApp`). The Flutter token source is a stub; the backend sender only logs without credentials. `firebase-admin` is not in `requirements.txt`.
- Flutter screens were tested against mock repositories, never against a running backend.
- No dark-mode / 3-width visual pass (`revora-ui-check`) for the S5 screens.

**Known limitations**
- Suspending a customer blocks sign-in but leaves their open requests live.
- Not built for S6: seller counter on the *final* price (they accept or decline), the dealer-silent-after-inspection reminders (48h/72h), and aggregating large final-price drops per dealer into an admin flag (each large drop writes an `OFFER_FINAL_LARGE_DROP` audit event to build on). Transfer, documents and payment come in S8.
- Sell listings: offer window is 2 days (URGENT), 14 days (NORMAL) or 5 days (MAX_PRICE); the plan's 12-hour urgent window is not built. No per-dealer daily lead cap on sell leads yet. Listing status `ACTIVE` means open (the plan calls it OPEN).
- Reactivating a dealer restores valid quotes silently (the buyer is not notified).
- Tapping a quote notification only marks it read (request notifications open the request).
- "Offer expiring in 4 hours" notification needs a scheduled job; not built.
- Unread badge refreshes on open / mark-read, not in real time.
- Older audit writers (inventory, auth, requirements, matching) do not record the actor role.
- Buy/Leads tab badges still show hard-coded numbers.
- Unused leftovers: `customerActivitiesProvider`, `dealerActivitiesProvider` and their mock data.
- Strings are hard-coded (no ARB localisation set up).
- Sell wizard has **no photo upload** yet (the API takes image URLs only; customer photo upload and the odometer-photo rule are not built).
- Procurement calculator treats a running loan and challans as the seller's liabilities paid out of the offer (they lower what the seller receives but do not add to the dealer's cost). The plan lists them as costs; confirm which you want.
- A dealer sees no sell leads until they pick the makes they buy (profile > "Cars I buy from owners").
- Old mock sell leads (with customer phone numbers) and the dead `ui/tabs/sell_leads_tab.dart` were removed.
- The Stepper used in the sell wizard now builds buttons only for the open step (it built duplicates for every step).
- Tests emit `datetime.utcnow()` deprecation warnings.

## 6. Accounts and identity

| Item | Value |
|---|---|
| Repo | `github.com/Ajithzx123/Revora` (public, personal) |
| `gh` login on this Mac | `Ajithzx123` (personal) |
| Commit email for this repo | `kumarajith577@gmail.com` (set locally) |
| Office email | Must never appear in this repo's history (it was removed from all 21 commits on 2026-11-09; old hashes may still be reachable on GitHub) |
| Supabase project | ref `hjvzirkdnoaqahzusdbj` (read-only MCP configured in untracked `.mcp.json`) |

## 7. gstack (project-local skill suite, installed 2026-11-15)

- **What:** garrytan/gstack v1.99.5.0 (`/gstack-review`, `/gstack-qa`, `/gstack-ship`, `/gstack-office-hours`, design and plan reviews, browser skills, ...). Installed for **Revora only**; no other project and no global Claude setting changed (global `~/.claude/settings.json` and `~/.claude/skills` verified identical before and after).
- **Where:** source in `/Users/santhosh/work/softwares/gstack`; project links in `.claude/skills/gstack-*` (git-ignored, they point at that folder); state in `~/.gstack` (telemetry off, auto-upgrade off, team mode off).
- **Installed with:** `/Users/santhosh/work/softwares/gstack/setup --local --prefix --no-team`, with `PATH=/opt/homebrew/opt/node@20/bin:$PATH` so the bundled browser could install. Default Node stays 16. Setup also ran `brew install coreutils`; we added `brew install bun node@20` (node@20 is keg-only).
- **Health check:** `/Users/santhosh/work/softwares/gstack/bin/gstack-doctor` (11 ok, 0 fail; Codex CLI not installed, so no outside-review coverage).
- **Conflicts with our rules:** `/gstack-ship` commits, pushes and opens PRs. Our rule is commit only at slice end and push only when asked, so do not run it without saying so. `/gstack-qa` drives a real browser.
- **Update:** manual only, `/gstack-upgrade` (the channel is `stable`). Re-run the setup command above after upgrading.
- **Remove:** delete `.claude/skills/gstack*` and `.claude/skills/_gstack-command`, then `rm -rf /Users/santhosh/work/softwares/gstack ~/.gstack`; optionally `brew uninstall bun node@20 coreutils`.

## 8. Change log (newest first)

- 2026-11-15: PR #2 (S6 + P0) merged after CI pinned Flutter to 3.44.0; end-of-day handoff written (START HERE section).
- 2026-11-15: P0 fix pass from the project review: phone layout fix, real admin data, secure `ENVIRONMENT` default, rate limiting, Postgres verification (found and fixed a deadlock, a missing driver and a foreign-key bug), CI on Postgres.
- 2026-11-15: gstack installed for Revora only (see section 7).
- 2026-11-09: S6 complete and committed (S6a sell-side backend, S6b Flutter, S6c counter-offers + inspection final offer; migrations 0007, 0008).
- 2026-11-09: S5a/S5b/S5c built and committed; branch pushed; PR #1 found conflicting with `main`; commit author email rewritten to personal and force-pushed; git/commit policy agreed; this document created.
- Earlier: S0–S4 (see `git log`).
