"""Sell listings: creating, matching dealers, expiry, price changes, closing, admin freeze.

Statuses: ACTIVE (open for offers) -> OFFER_ACCEPTED | CLOSED | EXPIRED | FROZEN (admin)
The only place a listing's status changes, apart from offer acceptance (offer_service).
"""
import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import HTTPException
from sqlmodel import Session, func, select

from backend.app.core import master_data as md
from backend.app.models.marketplace_models import Dealer, DealerOffer, DealerStatus, SellListing, SellMatch
from backend.app.schemas.marketplace_schema import SellListingCreate, SellListingResponse
from backend.app.services import audit_service
from backend.app.services import notification_service as notifications

SELL_MATCH_CAP = 10          # dealers shown one listing
BUY_RADIUS_KM = 150          # how far a dealer is matched from the listing's city
WINDOWS = {"URGENT": timedelta(days=2), "NORMAL": timedelta(days=14), "MAX_PRICE": timedelta(days=5)}
LIVE_OFFER = {"PENDING"}


def _now() -> datetime:
    return datetime.utcnow()


def _title(listing: SellListing) -> str:
    return f"{listing.year} {listing.make} {listing.model}"


def listing_response(session: Session, listing: SellListing) -> SellListingResponse:
    count = session.exec(
        select(func.count()).select_from(DealerOffer).where(DealerOffer.sell_listing_id == listing.id)
    ).one()
    return SellListingResponse(
        id=listing.id, customer_id=listing.customer_id, make=listing.make, model=listing.model,
        year=listing.year, fuel=listing.fuel, transmission=listing.transmission, km=listing.km,
        expected_price=listing.expected_price, city=listing.city,
        images=[i for i in listing.images_csv.split(",") if i], status=listing.status,
        created_at=listing.created_at, offer_count=count, variant=listing.variant, owners=listing.owners,
        color=listing.color, urgency=listing.urgency, loan_outstanding=listing.loan_outstanding,
        loan_amount=listing.loan_amount, challans_amount=listing.challans_amount,
        insurance_valid=listing.insurance_valid, description=listing.description,
        expires_at=listing.expires_at, status_reason=listing.status_reason,
    )


def live_offers(session: Session, listing_id: uuid.UUID) -> list[DealerOffer]:
    return list(
        session.exec(
            select(DealerOffer).where(DealerOffer.sell_listing_id == listing_id, DealerOffer.status.in_(LIVE_OFFER))
        ).all()
    )


def _notify_dealer(session: Session, offer: DealerOffer, type: str, title: str, body: str, window: str = "") -> None:
    dealer = session.get(Dealer, offer.dealer_id)
    if dealer is not None:
        notifications.notify(session, dealer.user_id, type, title, body, entity_type="dealer_offer", entity_id=offer.id, window=window)


# ------------------------------------------------------------------ create + match
def create_listing(session: Session, customer_id: uuid.UUID, data: SellListingCreate) -> SellListing:
    """Persists the listing, matches dealers and records the audit event. Does not commit."""
    now = _now()
    listing = SellListing(
        customer_id=customer_id, make=data.make, model=data.model, year=data.year, fuel=data.fuel,
        transmission=data.transmission, km=data.km, expected_price=data.expected_price, city=data.city,
        images_csv=",".join(data.images), status="ACTIVE", variant=data.variant, owners=data.owners,
        color=data.color, urgency=data.urgency, loan_outstanding=data.loan_outstanding,
        loan_amount=data.loan_amount, challans_amount=data.challans_amount,
        insurance_valid=data.insurance_valid, description=data.description,
        expires_at=now + WINDOWS[data.urgency], created_at=now,
    )
    session.add(listing)
    session.flush()
    audit_service.record(
        session, customer_id, "SELL_LISTING_CREATED", "sell_listing", listing.id,
        detail=_title(listing), after={"status": "ACTIVE", "expected_price": listing.expected_price},
    )
    match_listing(session, listing, now)
    return listing


def is_live(listing: SellListing, now: datetime) -> bool:
    return listing.status == "ACTIVE" and (listing.expires_at is None or listing.expires_at > now)


def _distance_reason(listing: SellListing, dealer: Dealer, distance: float) -> str:
    return f"In {listing.city}" if dealer.city == listing.city else f"{round(distance)} km away in {dealer.city}"


def match_listing(session: Session, listing: SellListing, now: Optional[datetime] = None) -> list[SellMatch]:
    """Shows the listing to up to 10 verified dealers who buy this make and are within range.
    Safe to repeat: a dealer is never matched twice and the cap counts existing matches. No commit."""
    now = now or _now()
    if not is_live(listing, now):
        return []
    existing = session.exec(select(SellMatch).where(SellMatch.listing_id == listing.id)).all()
    room = SELL_MATCH_CAP - len(existing)
    if room <= 0:
        return []
    matched = {m.dealer_id for m in existing}
    candidates = []
    for dealer in session.exec(select(Dealer).where(Dealer.status == DealerStatus.APPROVED)).all():
        if dealer.id in matched or listing.make not in dealer.buy_makes:
            continue
        distance = md.distance_km(dealer.city, listing.city)
        if distance <= BUY_RADIUS_KM:
            candidates.append((distance, dealer.created_at, str(dealer.id), dealer))
    candidates.sort(key=lambda c: c[:3])

    created: list[SellMatch] = []
    for distance, _, _, dealer in candidates[:room]:
        match = SellMatch(
            listing_id=listing.id, dealer_id=dealer.id, created_at=now,
            score=max(10, 100 - round(60 * distance / BUY_RADIUS_KM)),
            reasons_csv="|".join([f"Buys {listing.make}", _distance_reason(listing, dealer, distance)]),
        )
        session.add(match)
        created.append(match)
        notifications.notify(
            session, dealer.user_id, "SELL_LEAD", "New car to buy",
            f"A seller in {listing.city} is selling a {_title(listing)}.",
            entity_type="sell_listing", entity_id=listing.id, now=now,
        )
    if created:
        session.flush()
        total = len(existing) + len(created)
        audit_service.record(
            session, None, "SELL_LISTING_MATCHED", "sell_listing", listing.id, detail=f"{len(created)} new dealers"
        )
        notifications.notify(
            session, listing.customer_id, "SELL_MATCHES_FOUND", "Dealers have been notified",
            f"{total} verified dealer{'s' if total != 1 else ''} can see your {_title(listing)}.",
            entity_type="sell_listing", entity_id=listing.id, window=str(total), now=now,
        )
    return created


