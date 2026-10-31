from datetime import date, datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from backend.app.models.marketplace_models import DocumentStatus, DocumentType


class DealerUpdate(BaseModel):
    business_name: Optional[str] = Field(default=None, min_length=1, max_length=200)
    gstin: Optional[str] = Field(default=None, max_length=20)
    address: Optional[str] = Field(default=None, max_length=500)
    city: Optional[str] = Field(default=None, min_length=1, max_length=100)


class DocumentResponse(BaseModel):
    id: UUID
    doc_type: DocumentType
    original_name: str
    content_type: str
    size_bytes: int
    status: DocumentStatus
    review_note: Optional[str]
    expires_on: Optional[date]
    uploaded_at: datetime


class DealerResponse(BaseModel):
    id: UUID
    business_name: str
    gstin: Optional[str]
    address: Optional[str]
    city: str
    status: str
    status_reason: Optional[str]
    submitted_at: Optional[datetime]
    reviewed_at: Optional[datetime]
    documents: List[DocumentResponse]
    missing_documents: List[str]
    can_submit: bool
    editable: bool


class DealerSummary(BaseModel):
    id: UUID
    business_name: str
    city: str
    status: str
    submitted_at: Optional[datetime]
    created_at: datetime


class ReasonBody(BaseModel):
    reason: str = Field(min_length=3, max_length=1000)


class DocumentReview(BaseModel):
    status: DocumentStatus
    note: Optional[str] = Field(default=None, max_length=1000)
