import json
import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import FileResponse
from sqlalchemy import func
from sqlmodel import Session, col, select

from backend.app.api.dealer_onboarding_api import dealer_response
from backend.app.core.dependencies import current_user_id, require_admin
from backend.app.database.session import get_session
from backend.app.models.audit_model import AuditEvent
from backend.app.core.dependencies import ADMIN_ROLES
from backend.app.models.user_model import User, UserRole
from backend.app.models.marketplace_models import (
    Dealer,
    DealerDocument,
    DealerStatus,
    BuyRequirement,
    SellListing,
    DealerQuote,
    DealerOffer,
)
from backend.app.schemas.admin_schema import (
    AdminQuotePage,
    AdminQuoteRow,
    AuditEventResponse,
    AuditPage,
    UserStatusResponse,
    VoidBody,
)
from backend.app.schemas.dealer_schema import (
    DealerResponse,
    DealerSummary,
    DocumentReview,
    DocumentResponse,
    ReasonBody,
)
from backend.app.services import audit_service, matching_service, quote_service, storage
from backend.app.services.dealer_workflow import transition

router = APIRouter(prefix="/admin", tags=["Admin"])


def _count(session: Session, model) -> int:
    return session.exec(select(func.count()).select_from(model)).one()


def _get_dealer(session: Session, dealer_id: uuid.UUID) -> Dealer:
    dealer = session.get(Dealer, dealer_id)
    if not dealer:
        raise HTTPException(status_code=404, detail="Dealer not found")
    return dealer


