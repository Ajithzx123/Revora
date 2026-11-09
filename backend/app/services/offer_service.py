"""Purchase offers on sell listings: submit, revise, withdraw, expire, accept, reject, admin void.

Statuses: PENDING (live) -> ACCEPTED | REJECTED | NOT_SELECTED | WITHDRAWN | EXPIRED | VOID_ADMIN
Accepting is atomic: conditional UPDATEs claim the offer and the listing, so two simultaneous
accepts cannot both win on any database. Bidding is sealed: dealers only ever see their own offers.
"""
import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import HTTPException
from sqlalchemy import update
from sqlmodel import Session, select

from backend.app.models.marketplace_models import Dealer, DealerOffer, OfferRevision, OfferRound, SellListing, SellMatch
from backend.app.schemas.marketplace_schema import (
    FINAL_REASON_CODES,
    DealerOfferCreate,
    DealerOfferResponse,
    FinalOfferCreate,
    OfferRevise,
    OfferRoundResponse,
)
from backend.app.services import audit_service, sell_service
from backend.app.services import notification_service as notifications

LIVE = {"PENDING"}
MAX_REVISIONS = 3
MAX_ROUNDS = 5             # counter-offers per offer, both sides together
ROUND_VALID = timedelta(hours=24)
BIG_DROP_PERCENT = 5       # a final offer lower by more than this needs evidence
SELLER_CHOSE_OTHER = "The seller chose another dealer"
SUSPENSION_REASON = "The dealer's account was suspended"


def _now() -> datetime:
    return datetime.utcnow()


def _lakh(amount: int) -> str:
    return f"Rs {amount / 100000:.2f} lakh"


def _title(listing: SellListing) -> str:
    return f"{listing.year} {listing.make} {listing.model}"


def rounds_of(session: Session, offer_id: uuid.UUID) -> list[OfferRound]:
    return list(session.exec(select(OfferRound).where(OfferRound.offer_id == offer_id).order_by(OfferRound.round_no)).all())


def offer_response(session: Session, offer: DealerOffer, listing: Optional[SellListing] = None) -> DealerOfferResponse:
    dealer = session.get(Dealer, offer.dealer_id)
    listing = listing or session.get(SellListing, offer.sell_listing_id)
    drop = None
    if offer.final_price is not None and offer.offered_price > 0:
        drop = round((offer.offered_price - offer.final_price) * 100 / offer.offered_price, 1)
    return DealerOfferResponse(
        id=offer.id, dealer_id=offer.dealer_id,
        dealer_name=dealer.business_name if dealer else "Dealer",
        dealer_rating=dealer.rating if dealer else None,
        sell_listing_id=offer.sell_listing_id, offered_price=offer.offered_price, message=offer.message,
        status=offer.status, created_at=offer.created_at, status_reason=offer.status_reason,
        revision=offer.revision, valid_until=offer.valid_until,
        inspection_required=offer.inspection_required, pickup_days=offer.pickup_days,
        # Declared by the seller: the buyer's price must allow for settling the loan.
        loan_settlement_required=bool(listing and listing.loan_outstanding),
        rounds=[
            OfferRoundResponse(id=r.id, round_no=r.round_no, by=r.by, price=r.price, note=r.note, status=r.status, valid_until=r.valid_until)
            for r in rounds_of(session, offer.id)
        ],
        final_status=offer.final_status, final_price=offer.final_price, final_drop_percent=drop,
        final_reason_code=offer.final_reason_code, final_reason_note=offer.final_reason_note,
        final_evidence=offer.final_evidence,
    )


def _notify_seller(session: Session, offer: DealerOffer, listing: SellListing, type: str, title: str, body: str, window: str = "") -> None:
    notifications.notify(session, listing.customer_id, type, title, body, entity_type="dealer_offer", entity_id=offer.id, window=window)


def _notify_dealer(session: Session, offer: DealerOffer, type: str, title: str, body: str, window: str = "") -> None:
    sell_service._notify_dealer(session, offer, type, title, body, window)


