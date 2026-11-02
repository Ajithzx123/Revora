# Revora

Reverse car marketplace for India: customers post what they want to buy or sell, verified dealers compete with quotes and offers. See `CLAUDE.md`, `plans/` and `design/DESIGN.md`.

## Backend (FastAPI)
Run everything from the repo root (imports use the `backend.app...` prefix).

```bash
python3.12 -m venv backend/.venv
backend/.venv/bin/pip install -r backend/requirements.txt -r backend/requirements-dev.txt
backend/.venv/bin/alembic -c backend/alembic.ini upgrade head     # create/update the database
backend/.venv/bin/uvicorn backend.main:app --reload
backend/.venv/bin/python -m pytest backend/tests -q
```

After changing a model, write a migration (`alembic -c backend/alembic.ini revision --autogenerate -m "what changed"`); a test fails if models and migrations drift. In dev with SQLite the app also creates tables on startup; if you have an older `revora.db` from before S1, delete it (ids changed to UUID).

**Identity is Supabase Auth.** Sign-up, sign-in, OTP and password reset happen in Supabase; this API only verifies the access token and keeps a local profile (`POST /api/profile`, `GET/PATCH /api/me`). Roles live in our database, never in token metadata.

| Variable | Dev default | Required outside dev |
|---|---|---|
| `ENVIRONMENT` | `dev` | set to `staging` / `prod` |
| `SUPABASE_URL` | none | yes (also used to fetch signing keys) |
| `SUPABASE_JWT_SECRET` | none | only for projects still on the legacy HS256 secret |
| `CORS_ORIGINS` | any `localhost` port | yes, comma-separated origins |
| `DATABASE_URL` | `sqlite:///revora.db` | yes (Postgres) |
| `UPLOAD_DIR` | `backend/uploads` | yes (persistent, private disk) |

**Buy requests and inventory (S2).** Buyers post requests (`/api/requirements`) with the full set of preferences, then edit, pause, resume or close them; a request lives 14 days and a buyer may hold five open at once. Dealers manage stock at `/api/inventory`: each car has a unique registration number, up to 8 photos (JPEG/PNG/WebP, 5 MB) served publicly at `/api/media/<id>`, and a private minimum price that buyers never see. Pick-lists (makes, models, cities) come from `GET /api/master-data`. If you ran S1, run `alembic upgrade head` again: migration 0002 rebuilds the request, quote and inventory tables.

**Dealers** register with `account_type=DEALER` and start in `DRAFT`. They fill in details and upload three required documents (owner ID, business proof, address proof; PDF/JPEG/PNG up to 5 MB), then submit. An admin reviews each document and approves, requests changes, rejects, or later suspends. Only `APPROVED` dealers see leads, quote or make offers. Admin users are created directly in the database; they cannot be created from the API.

## Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run -d chrome          # mock data on by default in debug builds
flutter test
flutter analyze
```
Release builds always use the real backend (`USE_MOCK_DATA` is ignored).

### Running against the real backend and Supabase
```bash
# terminal 1 (repo root)
SUPABASE_URL=https://hjvzirkdnoaqahzusdbj.supabase.co backend/.venv/bin/uvicorn backend.main:app --reload
# terminal 2
cd frontend && flutter run -d chrome --dart-define=USE_MOCK_DATA=false
```
The project requires email confirmation: after signing up, open the link Supabase emails you, then sign in. A dealer lands on the application screen until an admin approves them. To make an admin, sign up normally, then in the database set that user's `role` to `ADMIN` in the `user` table.