def rematch_open_listings(session: Session) -> int:
    now = _now()
    listings = session.exec(select(SellListing).where(SellListing.status == "ACTIVE")).all()
    return sum(len(match_listing(session, l, now)) for l in listings)


# ------------------------------------------------------------------ expiry
def expire_if_due(session: Session, listing: SellListing, now: Optional[datetime] = None) -> bool:
    """Lazily expires an open listing past its window. Returns True if it expired. No commit."""
    now = now or _now()
    if listing.status != "ACTIVE" or listing.expires_at is None or listing.expires_at > now:
        return False
    listing.status, listing.status_reason, listing.updated_at = "EXPIRED", "The offer window ended", now
    session.add(listing)
    for offer in live_offers(session, listing.id):
        offer.status, offer.status_reason, offer.updated_at = "EXPIRED", "The listing expired", now
        session.add(offer)
    audit_service.record(
        session, None, "SELL_LISTING_EXPIRED", "sell_listing", listing.id,
        before={"status": "ACTIVE"}, after={"status": "EXPIRED"},
    )
    return True


def expire_due_listings(session: Session, now: Optional[datetime] = None) -> int:
    now = now or _now()
    due = session.exec(select(SellListing).where(SellListing.status == "ACTIVE", SellListing.expires_at <= now)).all()
    return sum(1 for l in due if expire_if_due(session, l, now))


# ------------------------------------------------------------------ seller actions
def change_price(session: Session, listing: SellListing, customer_id: uuid.UUID, new_price: int) -> SellListing:
    """The seller revises the asking price. Existing offers stay valid; dealers with live ones are told."""
    if listing.status != "ACTIVE":
        raise HTTPException(409, "Only an open listing can be changed")
    if new_price == listing.expected_price:
        return listing
    before = listing.expected_price
    listing.expected_price, listing.updated_at = new_price, _now()
    session.add(listing)
    audit_service.record(
        session, customer_id, "SELL_LISTING_PRICE_CHANGED", "sell_listing", listing.id,
        before={"expected_price": before}, after={"expected_price": new_price},
    )
    for offer in live_offers(session, listing.id):
        _notify_dealer(
            session, offer, "LISTING_PRICE_CHANGED", "Seller changed the asking price",
            f"The seller of the {_title(listing)} updated their expected price. Your offer is still valid.",
            window=str(new_price),
        )
    return listing


def close(session: Session, listing: SellListing, customer_id: uuid.UUID, reason: Optional[str], sold_elsewhere: bool) -> SellListing:
    """The seller closes the listing (or says it sold elsewhere). Live offers become NOT_SELECTED;
    dealers are told the listing closed and nothing about why or to whom."""
    if listing.status != "ACTIVE":
        raise HTTPException(409, "Only an open listing can be closed")
    now = _now()
    reason = (reason or "").strip() or ("Sold elsewhere" if sold_elsewhere else None)
    listing.status, listing.status_reason, listing.updated_at = "CLOSED", reason, now
    session.add(listing)
    audit_service.record(
        session, customer_id, "SELL_LISTING_SOLD_ELSEWHERE" if sold_elsewhere else "SELL_LISTING_CLOSED",
        "sell_listing", listing.id, reason=reason, before={"status": "ACTIVE"}, after={"status": "CLOSED"},
    )
    for offer in live_offers(session, listing.id):
        offer.status, offer.status_reason, offer.updated_at = "NOT_SELECTED", "The seller closed the listing", now
        session.add(offer)
        _notify_dealer(session, offer, "LISTING_CLOSED", "Listing closed", f"The {_title(listing)} is no longer for sale.")
    return listing


# ------------------------------------------------------------------ admin
def freeze(session: Session, listing: SellListing, admin_id: uuid.UUID, reason: str) -> SellListing:
    """Admin freeze (e.g. a stolen-vehicle report). No new offers and no acceptance until unfrozen."""
    if listing.status != "ACTIVE":
        raise HTTPException(409, "Only an open listing can be frozen")
    listing.status, listing.status_reason, listing.updated_at = "FROZEN", reason, _now()
    session.add(listing)
    audit_service.record(
        session, admin_id, "SELL_LISTING_FROZEN", "sell_listing", listing.id,
        reason=reason, before={"status": "ACTIVE"}, after={"status": "FROZEN"},
    )
    return listing


def unfreeze(session: Session, listing: SellListing, admin_id: uuid.UUID) -> SellListing:
    if listing.status != "FROZEN":
        raise HTTPException(409, "The listing is not frozen")
    listing.status, listing.status_reason, listing.updated_at = "ACTIVE", None, _now()
    session.add(listing)
    audit_service.record(
        session, admin_id, "SELL_LISTING_UNFROZEN", "sell_listing", listing.id,
        before={"status": "FROZEN"}, after={"status": "ACTIVE"},
    )
    expire_if_due(session, listing)
    return listing
