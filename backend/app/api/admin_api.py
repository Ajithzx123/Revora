from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List, Dict, Any

from backend.app.database.session import get_session
from backend.app.core.dependencies import require_admin
from backend.app.models.user_model import User
from backend.app.models.marketplace_models import (
    Dealer,
    BuyRequirement,
    SellListing,
    DealerQuote,
    DealerOffer,
)

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/metrics")
def get_admin_metrics(session: Session = Depends(get_session)):
    users_count = len(session.exec(select(User)).all())
    dealers_count = len(session.exec(select(Dealer)).all())
    reqs_count = len(session.exec(select(BuyRequirement)).all())
    listings_count = len(session.exec(select(SellListing)).all())
    quotes_count = len(session.exec(select(DealerQuote)).all())
    offers_count = len(session.exec(select(DealerOffer)).all())

    return {
        "total_users": users_count,
        "active_dealers": dealers_count,
        "buy_requirements": reqs_count,
        "sell_listings": listings_count,
        "quotes_exchanged": quotes_count,
        "purchase_offers": offers_count,
        "platform_status": "OPERATIONAL",
    }


@router.get("/dealers")
def list_dealers(session: Session = Depends(get_session)):
    dealers = session.exec(select(Dealer)).all()
    return dealers


@router.patch("/dealers/{dealer_id}/verify")
def verify_dealer(dealer_id: int, session: Session = Depends(get_session)):
    dealer = session.get(Dealer, dealer_id)
    if not dealer:
        raise HTTPException(status_code=404, detail="Dealer not found")
    dealer.verified = True
    session.add(dealer)
    session.commit()
    return {"status": True, "message": "Dealer verified successfully"}
