from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
import uuid
from datetime import datetime, timedelta
from typing import List, Optional

from sqlmodel import func

from backend.app.database.session import get_session
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
    DealerQuote,
    DealerOffer,
)
from backend.app.models.user_model import User
from backend.app.schemas.requirement_schema import BuyLeadResponse
from backend.app.services import matching_service, quote_service
from backend.app.schemas.marketplace_schema import (
    SellListingResponse,
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


@router.post("/leads/buy/{requirement_id}/dismiss", status_code=204)
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


@router.get("/leads/sell", response_model=List[SellListingResponse])
def get_seller_leads(
    _dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    listings = session.exec(
        select(SellListing).where(SellListing.status == "ACTIVE")
    ).all()
    return [
        SellListingResponse(
            id=l.id,
            customer_id=l.customer_id,
            make=l.make,
            model=l.model,
            year=l.year,
            fuel=l.fuel,
            transmission=l.transmission,
            km=l.km,
            expected_price=l.expected_price,
            city=l.city,
            images=[img for img in l.images_csv.split(",") if img],
            status=l.status,
            created_at=l.created_at,
        )
        for l in listings
    ]


# --- Dealer Sends Quote on Requirement ---
@router.post("/quotes", response_model=DealerQuoteResponse)
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
    session.commit()
    session.refresh(quote)
    return quote_service.quote_response(session, quote)


# --- Dealer Sends Purchase Offer on Sell Listing ---
@router.post("/offers", response_model=DealerOfferResponse)
def make_offer(
    offer_data: DealerOfferCreate,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    if offer_data.offered_price <= 0:
        raise HTTPException(status_code=422, detail="Offered price must be positive")
    listing = session.get(SellListing, offer_data.sell_listing_id)
    if listing is None or listing.status != "ACTIVE":
        raise HTTPException(status_code=404, detail="Listing not found or closed")
    already = session.exec(
        select(DealerOffer).where(
            DealerOffer.dealer_id == dealer.id,
            DealerOffer.sell_listing_id == offer_data.sell_listing_id,
        )
    ).first()
    if already is not None:
        raise HTTPException(status_code=409, detail="You have already made an offer on this listing")

    offer = DealerOffer(
        dealer_id=dealer.id,
        sell_listing_id=offer_data.sell_listing_id,
        offered_price=offer_data.offered_price,
        message=offer_data.message,
        status="PENDING",
    )
    session.add(offer)
    session.commit()
    session.refresh(offer)

    return DealerOfferResponse(
        id=offer.id,
        dealer_id=offer.dealer_id,
        dealer_name=dealer.business_name,
        dealer_rating=dealer.rating,
        sell_listing_id=offer.sell_listing_id,
        offered_price=offer.offered_price,
        message=offer.message,
        status=offer.status,
        created_at=offer.created_at,
    )
