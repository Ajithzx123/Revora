import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import event
from sqlmodel import SQLModel, Field


class AuditEvent(SQLModel, table=True):
    """Append-only record of sensitive actions. Never update or delete rows."""

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    actor_user_id: Optional[uuid.UUID] = Field(default=None, index=True)
    actor_role: Optional[str] = None       # role at the time; None for system jobs
    action: str = Field(index=True)
    entity_type: str = Field(index=True)
    entity_id: str = Field(index=True)
    detail: Optional[str] = None
    reason: Optional[str] = None           # the reason the actor gave (required for admin interventions)
    before_json: Optional[str] = None      # JSON of the changed fields before
    after_json: Optional[str] = None       # ... and after
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)


@event.listens_for(AuditEvent, "before_update")
@event.listens_for(AuditEvent, "before_delete")
def _audit_rows_are_immutable(mapper, connection, target):
    raise RuntimeError("Audit events are append-only")