def _supersede_rounds(session: Session, offer_id: uuid.UUID) -> None:
    for r in rounds_of(session, offer_id):
        if r.status == "OPEN":
            r.status = "SUPERSEDED"
            session.add(r)


def _expire_one(session: Session, offer: DealerOffer) -> bool:
    if offer.status in LIVE and offer.valid_until is not None and offer.valid_until <= _now():
        offer.status, offer.status_reason, offer.updated_at = "EXPIRED", "The offer ran out of time", _now()
        session.add(offer)
        audit_service.record(session, None, "OFFER_EXPIRED", "dealer_offer", offer.id)
        return True
    return False


def expire_due_offers(session: Session, now: Optional[datetime] = None) -> int:
    now = now or _now()
    due = session.exec(select(DealerOffer).where(DealerOffer.status.in_(LIVE), DealerOffer.valid_until <= now)).all()
    count = sum(1 for o in due if _expire_one(session, o))
    return count + sell_service.expire_due_listings(session, now)


def my_match(session: Session, dealer: Dealer, listing_id: uuid.UUID) -> Optional[SellMatch]:
    return session.exec(
        select(SellMatch).where(SellMatch.listing_id == listing_id, SellMatch.dealer_id == dealer.id, SellMatch.dismissed_at.is_(None))
    ).first()


# ------------------------------------------------------------------ dealer actions
def submit(session: Session, dealer: Dealer, data: DealerOfferCreate) -> DealerOffer:
    listing = session.get(SellListing, data.sell_listing_id)
    if listing is None or my_match(session, dealer, data.sell_listing_id) is None:
        # A dealer sees only the listings they were matched to, so others look like they do not exist.
        raise HTTPException(404, "Listing not found or closed")
    if sell_service.expire_if_due(session, listing):
        session.commit()
    if listing.status != "ACTIVE":
        raise HTTPException(404, "Listing not found or closed")
    already = session.exec(
        select(DealerOffer).where(DealerOffer.dealer_id == dealer.id, DealerOffer.sell_listing_id == listing.id)
    ).first()
    if already is not None:
        raise HTTPException(409, "You have already made an offer on this listing")
    now = _now()
    offer = DealerOffer(
        dealer_id=dealer.id, sell_listing_id=listing.id, offered_price=data.offered_price, message=data.message,
        status="PENDING", valid_until=now + timedelta(hours=data.valid_hours),
        inspection_required=data.inspection_required, pickup_days=data.pickup_days, created_at=now,
    )
    session.add(offer)
    session.flush()
    audit_service.record(session, dealer.user_id, "OFFER_SUBMITTED", "dealer_offer", offer.id, detail=f"price {offer.offered_price}")
    _notify_seller(session, offer, listing, "OFFER_RECEIVED", "New offer received",
                   f"A dealer offered {_lakh(offer.offered_price)} for your {_title(listing)}.")
    return offer


def revise(session: Session, offer: DealerOffer, dealer: Dealer, body: OfferRevise) -> DealerOffer:
    if _expire_one(session, offer):
        session.commit()
        raise HTTPException(409, "This offer has expired. Send a new one from the listing.")
    if offer.status not in LIVE:
        raise HTTPException(409, f"A {offer.status.lower().replace('_', ' ')} offer cannot be revised")
    listing = session.get(SellListing, offer.sell_listing_id)
    if listing is None or listing.status != "ACTIVE":
        raise HTTPException(409, "This listing is no longer open")
    if offer.revision > MAX_REVISIONS:
        raise HTTPException(409, "An offer can be revised three times")
    session.add(OfferRevision(offer_id=offer.id, revision=offer.revision, price=offer.offered_price, message=offer.message))
    offer.revision += 1
    offer.offered_price, offer.message = body.offered_price, body.message
    if body.pickup_days is not None:
        offer.pickup_days = body.pickup_days
    offer.valid_until = _now() + timedelta(hours=body.valid_hours or 48)
    offer.updated_at = _now()
    session.add(offer)
    _supersede_rounds(session, offer.id)  # a new price replaces any counter still open
    audit_service.record(session, dealer.user_id, "OFFER_REVISED", "dealer_offer", offer.id, detail=f"revision {offer.revision}")
    _notify_seller(session, offer, listing, "OFFER_REVISED", "A dealer updated their offer",
                   f"New offer {_lakh(offer.offered_price)} for your {_title(listing)}.", window=str(offer.revision))
    return offer


