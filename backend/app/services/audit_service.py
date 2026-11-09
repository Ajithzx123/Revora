"""The one way to write an audit event. Does not commit: the audit row lands in the same
transaction as the change it records."""
import json
import uuid
from typing import Any, Optional

from sqlmodel import Session

from backend.app.models.audit_model import AuditEvent
from backend.app.models.user_model import User


def record(
    session: Session,
    actor_id: Optional[uuid.UUID],
    action: str,
    entity_type: str,
    entity_id: Any,
    *,
    detail: Optional[str] = None,
    reason: Optional[str] = None,
    before: Optional[dict] = None,
    after: Optional[dict] = None,
) -> AuditEvent:
    actor = session.get(User, actor_id) if actor_id else None
    event = AuditEvent(
        actor_user_id=actor_id,
        actor_role=actor.role.value if actor else None,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id),
        detail=detail,
        reason=reason,
        before_json=json.dumps(before, default=str) if before is not None else None,
        after_json=json.dumps(after, default=str) if after is not None else None,
    )
    session.add(event)
    return event
