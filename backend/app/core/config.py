import os
from pathlib import Path
from typing import List, Optional

_BACKEND_DIR = Path(__file__).resolve().parents[2]


class Settings:
    PROJECT_NAME: str = "Revora API"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "dev")

    # Database (Postgres in staging/prod; SQLite is for local dev and tests)
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///revora.db")

    # Identity: Supabase Auth issues the tokens, this API only verifies them.
    SUPABASE_URL: Optional[str] = os.getenv("SUPABASE_URL") or None
    # Legacy HS256 projects. Projects on asymmetric signing keys leave this unset
    # and the public keys are fetched from SUPABASE_URL (JWKS).
    SUPABASE_JWT_SECRET: Optional[str] = os.getenv("SUPABASE_JWT_SECRET") or None
    SUPABASE_KEY: Optional[str] = os.getenv("SUPABASE_KEY") or None

    # Comma-separated allowed browser origins. Dev also allows any localhost port
    # (Flutter web picks a random one).
    CORS_ORIGINS: List[str] = [
        o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()
    ]
    CORS_ORIGIN_REGEX: Optional[str] = (
        r"http://(localhost|127\.0\.0\.1)(:\d+)?"
        if os.getenv("ENVIRONMENT", "dev") == "dev"
        else None
    )

    # Private uploads (dealer KYC documents). Replace with object storage later.
    UPLOAD_DIR: Path = Path(os.getenv("UPLOAD_DIR", str(_BACKEND_DIR / "uploads")))
    MAX_UPLOAD_BYTES: int = 5 * 1024 * 1024

    def validate(self) -> None:
        """Refuse to start outside dev with an unsafe configuration."""
        if self.ENVIRONMENT == "dev":
            return
        if not (self.SUPABASE_URL or self.SUPABASE_JWT_SECRET):
            raise RuntimeError(
                "Set SUPABASE_URL (and optionally SUPABASE_JWT_SECRET) when ENVIRONMENT is not 'dev'."
            )
        if not self.CORS_ORIGINS:
            raise RuntimeError("CORS_ORIGINS must list the allowed origins when ENVIRONMENT is not 'dev'.")


settings = Settings()
settings.validate()