def withdraw(session: Session, offer: DealerOffer, dealer: Dealer) -> DealerOffer:
    if offer.status == "ACCEPTED":
        raise HTTPException(409, "An accepted offer cannot be withdrawn. Contact support to cancel the deal.")
    if offer.status not in LIVE:
        raise HTTPException(409, f"A {offer.status.lower().replace('_', ' ')} offer cannot be withdrawn")
    offer.status, offer.updated_at = "WITHDRAWN", _now()
    session.add(offer)
    _supersede_rounds(session, offer.id)
    audit_service.record(session, dealer.user_id, "OFFER_WITHDRAWN", "dealer_offer", offer.id,
                         before={"status": "PENDING"}, after={"status": "WITHDRAWN"})
    listing = session.get(SellListing, offer.sell_listing_id)
    if listing is not None:
        _notify_seller(session, offer, listing, "OFFER_WITHDRAWN", "A dealer withdrew their offer",
                       "One of your offers is no longer available.")
    return offer


# ------------------------------------------------------------------ seller actions
def reject(session: Session, offer: DealerOffer, customer_id: uuid.UUID, reason: Optional[str]) -> DealerOffer:
    if offer.status not in LIVE:
        raise HTTPException(409, f"A {offer.status.lower().replace('_', ' ')} offer cannot be rejected")
    offer.status, offer.status_reason, offer.updated_at = "REJECTED", (reason or "").strip() or None, _now()
    session.add(offer)
    _supersede_rounds(session, offer.id)
    audit_service.record(session, customer_id, "OFFER_REJECTED", "dealer_offer", offer.id,
                         reason=offer.status_reason, before={"status": "PENDING"}, after={"status": "REJECTED"})
    return offer


def accept(session: Session, offer: DealerOffer, listing: SellListing, customer_id: uuid.UUID, expected_price: int) -> DealerOffer:
    """Accept one offer. Exactly one concurrent caller can succeed; the others get 409."""
    if offer.status == "ACCEPTED":
        return offer  # repeating the same accept is harmless
    if _expire_one(session, offer):
        session.commit()
        raise HTTPException(409, "This offer has expired")
    if offer.status != "PENDING":
        raise HTTPException(409, f"A {offer.status.lower().replace('_', ' ')} offer cannot be accepted")
    if listing.status == "FROZEN":
        raise HTTPException(409, "This listing is frozen by an administrator")
    if sell_service.expire_if_due(session, listing):
        session.commit()
        raise HTTPException(409, "This listing has expired")
    if offer.offered_price != expected_price:
        raise HTTPException(409, "The offer changed. Review the new price before accepting.")

    now = _now()
    claimed_offer = session.execute(
        update(DealerOffer)
        .where(DealerOffer.id == offer.id, DealerOffer.status == "PENDING", DealerOffer.offered_price == expected_price)
        .values(status="ACCEPTED", accepted_at=now, updated_at=now)
    ).rowcount
    claimed_listing = session.execute(
        update(SellListing)
        .where(SellListing.id == listing.id, SellListing.status == "ACTIVE")
        .values(status="OFFER_ACCEPTED", updated_at=now)
    ).rowcount if claimed_offer else 0
    if not (claimed_offer and claimed_listing):
        session.rollback()
        raise HTTPException(409, "This listing already has an accepted offer")

    _supersede_rounds(session, offer.id)
    others = session.exec(select(DealerOffer).where(DealerOffer.sell_listing_id == listing.id, DealerOffer.id != offer.id)).all()
    closed = 0
    for other in others:
        if other.status in LIVE:
            other.status, other.status_reason, other.updated_at = "NOT_SELECTED", SELLER_CHOSE_OTHER, now
            session.add(other)
            _supersede_rounds(session, other.id)
            closed += 1
            _notify_dealer(session, other, "OFFER_NOT_SELECTED", "Offer not selected",
                           f"The seller chose another dealer for the {_title(listing)}.")
    audit_service.record(
        session, customer_id, "OFFER_ACCEPTED", "dealer_offer", offer.id,
        detail=f"price {expected_price}; listing {listing.id}; {closed} other offers closed",
        before={"status": "PENDING"}, after={"status": "ACCEPTED", "offered_price": expected_price},
    )
    _notify_dealer(session, offer, "OFFER_ACCEPTED", "Your offer was accepted",
                   f"The seller accepted {_lakh(expected_price)} for the {_title(listing)}. Their contact details are now available.")
    return offer


