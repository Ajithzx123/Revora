import uuid
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import ValidationError
from sqlmodel import Session, func, select

from backend.app.core.dependencies import (
    ADMIN_ROLES,
    current_user_id,
    require_auth,
    require_customer,
)
from backend.app.database.session import get_session
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import (
    MatchRecord,
    BuyRequirement,
    Dealer,
    DealerQuote,
    DealerStatus,
    RequirementStatus,
)
from backend.app.schemas.marketplace_schema import DealerQuoteResponse
from backend.app.schemas.requirement_schema import (
    RequirementCreate,
    RequirementResponse,
    RequirementUpdate,
)
from backend.app.services import matching_service, quote_service
from backend.app.services import requirement_workflow as workflow

router = APIRouter(prefix="/requirements", tags=["Requirements"])

R = RequirementStatus

_RESPONSE_FIELDS = (
    "id", "customer_id", "make", "model", "variant", "year_min", "year_max",
    "budget_min", "budget_max", "fuel", "transmission", "body_type", "max_km",
    "max_owners", "city", "radius_km", "urgency", "needs_finance", "has_exchange",
    "notes", "status", "expires_at", "created_at",
)
_MATERIAL_FIELDS = ("make", "model", "variant", "city")


def to_response(session: Session, req: BuyRequirement) -> RequirementResponse:
    quote_count = session.exec(
        select(func.count()).select_from(DealerQuote).where(DealerQuote.requirement_id == req.id)
    ).one()
    return RequirementResponse(
        **{k: getattr(req, k) for k in _RESPONSE_FIELDS},
        must_have=[m for m in req.must_have_csv.split(",") if m],
        quote_count=quote_count,
        dealers_notified=matching_service.dealers_notified(session, req.id),
    )


def _owned(session: Session, requirement_id: uuid.UUID, user_data: dict) -> BuyRequirement:
    """The caller's own request, or 404 (never reveal that someone else's exists)."""
    req = session.get(BuyRequirement, requirement_id)
    if not req or req.customer_id != current_user_id(user_data):
        raise HTTPException(status_code=404, detail="Requirement not found")
    if workflow.expire_if_due(session, req):
        session.commit()
    return req


