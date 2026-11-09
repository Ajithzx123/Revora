"""Quote actions after a quote exists: revise, withdraw, negotiate, accept, reject."""
import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from backend.app.core.dependencies import current_user_id, require_customer, require_verified_dealer
from backend.app.database.session import get_session
from backend.app.models.marketplace_models import BuyRequirement, Dealer, DealerQuote
from backend.app.models.user_model import User
from backend.app.schemas.marketplace_schema import (
    AcceptQuote,
    CounterCreate,
    DealerQuoteResponse,
    MyQuoteResponse,
    NegotiationReply,
    QuoteRevise,
    ReasonOptional,
)
from backend.app.services import quote_service as svc

router = APIRouter(prefix="/quotes", tags=["Quotes"])


def _dealers_quote(session: Session, dealer: Dealer, quote_id: uuid.UUID) -> DealerQuote:
    quote = session.get(DealerQuote, quote_id)
    if quote is None or quote.dealer_id != dealer.id:
        raise HTTPException(404, "Quote not found")
    return quote


def _customers_quote(session: Session, user_data: dict, quote_id: uuid.UUID):
    quote = session.get(DealerQuote, quote_id)
    requirement = session.get(BuyRequirement, quote.requirement_id) if quote else None
    if quote is None or requirement is None or requirement.customer_id != current_user_id(user_data):
        raise HTTPException(404, "Quote not found")
    return quote, requirement


def _title(req: BuyRequirement) -> str:
    return f"{req.make} {req.model}" if req.model else req.make


# ---------------------------------------------------------------- dealer
@router.get("/mine", response_model=List[MyQuoteResponse])
def my_quotes(dealer: Dealer = Depends(require_verified_dealer), session: Session = Depends(get_session)):
    """The dealer's own quotes, newest first. The buyer's contact is released only once accepted."""
    svc.expire_due_quotes(session)
    session.commit()
    quotes = session.exec(select(DealerQuote).where(DealerQuote.dealer_id == dealer.id).order_by(DealerQuote.created_at.desc())).all()
    out = []
    for q in quotes:
        req = session.get(BuyRequirement, q.requirement_id)
        buyer = session.get(User, req.customer_id) if req else None
        accepted = q.status == "ACCEPTED"
        out.append(
            MyQuoteResponse(
                **svc.quote_response(session, q).model_dump(),
                request_title=_title(req) if req else "",
                request_city=req.city if req else "",
                request_status=req.status.value if req else "",
                buyer_first_name=buyer.name.strip().split(" ")[0] if buyer and buyer.name.strip() else "Buyer",
                buyer_name=buyer.name if accepted and buyer else None,
                buyer_phone=buyer.phone if accepted and buyer else None,
            )
        )
    return out


@router.put("/{quote_id}", response_model=DealerQuoteResponse)
def revise_quote(
    quote_id: uuid.UUID,
    body: QuoteRevise,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    quote = svc.revise(session, _dealers_quote(session, dealer, quote_id), dealer, body)
    return svc.quote_response(session, quote)


@router.post("/{quote_id}/withdraw", response_model=DealerQuoteResponse)
def withdraw_quote(
    quote_id: uuid.UUID,
    body: ReasonOptional,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    quote = svc.withdraw(session, _dealers_quote(session, dealer, quote_id), dealer, body.reason)
    return svc.quote_response(session, quote)


@router.post("/{quote_id}/negotiation", response_model=DealerQuoteResponse)
def dealer_negotiation_reply(
    quote_id: uuid.UUID,
    body: NegotiationReply,
    dealer: Dealer = Depends(require_verified_dealer),
    session: Session = Depends(get_session),
):
    quote = _dealers_quote(session, dealer, quote_id)
    svc.reply(session, quote, dealer.user_id, "DEALER", body.action, body.price, body.note)
    session.refresh(quote)
    return svc.quote_response(session, quote)


# ---------------------------------------------------------------- buyer
@router.post("/{quote_id}/accept", response_model=DealerQuoteResponse)
def accept_quote(
    quote_id: uuid.UUID,
    body: AcceptQuote,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    quote, requirement = _customers_quote(session, user_data, quote_id)
    quote = svc.accept(session, quote, requirement, current_user_id(user_data), body.expected_price)
    return svc.quote_response(session, quote)


@router.post("/{quote_id}/reject", response_model=DealerQuoteResponse)
def reject_quote(
    quote_id: uuid.UUID,
    body: ReasonOptional,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    quote, _ = _customers_quote(session, user_data, quote_id)
    quote = svc.reject(session, quote, current_user_id(user_data), body.reason)
    return svc.quote_response(session, quote)


@router.post("/{quote_id}/counter", response_model=DealerQuoteResponse)
def counter_quote(
    quote_id: uuid.UUID,
    body: CounterCreate,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    quote, _ = _customers_quote(session, user_data, quote_id)
    svc.counter_by_customer(session, quote, current_user_id(user_data), body.price, body.note)
    session.refresh(quote)
    return svc.quote_response(session, quote)


@router.post("/{quote_id}/negotiation/respond", response_model=DealerQuoteResponse)
def customer_negotiation_reply(
    quote_id: uuid.UUID,
    body: NegotiationReply,
    user_data: dict = Depends(require_customer),
    session: Session = Depends(get_session),
):
    quote, _ = _customers_quote(session, user_data, quote_id)
    svc.reply(session, quote, current_user_id(user_data), "CUSTOMER", body.action, body.price, body.note)
    session.refresh(quote)
    return svc.quote_response(session, quote)
