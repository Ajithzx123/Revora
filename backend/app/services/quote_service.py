"""Quote lifecycle: submit, revise, withdraw, expire, negotiate, accept.

Statuses: PENDING (live) -> ACCEPTED | REJECTED | NOT_SELECTED | WITHDRAWN | EXPIRED | UNAVAILABLE
          REQUOTE_REQUESTED (buyer changed the request; dealer must revise) -> PENDING
Accepting is atomic: conditional UPDATEs claim the quote and the request, so two simultaneous
accepts cannot both win on any database.
"""
import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import HTTPException
from sqlalchemy import update
from sqlmodel import Session, select

from backend.app.models.marketplace_models import (
    BuyRequirement,
    Dealer,
    DealerQuote,
    MatchRecord,
    QuoteRevision,
    QuoteRound,
    RequirementStatus,
    Vehicle,
    VehicleMedia,
    VehicleStatus,
)
from backend.app.schemas.marketplace_schema import DealerQuoteResponse, QuoteRoundResponse
from backend.app.services import audit_service
from backend.app.services import notification_service as notifications

LIVE = {"PENDING", "REQUOTE_REQUESTED"}
MAX_REVISIONS = 3          # a quote may be revised three times (four prices in all)
MAX_ROUNDS = 5             # counter-offers per quote, both sides together
ROUND_VALID = timedelta(hours=24)


def _now() -> datetime:
    return datetime.utcnow()


def audit(session: Session, actor: Optional[uuid.UUID], action: str, quote: DealerQuote, detail: str = "") -> None:
    audit_service.record(session, actor, action, "dealer_quote", quote.id, detail=detail or None)


# ------------------------------------------------------------ views
def _car_name(req: BuyRequirement) -> str:
    return f"{req.make} {req.model}" if req.model else req.make


def _lakh(amount: int) -> str:
    return f"Rs {amount / 100000:.2f} lakh"


def notify_buyer(session: Session, quote: DealerQuote, type: str, title: str, body: str, window: str = "") -> None:
    req = session.get(BuyRequirement, quote.requirement_id)
    if req is not None:
        notifications.notify(session, req.customer_id, type, title, body, entity_type="dealer_quote", entity_id=quote.id, window=window)


def notify_dealer(session: Session, quote: DealerQuote, type: str, title: str, body: str, window: str = "") -> None:
    dealer = session.get(Dealer, quote.dealer_id)
    if dealer is not None:
        notifications.notify(session, dealer.user_id, type, title, body, entity_type="dealer_quote", entity_id=quote.id, window=window)


def kind_for(session: Session, dealer: Dealer, requirement_id: uuid.UUID) -> str:
    match = session.exec(
        select(MatchRecord).where(MatchRecord.dealer_id == dealer.id, MatchRecord.requirement_id == requirement_id)
    ).first()
    return {1: "IN_STOCK", 2: "ALTERNATIVE", 3: "SOURCED"}.get(match.tier if match else 1, "IN_STOCK")


def rounds_of(session: Session, quote_id: uuid.UUID) -> list[QuoteRound]:
    return list(session.exec(select(QuoteRound).where(QuoteRound.quote_id == quote_id).order_by(QuoteRound.round_no)).all())


def quote_response(session: Session, quote: DealerQuote, *, with_rounds: bool = True) -> DealerQuoteResponse:
    dealer = session.get(Dealer, quote.dealer_id)
    car = session.get(Vehicle, quote.vehicle_id) if quote.vehicle_id else None
    cover = None
    if car is not None:
        cover = session.exec(
            select(VehicleMedia).where(VehicleMedia.vehicle_id == car.id).order_by(VehicleMedia.position)
        ).first()
    return DealerQuoteResponse(
        id=quote.id,
        dealer_id=quote.dealer_id,
        dealer_name=dealer.business_name if dealer else "Dealer",
        dealer_rating=dealer.rating if dealer else None,
        requirement_id=quote.requirement_id,
        vehicle_id=quote.vehicle_id,
        quoted_price=quote.quoted_price,
        message=quote.message,
        status=quote.status,
        created_at=quote.created_at,
        status_reason=quote.status_reason,
        kind=quote.kind,
        revision=quote.revision,
        valid_until=quote.valid_until,
        delivery_days=quote.delivery_days,
        warranty_months=quote.warranty_months,
        vehicle_title=f"{car.year} {car.make} {car.model}" if car else None,
        vehicle_year=car.year if car else None,
        vehicle_km=car.km if car else None,
        vehicle_fuel=car.fuel if car else None,
        vehicle_transmission=car.transmission if car else None,
        vehicle_image_url=f"/api/media/{cover.id}" if cover else None,
        list_price=car.price if car else None,
        rounds=[
            QuoteRoundResponse(id=r.id, round_no=r.round_no, by=r.by, price=r.price, note=r.note, status=r.status, valid_until=r.valid_until)
            for r in rounds_of(session, quote.id)
        ]
        if with_rounds
        else [],
    )


