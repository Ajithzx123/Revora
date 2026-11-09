"""Purchase offers: the dealer's own list and changes, and the seller's accept/reject.
Submitting an offer is POST /offers in dealer_api (kept at its original path)."""
import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, col, select

from backend.app.core.dependencies import current_user_id, require_customer, require_verified_dealer
from backend.app.database.session import get_session
from backend.app.models.marketplace_models import Dealer, DealerOffer, SellListing
from backend.app.models.user_model import User
from backend.app.schemas.marketplace_schema import (
    AcceptOffer,
    CounterCreate,
    DealerOfferResponse,
    FinalOfferCreate,
    FinalOfferRespond,
    MyOfferResponse,
    NegotiationReply,
    OfferRevise,
    ReasonOptional,
)
from backend.app.services import offer_service as svc
from backend.app.services import sell_service

router = APIRouter(prefix="/offers", tags=["Purchase Offers"])


def _dealers_offer(session: Session, dealer: Dealer, offer_id: uuid.UUID) -> DealerOffer:
    offer = session.get(DealerOffer, offer_id)
    if offer is None or offer.dealer_id != dealer.id:
        raise HTTPException(404, "Offer not found")
    return offer


def _sellers_offer(session: Session, user_data: dict, offer_id: uuid.UUID):
    offer = session.get(DealerOffer, offer_id)
    listing = session.get(SellListing, offer.sell_listing_id) if offer else None
    if offer is None or listing is None or listing.customer_id != current_user_id(user_data):
        raise HTTPException(404, "Offer not found")
    return offer, listing


def _title(l: SellListing) -> str:
    return f"{l.year} {l.make} {l.model}"


# ---------------------------------------------------------------- dealer
@router.get("/mine", response_model=List[MyOfferResponse])
def my_offers(dealer: Dealer = Depends(require_verified_dealer), session: Session = Depends(get_session)):
    """The dealer's own offers, newest first. The seller's contact is released only once accepted."""
    svc.expire_due_offers(session)
    session.commit()
    offers = session.exec(
        select(DealerOffer).where(DealerOffer.dealer_id == dealer.id).order_by(col(DealerOffer.created_at).desc())
    ).all()
    out = []
    for o in offers:
        listing = session.get(SellListing, o.sell_listing_id)
        seller = session.get(User, listing.customer_id) if listing else None
        accepted = o.status == "ACCEPTED"
        out.append(
            MyOfferResponse(
                **svc.offer_response(session, o, listing).model_dump(),
                listing_title=_title(listing) if listing else "",
                listing_city=listing.city if listing else "",
                listing_status=listing.status if listing else "",
                seller_first_name=(seller.name.split()[0] if seller and seller.name else "Seller"),
                seller_name=seller.name if (accepted and seller) else None,
                seller_phone=seller.phone if (accepted and seller) else None,
            )
        )
    return out


@router.put("/{offer_id}", response_model=DealerOfferResponse)
def revise_offer(
    offer_id: uuid.UUID,
    body: OfferRevise,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    offer = _dealers_offer(session, dealer, offer_id)
    svc.revise(session, offer, dealer, body)
    session.commit()
    session.refresh(offer)
    return svc.offer_response(session, offer)


@router.post("/{offer_id}/withdraw", response_model=DealerOfferResponse)
def withdraw_offer(
    offer_id: uuid.UUID,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    offer = _dealers_offer(session, dealer, offer_id)
    svc.withdraw(session, offer, dealer)
    session.commit()
    session.refresh(offer)
    return svc.offer_response(session, offer)


# ---------------------------------------------------------------- seller
@router.post("/{offer_id}/accept", response_model=DealerOfferResponse)
def accept_offer(
    offer_id: uuid.UUID,
    body: AcceptOffer,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    offer, listing = _sellers_offer(session, user_data, offer_id)
    svc.accept(session, offer, listing, current_user_id(user_data), body.expected_price)
    session.commit()
    session.refresh(offer)
    return svc.offer_response(session, offer, listing)


@router.post("/{offer_id}/reject", response_model=DealerOfferResponse)
def reject_offer(
    offer_id: uuid.UUID,
    body: ReasonOptional,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    offer, listing = _sellers_offer(session, user_data, offer_id)
    svc.reject(session, offer, current_user_id(user_data), body.reason)
    session.commit()
    session.refresh(offer)
    return svc.offer_response(session, offer, listing)


@router.post("/{offer_id}/counter", response_model=DealerOfferResponse)
def counter_offer(
    offer_id: uuid.UUID,
    body: CounterCreate,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    """The seller asks for more. The dealer has 24 hours to answer; at most 5 rounds per offer."""
    offer, listing = _sellers_offer(session, user_data, offer_id)
    svc.counter_by_seller(session, offer, current_user_id(user_data), body.price, body.note)
    session.commit()
    session.refresh(offer)
    return svc.offer_response(session, offer, listing)


@router.post("/{offer_id}/negotiation/respond", response_model=DealerOfferResponse)
def seller_negotiation_reply(
    offer_id: uuid.UUID,
    body: NegotiationReply,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    """The seller answers the dealer's counter: ACCEPT or DECLINE."""
    offer, listing = _sellers_offer(session, user_data, offer_id)
    svc.reply(session, offer, current_user_id(user_data), "SELLER", body.action, body.price, body.note)
    session.commit()
    session.refresh(offer)
    return svc.offer_response(session, offer, listing)


@router.post("/{offer_id}/negotiation", response_model=DealerOfferResponse)
def dealer_negotiation_reply(
    offer_id: uuid.UUID,
    body: NegotiationReply,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    """The dealer answers the seller's counter: ACCEPT, DECLINE, or COUNTER with a price in between."""
    offer = _dealers_offer(session, dealer, offer_id)
    svc.reply(session, offer, dealer.user_id, "DEALER", body.action, body.price, body.note)
    session.commit()
    session.refresh(offer)
    return svc.offer_response(session, offer)


@router.post("/{offer_id}/final", response_model=DealerOfferResponse)
def submit_final_offer(
    offer_id: uuid.UUID,
    body: FinalOfferCreate,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    """After inspection, confirm the accepted price or lower it (reason, and evidence if over 5%)."""
    offer = _dealers_offer(session, dealer, offer_id)
    svc.submit_final(session, offer, dealer, body)
    session.commit()
    session.refresh(offer)
    return svc.offer_response(session, offer)


@router.post("/{offer_id}/final/respond", response_model=DealerOfferResponse)
def respond_to_final_offer(
    offer_id: uuid.UUID,
    body: FinalOfferRespond,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    """Accept the final price, or decline it for free: the listing reopens."""
    offer, listing = _sellers_offer(session, user_data, offer_id)
    svc.respond_final(session, offer, current_user_id(user_data), body.action)
    session.commit()
    session.refresh(offer)
    session.refresh(listing)
    return svc.offer_response(session, offer, listing)
