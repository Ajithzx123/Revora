from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select
import uuid
from datetime import datetime, timedelta
from typing import List, Optional

from sqlmodel import func

from backend.app.database.session import get_session
from backend.app.core import rate_limit
from backend.app.core.dependencies import get_dealer_profile, require_verified_dealer
from pydantic import BaseModel, Field
from backend.app.models.marketplace_models import (
    MatchRecord,
    Vehicle,
    VehicleStatus,
    Dealer,
    BuyRequirement,
    RequirementStatus,
    SellListing,
    SellMatch,
    DealerQuote,
    DealerOffer,
)
from backend.app.models.user_model import User
from backend.app.schemas.requirement_schema import BuyLeadResponse
from backend.app.services import matching_service, offer_service, quote_service, sell_service
from backend.app.schemas.marketplace_schema import (
    SellLeadResponse,
    DealerQuoteCreate,
    DealerQuoteResponse,
    DealerOfferCreate,
    DealerOfferResponse,
)

router = APIRouter(tags=["Dealer"])


# --- Dealer Leads Feed ---
def _lead(session: Session, req: BuyRequirement, match: MatchRecord) -> BuyLeadResponse:
    buyer = session.get(User, req.customer_id)
    quote_count = session.exec(
        select(func.count()).select_from(DealerQuote).where(DealerQuote.requirement_id == req.id)
    ).one()
    car = session.get(Vehicle, match.vehicle_id) if match.vehicle_id else None
    return BuyLeadResponse(
        buyer_first_name=(buyer.name.strip().split(" ")[0] if buyer and buyer.name.strip() else "Buyer"),
        must_have=[m for m in req.must_have_csv.split(",") if m],
        quote_count=quote_count,
        match_score=match.score,
        match_tier=match.tier,
        match_reasons=match.reasons,
        matched_vehicle_id=car.id if car else None,
        matched_vehicle_title=(f"{car.year} {car.make} {car.model}" + (f" {car.variant}" if car.variant else "")) if car else None,
        matched_vehicle_price=car.price if car else None,
        response_deadline=matching_service.response_deadline(req, match.created_at),
        **req.model_dump(exclude={"customer_id", "must_have_csv", "status", "updated_at"}),
    )


def _my_match(session: Session, dealer: Dealer, requirement_id) -> Optional[MatchRecord]:
    return session.exec(
        select(MatchRecord).where(
            MatchRecord.dealer_id == dealer.id,
            MatchRecord.requirement_id == requirement_id,
            MatchRecord.dismissed_at.is_(None),
        )
    ).first()