# ------------------------------------------------------------ expiry
def expire_due_quotes(session: Session, now: Optional[datetime] = None) -> int:
    """Mark live quotes past `valid_until` as expired, and lapse their open counters. No commit."""
    now = now or _now()
    due = session.exec(select(DealerQuote).where(DealerQuote.status.in_(LIVE), DealerQuote.valid_until <= now)).all()
    for quote in due:
        quote.status = "EXPIRED"
        quote.status_reason = "Validity ended"
        session.add(quote)
        for r in rounds_of(session, quote.id):
            if r.status == "OPEN":
                r.status = "EXPIRED"
                session.add(r)
        audit(session, None, "QUOTE_EXPIRED", quote)
    for r in session.exec(select(QuoteRound).where(QuoteRound.status == "OPEN", QuoteRound.valid_until <= now)).all():
        r.status = "EXPIRED"
        session.add(r)
    return len(due)


def _expire_one(session: Session, quote: DealerQuote) -> bool:
    if quote.status in LIVE and quote.valid_until is not None and quote.valid_until <= _now():
        expire_due_quotes(session)
        return True
    return False


# ------------------------------------------------------------ dealer actions
def revise(session: Session, quote: DealerQuote, dealer: Dealer, body) -> DealerQuote:
    if _expire_one(session, quote):
        session.commit()
        raise HTTPException(409, "This quote has expired. Send a new one from the request.")
    if quote.status not in LIVE:
        raise HTTPException(409, f"A {quote.status.lower().replace('_', ' ')} quote cannot be revised")
    requirement = session.get(BuyRequirement, quote.requirement_id)
    if requirement is None or requirement.status != RequirementStatus.OPEN:
        raise HTTPException(409, "This request is no longer open")
    if quote.revision > MAX_REVISIONS:
        raise HTTPException(409, "A quote can be revised three times")
    if quote.vehicle_id:
        car = session.get(Vehicle, quote.vehicle_id)
        if car is None or car.status != VehicleStatus.AVAILABLE:
            raise HTTPException(409, "This vehicle is no longer available")
    session.add(QuoteRevision(quote_id=quote.id, revision=quote.revision, price=quote.quoted_price, message=quote.message))
    quote.revision += 1
    quote.quoted_price = body.quoted_price
    quote.message = body.message
    if body.delivery_days is not None:
        quote.delivery_days = body.delivery_days
    if body.warranty_months is not None:
        quote.warranty_months = body.warranty_months
    quote.valid_until = _now() + timedelta(hours=body.valid_hours or 72)
    quote.status = "PENDING"
    quote.status_reason = None
    quote.updated_at = _now()
    session.add(quote)
    for r in rounds_of(session, quote.id):  # a new price replaces any counter still open
        if r.status == "OPEN":
            r.status = "SUPERSEDED"
            session.add(r)
    audit(session, dealer.user_id, "QUOTE_REVISED", quote, f"revision {quote.revision}")
    notify_buyer(session, quote, "QUOTE_REVISED", "A dealer updated their quote",
                 f"New total {_lakh(quote.quoted_price)} for your {_car_name(requirement)}.", window=str(quote.revision))
    session.commit()
    session.refresh(quote)
    return quote


