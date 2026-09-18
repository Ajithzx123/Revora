import os
from typing import Optional


class Settings:
    PROJECT_NAME: str = "Revora API"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "dev")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "revora_secret_key_change_in_production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day for dev convenience
    
    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "sqlite:///revora.db"
    )
    
    # Supabase (Optional for direct DB vs REST)
    SUPABASE_URL: Optional[str] = os.getenv("SUPABASE_URL", None)
    SUPABASE_KEY: Optional[str] = os.getenv("SUPABASE_KEY", None)


settings = Settings()