# ------------------------------------------------------------------ admin
def void_by_admin(session: Session, offer: DealerOffer, admin_id: uuid.UUID, reason: str, cause: str = "ADMIN") -> None:
    """Void one live offer. The price and message are never touched. No commit."""
    if offer.status not in LIVE:
        raise HTTPException(409, f"A {offer.status.lower().replace('_', ' ')} offer cannot be voided")
    before = {"status": offer.status, "offered_price": offer.offered_price}
    offer.status, offer.status_reason, offer.void_cause, offer.updated_at = "VOID_ADMIN", reason, cause, _now()
    session.add(offer)
    _supersede_rounds(session, offer.id)
    audit_service.record(
        session, admin_id, "OFFER_VOIDED_BY_ADMIN", "dealer_offer", offer.id, reason=reason, detail=cause,
        before=before, after={"status": offer.status, "offered_price": offer.offered_price},
    )
    listing = session.get(SellListing, offer.sell_listing_id)
    if listing is not None:
        _notify_seller(session, offer, listing, "OFFER_VOIDED", "An offer is no longer available", "An administrator closed one of your offers.")
    if cause == "ADMIN":
        _notify_dealer(session, offer, "OFFER_VOIDED", "Your offer was voided", f"An administrator voided your offer. Reason: {reason}")


def void_live_offers_of_dealer(session: Session, dealer: Dealer, admin_id: uuid.UUID) -> int:
    offers = session.exec(select(DealerOffer).where(DealerOffer.dealer_id == dealer.id)).all()
    live = [o for o in offers if o.status in LIVE]
    for o in live:
        void_by_admin(session, o, admin_id, SUSPENSION_REASON, cause="DEALER_SUSPENDED")
    return len(live)


def restore_after_reactivation(session: Session, dealer: Dealer, admin_id: uuid.UUID) -> int:
    """Bring back offers voided by the suspension, but only those still valid on a still-open listing."""
    offers = session.exec(
        select(DealerOffer).where(
            DealerOffer.dealer_id == dealer.id, DealerOffer.status == "VOID_ADMIN", DealerOffer.void_cause == "DEALER_SUSPENDED"
        )
    ).all()
    now, restored = _now(), 0
    for o in offers:
        listing = session.get(SellListing, o.sell_listing_id)
        still_open = listing is not None and sell_service.is_live(listing, now)
        in_date = o.valid_until is None or o.valid_until > now
        before = {"status": o.status}
        if still_open and in_date:
            o.status, o.status_reason = "PENDING", None
            restored += 1
        elif listing is not None and listing.status == "OFFER_ACCEPTED":
            o.status, o.status_reason = "NOT_SELECTED", "The seller chose another dealer"
        else:
            o.status, o.status_reason = "EXPIRED", "Not restored after reactivation: no longer valid"
        o.void_cause, o.updated_at = None, now
        session.add(o)
        audit_service.record(
            session, admin_id, "OFFER_RESTORED_AFTER_REACTIVATION" if o.status == "PENDING" else "OFFER_NOT_RESTORED",
            "dealer_offer", o.id, before=before, after={"status": o.status},
        )
    return restored


