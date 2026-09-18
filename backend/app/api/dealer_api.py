from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List

from backend.app.database.session import get_session
from backend.app.core.dependencies import require_auth
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
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    user_id = user_data.get("sub") or user_data.get("id")
    dealer = session.exec(select(Dealer).where(Dealer.user_id == user_id)).first()
    if not dealer:
        # Auto-create dealer record if first time
        dealer = Dealer(
            user_id=user_id,
            business_name="Revora Partner Dealership",
            city="Mumbai",
            verified=True,
        )
        session.add(dealer)
        session.commit()
        session.refresh(dealer)

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
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    user_id = user_data.get("sub") or user_data.get("id")
    dealer = session.exec(select(Dealer).where(Dealer.user_id == user_id)).first()
    if not dealer:
        return []

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
def get_buyer_leads(session: Session = Depends(get_session)):
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
def get_seller_leads(session: Session = Depends(get_session)):
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
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    user_id = user_data.get("sub") or user_data.get("id")
    dealer = session.exec(select(Dealer).where(Dealer.user_id == user_id)).first()
    if not dealer:
        dealer = Dealer(
            user_id=user_id,
            business_name="Authorized Partner",
            city="Mumbai",
            verified=True,
        )
        session.add(dealer)
        session.commit()
        session.refresh(dealer)

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
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    user_id = user_data.get("sub") or user_data.get("id")
    dealer = session.exec(select(Dealer).where(Dealer.user_id == user_id)).first()
    if not dealer:
        dealer = Dealer(
            user_id=user_id,
            business_name="Authorized Partner",
            city="Mumbai",
            verified=True,
        )
        session.add(dealer)
        session.commit()
        session.refresh(dealer)

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
