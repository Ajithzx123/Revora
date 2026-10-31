"""Dealer verification state machine. The only place dealer.status may change."""
import uuid
from datetime import datetime
from typing import Optional

from fastapi import HTTPException, status
from sqlmodel import Session, select

from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import (
    REQUIRED_DOCUMENTS,
    Dealer,
    DealerDocument,
    DealerStatus,
    DocumentStatus,
)

S = DealerStatus

ALLOWED_TRANSITIONS = {
    S.DRAFT: {S.PENDING},
    S.NEEDS_CHANGES: {S.PENDING},
    S.PENDING: {S.APPROVED, S.NEEDS_CHANGES, S.REJECTED},
    S.APPROVED: {S.SUSPENDED},
    S.SUSPENDED: {S.APPROVED},  # reactivation
    S.REJECTED: set(),          # terminal; a new application needs admin help
}

REASON_REQUIRED = {S.NEEDS_CHANGES, S.REJECTED, S.SUSPENDED}

# Statuses in which the dealer may edit details and documents.
DEALER_EDITABLE = {S.DRAFT, S.NEEDS_CHANGES}


def current_documents(session: Session, dealer_id: uuid.UUID) -> list[DealerDocument]:
    return list(
        session.exec(
            select(DealerDocument).where(
                DealerDocument.dealer_id == dealer_id, DealerDocument.is_current == True  # noqa: E712
            )
        ).all()
    )


def missing_documents(documents: list[DealerDocument]) -> list[str]:
    present = {d.doc_type for d in documents}
    return [t.value for t in REQUIRED_DOCUMENTS if t not in present]


def transition(
    session: Session,
    dealer: Dealer,
    new_status: DealerStatus,
    actor_id: uuid.UUID,
    reason: Optional[str] = None,
) -> None:
    """Move a dealer to `new_status`, enforcing the rules, and record an audit event.

    Does not commit; the caller commits so the change and its audit row land together.
    """
    old = dealer.status
    if new_status not in ALLOWED_TRANSITIONS[old]:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A dealer in {old.value} cannot move to {new_status.value}",
        )
    reason = (reason or "").strip() or None
    if new_status in REASON_REQUIRED and not reason:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"A reason is required for {new_status.value}",
        )

    docs = current_documents(session, dealer.id)
    if new_status == S.PENDING:
        missing = missing_documents(docs)
        if missing:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Missing required documents: {', '.join(missing)}",
            )
        if not (dealer.business_name and dealer.city and dealer.address):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Business name, city and address are required",
            )
    if new_status == S.APPROVED and old == S.PENDING:
        unaccepted = [
            d.doc_type.value
            for d in docs
            if d.doc_type in REQUIRED_DOCUMENTS and d.status != DocumentStatus.ACCEPTED
        ]
        if unaccepted:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Accept these documents first: {', '.join(unaccepted)}",
            )

    now = datetime.utcnow()
    dealer.status = new_status
    if new_status == S.PENDING:
        dealer.submitted_at = now
        dealer.status_reason = None
    else:
        dealer.reviewed_at = now
        dealer.reviewed_by = actor_id
        dealer.status_reason = reason if new_status in REASON_REQUIRED else None
    session.add(dealer)
    session.add(
        AuditEvent(
            actor_user_id=actor_id,
            action=f"DEALER_{new_status.value}",
            entity_type="dealer",
            entity_id=str(dealer.id),
            detail=f"{old.value} -> {new_status.value}" + (f": {reason}" if reason else ""),
        )
    )