# ------------------------------------------------------------------ negotiation (seller <-> dealer)
def _open_round(session: Session, offer_id: uuid.UUID) -> Optional[OfferRound]:
    return session.exec(
        select(OfferRound).where(OfferRound.offer_id == offer_id, OfferRound.status == "OPEN", OfferRound.valid_until > _now())
    ).first()


def _negotiable(session: Session, offer: DealerOffer) -> SellListing:
    """A live offer on an open listing; raises 409 otherwise."""
    if _expire_one(session, offer):
        session.commit()
        raise HTTPException(409, "This offer has expired")
    if offer.status not in LIVE:
        raise HTTPException(409, "Only a live offer can be negotiated")
    listing = session.get(SellListing, offer.sell_listing_id)
    if listing is None or listing.status != "ACTIVE":
        raise HTTPException(409, "This listing is no longer open")
    return listing


def counter_by_seller(session: Session, offer: DealerOffer, customer_id: uuid.UUID, price: int, note: Optional[str]) -> OfferRound:
    """The seller asks for more than the offered price."""
    listing = _negotiable(session, offer)
    if price <= offer.offered_price:
        raise HTTPException(422, "A counter-offer must be higher than the offered price")
    if _open_round(session, offer.id) is not None:
        raise HTTPException(409, "A counter-offer is already waiting for a reply")
    count = len(rounds_of(session, offer.id))
    if count >= MAX_ROUNDS:
        raise HTTPException(409, "The negotiation limit for this offer has been reached")
    rnd = OfferRound(offer_id=offer.id, round_no=count + 1, by="SELLER", price=price, note=note, valid_until=_now() + ROUND_VALID)
    session.add(rnd)
    audit_service.record(session, customer_id, "OFFER_COUNTER_BY_SELLER", "dealer_offer", offer.id, detail=f"{price}")
    _notify_dealer(session, offer, "OFFER_COUNTER_RECEIVED", "Counter-offer from a seller",
                   f"The seller asked {_lakh(price)} against your {_lakh(offer.offered_price)} offer for the {_title(listing)}.", window=str(rnd.id))
    return rnd


def _agree(session: Session, offer: DealerOffer, rnd: OfferRound, actor: uuid.UUID) -> None:
    session.add(OfferRevision(offer_id=offer.id, revision=offer.revision, price=offer.offered_price, message=offer.message))
    offer.revision += 1
    offer.offered_price = rnd.price
    offer.updated_at = _now()
    session.add(offer)
    rnd.status = "AGREED"
    session.add(rnd)
    audit_service.record(session, actor, "OFFER_PRICE_AGREED", "dealer_offer", offer.id, detail=f"{rnd.price}")


