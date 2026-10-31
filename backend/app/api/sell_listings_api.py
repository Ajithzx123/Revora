from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from typing import List

from backend.app.database.session import get_session
from backend.app.core.dependencies import (
    ADMIN_ROLES,
    current_user_id,
    require_auth,
    require_customer,
)
from backend.app.models.marketplace_models import (
    SellListing,
    DealerOffer,
    Dealer,
)
from backend.app.schemas.marketplace_schema import (
    SellListingCreate,
    SellListingResponse,
    DealerOfferResponse,
)

router = APIRouter(prefix="/sell-listings", tags=["Sell Listings"])


@router.post("/", response_model=SellListingResponse)
def create_sell_listing(
    listing_data: SellListingCreate,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    customer_id = current_user_id(user_data)
    images_str = ",".join(listing_data.images) if listing_data.images else ""
    
    listing = SellListing(
        customer_id=customer_id,
        make=listing_data.make,
        model=listing_data.model,
        year=listing_data.year,
        fuel=listing_data.fuel,
        transmission=listing_data.transmission,
        km=listing_data.km,
        expected_price=listing_data.expected_price,
        city=listing_data.city,
        images_csv=images_str,
        status="ACTIVE",
    )
    session.add(listing)
    session.commit()
    session.refresh(listing)

    return SellListingResponse(
        id=listing.id,
        customer_id=listing.customer_id,
        make=listing.make,
        model=listing.model,
        year=listing.year,
        fuel=listing.fuel,
        transmission=listing.transmission,
        km=listing.km,
        expected_price=listing.expected_price,
        city=listing.city,
        images=[img for img in listing.images_csv.split(",") if img],
        status=listing.status,
        created_at=listing.created_at,
        offer_count=0,
    )


@router.get("/", response_model=List[SellListingResponse])
def get_user_listings(
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    customer_id = current_user_id(user_data)
    statement = select(SellListing).where(SellListing.customer_id == customer_id)
    listings = session.exec(statement).all()

    result = []
    for item in listings:
        offers_count = len(
            session.exec(
                select(DealerOffer).where(DealerOffer.sell_listing_id == item.id)
            ).all()
        )
        result.append(
            SellListingResponse(
                id=item.id,
                customer_id=item.customer_id,
                make=item.make,
                model=item.model,
                year=item.year,
                fuel=item.fuel,
                transmission=item.transmission,
                km=item.km,
                expected_price=item.expected_price,
                city=item.city,
                images=[img for img in item.images_csv.split(",") if img],
                status=item.status,
                created_at=item.created_at,
                offer_count=offers_count,
            )
        )
    return result


@router.get("/{listing_id}", response_model=SellListingResponse)
def get_listing_detail(
    listing_id: int,
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    item = session.get(SellListing, listing_id)
    if not item:
        raise HTTPException(status_code=404, detail="Listing not found")
    is_owner = item.customer_id == current_user_id(user_data)
    is_admin = user_data.get("role") in ADMIN_ROLES
    is_dealer = (
        user_data.get("role") == "DEALER"
        and session.exec(
            select(Dealer).where(
                Dealer.user_id == current_user_id(user_data), Dealer.verified == True  # noqa: E712
            )
        ).first()
        is not None
    )
    if not (is_owner or is_admin or is_dealer):
        raise HTTPException(status_code=404, detail="Listing not found")

    offers_count = len(
        session.exec(
            select(DealerOffer).where(DealerOffer.sell_listing_id == item.id)
        ).all()
    )
    return SellListingResponse(
        id=item.id,
        customer_id=item.customer_id,
        make=item.make,
        model=item.model,
        year=item.year,
        fuel=item.fuel,
        transmission=item.transmission,
        km=item.km,
        expected_price=item.expected_price,
        city=item.city,
        images=[img for img in item.images_csv.split(",") if img],
        status=item.status,
        created_at=item.created_at,
        offer_count=offers_count,
    )


@router.get("/{listing_id}/offers", response_model=List[DealerOfferResponse])
def get_offers_for_listing(
    listing_id: int,
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    # Sealed bidding: only the listing's owner (or an admin) sees offers.
    item = session.get(SellListing, listing_id)
    if not item or not (
        item.customer_id == current_user_id(user_data) or user_data.get("role") in ADMIN_ROLES
    ):
        raise HTTPException(status_code=404, detail="Listing not found")
    offers = session.exec(
        select(DealerOffer).where(DealerOffer.sell_listing_id == listing_id)
    ).all()

    result = []
    for o in offers:
        dealer = session.get(Dealer, o.dealer_id)
        result.append(
            DealerOfferResponse(
                id=o.id,
                dealer_id=o.dealer_id,
                dealer_name=dealer.business_name if dealer else "Authorized Dealer",
                dealer_rating=dealer.rating if dealer else 4.9,
                sell_listing_id=o.sell_listing_id,
                offered_price=o.offered_price,
                message=o.message,
                status=o.status,
                created_at=o.created_at,
            )
        )
    return result