@router.get("/leads/buy", response_model=List[BuyLeadResponse])
def get_buyer_leads(
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    """Open buyer requests this dealer was matched to, best match first. Never reveals who the buyer is."""
    now = datetime.utcnow()
    rows = session.exec(
        select(MatchRecord, BuyRequirement)
        .join(BuyRequirement, BuyRequirement.id == MatchRecord.requirement_id)
        .where(
            MatchRecord.dealer_id == dealer.id,
            MatchRecord.dismissed_at.is_(None),
            BuyRequirement.status == RequirementStatus.OPEN,
            BuyRequirement.expires_at > now,
        )
    ).all()
    leads = [_lead(session, req, match) for match, req in rows]
    return sorted(leads, key=lambda l: (l.match_tier, -l.match_score, l.response_deadline))


class DismissLead(BaseModel):
    reason: str = Field(default="NOT_INTERESTED", max_length=60)


@router.post("/leads/buy/{requirement_id}/dismiss", status_code=204, dependencies=[Depends(rate_limit.action)])
def dismiss_lead(
    requirement_id: uuid.UUID,
    body: DismissLead,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    """'Not for me': hides the request from this dealer. It is never shown to them again."""
    match = _my_match(session, dealer, requirement_id)
    if match is None:
        raise HTTPException(status_code=404, detail="Request not found")
    match.dismissed_at = datetime.utcnow()
    match.dismissed_reason = body.reason
    session.add(match)
    session.commit()


@router.get("/leads/sell", response_model=List[SellLeadResponse])
def get_seller_leads(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    """Only listings this dealer was matched to (they buy the make and are in range)."""
    offer_service.expire_due_offers(session)
    session.commit()
    rows = session.exec(
        select(SellMatch, SellListing)
        .join(SellListing, SellListing.id == SellMatch.listing_id)
        .where(SellMatch.dealer_id == dealer.id, SellMatch.dismissed_at.is_(None), SellListing.status == "ACTIVE")
        .order_by(SellMatch.score.desc(), SellMatch.created_at.desc())
        .offset(offset)
        .limit(limit)
    ).all()
    mine = {
        o.sell_listing_id: o.status
        for o in session.exec(select(DealerOffer).where(DealerOffer.dealer_id == dealer.id)).all()
    }
    out = []
    for match, listing in rows:
        base = sell_service.listing_response(session, listing).model_dump()
        base.pop("offer_count", None)   # sealed: dealers never see how many offers exist
        out.append(
            SellLeadResponse(
                **base, offer_count=0, match_score=match.score, match_reasons=match.reasons,
                my_offer_status=mine.get(listing.id),
            )
        )
    return out


# --- Dealer Sends Quote on Requirement ---
@router.post("/quotes", response_model=DealerQuoteResponse, dependencies=[Depends(rate_limit.submit)])
def send_quote(
    quote_data: DealerQuoteCreate,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    requirement = session.get(BuyRequirement, quote_data.requirement_id)
    if (
        requirement is None
        or requirement.status != RequirementStatus.OPEN
        or requirement.expires_at <= datetime.utcnow()
    ):
        raise HTTPException(status_code=404, detail="Requirement not found or closed")
    if _my_match(session, dealer, quote_data.requirement_id) is None:
        # Dealers quote only the requests they were shown, so matching cannot be bypassed.
        raise HTTPException(status_code=403, detail="This request was not matched to you")
    if quote_data.vehicle_id is not None:
        car = session.get(Vehicle, quote_data.vehicle_id)
        if car is None or car.dealer_id != dealer.id:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        if car.status != VehicleStatus.AVAILABLE:
            raise HTTPException(status_code=409, detail="This vehicle is no longer available")
    already = session.exec(
        select(DealerQuote).where(
            DealerQuote.dealer_id == dealer.id,
            DealerQuote.requirement_id == quote_data.requirement_id,
        )
    ).first()
    if already is not None:
        raise HTTPException(status_code=409, detail="You have already quoted this requirement")

    quote = DealerQuote(
        dealer_id=dealer.id,
        requirement_id=quote_data.requirement_id,
        vehicle_id=quote_data.vehicle_id,
        quoted_price=quote_data.quoted_price,
        message=quote_data.message,
        status="PENDING",
        kind=quote_service.kind_for(session, dealer, quote_data.requirement_id),
        valid_until=datetime.utcnow() + timedelta(hours=quote_data.valid_hours),
        delivery_days=quote_data.delivery_days,
        warranty_months=quote_data.warranty_months,
    )
    session.add(quote)
    quote_service.audit(session, dealer.user_id, "QUOTE_SUBMITTED", quote, f"price {quote.quoted_price}")
    quote_service.notify_buyer(
        session, quote, "QUOTE_RECEIVED", "New quote received",
        f"A dealer quoted {quote_service._lakh(quote.quoted_price)} for your {quote_service._car_name(requirement)}.",
    )
    session.commit()
    session.refresh(quote)
    return quote_service.quote_response(session, quote)


# --- Dealer Sends Purchase Offer on Sell Listing ---
@router.post("/offers", response_model=DealerOfferResponse, dependencies=[Depends(rate_limit.submit)])
def make_offer(
    offer_data: DealerOfferCreate,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    """Offer to buy a listing this dealer was matched to. Sealed: nobody sees other offers."""
    offer = offer_service.submit(session, dealer, offer_data)
    session.commit()
    session.refresh(offer)
    return offer_service.offer_response(session, offer)