def withdraw(session: Session, quote: DealerQuote, dealer: Dealer, reason: Optional[str]) -> DealerQuote:
    if quote.status == "ACCEPTED":
        raise HTTPException(409, "An accepted quote cannot be withdrawn. Contact support to cancel the deal.")
    if quote.status not in LIVE:
        raise HTTPException(409, f"A {quote.status.lower().replace('_', ' ')} quote cannot be withdrawn")
    quote.status = "WITHDRAWN"
    quote.status_reason = (reason or "").strip() or None
    quote.updated_at = _now()
    session.add(quote)
    for r in rounds_of(session, quote.id):
        if r.status == "OPEN":
            r.status = "SUPERSEDED"
            session.add(r)
    audit(session, dealer.user_id, "QUOTE_WITHDRAWN", quote, quote.status_reason or "")
    notify_buyer(session, quote, "QUOTE_WITHDRAWN", "A dealer withdrew their quote", "One of your quotes is no longer available.")
    session.commit()
    session.refresh(quote)
    return quote


# ------------------------------------------------------------ buyer actions
def reject(session: Session, quote: DealerQuote, customer_id: uuid.UUID, reason: Optional[str]) -> DealerQuote:
    if quote.status not in LIVE:
        raise HTTPException(409, f"A {quote.status.lower().replace('_', ' ')} quote cannot be rejected")
    quote.status = "REJECTED"
    quote.status_reason = (reason or "").strip() or None
    quote.updated_at = _now()
    session.add(quote)
    for r in rounds_of(session, quote.id):
        if r.status == "OPEN":
            r.status = "SUPERSEDED"
            session.add(r)
    audit(session, customer_id, "QUOTE_REJECTED", quote, quote.status_reason or "")
    session.commit()
    session.refresh(quote)
    return quote


def accept(session: Session, quote: DealerQuote, requirement: BuyRequirement, customer_id: uuid.UUID, expected_price: int) -> DealerQuote:
    """Accept one quote. Exactly one concurrent caller can succeed; the others get 409."""
    if quote.status == "ACCEPTED":
        return quote  # repeating the same accept is harmless
    if _expire_one(session, quote):
        session.commit()
        raise HTTPException(409, "This quote has expired")
    if quote.status != "PENDING":
        raise HTTPException(409, f"A {quote.status.lower().replace('_', ' ')} quote cannot be accepted")
    if quote.quoted_price != expected_price:
        raise HTTPException(409, "The price changed. Review the new total before accepting.")
    car = session.get(Vehicle, quote.vehicle_id) if quote.vehicle_id else None
    if car is not None and car.status != VehicleStatus.AVAILABLE:
        quote.status = "UNAVAILABLE"
        quote.status_reason = "Car no longer available"
        session.add(quote)
        session.commit()
        raise HTTPException(409, "This car is no longer available")

    now = _now()
    claimed_quote = session.execute(
        update(DealerQuote)
        .where(DealerQuote.id == quote.id, DealerQuote.status == "PENDING", DealerQuote.quoted_price == expected_price)
        .values(status="ACCEPTED", accepted_at=now, updated_at=now)
    ).rowcount
    claimed_request = session.execute(
        update(BuyRequirement)
        .where(BuyRequirement.id == requirement.id, BuyRequirement.status == RequirementStatus.OPEN)
        .values(status=RequirementStatus.QUOTE_ACCEPTED, updated_at=now)
    ).rowcount if claimed_quote else 0
    if not (claimed_quote and claimed_request):
        session.rollback()
        raise HTTPException(409, "This request already has an accepted quote")

    others = session.exec(
        select(DealerQuote).where(DealerQuote.requirement_id == requirement.id, DealerQuote.id != quote.id)
    ).all()
    for other in others:
        if other.status in LIVE:
            other.status = "NOT_SELECTED"
            other.status_reason = "The buyer chose another dealer"
            session.add(other)
        for r in rounds_of(session, other.id):
            if r.status == "OPEN":
                r.status = "SUPERSEDED"
                session.add(r)
    for r in rounds_of(session, quote.id):
        if r.status == "OPEN":
            r.status = "SUPERSEDED"
            session.add(r)
    if car is not None:
        car.status = VehicleStatus.RESERVED
        session.add(car)
    audit_service.record(
        session, customer_id, "QUOTE_ACCEPTED", "dealer_quote", quote.id,
        detail=f"price {expected_price}; request {requirement.id}; {len(others)} other quotes closed",
        before={"status": "PENDING"}, after={"status": "ACCEPTED", "quoted_price": expected_price},
    )
    notify_dealer(session, quote, "QUOTE_ACCEPTED", "Your quote was accepted",
                  f"The buyer accepted {_lakh(expected_price)} for the {_car_name(requirement)}. Their contact details are now available.")
    for other in others:
        if other.status == "NOT_SELECTED":  # no winner or price is revealed to competitors
            notify_dealer(session, other, "QUOTE_NOT_SELECTED", "Quote not selected",
                          f"The buyer chose another dealer for the {_car_name(requirement)}.")
    session.commit()
    session.refresh(quote)
    return quote


