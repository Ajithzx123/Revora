from sqlmodel import SQLModel, create_engine
from backend.app.core.config import settings

# Supports SQLite locally and PostgreSQL / Supabase in production via DATABASE_URL
connect_args = {"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.ENVIRONMENT == "dev",
    connect_args=connect_args
)