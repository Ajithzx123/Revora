"""Notifications: domain event -> NotificationEvent row (the in-app feed) -> push delivery.

Rules (plans/revora_plan_2, Deliverable 8):
- the in-app record is always kept; push is best effort with 3 attempts and backoff
- dedupe key = (type, entity, recipient, window), enforced by a unique column
- preferences switch push off per category; critical events ignore preferences and quiet hours
- non-critical push waits out quiet hours (22:00-08:00 IST)
- notify() never commits: the notification lands in the same transaction as the change it reports
"""
import logging
import uuid
from datetime import datetime, timedelta
from typing import Optional

from sqlalchemy.exc import IntegrityError
from sqlmodel import Session, col, func, select

from backend.app.models.notification_models import (
    DeviceToken,
    NotificationDelivery,
    NotificationEvent,
    NotificationPreference,
)
from backend.app.services import push

log = logging.getLogger("revora.notifications")

MAX_ATTEMPTS = 3
IST = timedelta(hours=5, minutes=30)
QUIET_START, QUIET_END = 22, 8

# Categories a user can switch push off for. ACCOUNT is critical and cannot be switched off.
PREFERENCE_CATEGORIES = ("LEADS", "QUOTES", "DEALS", "MARKETING")

# type -> (category, critical, push)
EVENT_TYPES: dict[str, tuple[str, bool, bool]] = {
    "NEW_LEAD": ("LEADS", False, True),
    "MATCHES_FOUND": ("LEADS", False, False),
    "QUOTE_RECEIVED": ("QUOTES", False, True),
    "QUOTE_REVISED": ("QUOTES", False, True),
    "QUOTE_WITHDRAWN": ("QUOTES", False, True),
    "COUNTER_RECEIVED": ("QUOTES", False, True),
    "COUNTER_ACCEPTED": ("QUOTES", False, True),
    "COUNTER_DECLINED": ("QUOTES", False, False),
    "QUOTE_ACCEPTED": ("DEALS", True, True),
    "QUOTE_NOT_SELECTED": ("DEALS", False, False),
    "DEALER_APPROVED": ("ACCOUNT", True, True),
    "DEALER_REACTIVATED": ("ACCOUNT", True, True),
    "DEALER_NEEDS_CHANGES": ("ACCOUNT", True, True),
    "DEALER_REJECTED": ("ACCOUNT", True, True),
    "DEALER_SUSPENDED": ("ACCOUNT", True, True),
}


def _now() -> datetime:
    return datetime.utcnow()


def after_quiet_hours(now: datetime) -> datetime:
    """`now` if it is outside quiet hours, otherwise the next 08:00 IST (as UTC)."""
    local = now + IST
    if QUIET_END <= local.hour < QUIET_START:
        return now
    morning = local.replace(hour=QUIET_END, minute=0, second=0, microsecond=0)
    if local.hour >= QUIET_START:
        morning += timedelta(days=1)
    return morning - IST


def push_enabled(session: Session, user_id: uuid.UUID, category: str) -> bool:
    pref = session.exec(
        select(NotificationPreference).where(
            NotificationPreference.user_id == user_id, NotificationPreference.category == category
        )
    ).first()
    return True if pref is None else pref.push_enabled


def notify(
    session: Session,
    recipient_id: uuid.UUID,
    type: str,
    title: str,
    body: str,
    *,
    entity_type: Optional[str] = None,
    entity_id: Optional[uuid.UUID | str] = None,
    window: str = "",
    now: Optional[datetime] = None,
) -> Optional[NotificationEvent]:
    """Record one notification. Returns None when the same one was already recorded.

    `window` separates legitimately repeated events about one entity (e.g. a quote revision
    number). Bodies must contain nothing the recipient may not see: no contact details, and
    never a competitor's price or identity.
    """
    category, critical, wants_push = EVENT_TYPES[type]
    now = now or _now()
    key = f"{type}:{entity_id}:{recipient_id}:{window}"
    if session.exec(select(NotificationEvent.id).where(NotificationEvent.dedupe_key == key)).first():
        return None
    event = NotificationEvent(
        recipient_id=recipient_id,
        type=type,
        category=category,
        title=title,
        body=body,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id is not None else None,
        critical=critical,
        dedupe_key=key,
        created_at=now,
    )
    try:
        with session.begin_nested():  # a concurrent duplicate must not poison the outer transaction
            session.add(event)
            session.flush()
    except IntegrityError:
        return None
    session.add(NotificationDelivery(event_id=event.id, channel="IN_APP", status="SENT", attempts=1, sent_at=now))
    if wants_push and (critical or push_enabled(session, recipient_id, category)):
        session.add(
            NotificationDelivery(
                event_id=event.id,
                channel="PUSH",
                deliver_after=now if critical else after_quiet_hours(now),
            )
        )
    return event


