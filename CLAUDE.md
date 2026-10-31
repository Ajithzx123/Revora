# Revora — Project Rules for Claude

Revora is a **reverse car marketplace for India**: customers post what they want to buy or sell, verified dealers compete with quotes (buy) and purchase offers (sell). It is NOT a classified-listing site. Demand and competitive offers are the centre; inventory is supporting.

Read first: `plans/revora_plan_1_audit_and_features.md`, `plans/revora_plan_2_flows_and_rules.md`, `plans/revora_plan_3_screens_tech_roadmap.md`, `plans/revora_scenarios.md`, `design/DESIGN.md`.

## Stack (do not swap without approval)
- Backend: `backend/` FastAPI + SQLModel, Postgres (Supabase) target, SQLite local only. Run from the repo root (`uvicorn backend.main:app --reload`) because imports use the `backend.app...` prefix.
- Frontend: `frontend/` Flutter, Riverpod (`flutter_riverpod`), `go_router`, Dio, `supabase_flutter`, Outfit font via `google_fonts`.
- Storage/Realtime/Push: Supabase Storage + Realtime, Firebase Cloud Messaging.

## Working agreements
1. **Plan-first.** Work happens in the slices (S0…S12) in the roadmap. Do one slice at a time; do not start a later slice early. Do not implement anything the user has not approved.
2. **Evidence before claims.** Never say a feature exists/works without checking the code or running it.
3. **Small, testable changes.** Every slice ends with tests passing and a short summary of what changed and what is unverified.
4. **No secrets in the repo.** Keys come from env/`--dart-define`. Never commit `.env`, service-account files, or real keys.
5. **Ask before** destructive or outward-facing actions (deleting data, pushing, changing infra, sending messages).
6. **Match existing style.** Follow the surrounding code's naming, comment density and folder layout. Do not reformat unrelated code.

## Product rules (must hold in all code)
- Buying requests, selling listings, quotes, purchase offers, negotiation, bookings, transactions and payments are **separate entities with separate status fields**. Never one generic status.
- State changes go through one service function per transition with allowed-transition checks. Sensitive transitions write an `audit_event`.
- Accepting a quote/offer is **atomic** (row lock + status re-check). Two simultaneous accepts → one succeeds, one gets 409.
- Bidding is **sealed**: dealers never see competitors' prices.
- Matching never notifies every dealer: hard requirements filter, soft preferences score, cap 15 dealers/request, no repeat match.
- A dealer is **never auto-verified**. Verification is an admin action with an audit record.
- Admins cannot edit prices or messages. They can freeze/void with a reason.
- Unverified vehicle info must never look verified: label source (Owner declared / Dealer claim / Verified).
- Customer phone/contact is hidden from dealers until acceptance.
- Money is integer rupees in API and DB; format only in the UI (lakh/crore) via `price_formatter.dart`.
- IDs are UUID strings across DB, API and Flutter (pending decision D3 — confirm before schema work).
- Subscriptions never influence verification, matching rank or quote ranking.

## Backend rules
- Every endpoint: authenticated + **role check** (`require_role`) + **ownership check** on the object. "Logged in" is never enough.
- Pydantic schemas for all inputs/outputs; paginate every list; validate ranges (price > 0, year bounds, km plausible).
- Schema changes via **Alembic migrations only** (no reliance on `create_all` once S0 is done).
- Idempotency key on payment/accept endpoints. Expiry via scheduled job, and re-checked at action time.
- Rate-limit auth/OTP/quote/report endpoints. CORS restricted to known origins in non-dev.
- Tests: pytest + httpx; a permission-matrix test per router; state-transition tests; a concurrency test for accept.
- Never log tokens, passwords, OTPs, documents or full phone numbers.

## Frontend rules
- Architecture per module: `domain` (entities, repository interface) → `data` (api + mock repositories) → `presentation` (providers, ui). Screens never call Dio directly; they use providers → repositories.
- Keep mock repositories for tests/demos; real `Api*Repository` is the default. No role detection from email text, ever.
- Routes: one canonical path per screen; role guards in `go_router` `redirect`. No duplicate routes.
- Every async screen implements **loading (skeleton), empty, error (retry), success** states. Offline banner globally.
- Forms: validate inline, save drafts, numeric keyboards, disable submit while pending, prevent double-submit.
- Strings go through localisation (ARB) once S0 sets it up; no hard-coded user-facing text in new code.
- Use `const` widgets, `ListView.builder`, `CachedNetworkImage`; avoid rebuilding whole screens from providers (select narrow state).
- Run before finishing: `flutter analyze`, `dart format`, `flutter test`.

## Design rules (details in `design/DESIGN.md`)
- Use tokens from `lib/core/theme/` (`AppColors`, `AppSpacing`, `AppTextStyles`); never hard-code colors, font sizes or spacing in screens.
- Use shared widgets in `lib/shared/widgets/` first; add a new shared widget only when two screens need it.
- Tap targets ≥ 48dp, text contrast ≥ 4.5:1, no colour-only status, text scaling to 200% must not break layouts.
- Check every UI change with the **`revora-ui-check`** project skill (`.claude/skills/revora-ui-check`), at mobile (375×812), tablet (768) and desktop widths, light and dark.

## Skills to use
- UI work: `revora-ui-check` (project), `design:design-critique`, `design:accessibility-review`, `design:ux-copy`, `design:design-system`, `design:design-handoff`; plus installed Flutter skills (Dart and Flutter, Flutter Skills, frontend-design) when enabled.
- Installed project skills (vetted, see `.claude/skills/THIRD_PARTY.md`): `mobile-design-discovery`, `mobile-ux-patterns`, `mobile-visual-design`, `flutter-ui-craft`, `mobile-design-review`, `ui-ux-pro-max` (run `python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --stack flutter`), `dh-flutter-*` (ui, responsive layout, localization, routing, tests, security, dio, json), `implementing-riverpod`, `integrating-flutter-backend`, `securing-flutter-apps`, `testing-flutter`, `optimizing-flutter-performance`. Where they disagree with this file or `design/DESIGN.md`, this file wins.
- Backend/system: `engineering:system-design`, `engineering:testing-strategy`, `engineering:code-review`, `security-review`, `engineering:deploy-checklist`.
- Metrics/analytics: `data:*` skills.

## Definition of done (every slice)
Acceptance criteria met · tests added and green · analyze/format clean · UI checked at 3 widths in light/dark · empty/loading/error states present · permissions tested · audit events for sensitive actions · docs/plan updated · no secrets, no TODOs left without a ticket.

## Known issues to fix in S0 (do not copy these patterns)
Auto-verified dealer in `send_quote`; dealer endpoints without role checks; unprotected admin/leads routes; demo role-by-email login in `auth_repository.dart`; default `SECRET_KEY`; open CORS; duplicate routes.
