from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List

from backend.app.database.session import get_session
from backend.app.core.dependencies import get_dealer_profile, require_verified_dealer
from backend.app.models.marketplace_models import (
    CarInventory,
    Dealer,
    BuyRequirement,
    SellListing,
    DealerQuote,
    DealerOffer,
)
from backend.app.schemas.marketplace_schema import (
    CarInventoryCreate,
    CarInventoryResponse,
    BuyRequirementResponse,
    SellListingResponse,
    DealerQuoteCreate,
    DealerQuoteResponse,
    DealerOfferCreate,
    DealerOfferResponse,
)

router = APIRouter(tags=["Dealer"])


# --- Dealer Inventory ---
@router.post("/inventory", response_model=CarInventoryResponse)
def add_inventory_car(
    car_data: CarInventoryCreate,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    images_str = ",".join(car_data.images) if car_data.images else ""
    car = CarInventory(
        dealer_id=dealer.id,
        make=car_data.make,
        model=car_data.model,
        year=car_data.year,
        fuel=car_data.fuel,
        transmission=car_data.transmission,
        km=car_data.km,
        price=car_data.price,
        images_csv=images_str,
        status="AVAILABLE",
    )
    session.add(car)
    session.commit()
    session.refresh(car)

    return CarInventoryResponse(
        id=car.id,
        dealer_id=car.dealer_id,
        make=car.make,
        model=car.model,
        year=car.year,
        fuel=car.fuel,
        transmission=car.transmission,
        km=car.km,
        price=car.price,
        images=[img for img in car.images_csv.split(",") if img],
        status=car.status,
        created_at=car.created_at,
    )


@router.get("/inventory", response_model=List[CarInventoryResponse])
def get_inventory(
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    cars = session.exec(
        select(CarInventory).where(CarInventory.dealer_id == dealer.id)
    ).all()

    return [
        CarInventoryResponse(
            id=c.id,
            dealer_id=c.dealer_id,
            make=c.make,
            model=c.model,
            year=c.year,
            fuel=c.fuel,
            transmission=c.transmission,
            km=c.km,
            price=c.price,
            images=[img for img in c.images_csv.split(",") if img],
            status=c.status,
            created_at=c.created_at,
        )
        for c in cars
    ]


# --- Dealer Leads Feed ---
@router.get("/leads/buy", response_model=List[BuyRequirementResponse])
def get_buyer_leads(
    _dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    reqs = session.exec(
        select(BuyRequirement).where(BuyRequirement.status == "ACTIVE")
    ).all()
    return [
        BuyRequirementResponse(
            id=r.id,
            customer_id=r.customer_id,
            make=r.make,
            model=r.model,
            year_min=r.year_min,
            budget=r.budget,
            fuel=r.fuel,
            transmission=r.transmission,
            city=r.city,
            notes=r.notes,
            status=r.status,
            created_at=r.created_at,
        )
        for r in reqs
    ]


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
    if requirement is None or requirement.status != "ACTIVE":
        raise HTTPException(status_code=404, detail="Requirement not found or closed")
    if quote_data.car_inventory_id is not None:
        car = session.get(CarInventory, quote_data.car_inventory_id)
        if car is None or car.dealer_id != dealer.id:
            raise HTTPException(status_code=404, detail="Inventory car not found")
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
        car_inventory_id=quote_data.car_inventory_id,
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
        car_inventory_id=quote.car_inventory_id,
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