def reply(session: Session, offer: DealerOffer, actor_id: uuid.UUID, side: str, action: str, price: Optional[int], note: Optional[str]) -> OfferRound:
    """The other side answers the open counter-offer. `side` is who is answering (SELLER or DEALER)."""
    listing = _negotiable(session, offer)
    rnd = _open_round(session, offer.id)
    if rnd is None or rnd.by == side:
        raise HTTPException(409, "There is no counter-offer waiting for your reply")
    notify_other = (lambda *a, **k: _notify_dealer(session, offer, *a, **k)) if side == "SELLER" else (
        lambda *a, **k: _notify_seller(session, offer, listing, *a, **k)
    )
    if action == "ACCEPT":
        _agree(session, offer, rnd, actor_id)
        notify_other("OFFER_COUNTER_ACCEPTED", "Counter-offer accepted", f"The price is now {_lakh(offer.offered_price)}.", window=str(rnd.id))
    elif action == "DECLINE":
        rnd.status = "DECLINED"
        session.add(rnd)
        audit_service.record(session, actor_id, f"OFFER_COUNTER_DECLINED_BY_{side}", "dealer_offer", offer.id)
        notify_other("OFFER_COUNTER_DECLINED", "Counter-offer declined", "Your counter-offer was declined. The offered price stands.", window=str(rnd.id))
    else:  # COUNTER
        if side == "SELLER":
            raise HTTPException(422, "Decline or accept, or send a new counter-offer")
        if price is None or not (offer.offered_price < price < rnd.price):
            raise HTTPException(422, "Your counter must be above your offer and below the seller's ask")
        count = len(rounds_of(session, offer.id))
        if count >= MAX_ROUNDS:
            raise HTTPException(409, "The negotiation limit for this offer has been reached")
        rnd.status = "COUNTERED"
        session.add(rnd)
        new = OfferRound(offer_id=offer.id, round_no=count + 1, by=side, price=price, note=note, valid_until=_now() + ROUND_VALID)
        session.add(new)
        audit_service.record(session, actor_id, "OFFER_COUNTER_BY_DEALER", "dealer_offer", offer.id, detail=f"{price}")
        notify_other("OFFER_COUNTER_RECEIVED", "A dealer countered your ask", f"The dealer's counter is {_lakh(price)}.", window=str(new.id))
        rnd = new
    return rnd


# ------------------------------------------------------------------ inspection: the final offer
def submit_final(session: Session, offer: DealerOffer, dealer: Dealer, data: FinalOfferCreate) -> DealerOffer:
    """After the seller accepts, the dealer inspects the car and confirms or lowers the price.
    The same price is confirmed at once. A lower one needs a reason code, and a drop of more than
    5% also needs evidence. The seller may decline it for free."""
    listing = session.get(SellListing, offer.sell_listing_id)
    if offer.status != "ACCEPTED" or listing is None or listing.status != "OFFER_ACCEPTED":
        raise HTTPException(409, "A final offer follows an accepted offer")
    if not offer.inspection_required:
        raise HTTPException(409, "This offer is not subject to inspection")
    if offer.final_status is not None:
        raise HTTPException(409, "A final offer was already sent")
    if data.price > offer.offered_price:
        raise HTTPException(422, "A final offer cannot be higher than the accepted offer")

    now = _now()
    drop = (offer.offered_price - data.price) * 100 / offer.offered_price
    if data.price < offer.offered_price:
        if data.reason_code is None:
            raise HTTPException(422, f"A reason is required when the price drops: {', '.join(FINAL_REASON_CODES)}")
        if drop > BIG_DROP_PERCENT and not data.evidence_urls:
            raise HTTPException(422, f"A drop of more than {BIG_DROP_PERCENT}% needs evidence (photos or a report link)")

    offer.final_price, offer.final_submitted_at, offer.updated_at = data.price, now, now
    offer.final_reason_code = data.reason_code if data.price < offer.offered_price else None
    offer.final_reason_note = data.reason_note
    offer.final_evidence_csv = ",".join(data.evidence_urls)
    same = data.price == offer.offered_price
    offer.final_status = "ACCEPTED" if same else "SUBMITTED"
    if same:
        offer.final_decided_at = now
        listing.status, listing.updated_at = "FINAL_ACCEPTED", now
        session.add(listing)
    session.add(offer)
    audit_service.record(
        session, dealer.user_id, "OFFER_FINAL_CONFIRMED" if same else "OFFER_FINAL_SUBMITTED", "dealer_offer", offer.id,
        reason=offer.final_reason_code, detail=f"drop {drop:.1f}%",
        before={"price": offer.offered_price}, after={"price": data.price, "final_status": offer.final_status},
    )
    if drop > BIG_DROP_PERCENT:
        # Repeated large drops across many sellers are the bait-and-switch pattern admins look for.
        audit_service.record(session, dealer.user_id, "OFFER_FINAL_LARGE_DROP", "dealer_offer", offer.id, detail=f"{drop:.1f}%")
    if same:
        _notify_seller(session, offer, listing, "FINAL_OFFER_RECEIVED", "Final price confirmed",
                       f"After inspection the dealer confirmed {_lakh(data.price)} for your {_title(listing)}.", window="final")
    else:
        label = (offer.final_reason_code or "").replace("_", " ").lower()
        _notify_seller(session, offer, listing, "FINAL_OFFER_RECEIVED", "Final offer is lower",
                       f"After inspection the dealer offers {_lakh(data.price)}, {_lakh(offer.offered_price - data.price)} lower. Reason: {label}. You can decline for free.",
                       window="final")
    return offer


