# Revora

Reverse car marketplace for India: customers post what they want to buy or sell, verified dealers compete with quotes and offers. See `CLAUDE.md`, `plans/` and `design/DESIGN.md`.

## Backend (FastAPI)
Run everything from the repo root (imports use the `backend.app...` prefix).

```bash
python3.12 -m venv backend/.venv
backend/.venv/bin/pip install -r backend/requirements.txt -r backend/requirements-dev.txt
backend/.venv/bin/uvicorn backend.main:app --reload
backend/.venv/bin/python -m pytest backend/tests -q
```

Environment variables

| Variable | Dev default | Required outside dev |
|---|---|---|
| `ENVIRONMENT` | `dev` | set to `staging` / `prod` |
| `SECRET_KEY` | built-in dev key | yes, random, 32+ chars (the app refuses to start otherwise) |
| `CORS_ORIGINS` | any `localhost` port | yes, comma-separated origins |
| `DATABASE_URL` | `sqlite:///revora.db` | yes (Postgres) |

New accounts are customers by default. A dealer signs up with `account_type=DEALER` and stays **unverified** until an admin calls `PATCH /api/admin/dealers/{id}/verify`. Admin users are created directly in the database; they cannot be created from the API.

## Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run -d chrome          # mock data on by default in debug builds
flutter test
flutter analyze
```
Release builds always use the real backend (`USE_MOCK_DATA` is ignored).
