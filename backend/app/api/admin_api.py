from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlmodel import Session, select

from backend.app.database.session import get_session
from backend.app.core.dependencies import current_user_id, require_admin
from backend.app.models.audit_model import AuditEvent
from backend.app.models.user_model import User
from backend.app.models.marketplace_models import (
    Dealer,
    BuyRequirement,
    SellListing,
    DealerQuote,
    DealerOffer,
)

router = APIRouter(prefix="/admin", tags=["Admin"])


def _count(session: Session, model) -> int:
    return session.exec(select(func.count()).select_from(model)).one()


@router.get("/metrics")
def get_admin_metrics(
    _admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    return {
        "total_users": _count(session, User),
        "active_dealers": _count(session, Dealer),
        "buy_requirements": _count(session, BuyRequirement),
        "sell_listings": _count(session, SellListing),
        "quotes_exchanged": _count(session, DealerQuote),
        "purchase_offers": _count(session, DealerOffer),
        "platform_status": "OPERATIONAL",
    }


@router.get("/dealers")
def list_dealers(
    _admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    return session.exec(select(Dealer)).all()


@router.patch("/dealers/{dealer_id}/verify")
def verify_dealer(
    dealer_id: int,
    admin: dict = Depends(require_admin),
    session: Session = Depends(get_session),
):
    dealer = session.get(Dealer, dealer_id)
    if not dealer:
        raise HTTPException(status_code=404, detail="Dealer not found")
    if dealer.verified:
        return {"status": True, "message": "Dealer already verified"}

    dealer.verified = True
    session.add(dealer)
    session.add(
        AuditEvent(
            actor_user_id=current_user_id(admin),
            action="DEALER_VERIFIED",
            entity_type="dealer",
            entity_id=dealer.id,
        )
    )
    session.commit()
    return {"status": True, "message": "Dealer verified successfully"}
