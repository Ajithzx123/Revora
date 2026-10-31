from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from sqlmodel import Session, select

from backend.app.core.security import SECRET_KEY, ALGORITHM
from backend.app.database.session import get_session
from backend.app.models.marketplace_models import Dealer
from backend.app.models.user_model import UserRole


security = HTTPBearer()

CUSTOMER_ROLES = {UserRole.CUSTOMER.value, UserRole.USER.value}
ADMIN_ROLES = {UserRole.ADMIN.value, UserRole.ROOT_ADMIN.value}


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):

    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        ) from exc

    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
        )

    if payload.get("user_id") is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )

    return payload


def require_auth(user_data=Depends(verify_token)):
    return user_data


def current_user_id(user_data: dict) -> int:
    """The id of the authenticated user (the token carries it as `user_id`)."""
    return int(user_data["user_id"])


def _require_roles(allowed: set, label: str):
    def checker(user_data=Depends(verify_token)):
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


def require_root_admin(user_data=Depends(verify_token)):
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
    if not dealer.verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Dealer account is not verified yet",
        )
    return dealer
