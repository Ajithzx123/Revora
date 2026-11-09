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


class UserStatusResponse(BaseModel):
    id: uuid.UUID
    role: str
    is_active: bool