@router.get("/metrics")
def get_admin_metrics(
    _admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    approved = session.exec(
        select(func.count()).select_from(Dealer).where(Dealer.status == DealerStatus.APPROVED)
    ).one()
    pending = session.exec(
        select(func.count()).select_from(Dealer).where(Dealer.status == DealerStatus.PENDING)
    ).one()
    return {
        "total_users": _count(session, User),
        "active_dealers": approved,
        "pending_dealer_applications": pending,
        "buy_requirements": _count(session, BuyRequirement),
        "sell_listings": _count(session, SellListing),
        "quotes_exchanged": _count(session, DealerQuote),
        "purchase_offers": _count(session, DealerOffer),
        "platform_status": "OPERATIONAL",
    }


@router.get("/dealers", response_model=List[DealerSummary])
def list_dealers(
    status: Optional[DealerStatus] = None,
    _admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    query = select(Dealer).order_by(Dealer.created_at.desc())
    if status is not None:
        query = query.where(Dealer.status == status)
    return [
        DealerSummary(
            id=d.id,
            business_name=d.business_name,
            city=d.city,
            status=d.status.value,
            submitted_at=d.submitted_at,
            created_at=d.created_at,
        )
        for d in session.exec(query).all()
    ]


@router.get("/dealers/{dealer_id}", response_model=DealerResponse)
def get_dealer(
    dealer_id: uuid.UUID,
    _admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    return dealer_response(session, _get_dealer(session, dealer_id))


def _decide(
    dealer_id: uuid.UUID,
    new_status: DealerStatus,
    reason: Optional[str],
    admin: dict,
    session: Session,
) -> DealerResponse:
    dealer = _get_dealer(session, dealer_id)
    was = dealer.status
    transition(session, dealer, new_status, current_user_id(admin), reason)
    session.flush()
    if new_status == DealerStatus.SUSPENDED:
        quote_service.void_live_quotes_of_dealer(session, dealer, current_user_id(admin))
    elif new_status == DealerStatus.APPROVED and was == DealerStatus.SUSPENDED:
        quote_service.restore_after_reactivation(session, dealer, current_user_id(admin))
    if new_status == DealerStatus.APPROVED:
        matching_service.rematch_open_requests(session)  # a newly approved dealer may suit waiting buyers
    session.commit()
    session.refresh(dealer)
    return dealer_response(session, dealer)


@router.post("/dealers/{dealer_id}/approve", response_model=DealerResponse)
def approve_dealer(
    dealer_id: uuid.UUID,
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    return _decide(dealer_id, DealerStatus.APPROVED, None, admin, session)


@router.post("/dealers/{dealer_id}/request-changes", response_model=DealerResponse)
def request_changes(
    dealer_id: uuid.UUID,
    body: ReasonBody,
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    return _decide(dealer_id, DealerStatus.NEEDS_CHANGES, body.reason, admin, session)


@router.post("/dealers/{dealer_id}/reject", response_model=DealerResponse)
def reject_dealer(
    dealer_id: uuid.UUID,
    body: ReasonBody,
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    return _decide(dealer_id, DealerStatus.REJECTED, body.reason, admin, session)


@router.post("/dealers/{dealer_id}/suspend", response_model=DealerResponse)
def suspend_dealer(
    dealer_id: uuid.UUID,
    body: ReasonBody,
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    return _decide(dealer_id, DealerStatus.SUSPENDED, body.reason, admin, session)


@router.post("/dealers/{dealer_id}/reactivate", response_model=DealerResponse)
def reactivate_dealer(
    dealer_id: uuid.UUID,
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    dealer = _get_dealer(session, dealer_id)
    if dealer.status != DealerStatus.SUSPENDED:
        raise HTTPException(status_code=409, detail="Only suspended dealers can be reactivated")
    return _decide(dealer_id, DealerStatus.APPROVED, None, admin, session)


def _get_document(session: Session, dealer_id: uuid.UUID, document_id: uuid.UUID) -> DealerDocument:
    document = session.get(DealerDocument, document_id)
    if document is None or document.dealer_id != dealer_id:
        raise HTTPException(status_code=404, detail="Document not found")
    return document


@router.post("/dealers/{dealer_id}/documents/{document_id}/review", response_model=DocumentResponse)
def review_document(
    dealer_id: uuid.UUID,
    document_id: uuid.UUID,
    body: DocumentReview,
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    from backend.app.api.dealer_onboarding_api import document_response
    from backend.app.models.marketplace_models import DocumentStatus

    dealer = _get_dealer(session, dealer_id)
    document = _get_document(session, dealer.id, document_id)
    if body.status == DocumentStatus.PENDING:
        raise HTTPException(status_code=422, detail="Choose ACCEPTED or REJECTED")
    if body.status == DocumentStatus.REJECTED and not (body.note or "").strip():
        raise HTTPException(status_code=422, detail="A note is required when rejecting a document")
    before_status = document.status.value
    document.status = body.status
    document.review_note = (body.note or "").strip() or None
    session.add(document)
    audit_service.record(
        session, current_user_id(admin), f"DOCUMENT_{body.status.value}", "dealer_document", document.id,
        detail=document.doc_type.value, reason=document.review_note,
        before={"status": before_status}, after={"status": body.status.value},
    )
    session.commit()
    session.refresh(document)
    return document_response(document)


@router.get("/dealers/{dealer_id}/documents/{document_id}/file")
def download_document(
    dealer_id: uuid.UUID,
    document_id: uuid.UUID,
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    document = _get_document(session, _get_dealer(session, dealer_id).id, document_id)
    path = storage.path_for(document.storage_key)
    if not path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    # Viewing KYC documents is itself an audited action.
    audit_service.record(
        session, current_user_id(admin), "DOCUMENT_VIEWED", "dealer_document", document.id, detail=document.doc_type.value
    )
    session.commit()
    return FileResponse(
        path,
        media_type=document.content_type,
        filename=document.original_name,
        headers={"Cache-Control": "no-store"},
    )


@router.get("/requirements/{requirement_id}/matches")
def requirement_matches(
    requirement_id: uuid.UUID,
    _admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    """Which dealers were shown a request, and why. For support and fairness checks."""
    from backend.app.models.marketplace_models import MatchRecord

    rows = session.exec(
        select(MatchRecord).where(MatchRecord.requirement_id == requirement_id).order_by(MatchRecord.tier, MatchRecord.score.desc())
    ).all()
    out = []
    for m in rows:
        dealer = session.get(Dealer, m.dealer_id)
        out.append(
            {
                "dealer_id": m.dealer_id,
                "dealer": dealer.business_name if dealer else None,
                "tier": m.tier,
                "score": m.score,
                "reasons": m.reasons,
                "dismissed": m.dismissed_at is not None,
                "matched_at": m.created_at,
            }
        )
    return out


@router.get("/liquidity")
def marketplace_liquidity(
    _admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    """Open and unmatched requests against approved dealers, per city: where to recruit next."""
    return matching_service.liquidity(session)


@router.post("/matching/run")
def run_matching_now(
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    """Re-run matching for every open request (also done on a schedule)."""
    created = matching_service.rematch_open_requests(session)
    audit_service.record(session, current_user_id(admin), "MATCHING_RUN", "platform", "matching", detail=f"{created} matches created")
    session.commit()
    return {"matches_created": created}


# ---------------------------------------------------------------- audit log
def _parse(blob: Optional[str]):
    try:
        return json.loads(blob) if blob else None
    except ValueError:
        return None


@router.get("/audit", response_model=AuditPage)
def audit_log(
    action: Optional[str] = Query(None, max_length=80),
    entity_type: Optional[str] = Query(None, max_length=60),
    entity_id: Optional[str] = Query(None, max_length=80),
    actor_id: Optional[uuid.UUID] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    _admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    """Read-only, newest first. There is no endpoint that edits or deletes an audit event."""
    query = select(AuditEvent)
    if action:
        query = query.where(AuditEvent.action == action)
    if entity_type:
        query = query.where(AuditEvent.entity_type == entity_type)
    if entity_id:
        query = query.where(AuditEvent.entity_id == entity_id)
    if actor_id:
        query = query.where(AuditEvent.actor_user_id == actor_id)
    total = session.exec(select(func.count()).select_from(query.subquery())).one()
    rows = session.exec(query.order_by(col(AuditEvent.created_at).desc()).offset(offset).limit(limit)).all()
    names = {u.id: u.name for u in session.exec(select(User).where(col(User.id).in_({r.actor_user_id for r in rows if r.actor_user_id}))).all()}
    items = [
        AuditEventResponse(
            id=r.id, actor_user_id=r.actor_user_id, actor_name=names.get(r.actor_user_id), actor_role=r.actor_role,
            action=r.action, entity_type=r.entity_type, entity_id=r.entity_id, detail=r.detail, reason=r.reason,
            before=_parse(r.before_json), after=_parse(r.after_json), created_at=r.created_at,
        )
        for r in rows
    ]
    return AuditPage(items=items, total=total, limit=limit, offset=offset)


# ---------------------------------------------------------------- quote monitoring
@router.get("/quotes", response_model=AdminQuotePage)
def monitor_quotes(
    status: Optional[str] = Query(None, max_length=30),
    requirement_id: Optional[uuid.UUID] = None,
    dealer_id: Optional[uuid.UUID] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    _admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    query = select(DealerQuote)
    if status:
        query = query.where(DealerQuote.status == status)
    if requirement_id:
        query = query.where(DealerQuote.requirement_id == requirement_id)
    if dealer_id:
        query = query.where(DealerQuote.dealer_id == dealer_id)
    total = session.exec(select(func.count()).select_from(query.subquery())).one()
    quotes = session.exec(query.order_by(col(DealerQuote.created_at).desc()).offset(offset).limit(limit)).all()
    return AdminQuotePage(items=[_quote_row(session, q) for q in quotes], total=total, limit=limit, offset=offset)


@router.post("/quotes/{quote_id}/void", response_model=AdminQuoteRow)
def void_quote(
    quote_id: uuid.UUID,
    body: VoidBody,
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    """Close a live quote with a reason. The price and message are never touched."""
    quote = session.get(DealerQuote, quote_id)
    if quote is None:
        raise HTTPException(404, "Quote not found")
    quote_service.void_by_admin(session, quote, current_user_id(admin), body.reason.strip())
    session.commit()
    return _quote_row(session, quote)


def _quote_row(session: Session, q: DealerQuote) -> AdminQuoteRow:
    req = session.get(BuyRequirement, q.requirement_id)
    dealer = session.get(Dealer, q.dealer_id)
    return AdminQuoteRow(
        id=q.id, requirement_id=q.requirement_id,
        request_title=(f"{req.make} {req.model}" if req and req.model else (req.make if req else "")),
        dealer_id=q.dealer_id, dealer_name=dealer.business_name if dealer else "Dealer",
        quoted_price=q.quoted_price, status=q.status, status_reason=q.status_reason, kind=q.kind,
        revision=q.revision, valid_until=q.valid_until, created_at=q.created_at,
    )


# ---------------------------------------------------------------- customer accounts
def _set_user_active(user_id: uuid.UUID, active: bool, reason: Optional[str], admin: dict, session: Session) -> UserStatusResponse:
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(404, "User not found")
    if user.id == current_user_id(admin) or user.role.value in ADMIN_ROLES:
        raise HTTPException(409, "Admin accounts cannot be suspended here")
    if user.role == UserRole.DEALER:
        raise HTTPException(409, "Dealers are suspended from the dealer review screen")
    if user.is_active == active:
        raise HTTPException(409, "The account is already " + ("active" if active else "suspended"))
    user.is_active = active
    session.add(user)
    audit_service.record(
        session, current_user_id(admin), "USER_REACTIVATED" if active else "USER_SUSPENDED", "user", user.id,
        reason=reason, before={"is_active": not active}, after={"is_active": active},
    )
    session.commit()
    return UserStatusResponse(id=user.id, role=user.role.value, is_active=user.is_active)


@router.post("/users/{user_id}/suspend", response_model=UserStatusResponse)
def suspend_user(user_id: uuid.UUID, body: VoidBody, admin: dict = Depends(require_admin), session: Session = Depends(get_session)):
    return _set_user_active(user_id, False, body.reason.strip(), admin, session)


@router.post("/users/{user_id}/reactivate", response_model=UserStatusResponse)
def reactivate_user(user_id: uuid.UUID, admin: dict = Depends(require_admin), session: Session = Depends(get_session)):
    return _set_user_active(user_id, True, None, admin, session)
