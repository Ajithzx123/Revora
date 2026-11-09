"""Buy-request state machine. The only place requirement.status may change."""
import uuid
from datetime import datetime
from typing import Optional

from fastapi import HTTPException, status
from sqlmodel import Session, select

from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import BuyRequirement, DealerQuote, RequirementStatus

R = RequirementStatus

ALLOWED_TRANSITIONS = {
    R.OPEN: {R.PAUSED, R.CANCELLED, R.EXPIRED, R.QUOTE_ACCEPTED},
    R.PAUSED: {R.OPEN, R.CANCELLED, R.EXPIRED},
    R.QUOTE_ACCEPTED: {R.IN_TRANSACTION, R.CANCELLED},
    R.IN_TRANSACTION: {R.COMPLETED, R.CANCELLED},
    R.COMPLETED: set(),
    R.EXPIRED: set(),
    R.CANCELLED: set(),
}

EDITABLE = {R.OPEN, R.PAUSED}
ACTIVE = {R.OPEN, R.PAUSED}

MAX_ACTIVE_REQUESTS = 5
LIFETIME_DAYS = 14

# Quote statuses that are still "live" and get closed with the request.
LIVE_QUOTE_STATUSES = {"PENDING", "REQUOTE_REQUESTED"}


def transition(
    session: Session,
    requirement: BuyRequirement,
    new_status: RequirementStatus,
    actor_id: Optional[uuid.UUID],
    reason: Optional[str] = None,
) -> None:
    """Move a request to `new_status` and record it. Does not commit."""
    old = requirement.status
    if new_status not in ALLOWED_TRANSITIONS[old]:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"A request that is {old.value.lower().replace('_', ' ')} cannot become "
            f"{new_status.value.lower().replace('_', ' ')}",
        )
    requirement.status = new_status
    requirement.updated_at = datetime.utcnow()
    session.add(requirement)

    if new_status in {R.CANCELLED, R.EXPIRED}:
        # Dealers' open quotes close with the request; nobody is left waiting on a dead request.
        for quote in session.exec(
            select(DealerQuote).where(DealerQuote.requirement_id == requirement.id)
        ).all():
            if quote.status in LIVE_QUOTE_STATUSES:
                quote.status = "CLOSED_BY_CUSTOMER" if new_status == R.CANCELLED else "EXPIRED"
                session.add(quote)

    session.add(
        AuditEvent(
            actor_user_id=actor_id,
            action=f"REQUIREMENT_{new_status.value}",
            entity_type="buy_requirement",
            entity_id=str(requirement.id),
            detail=f"{old.value} -> {new_status.value}" + (f": {reason}" if reason else ""),
        )
    )


def expire_if_due(session: Session, requirement: BuyRequirement) -> bool:
    """Lazily expire a request whose time ran out. Returns True if it changed."""
    if requirement.status in ACTIVE and requirement.expires_at <= datetime.utcnow():
        transition(session, requirement, R.EXPIRED, None, "request lifetime ended")
        return True
    return False
