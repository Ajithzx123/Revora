"""The dealer's own application: details, documents, submit."""
import uuid
from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlmodel import Session

from backend.app.core.dependencies import current_user_id, get_dealer_profile, require_dealer
from backend.app.database.session import get_session
from backend.app.models.marketplace_models import (
    Dealer,
    DealerDocument,
    DocumentStatus,
    DocumentType,
)
from backend.app.core import master_data as md
from backend.app.schemas.dealer_schema import DealerResponse, DealerUpdate, DocumentResponse, SourcingUpdate
from backend.app.services import storage
from backend.app.services.dealer_workflow import (
    DEALER_EDITABLE,
    current_documents,
    missing_documents,
    transition,
)
from backend.app.models.marketplace_models import DealerStatus

router = APIRouter(prefix="/dealers", tags=["Dealer onboarding"])


def document_response(d: DealerDocument) -> DocumentResponse:
    return DocumentResponse(
        id=d.id,
        doc_type=d.doc_type,
        original_name=d.original_name,
        content_type=d.content_type,
        size_bytes=d.size_bytes,
        status=d.status,
        review_note=d.review_note,
        expires_on=d.expires_on,
        uploaded_at=d.uploaded_at,
    )


def dealer_response(session: Session, dealer: Dealer) -> DealerResponse:
    docs = current_documents(session, dealer.id)
    missing = missing_documents(docs)
    editable = dealer.status in DEALER_EDITABLE
    complete = bool(dealer.business_name and dealer.city and dealer.address)
    return DealerResponse(
        id=dealer.id,
        business_name=dealer.business_name,
        gstin=dealer.gstin,
        address=dealer.address,
        city=dealer.city,
        status=dealer.status.value,
        status_reason=dealer.status_reason,
        submitted_at=dealer.submitted_at,
        reviewed_at=dealer.reviewed_at,
        documents=[document_response(d) for d in docs],
        missing_documents=missing,
        can_submit=editable and not missing and complete,
        editable=editable,
        sourcing_makes=dealer.sourcing_makes,
    )


def _require_editable(dealer: Dealer) -> None:
    if dealer.status not in DEALER_EDITABLE:
        raise HTTPException(
            status_code=409,
            detail=f"Your application is {dealer.status.value} and cannot be edited now",
        )


@router.get("/me", response_model=DealerResponse)
def get_my_dealer(
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    return dealer_response(session, dealer)


@router.patch("/me", response_model=DealerResponse)
def update_my_dealer(
    body: DealerUpdate,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    _require_editable(dealer)
    for field, value in body.model_dump(exclude_unset=True).items():
        if value is not None:
            setattr(dealer, field, value.strip())
    session.add(dealer)
    session.commit()
    session.refresh(dealer)
    return dealer_response(session, dealer)


@router.post("/me/documents", response_model=DocumentResponse, status_code=201)
async def upload_document(
    doc_type: DocumentType = Form(...),
    file: UploadFile = File(...),
    expires_on: Optional[date] = Form(default=None),
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    _require_editable(dealer)
    storage_key, content_type, size = await storage.save_document(file)
    # A newer upload of the same type supersedes the old one (history is kept).
    for old in current_documents(session, dealer.id):
        if old.doc_type == doc_type:
            old.is_current = False
            session.add(old)
    document = DealerDocument(
        dealer_id=dealer.id,
        doc_type=doc_type,
        storage_key=storage_key,
        original_name=(file.filename or "document")[:200],
        content_type=content_type,
        size_bytes=size,
        expires_on=expires_on,
        status=DocumentStatus.PENDING,
    )
    session.add(document)
    session.commit()
    session.refresh(document)
    return document_response(document)


@router.delete("/me/documents/{document_id}", status_code=204)
def delete_document(
    document_id: uuid.UUID,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    _require_editable(dealer)
    document = session.get(DealerDocument, document_id)
    if document is None or document.dealer_id != dealer.id or not document.is_current:
        raise HTTPException(status_code=404, detail="Document not found")
    document.is_current = False
    session.add(document)
    session.commit()


@router.post("/me/submit", response_model=DealerResponse)
def submit_application(
    user_data: dict = Depends(require_dealer),
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    transition(session, dealer, DealerStatus.PENDING, current_user_id(user_data))
    session.commit()
    session.refresh(dealer)
    return dealer_response(session, dealer)


@router.put("/me/sourcing", response_model=DealerResponse)
def set_sourcing_makes(
    body: SourcingUpdate,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    """Makes this dealer will source on request without having the car in stock.
    Allowed in any status; it takes effect once the dealer is approved."""
    unknown = sorted({m for m in body.makes if m not in md.MAKES_AND_MODELS})
    if unknown:
        raise HTTPException(status_code=422, detail=f"Unknown make: {', '.join(unknown)}")
    dealer.sourcing_makes_csv = ",".join(sorted(set(body.makes)))
    session.add(dealer)
    if dealer.status == DealerStatus.APPROVED:
        from backend.app.services import matching_service

        matching_service.rematch_open_requests(session)
    session.commit()
    session.refresh(dealer)
    return dealer_response(session, dealer)
