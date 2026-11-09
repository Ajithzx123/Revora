import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, col, select

from backend.app.core.dependencies import (
    ADMIN_ROLES,
    current_user_id,
    require_auth,
    require_customer,
)
from backend.app.database.session import get_session
from backend.app.models.marketplace_models import Dealer, DealerOffer, DealerStatus, SellListing
from backend.app.schemas.marketplace_schema import (
    DealerOfferResponse,
    SellListingClose,
    SellListingCreate,
    SellListingPrice,
    SellListingResponse,
)
from backend.app.services import offer_service, sell_service

router = APIRouter(prefix="/sell-listings", tags=["Sell Listings"])


def _owned(session: Session, user_data: dict, listing_id: uuid.UUID) -> SellListing:
    listing = session.get(SellListing, listing_id)
    if listing is None or listing.customer_id != current_user_id(user_data):
        raise HTTPException(status_code=404, detail="Listing not found")
    return listing


@router.post("/", response_model=SellListingResponse, status_code=201)
def create_sell_listing(
    listing_data: SellListingCreate,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    listing = sell_service.create_listing(session, current_user_id(user_data), listing_data)
    session.commit()
    session.refresh(listing)
    return sell_service.listing_response(session, listing)


@router.get("/", response_model=List[SellListingResponse])
def get_user_listings(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    sell_service.expire_due_listings(session)
    session.commit()
    listings = session.exec(
        select(SellListing)
        .where(SellListing.customer_id == current_user_id(user_data))
        .order_by(col(SellListing.created_at).desc())
        .offset(offset)
        .limit(limit)
    ).all()
    return [sell_service.listing_response(session, l) for l in listings]


@router.get("/{listing_id}", response_model=SellListingResponse)
def get_listing_detail(
    listing_id: uuid.UUID,
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    item = session.get(SellListing, listing_id)
    if not item:
        raise HTTPException(status_code=404, detail="Listing not found")
    is_owner = item.customer_id == current_user_id(user_data)
    is_admin = user_data.get("role") in ADMIN_ROLES
    # A dealer may open only a listing they were matched to.
    is_matched_dealer = False
    if user_data.get("role") == "DEALER":
        dealer = session.exec(
            select(Dealer).where(Dealer.user_id == current_user_id(user_data), Dealer.status == DealerStatus.APPROVED)
        ).first()
        is_matched_dealer = dealer is not None and offer_service.my_match(session, dealer, item.id) is not None
    if not (is_owner or is_admin or is_matched_dealer):
        raise HTTPException(status_code=404, detail="Listing not found")
    if sell_service.expire_if_due(session, item):
        session.commit()
        session.refresh(item)
    return sell_service.listing_response(session, item)


@router.put("/{listing_id}/price", response_model=SellListingResponse)
def change_price(
    listing_id: uuid.UUID,
    body: SellListingPrice,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    """Change the expected price. Offers already made stay valid; those dealers are told."""
    listing = _owned(session, user_data, listing_id)
    sell_service.change_price(session, listing, current_user_id(user_data), body.expected_price)
    session.commit()
    session.refresh(listing)
    return sell_service.listing_response(session, listing)


@router.post("/{listing_id}/close", response_model=SellListingResponse)
def close_listing(
    listing_id: uuid.UUID,
    body: SellListingClose,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    """Stop selling, or record that the car sold elsewhere. Every live offer is closed."""
    listing = _owned(session, user_data, listing_id)
    sell_service.close(session, listing, current_user_id(user_data), body.reason, body.sold_elsewhere)
    session.commit()
    session.refresh(listing)
    return sell_service.listing_response(session, listing)


@router.get("/{listing_id}/offers", response_model=List[DealerOfferResponse])
def get_offers_for_listing(
    listing_id: uuid.UUID,
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    """Sealed bidding: only the listing's owner (or an admin) sees offers. Highest price first."""
    item = session.get(SellListing, listing_id)
    if not item or not (
        item.customer_id == current_user_id(user_data) or user_data.get("role") in ADMIN_ROLES
    ):
        raise HTTPException(status_code=404, detail="Listing not found")
    offer_service.expire_due_offers(session)
    session.commit()
    offers = session.exec(
        select(DealerOffer)
        .where(DealerOffer.sell_listing_id == listing_id)
        .order_by(col(DealerOffer.offered_price).desc(), col(DealerOffer.created_at))
    ).all()
    return [offer_service.offer_response(session, o, item) for o in offers]
