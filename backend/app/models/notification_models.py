import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import UniqueConstraint
from sqlmodel import Field, SQLModel


def _id() -> uuid.UUID:
    return uuid.uuid4()


class NotificationEvent(SQLModel, table=True):
    """One notification for one recipient. This row is also the in-app feed entry.

    `dedupe_key` is unique, so a retried request or a repeated job can never notify twice.
    """

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    recipient_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    type: str = Field(index=True)
    category: str                      # LEADS, QUOTES, DEALS, ACCOUNT, MARKETING
    title: str
    body: str
    entity_type: Optional[str] = None
    entity_id: Optional[str] = None
    critical: bool = Field(default=False)   # critical events ignore preferences and quiet hours
    dedupe_key: str = Field(unique=True, index=True)
    read_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)


class NotificationDelivery(SQLModel, table=True):
    """Per-channel delivery log. The in-app record is always created; push is best effort."""

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    event_id: uuid.UUID = Field(foreign_key="notificationevent.id", index=True)
    channel: str                        # IN_APP, PUSH
    status: str = Field(default="PENDING", index=True)  # PENDING, SENT, FAILED, SKIPPED
    attempts: int = Field(default=0)
    deliver_after: datetime = Field(default_factory=datetime.utcnow)
    last_error: Optional[str] = None
    sent_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class DeviceToken(SQLModel, table=True):
    """A push token registered by a signed-in device. A token belongs to one user at a time."""

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    token: str = Field(unique=True, index=True)
    platform: str = Field(default="unknown")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_seen_at: datetime = Field(default_factory=datetime.utcnow)


class NotificationPreference(SQLModel, table=True):
    """Push on/off per category. In-app records are always kept; critical events ignore this."""

    __table_args__ = (UniqueConstraint("user_id", "category", name="uq_notification_pref"),)

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    category: str
    push_enabled: bool = Field(default=True)
