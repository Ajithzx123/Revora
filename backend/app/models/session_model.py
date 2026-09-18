from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


class UserSession(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(index=True, foreign_key="user.id")
    refresh_token_hash: str = Field(index=True)
    device_id: Optional[str] = Field(default=None, index=True)
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    is_active: bool = Field(default=True, index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_used_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: datetime
    revoked_at: Optional[datetime] = None