# ---------------------------------------------------------------- push delivery
def dispatch_pending(session: Session, now: Optional[datetime] = None, limit: int = 200) -> int:
    """Send due push deliveries; returns how many were sent. Commits. Safe to call repeatedly."""
    now = now or _now()
    due = session.exec(
        select(NotificationDelivery)
        .where(
            NotificationDelivery.channel == "PUSH",
            NotificationDelivery.status == "PENDING",
            NotificationDelivery.deliver_after <= now,
        )
        .order_by(col(NotificationDelivery.deliver_after))
        .limit(limit)
    ).all()
    sender = push.get_sender()
    sent = 0
    for delivery in due:
        event = session.get(NotificationEvent, delivery.event_id)
        tokens = session.exec(select(DeviceToken).where(DeviceToken.user_id == event.recipient_id)).all()
        if not tokens:
            delivery.status, delivery.last_error = "SKIPPED", "no registered device"
            session.add(delivery)
            continue
        data = {"type": event.type, "entity_type": event.entity_type or "", "entity_id": event.entity_id or ""}
        delivered, error = False, None
        for t in tokens:
            try:
                sender.send(t.token, event.title, event.body, data)
                delivered = True
            except Exception as exc:  # one bad token must not block the rest
                error = type(exc).__name__
        delivery.attempts += 1
        if delivered:
            delivery.status, delivery.sent_at, delivery.last_error = "SENT", now, None
            sent += 1
        elif delivery.attempts >= MAX_ATTEMPTS:
            delivery.status, delivery.last_error = "FAILED", error
        else:
            delivery.deliver_after = now + timedelta(minutes=2 ** delivery.attempts)
            delivery.last_error = error
        session.add(delivery)
    session.commit()
    return sent


# ---------------------------------------------------------------- feed (always the caller's own)
def feed(session: Session, user_id: uuid.UUID, *, limit: int, offset: int, unread_only: bool) -> tuple[list[NotificationEvent], int]:
    base = select(NotificationEvent).where(NotificationEvent.recipient_id == user_id)
    if unread_only:
        base = base.where(col(NotificationEvent.read_at).is_(None))
    total = session.exec(select(func.count()).select_from(base.subquery())).one()
    items = session.exec(base.order_by(col(NotificationEvent.created_at).desc()).offset(offset).limit(limit)).all()
    return list(items), total


def unread_count(session: Session, user_id: uuid.UUID) -> int:
    return session.exec(
        select(func.count()).select_from(NotificationEvent).where(
            NotificationEvent.recipient_id == user_id, col(NotificationEvent.read_at).is_(None)
        )
    ).one()


def mark_read(session: Session, user_id: uuid.UUID, ids: Optional[list[uuid.UUID]]) -> int:
    """Mark the caller's notifications read (all of them when `ids` is None). Others' ids are ignored."""
    query = select(NotificationEvent).where(
        NotificationEvent.recipient_id == user_id, col(NotificationEvent.read_at).is_(None)
    )
    if ids is not None:
        query = query.where(col(NotificationEvent.id).in_(ids))
    rows = session.exec(query).all()
    now = _now()
    for row in rows:
        row.read_at = now
        session.add(row)
    session.commit()
    return len(rows)


# ---------------------------------------------------------------- preferences and devices
def get_preferences(session: Session, user_id: uuid.UUID) -> dict[str, bool]:
    stored = {
        p.category: p.push_enabled
        for p in session.exec(select(NotificationPreference).where(NotificationPreference.user_id == user_id)).all()
    }
    return {c: stored.get(c, True) for c in PREFERENCE_CATEGORIES}


def set_preferences(session: Session, user_id: uuid.UUID, changes: dict[str, bool]) -> dict[str, bool]:
    for category, enabled in changes.items():
        pref = session.exec(
            select(NotificationPreference).where(
                NotificationPreference.user_id == user_id, NotificationPreference.category == category
            )
        ).first()
        if pref is None:
            pref = NotificationPreference(user_id=user_id, category=category)
        pref.push_enabled = enabled
        session.add(pref)
    session.commit()
    return get_preferences(session, user_id)


def register_device(session: Session, user_id: uuid.UUID, token: str, platform: str) -> None:
    """Upsert. A token seen under a new user moves to them (shared phone, new sign-in)."""
    row = session.exec(select(DeviceToken).where(DeviceToken.token == token)).first()
    if row is None:
        row = DeviceToken(user_id=user_id, token=token, platform=platform)
    row.user_id, row.platform, row.last_seen_at = user_id, platform, _now()
    session.add(row)
    session.commit()


def remove_device(session: Session, user_id: uuid.UUID, token: str) -> None:
    row = session.exec(
        select(DeviceToken).where(DeviceToken.token == token, DeviceToken.user_id == user_id)
    ).first()
    if row is not None:
        session.delete(row)
        session.commit()
