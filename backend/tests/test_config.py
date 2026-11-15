"""Configuration is secure by default: a forgotten variable must stop the server, not loosen it."""
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBE = "from backend.app.core.config import settings; print(settings.ENVIRONMENT, settings.SQL_ECHO, settings.CORS_ORIGIN_REGEX)"


def run(**env):
    base = {k: v for k, v in os.environ.items() if k not in (
        "ENVIRONMENT", "SQL_ECHO", "SUPABASE_URL", "SUPABASE_JWT_SECRET", "CORS_ORIGINS", "DATABASE_URL")}
    return subprocess.run([sys.executable, "-c", PROBE], cwd=ROOT, env={**base, **env}, capture_output=True, text=True)


def test_an_unset_environment_means_production_and_refuses_to_start():
    r = run()
    assert r.returncode != 0 and "DATABASE_URL" in r.stderr  # SQLite is refused outside dev


def test_production_needs_identity_and_origins_too():
    r = run(DATABASE_URL="postgresql://u:p@localhost/db")
    assert r.returncode != 0 and "SUPABASE_URL" in r.stderr
    r = run(DATABASE_URL="postgresql://u:p@localhost/db", SUPABASE_URL="https://x.supabase.co")
    assert r.returncode != 0 and "CORS_ORIGINS" in r.stderr
    ok = run(DATABASE_URL="postgresql://u:p@localhost/db", SUPABASE_URL="https://x.supabase.co", CORS_ORIGINS="https://app.example.com")
    assert ok.returncode == 0 and ok.stdout.split()[0] == "prod"


def test_dev_is_explicit_and_sql_echo_is_opt_in():
    r = run(ENVIRONMENT="dev")
    assert r.returncode == 0 and r.stdout.split()[:2] == ["dev", "False"]   # no SQL logging by default, even in dev
    assert "localhost" in r.stdout                                          # dev allows localhost origins
    assert run(ENVIRONMENT="dev", SQL_ECHO="1").stdout.split()[1] == "True"


def test_production_never_allows_localhost_origins():
    r = run(DATABASE_URL="postgresql://u:p@localhost/db", SUPABASE_URL="https://x.supabase.co", CORS_ORIGINS="https://app.example.com")
    assert r.stdout.split()[2] == "None"