@router.post("/", response_model=RequirementResponse, status_code=201)
def create_requirement(
    data: RequirementCreate,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    customer_id = current_user_id(user_data)
    active = list(
        session.exec(
            select(BuyRequirement).where(
                BuyRequirement.customer_id == customer_id,
                BuyRequirement.status.in_(list(workflow.ACTIVE)),
            )
        ).all()
    )
    for existing in active:
        workflow.expire_if_due(session, existing)
    active = [r for r in active if r.status in workflow.ACTIVE]

    if len(active) >= workflow.MAX_ACTIVE_REQUESTS:
        raise HTTPException(
            status_code=409,
            detail=f"You already have {workflow.MAX_ACTIVE_REQUESTS} open requests. Close one to post another.",
        )
    if any(
        r.make == data.make and r.model == data.model and r.city == data.city
        and r.budget_max == data.budget_max
        for r in active
    ):
        raise HTTPException(
            status_code=409,
            detail="You already have an open request for this car in this city and budget.",
        )

    requirement = BuyRequirement(
        customer_id=customer_id,
        must_have_csv=",".join(data.must_have),
        expires_at=datetime.utcnow() + timedelta(days=workflow.LIFETIME_DAYS),
        **data.model_dump(exclude={"must_have"}),
    )
    session.add(requirement)
    session.flush()
    session.add(
        AuditEvent(
            actor_user_id=customer_id,
            action="REQUIREMENT_POSTED",
            entity_type="buy_requirement",
            entity_id=str(requirement.id),
        )
    )
    matching_service.run_matching(session, requirement)
    session.commit()
    session.refresh(requirement)
    return to_response(session, requirement)


@router.get("/", response_model=List[RequirementResponse])
def list_my_requirements(
    status: Optional[RequirementStatus] = Query(default=None),
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    items = session.exec(
        select(BuyRequirement)
        .where(BuyRequirement.customer_id == current_user_id(user_data))
        .order_by(BuyRequirement.created_at.desc())
    ).all()
    for item in items:
        workflow.expire_if_due(session, item)
    session.commit()
    if status is not None:
        items = [i for i in items if i.status == status]
    return [to_response(session, i) for i in items]


@router.get("/{requirement_id}", response_model=RequirementResponse)
def get_requirement_detail(
    requirement_id: uuid.UUID,
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    req = session.get(BuyRequirement, requirement_id)
    if not req:
        raise HTTPException(status_code=404, detail="Requirement not found")
    is_owner = req.customer_id == current_user_id(user_data)
    is_admin = user_data.get("role") in ADMIN_ROLES
    is_dealer = False
    if user_data.get("role") == "DEALER":
        dealer = session.exec(
            select(Dealer).where(
                Dealer.user_id == current_user_id(user_data),
                Dealer.status == DealerStatus.APPROVED,
            )
        ).first()
        # A dealer sees only requests they were matched to.
        is_dealer = dealer is not None and session.exec(
            select(MatchRecord).where(
                MatchRecord.dealer_id == dealer.id,
                MatchRecord.requirement_id == req.id,
                MatchRecord.dismissed_at.is_(None),
            )
        ).first() is not None
    if not (is_owner or is_admin or is_dealer):
        # 404, not 403: do not reveal that the id exists
        raise HTTPException(status_code=404, detail="Requirement not found")
    if workflow.expire_if_due(session, req):
        session.commit()
    return to_response(session, req)


def _is_material_change(before: BuyRequirement, changes: dict) -> bool:
    """A change that can make existing quotes wrong: another car, another place, or a big budget swing."""
    if any(f in changes and changes[f] != getattr(before, f) for f in _MATERIAL_FIELDS):
        return True
    new_budget = changes.get("budget_max")
    if new_budget is not None and before.budget_max > 0:
        return abs(new_budget - before.budget_max) / before.budget_max > 0.20
    return False


@router.patch("/{requirement_id}", response_model=RequirementResponse)
def edit_requirement(
    requirement_id: uuid.UUID,
    data: RequirementUpdate,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    req = _owned(session, requirement_id, user_data)
    if req.status not in workflow.EDITABLE:
        raise HTTPException(
            status_code=409,
            detail=f"A request that is {req.status.value.lower().replace('_', ' ')} can no longer be edited",
        )
    changes = data.model_dump(exclude_unset=True)
    must_have = changes.pop("must_have", None)

    # Re-validate the merged request so an edit can never produce an impossible one.
    merged = {k: getattr(req, k) for k in RequirementCreate.model_fields if k != "must_have"}
    merged.update(changes)
    try:
        RequirementCreate(
            **merged,
            must_have=must_have if must_have is not None else [m for m in req.must_have_csv.split(",") if m],
        )
    except ValidationError as exc:
        first = exc.errors()[0]
        field = first["loc"][-1] if first["loc"] else "request"
        raise HTTPException(status_code=422, detail=f"{field}: {first['msg']}") from exc

    material = _is_material_change(req, changes)
    before = {k: str(getattr(req, k)) for k in changes if getattr(req, k) != changes[k]}
    for key, value in changes.items():
        setattr(req, key, value)
    if must_have is not None:
        req.must_have_csv = ",".join(must_have)
    req.updated_at = datetime.utcnow()
    session.add(req)

    if material:
        for quote in session.exec(
            select(DealerQuote).where(DealerQuote.requirement_id == req.id)
        ).all():
            if quote.status == "PENDING":
                quote.status = "REQUOTE_REQUESTED"
                session.add(quote)
    session.add(
        AuditEvent(
            actor_user_id=current_user_id(user_data),
            action="REQUIREMENT_EDITED",
            entity_type="buy_requirement",
            entity_id=str(req.id),
            detail=("material change; " if material else "") + f"changed: {', '.join(sorted(before)) or 'nothing'}",
        )
    )
    matching_service.run_matching(session, req)  # a changed request may now suit more dealers
    session.commit()
    session.refresh(req)
    return to_response(session, req)


def _move(requirement_id, new_status, user_data, session):
    req = _owned(session, requirement_id, user_data)
    workflow.transition(session, req, new_status, current_user_id(user_data))
    session.commit()
    session.refresh(req)
    return to_response(session, req)


@router.post("/{requirement_id}/pause", response_model=RequirementResponse)
def pause_requirement(
    requirement_id: uuid.UUID,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    return _move(requirement_id, R.PAUSED, user_data, session)


@router.post("/{requirement_id}/resume", response_model=RequirementResponse)
def resume_requirement(
    requirement_id: uuid.UUID,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    response = _move(requirement_id, R.OPEN, user_data, session)
    req = session.get(BuyRequirement, requirement_id)
    matching_service.run_matching(session, req)  # stock may have changed while it was paused
    session.commit()
    return to_response(session, req)


@router.post("/{requirement_id}/cancel", response_model=RequirementResponse)
def cancel_requirement(
    requirement_id: uuid.UUID,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    return _move(requirement_id, R.CANCELLED, user_data, session)


@router.get("/{requirement_id}/quotes", response_model=List[DealerQuoteResponse])
def get_quotes_for_requirement(
    requirement_id: uuid.UUID,
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    # Sealed bidding: only the requirement's owner (or an admin) sees quotes.
    req = session.get(BuyRequirement, requirement_id)
    if not req or not (
        req.customer_id == current_user_id(user_data) or user_data.get("role") in ADMIN_ROLES
    ):
        raise HTTPException(status_code=404, detail="Requirement not found")
    quote_service.expire_due_quotes(session)
    session.commit()
    quotes = session.exec(
        select(DealerQuote).where(DealerQuote.requirement_id == requirement_id).order_by(DealerQuote.quoted_price)
    ).all()
    return [quote_service.quote_response(session, q) for q in quotes]