# ------------------------------------------------------------ negotiation
def _open_round(session: Session, quote_id: uuid.UUID) -> Optional[QuoteRound]:
    return session.exec(
        select(QuoteRound).where(QuoteRound.quote_id == quote_id, QuoteRound.status == "OPEN", QuoteRound.valid_until > _now())
    ).first()


def counter_by_customer(session: Session, quote: DealerQuote, customer_id: uuid.UUID, price: int, note: Optional[str]) -> QuoteRound:
    if _expire_one(session, quote):
        session.commit()
        raise HTTPException(409, "This quote has expired")
    if quote.status != "PENDING":
        raise HTTPException(409, "Only a live quote can be negotiated")
    if price >= quote.quoted_price:
        raise HTTPException(422, "A counter-offer must be lower than the quoted price")
    if _open_round(session, quote.id) is not None:
        raise HTTPException(409, "A counter-offer is already waiting for a reply")
    count = len(rounds_of(session, quote.id))
    if count >= MAX_ROUNDS:
        raise HTTPException(409, "The negotiation limit for this quote has been reached")
    r = QuoteRound(quote_id=quote.id, round_no=count + 1, by="CUSTOMER", price=price, note=note, valid_until=_now() + ROUND_VALID)
    session.add(r)
    audit(session, customer_id, "QUOTE_COUNTER_BY_CUSTOMER", quote, f"{price}")
    notify_dealer(session, quote, "COUNTER_RECEIVED", "Counter-offer from a buyer",
                  f"A buyer offered {_lakh(price)} against your {_lakh(quote.quoted_price)} quote.", window=str(r.id))
    session.commit()
    session.refresh(r)
    return r


def _agree(session: Session, quote: DealerQuote, rnd: QuoteRound, actor: uuid.UUID) -> None:
    session.add(QuoteRevision(quote_id=quote.id, revision=quote.revision, price=quote.quoted_price, message=quote.message))
    quote.revision += 1
    quote.quoted_price = rnd.price
    quote.updated_at = _now()
    session.add(quote)
    rnd.status = "AGREED"
    session.add(rnd)
    audit(session, actor, "QUOTE_PRICE_AGREED", quote, f"{rnd.price}")


def reply(session: Session, quote: DealerQuote, actor_id: uuid.UUID, side: str, action: str, price: Optional[int], note: Optional[str]) -> QuoteRound:
    """The other side answers the open counter-offer. `side` is who is answering (CUSTOMER/DEALER)."""
    if _expire_one(session, quote):
        session.commit()
        raise HTTPException(409, "This quote has expired")
    if quote.status != "PENDING":
        raise HTTPException(409, "Only a live quote can be negotiated")
    rnd = _open_round(session, quote.id)
    if rnd is None or rnd.by == side:
        raise HTTPException(409, "There is no counter-offer waiting for your reply")
    other_side_notify = notify_buyer if side == "DEALER" else notify_dealer
    if action == "ACCEPT":
        _agree(session, quote, rnd, actor_id)
        other_side_notify(session, quote, "COUNTER_ACCEPTED", "Counter-offer accepted",
                          f"The price is now {_lakh(quote.quoted_price)}.", window=str(rnd.id))
    elif action == "DECLINE":
        rnd.status = "DECLINED"
        session.add(rnd)
        audit(session, actor_id, f"QUOTE_COUNTER_DECLINED_BY_{side}", quote)
        other_side_notify(session, quote, "COUNTER_DECLINED", "Counter-offer declined",
                          "Your counter-offer was declined. The quoted price stands.", window=str(rnd.id))
    else:  # COUNTER
        if side == "CUSTOMER":
            raise HTTPException(422, "Decline or accept, or send a new counter-offer")
        if price is None or not (rnd.price < price < quote.quoted_price):
            raise HTTPException(422, "Your counter must be above the buyer's offer and below your quoted price")
        count = len(rounds_of(session, quote.id))
        if count >= MAX_ROUNDS:
            raise HTTPException(409, "The negotiation limit for this quote has been reached")
        rnd.status = "COUNTERED"
        session.add(rnd)
        new = QuoteRound(quote_id=quote.id, round_no=count + 1, by=side, price=price, note=note, valid_until=_now() + ROUND_VALID)
        session.add(new)
        audit(session, actor_id, "QUOTE_COUNTER_BY_DEALER", quote, f"{price}")
        notify_buyer(session, quote, "COUNTER_RECEIVED", "A dealer countered your offer",
                     f"The dealer's counter is {_lakh(price)}.", window=str(new.id))
        rnd = new
    session.commit()
    session.refresh(rnd)
    return rnd


