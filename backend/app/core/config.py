import os
from typing import List, Optional

_DEV_SECRET = "revora_dev_only_secret_change_me"


class Settings:
    PROJECT_NAME: str = "Revora API"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "dev")
    SECRET_KEY: str = os.getenv("SECRET_KEY", _DEV_SECRET)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day for dev convenience

    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "sqlite:///revora.db"
    )

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

    # Supabase (Optional for direct DB vs REST)
    SUPABASE_URL: Optional[str] = os.getenv("SUPABASE_URL", None)
    SUPABASE_KEY: Optional[str] = os.getenv("SUPABASE_KEY", None)

    def validate(self) -> None:
        """Refuse to start outside dev with an unsafe configuration."""
        if self.ENVIRONMENT == "dev":
            return
        if self.SECRET_KEY == _DEV_SECRET or len(self.SECRET_KEY) < 32:
            raise RuntimeError(
                "SECRET_KEY must be set to a random value of at least 32 characters "
                "when ENVIRONMENT is not 'dev'."
            )
        if not self.CORS_ORIGINS:
            raise RuntimeError("CORS_ORIGINS must list the allowed origins when ENVIRONMENT is not 'dev'.")


settings = Settings()
settings.validate()
