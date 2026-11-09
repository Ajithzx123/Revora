import uuid
from datetime import datetime
from typing import Dict, List, Optional

from pydantic import BaseModel, Field


class NotificationResponse(BaseModel):
    id: uuid.UUID
    type: str
    category: str
    title: str
    body: str
    entity_type: Optional[str] = None
    entity_id: Optional[str] = None
    critical: bool
    read: bool
    created_at: datetime


class NotificationPage(BaseModel):
    items: List[NotificationResponse]
    total: int
    unread_count: int
    limit: int
    offset: int


class MarkReadBody(BaseModel):
    ids: Optional[List[uuid.UUID]] = Field(default=None, max_length=200, description="Omit to mark everything read")


class MarkReadResult(BaseModel):
    marked: int
    unread_count: int


class PreferencesBody(BaseModel):
    preferences: Dict[str, bool]


class DeviceBody(BaseModel):
    token: str = Field(min_length=10, max_length=4096)
    platform: str = Field(default="unknown", pattern="^(android|ios|web|unknown)$")
