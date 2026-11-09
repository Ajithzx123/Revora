"""Profile endpoints. Sign-in, sign-up, OTP and password flows are handled by Supabase Auth."""
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from backend.app.core.dependencies import current_user_id, verify_identity, verify_token
from backend.app.database.session import get_session
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import Dealer, DealerStatus
from backend.app.models.user_model import User, UserRole
from backend.app.schemas.profile_schema import ProfileCreate, ProfileResponse, ProfileUpdate

router = APIRouter(tags=["Profile"])


def _profile_response(session: Session, user: User) -> ProfileResponse:
    dealer = None
    if user.role == UserRole.DEALER:
        dealer = session.exec(select(Dealer).where(Dealer.user_id == user.id)).first()
    return ProfileResponse(
        id=user.id,
        name=user.name,
        email=user.email,
        phone=user.phone,
        city=user.city,
        role=user.role.value,
        dealer_status=dealer.status.value if dealer else None,
    )


@router.post("/profile", response_model=ProfileResponse, status_code=201)
def create_profile(
    body: ProfileCreate,
    claims: dict = Depends(verify_identity),
    session: Session = Depends(get_session),
):
    """Create the Revora profile for the signed-in Supabase user (once)."""
    email = claims.get("email")
    if not email:
        raise HTTPException(status_code=422, detail="Your account has no email address")
    if session.get(User, claims["uid"]) is not None:
        raise HTTPException(status_code=409, detail="Profile already exists")
    if session.exec(select(User).where(User.email == email)).first() is not None:
        raise HTTPException(status_code=409, detail="This email is already registered")

    is_dealer = body.account_type == "DEALER"
    user = User(
        id=claims["uid"],
        name=body.name.strip(),
        email=email,
        phone=body.phone,
        city=body.city,
        role=UserRole.DEALER if is_dealer else UserRole.CUSTOMER,
    )
    session.add(user)
    session.flush()
    if is_dealer:
        # Never approved at signup: the application goes through admin review.
        dealer = Dealer(
            user_id=user.id,
            business_name=body.business_name.strip(),
            city=body.city.strip(),
            status=DealerStatus.DRAFT,
        )
        session.add(dealer)
        session.flush()
        session.add(
            AuditEvent(
                actor_user_id=user.id,
                action="DEALER_APPLICATION_STARTED",
                entity_type="dealer",
                entity_id=str(dealer.id),
            )
        )
    session.commit()
    session.refresh(user)
    return _profile_response(session, user)


@router.get("/me", response_model=ProfileResponse)
def get_me(
    user_data: dict = Depends(verify_token),
    session: Session = Depends(get_session),
):
    return _profile_response(session, session.get(User, current_user_id(user_data)))


@router.patch("/me", response_model=ProfileResponse)
def update_me(
    body: ProfileUpdate,
    user_data: dict = Depends(verify_token),
    session: Session = Depends(get_session),
):
    user = session.get(User, current_user_id(user_data))
    for field, value in body.model_dump(exclude_unset=True).items():
        if value is not None:
            setattr(user, field, value.strip() if isinstance(value, str) else value)
    session.add(user)
    session.commit()
    session.refresh(user)
    return _profile_response(session, user)
