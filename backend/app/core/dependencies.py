import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlmodel import Session, select

from backend.app.core.supabase_auth import decode_supabase_token
from backend.app.database.session import get_session
from backend.app.models.marketplace_models import Dealer, DealerStatus
from backend.app.models.user_model import User, UserRole


security = HTTPBearer()

CUSTOMER_ROLES = {UserRole.CUSTOMER.value, UserRole.USER.value}
ADMIN_ROLES = {UserRole.ADMIN.value, UserRole.ROOT_ADMIN.value}


def verify_identity(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """A valid Supabase token. The caller may not have a Revora profile yet."""
    claims = decode_supabase_token(credentials.credentials)
    try:
        claims["uid"] = uuid.UUID(str(claims.get("sub")))
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc
    return claims


def verify_token(
    claims: dict = Depends(verify_identity),
    session: Session = Depends(get_session),
) -> dict:
    """A valid token for a user who has a Revora profile. Role comes from our database."""
    user = session.get(User, claims["uid"])
    if user is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Profile not created")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")
    return {"user_id": user.id, "role": user.role.value, "email": user.email}


def require_auth(user_data: dict = Depends(verify_token)) -> dict:
    return user_data


def current_user_id(user_data: dict) -> uuid.UUID:
    """The id of the authenticated user."""
    return user_data["user_id"]


def _require_roles(allowed: set, label: str):
    def checker(user_data: dict = Depends(verify_token)):
        if user_data.get("role") not in allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"{label} access required",
            )
        return user_data

    return checker


require_customer = _require_roles(CUSTOMER_ROLES, "Customer")
require_dealer = _require_roles({UserRole.DEALER.value}, "Dealer")
require_admin = _require_roles(ADMIN_ROLES, "Admin")


def require_root_admin(user_data: dict = Depends(verify_token)):
    if user_data.get("role") != UserRole.ROOT_ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Root admin access required",
        )

    return user_data


def get_dealer_profile(
    user_data: dict = Depends(require_dealer),
    session: Session = Depends(get_session),
) -> Dealer:
    """The caller's dealer record, whatever its verification state."""
    dealer = session.exec(
        select(Dealer).where(Dealer.user_id == current_user_id(user_data))
    ).first()
    if dealer is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Dealer profile not found",
        )
    return dealer


def require_verified_dealer(dealer: Dealer = Depends(get_dealer_profile)) -> Dealer:
    """Only admin-approved dealers may see leads or submit quotes and offers."""
    if dealer.status != DealerStatus.APPROVED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Dealer account is not verified yet",
        )
    return dealer
