from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field


class AuditEvent(SQLModel, table=True):
    """Append-only record of sensitive actions. Never update or delete rows."""

    id: Optional[int] = Field(default=None, primary_key=True)
    actor_user_id: Optional[int] = Field(default=None, index=True)
    action: str = Field(index=True)
    entity_type: str
    entity_id: int
    detail: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
