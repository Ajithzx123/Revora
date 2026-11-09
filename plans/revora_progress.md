# Revora — Progress, Process and Open Items

The single place to see where the project stands, how we work, and what is left.
Update it at the end of every feature (slice) and whenever a decision changes. Last updated: 2026-11-09.

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
| Backend server | `backend/.venv/bin/uvicorn backend.main:app --reload` (run from repo root) |
| New migration | add `backend/migrations/versions/000N_*.py`; `test_migrations.py` fails if models and migrations drift |
| Flutter SDK | `/Users/santhosh/work/softwares/flutter/bin` is **not on PATH**: `export PATH=/Users/santhosh/work/softwares/flutter/bin:$PATH` |
| Flutter checks (in `frontend/`) | `flutter analyze`, `dart format lib test`, `flutter test` |
| Mock vs live data | Flutter uses mock repositories by default in debug/test (`USE_MOCK_DATA`); release builds never use mocks |

Current numbers: backend **296** tests passing; Flutter **180** tests passing, analyze and format clean.

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

- Working branch: `s0-security-foundation` (holds S0–S5c; the name is stale). 21 commits plus the merge commit ahead of the common base `3b4ff4d`, all authored with the personal email.
- Pushed to `origin/s0-security-foundation`. **PR #1** is open and **conflicts with `main`**.
- **Why it conflicts:** `main` has 3 UI commits (22–29 Sep 2026: "buy req ui" ×2, "popup button ui") that restructured the Flutter app (`ui/` → `pages/` + `layouts/`, new router `core/router/`, `api_client.dart`, `auth_provider.dart`, accent/theme system, new buy-a-car flow). This branch rewrote the same layers (auth, router, theme, most screens). About 100 files conflict. A merge attempt was aborted; nothing was changed.
- **Earlier proposal (superseded by the decision below):** merge `main` into the branch keeping this branch's core (auth, router, network, Showroom theme); keep their `pages/` + `layouts/` folder layout; bring over their buy-flow screens and appearance settings if they fit. Re-run all checks after.
- **Second merge attempt (2026-11-09), aborted:** git resolved most renames cleanly, but the real blocker is a **theme clash**. `main` builds on its own theme system (navy/indigo palette, switchable accent, light/dark runtime toggle, `context.revoraColors` via `revora_theme_colors.dart`, `theme_provider.dart`, `accent_provider.dart`). This branch uses the "Showroom" theme (warm canvas, ignition orange, `AppColors` tokens). Their buy-flow screens and several shared widgets (`spec_chip`, `status_chip`, `dealer_match_card`) depend on `revoraColors`, so they cannot be brought over without their theme. Tree was reset to `925ce18`; nothing merged.
- **Decision (2026-11-09): keep the latest.** `main`'s September UI commits are older than the Showroom redesign (31 Oct) and S1–S5c, so this branch wins. Merged with `git merge -s ours origin/main` (commit `3de908c`, local, not yet pushed): the tree is unchanged, `main` is now an ancestor, and PR #1 will no longer conflict once pushed. Their buy-flow, accent/theme system and `ui/`→`pages/` restructure were NOT applied; they stay reachable in `main`'s history if ever wanted.
- Local safety branch: `backup-before-author-rewrite` (old commits with the office email; local only; delete when no longer needed).
- Lesson: long-lived branches that never merge to `main` diverge. Merge `main` into the branch regularly, or merge each finished slice.

## 5. Open items and known gaps

**Decisions waiting on the user**
- Merge `main` into the branch (see section 4).
- Whether the `main` UI changes (buy flow, accent/theme) are wanted.

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

## 7. Change log (newest first)

- 2026-11-09: S6 complete and committed (S6a sell-side backend, S6b Flutter, S6c counter-offers + inspection final offer; migrations 0007, 0008).
- 2026-11-09: S5a/S5b/S5c built and committed; branch pushed; PR #1 found conflicting with `main`; commit author email rewritten to personal and force-pushed; git/commit policy agreed; this document created.
- Earlier: S0–S4 (see `git log`).
