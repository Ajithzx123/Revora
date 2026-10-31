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