def respond_final(session: Session, offer: DealerOffer, customer_id: uuid.UUID, action: str) -> DealerOffer:
    """The seller accepts the lowered price, or declines it for free (the listing reopens)."""
    listing = session.get(SellListing, offer.sell_listing_id)
    if listing is None:
        raise HTTPException(404, "Offer not found")
    wanted = "ACCEPTED" if action == "ACCEPT" else "DECLINED"
    if offer.final_status == wanted:
        return offer  # repeating the same answer is harmless
    if offer.final_status != "SUBMITTED":
        raise HTTPException(409, "There is no final offer waiting for your answer")

    now = _now()
    claimed = session.execute(
        update(DealerOffer)
        .where(DealerOffer.id == offer.id, DealerOffer.final_status == "SUBMITTED")
        .values(final_status=wanted, final_decided_at=now, updated_at=now)
    ).rowcount
    if not claimed:
        session.rollback()
        raise HTTPException(409, "The final offer was already answered")
    if action == "ACCEPT":
        session.execute(update(SellListing).where(SellListing.id == listing.id).values(status="FINAL_ACCEPTED", updated_at=now))
        audit_service.record(session, customer_id, "OFFER_FINAL_ACCEPTED", "dealer_offer", offer.id,
                             before={"final_status": "SUBMITTED"}, after={"final_status": "ACCEPTED", "price": offer.final_price})
        _notify_dealer(session, offer, "FINAL_OFFER_ACCEPTED", "Final offer accepted",
                       f"The seller accepted {_lakh(offer.final_price or 0)} for the {_title(listing)}.")
        return offer

    # Declined: no penalty. The offer closes, the listing reopens and other still-valid offers come back.
    session.execute(
        update(DealerOffer).where(DealerOffer.id == offer.id)
        .values(status="REJECTED", status_reason="The seller declined the price after inspection")
    )
    session.execute(update(SellListing).where(SellListing.id == listing.id).values(status="ACTIVE", updated_at=now))
    audit_service.record(session, customer_id, "OFFER_FINAL_DECLINED", "dealer_offer", offer.id,
                         before={"final_status": "SUBMITTED"}, after={"final_status": "DECLINED"})
    _notify_dealer(session, offer, "FINAL_OFFER_DECLINED", "Final offer declined",
                   f"The seller declined the revised price for the {_title(listing)}. No penalty applies.")
    session.flush()
    session.refresh(listing)
    reopened = 0
    for other in session.exec(
        select(DealerOffer).where(
            DealerOffer.sell_listing_id == listing.id, DealerOffer.id != offer.id,
            DealerOffer.status == "NOT_SELECTED", DealerOffer.status_reason == SELLER_CHOSE_OTHER,
        )
    ).all():
        if other.valid_until is not None and other.valid_until > now:
            other.status, other.status_reason, other.updated_at = "PENDING", None, now
            session.add(other)
            reopened += 1
            _notify_dealer(session, other, "OFFER_REOPENED", "Your offer is open again",
                           f"The seller's first choice fell through, so your offer for the {_title(listing)} is live again.")
    sell_service.expire_if_due(session, listing)  # the window may have ended while inspecting
    return offer