# ------------------------------------------------------------ admin interventions
# Admins can void a live quote with a reason. They can never change its price or message, and
# an accepted deal is not voidable here: it continues under admin watch.
SUSPENSION_REASON = "The dealer's account was suspended"


def void_by_admin(session: Session, quote: DealerQuote, admin_id: uuid.UUID, reason: str, cause: str = "ADMIN") -> None:
    """Void one live quote. Does not commit."""
    if quote.status not in LIVE:
        raise HTTPException(409, f"A {quote.status.lower().replace('_', ' ')} quote cannot be voided")
    before = {"status": quote.status, "quoted_price": quote.quoted_price}
    quote.status = "VOID_ADMIN"
    quote.status_reason = reason
    quote.void_cause = cause
    quote.updated_at = _now()
    session.add(quote)
    for r in rounds_of(session, quote.id):
        if r.status == "OPEN":
            r.status = "SUPERSEDED"
            session.add(r)
    audit_service.record(
        session, admin_id, "QUOTE_VOIDED_BY_ADMIN", "dealer_quote", quote.id,
        reason=reason, before=before, after={"status": quote.status, "quoted_price": quote.quoted_price},
        detail=cause,
    )
    notify_buyer(session, quote, "QUOTE_VOIDED", "A quote is no longer available", "An administrator closed one of your quotes.")
    if cause == "ADMIN":
        notify_dealer(session, quote, "QUOTE_VOIDED", "Your quote was voided", f"An administrator voided your quote. Reason: {reason}")


def void_live_quotes_of_dealer(session: Session, dealer: Dealer, admin_id: uuid.UUID) -> int:
    quotes = session.exec(select(DealerQuote).where(DealerQuote.dealer_id == dealer.id)).all()
    live = [q for q in quotes if q.status in LIVE]
    for q in live:
        void_by_admin(session, q, admin_id, SUSPENSION_REASON, cause="DEALER_SUSPENDED")
    return len(live)


def restore_after_reactivation(session: Session, dealer: Dealer, admin_id: uuid.UUID) -> int:
    """Bring back quotes voided by the suspension, but only those still valid on a still-open request."""
    quotes = session.exec(
        select(DealerQuote).where(
            DealerQuote.dealer_id == dealer.id,
            DealerQuote.status == "VOID_ADMIN",
            DealerQuote.void_cause == "DEALER_SUSPENDED",
        )
    ).all()
    restored = 0
    now = _now()
    for q in quotes:
        req = session.get(BuyRequirement, q.requirement_id)
        still_open = req is not None and req.status == RequirementStatus.OPEN and req.expires_at > now
        in_date = q.valid_until is None or q.valid_until > now
        before = {"status": q.status}
        if still_open and in_date:
            q.status, q.status_reason = "PENDING", None
            restored += 1
        elif req is not None and req.status == RequirementStatus.QUOTE_ACCEPTED:
            q.status, q.status_reason = "NOT_SELECTED", "The buyer chose another dealer"
        else:
            q.status, q.status_reason = "EXPIRED", "Not restored after reactivation: no longer valid"
        q.void_cause, q.updated_at = None, now
        session.add(q)
        audit_service.record(
            session, admin_id, "QUOTE_RESTORED_AFTER_REACTIVATION" if q.status == "PENDING" else "QUOTE_NOT_RESTORED",
            "dealer_quote", q.id, before=before, after={"status": q.status},
        )
    return restored
