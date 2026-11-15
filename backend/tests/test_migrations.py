"""The Alembic migrations must build exactly the schema the models describe."""
import os
import subprocess
import sys
from pathlib import Path

from sqlalchemy import create_engine, inspect
from sqlmodel import SQLModel

ROOT = Path(__file__).resolve().parents[2]


def _upgrade(db_path: Path):
    env = {**os.environ, "DATABASE_URL": f"sqlite:///{db_path}"}
    subprocess.run(
        [sys.executable, "-m", "alembic", "-c", str(ROOT / "backend" / "alembic.ini"), "upgrade", "head"],
        check=True, cwd=ROOT, env=env, capture_output=True,
    )


def test_migrations_match_models(tmp_path):
    db = tmp_path / "migrated.db"
    _upgrade(db)
    inspector = inspect(create_engine(f"sqlite:///{db}"))
    migrated = {t for t in inspector.get_table_names() if t != "alembic_version"}
    assert migrated == set(SQLModel.metadata.tables)
    for name, table in SQLModel.metadata.tables.items():
        assert {c["name"] for c in inspector.get_columns(name)} == {c.name for c in table.columns}, name


def test_no_pending_model_changes(tmp_path):
    """Fails when a model changed but no migration was written."""
    from alembic.autogenerate import compare_metadata
    from alembic.migration import MigrationContext

    db = tmp_path / "drift.db"
    _upgrade(db)
    with create_engine(f"sqlite:///{db}").connect() as conn:
        diff = compare_metadata(MigrationContext.configure(conn), SQLModel.metadata)
    assert diff == [], diff


def test_migrations_build_the_same_schema_on_postgres():
    """The production database is Postgres, so the migrations must work there too (not only on SQLite).
    Runs when TEST_DATABASE_URL points at a Postgres server; builds a throw-away database on it."""
    import uuid

    import pytest
    from sqlalchemy import text
    from sqlalchemy.engine import make_url

    url = os.environ.get("TEST_DATABASE_URL", "")
    if not url.startswith("postgresql"):
        pytest.skip("needs TEST_DATABASE_URL pointing at Postgres")
    base = make_url(url)
    name = f"revora_mig_{uuid.uuid4().hex[:8]}"
    admin = create_engine(base.set(database="postgres"), isolation_level="AUTOCOMMIT")
    with admin.connect() as c:
        c.execute(text(f'CREATE DATABASE "{name}"'))
    target = base.set(database=name)
    try:
        env = {**os.environ, "DATABASE_URL": target.render_as_string(hide_password=False)}
        subprocess.run(
            [sys.executable, "-m", "alembic", "-c", str(ROOT / "backend" / "alembic.ini"), "upgrade", "head"],
            check=True, cwd=ROOT, env=env, capture_output=True,
        )
        engine = create_engine(target)
        inspector = inspect(engine)
        migrated = {t for t in inspector.get_table_names() if t != "alembic_version"}
        assert migrated == set(SQLModel.metadata.tables)
        from alembic.autogenerate import compare_metadata
        from alembic.migration import MigrationContext

        with engine.connect() as conn:
            diff = compare_metadata(MigrationContext.configure(conn), SQLModel.metadata)
        assert diff == [], diff
        engine.dispose()
    finally:
        with admin.connect() as c:
            c.execute(text(f'DROP DATABASE IF EXISTS "{name}" WITH (FORCE)'))
        admin.dispose()
