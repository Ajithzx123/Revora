import uuid
from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field


class AuditEvent(SQLModel, table=True):
    """Append-only record of sensitive actions. Never update or delete rows."""

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    actor_user_id: Optional[uuid.UUID] = Field(default=None, index=True)
    action: str = Field(index=True)
    entity_type: str
    entity_id: str
    detail: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
