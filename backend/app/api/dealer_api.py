from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from datetime import datetime
from typing import List

from sqlmodel import func

from backend.app.database.session import get_session
from backend.app.core.dependencies import get_dealer_profile, require_verified_dealer
from backend.app.models.marketplace_models import (
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
from backend.app.schemas.marketplace_schema import (
    SellListingResponse,
    DealerQuoteCreate,
    DealerQuoteResponse,
    DealerOfferCreate,
    DealerOfferResponse,
)

router = APIRouter(tags=["Dealer"])


# --- Dealer Leads Feed ---
@router.get("/leads/buy", response_model=List[BuyLeadResponse])
def get_buyer_leads(
    _dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    """Open buyer requests. Matching to the right dealers arrives in S3; for now every
    approved dealer sees every open, unexpired request, but never who the buyer is."""
    requirements = session.exec(
        select(BuyRequirement)
        .where(
            BuyRequirement.status == RequirementStatus.OPEN,
            BuyRequirement.expires_at > datetime.utcnow(),
        )
        .order_by(BuyRequirement.created_at.desc())
    ).all()
    leads = []
    for r in requirements:
        buyer = session.get(User, r.customer_id)
        quote_count = session.exec(
            select(func.count()).select_from(DealerQuote).where(DealerQuote.requirement_id == r.id)
        ).one()
        leads.append(
            BuyLeadResponse(
                buyer_first_name=(buyer.name.strip().split(" ")[0] if buyer and buyer.name.strip() else "Buyer"),
                must_have=[m for m in r.must_have_csv.split(",") if m],
                quote_count=quote_count,
                **r.model_dump(exclude={"customer_id", "must_have_csv", "status", "updated_at"}),
            )
        )
    return leads


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
    if quote_data.quoted_price <= 0:
        raise HTTPException(status_code=422, detail="Quoted price must be positive")
    requirement = session.get(BuyRequirement, quote_data.requirement_id)
    if (
        requirement is None
        or requirement.status != RequirementStatus.OPEN
        or requirement.expires_at <= datetime.utcnow()
    ):
        raise HTTPException(status_code=404, detail="Requirement not found or closed")
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
    )
    session.add(quote)
    session.commit()
    session.refresh(quote)

    return DealerQuoteResponse(
        id=quote.id,
        dealer_id=quote.dealer_id,
        dealer_name=dealer.business_name,
        dealer_rating=dealer.rating,
        requirement_id=quote.requirement_id,
        vehicle_id=quote.vehicle_id,
        quoted_price=quote.quoted_price,
        message=quote.message,
        status=quote.status,
        created_at=quote.created_at,
    )


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
