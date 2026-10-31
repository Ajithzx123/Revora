import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy import func
from sqlmodel import Session, select

from backend.app.api.dealer_onboarding_api import dealer_response
from backend.app.core.dependencies import current_user_id, require_admin
from backend.app.database.session import get_session
from backend.app.models.audit_model import AuditEvent
from backend.app.models.user_model import User
from backend.app.models.marketplace_models import (
    Dealer,
    DealerDocument,
    DealerStatus,
    BuyRequirement,
    SellListing,
    DealerQuote,
    DealerOffer,
)
from backend.app.schemas.dealer_schema import (
    DealerResponse,
    DealerSummary,
    DocumentReview,
    DocumentResponse,
    ReasonBody,
)
from backend.app.services import storage
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
    transition(session, dealer, new_status, current_user_id(admin), reason)
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
    document.status = body.status
    document.review_note = (body.note or "").strip() or None
    session.add(document)
    session.add(
        AuditEvent(
            actor_user_id=current_user_id(admin),
            action=f"DOCUMENT_{body.status.value}",
            entity_type="dealer_document",
            entity_id=str(document.id),
            detail=document.doc_type.value,
        )
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
    session.add(
        AuditEvent(
            actor_user_id=current_user_id(admin),
            action="DOCUMENT_VIEWED",
            entity_type="dealer_document",
            entity_id=str(document.id),
            detail=document.doc_type.value,
        )
    )
    session.commit()
    return FileResponse(
        path,
        media_type=document.content_type,
        filename=document.original_name,
        headers={"Cache-Control": "no-store"},
    )
