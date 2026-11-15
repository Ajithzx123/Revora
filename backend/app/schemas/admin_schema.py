import uuid
from datetime import datetime
from typing import Any, List, Optional

from pydantic import BaseModel, Field


class AuditEventResponse(BaseModel):
    id: uuid.UUID
    actor_user_id: Optional[uuid.UUID] = None
    actor_name: Optional[str] = None
    actor_role: Optional[str] = None
    action: str
    entity_type: str
    entity_id: str
    detail: Optional[str] = None
    reason: Optional[str] = None
    before: Optional[Any] = None
    after: Optional[Any] = None
    created_at: datetime


class AuditPage(BaseModel):
    items: List[AuditEventResponse]
    total: int
    limit: int
    offset: int


class AdminQuoteRow(BaseModel):
    id: uuid.UUID
    requirement_id: uuid.UUID
    request_title: str
    dealer_id: uuid.UUID
    dealer_name: str
    quoted_price: int
    status: str
    status_reason: Optional[str] = None
    kind: str
    revision: int
    valid_until: Optional[datetime] = None
    created_at: datetime


class AdminQuotePage(BaseModel):
    items: List[AdminQuoteRow]
    total: int
    limit: int
    offset: int


class VoidBody(BaseModel):
    reason: str = Field(min_length=5, max_length=500)


class AdminRequirementRow(BaseModel):
    id: uuid.UUID
    title: str
    city: str
    budget_min: int
    budget_max: int
    status: str
    customer_name: str
    quotes_count: int
    matches_count: int
    created_at: datetime
    expires_at: datetime


class AdminRequirementPage(BaseModel):
    items: List[AdminRequirementRow]
    total: int
    limit: int
    offset: int


class AdminVehicleRow(BaseModel):
    """A car in a dealer's stock as the admin sees it. The dealer's private minimum price is never included."""

    id: uuid.UUID
    title: str
    registration_no: str
    dealer_id: uuid.UUID
    dealer_name: str
    price: int
    km: int
    fuel: str
    city: str
    status: str
    created_at: datetime


class AdminVehiclePage(BaseModel):
    items: List[AdminVehicleRow]
    total: int
    limit: int
    offset: int


class UserStatusResponse(BaseModel):
    id: uuid.UUID
    role: str
    is_active: bool


class AdminOfferRow(BaseModel):
    id: uuid.UUID
    listing_id: uuid.UUID
    listing_title: str
    dealer_id: uuid.UUID
    dealer_name: str
    offered_price: int
    status: str
    status_reason: Optional[str] = None
    revision: int
    valid_until: Optional[datetime] = None
    created_at: datetime


class AdminOfferPage(BaseModel):
    items: List[AdminOfferRow]
    total: int
    limit: int
    offset: int
