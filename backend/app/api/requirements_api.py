from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List

from backend.app.database.session import get_session
from backend.app.core.dependencies import require_auth
from backend.app.models.marketplace_models import (
    BuyRequirement,
    DealerQuote,
    Dealer,
)
from backend.app.schemas.marketplace_schema import (
    BuyRequirementCreate,
    BuyRequirementResponse,
    DealerQuoteResponse,
)

router = APIRouter(prefix="/requirements", tags=["Requirements"])


@router.post("/", response_model=BuyRequirementResponse)
def create_requirement(
    req_data: BuyRequirementCreate,
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    customer_id = user_data.get("sub") or user_data.get("id")
    requirement = BuyRequirement(
        customer_id=customer_id,
        make=req_data.make,
        model=req_data.model,
        year_min=req_data.year_min,
        budget=req_data.budget,
        fuel=req_data.fuel,
        transmission=req_data.transmission,
        city=req_data.city,
        notes=req_data.notes,
        status="ACTIVE",
    )
    session.add(requirement)
    session.commit()
    session.refresh(requirement)
    
    return BuyRequirementResponse(
        id=requirement.id,
        customer_id=requirement.customer_id,
        make=requirement.make,
        model=requirement.model,
        year_min=requirement.year_min,
        budget=requirement.budget,
        fuel=requirement.fuel,
        transmission=requirement.transmission,
        city=requirement.city,
        notes=requirement.notes,
        status=requirement.status,
        created_at=requirement.created_at,
        quote_count=0,
    )


@router.get("/", response_model=List[BuyRequirementResponse])
def get_user_requirements(
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    customer_id = user_data.get("sub") or user_data.get("id")
    statement = select(BuyRequirement).where(BuyRequirement.customer_id == customer_id)
    requirements = session.exec(statement).all()

    result = []
    for req in requirements:
        quotes_count = len(
            session.exec(
                select(DealerQuote).where(DealerQuote.requirement_id == req.id)
            ).all()
        )
        result.append(
            BuyRequirementResponse(
                id=req.id,
                customer_id=req.customer_id,
                make=req.make,
                model=req.model,
                year_min=req.year_min,
                budget=req.budget,
                fuel=req.fuel,
                transmission=req.transmission,
                city=req.city,
                notes=req.notes,
                status=req.status,
                created_at=req.created_at,
                quote_count=quotes_count,
            )
        )
    return result


@router.get("/{requirement_id}", response_model=BuyRequirementResponse)
def get_requirement_detail(
    requirement_id: int,
    session: Session = Depends(get_session),
):
    req = session.get(BuyRequirement, requirement_id)
    if not req:
        raise HTTPException(status_code=404, detail="Requirement not found")
        
    quotes_count = len(
        session.exec(
            select(DealerQuote).where(DealerQuote.requirement_id == req.id)
        ).all()
    )
    return BuyRequirementResponse(
        id=req.id,
        customer_id=req.customer_id,
        make=req.make,
        model=req.model,
        year_min=req.year_min,
        budget=req.budget,
        fuel=req.fuel,
        transmission=req.transmission,
        city=req.city,
        notes=req.notes,
        status=req.status,
        created_at=req.created_at,
        quote_count=quotes_count,
    )


@router.get("/{requirement_id}/quotes", response_model=List[DealerQuoteResponse])
def get_quotes_for_requirement(
    requirement_id: int,
    session: Session = Depends(get_session),
):
    quotes = session.exec(
        select(DealerQuote).where(DealerQuote.requirement_id == requirement_id)
    ).all()
    
    result = []
    for q in quotes:
        dealer = session.get(Dealer, q.dealer_id)
        result.append(
            DealerQuoteResponse(
                id=q.id,
                dealer_id=q.dealer_id,
                dealer_name=dealer.business_name if dealer else "Authorized Dealer",
                dealer_rating=dealer.rating if dealer else 4.8,
                requirement_id=q.requirement_id,
                car_inventory_id=q.car_inventory_id,
                quoted_price=q.quoted_price,
                message=q.message,
                status=q.status,
                created_at=q.created_at,
            )
        )
    return result


@router.patch("/{requirement_id}/close")
def close_requirement(
    requirement_id: int,
    user_data: dict = Depends(require_auth),
    session: Session = Depends(get_session),
):
    req = session.get(BuyRequirement, requirement_id)
    if not req:
        raise HTTPException(status_code=404, detail="Requirement not found")
    req.status = "CLOSED"
    session.add(req)
    session.commit()
    return {"status": True, "message": "Requirement closed successfully"}
