"""The signed-in user's own notifications. Every query is scoped to the caller, so there is no
object id that could be guessed to read someone else's feed."""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session

from backend.app.core.dependencies import current_user_id, require_auth
from backend.app.database.session import get_session
from backend.app.schemas.notification_schema import (
    DeviceBody,
    MarkReadBody,
    MarkReadResult,
    NotificationPage,
    NotificationResponse,
    PreferencesBody,
)
from backend.app.services import notification_service as svc

router = APIRouter(prefix="/notifications", tags=["Notifications"])


def _response(n) -> NotificationResponse:
    return NotificationResponse(
        id=n.id, type=n.type, category=n.category, title=n.title, body=n.body,
        entity_type=n.entity_type, entity_id=n.entity_id, critical=n.critical,
        read=n.read_at is not None, created_at=n.created_at,
    )


@router.get("", response_model=NotificationPage)
def list_notifications(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    unread_only: bool = False,
    user: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    uid = current_user_id(user)
    items, total = svc.feed(session, uid, limit=limit, offset=offset, unread_only=unread_only)
    return NotificationPage(
        items=[_response(n) for n in items], total=total,
        unread_count=svc.unread_count(session, uid), limit=limit, offset=offset,
    )


@router.get("/unread-count")
def unread_count(user: dict = Depends(require_auth), session: Session = Depends(get_session)):
    return {"unread_count": svc.unread_count(session, current_user_id(user))}


@router.post("/mark-read", response_model=MarkReadResult)
def mark_read(body: MarkReadBody, user: dict = Depends(require_auth), session: Session = Depends(get_session)):
    uid = current_user_id(user)
    marked = svc.mark_read(session, uid, body.ids)
    return MarkReadResult(marked=marked, unread_count=svc.unread_count(session, uid))


@router.get("/preferences")
def get_preferences(user: dict = Depends(require_auth), session: Session = Depends(get_session)):
    return {"preferences": svc.get_preferences(session, current_user_id(user))}


@router.put("/preferences")
def set_preferences(body: PreferencesBody, user: dict = Depends(require_auth), session: Session = Depends(get_session)):
    unknown = set(body.preferences) - set(svc.PREFERENCE_CATEGORIES)
    if unknown:
        raise HTTPException(422, f"Unknown or non-optional categories: {', '.join(sorted(unknown))}")
    return {"preferences": svc.set_preferences(session, current_user_id(user), body.preferences)}


@router.post("/devices", status_code=204)
def register_device(body: DeviceBody, user: dict = Depends(require_auth), session: Session = Depends(get_session)):
    svc.register_device(session, current_user_id(user), body.token, body.platform)


@router.post("/devices/remove", status_code=204)
def remove_device(body: DeviceBody, user: dict = Depends(require_auth), session: Session = Depends(get_session)):
    """POST rather than DELETE so the token stays out of URLs and access logs."""
    svc.remove_device(session, current_user_id(user), body.token)
