from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from backend.app.core.security import SECRET_KEY, ALGORITHM
from backend.app.models.user_model import UserRole


security = HTTPBearer()


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

    return payload


def require_auth(user_data=Depends(verify_token)):
    return user_data


def require_admin(user_data=Depends(verify_token)):
    if user_data.get("role") not in [UserRole.ADMIN.value, UserRole.ROOT_ADMIN.value]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

    return user_data


def require_root_admin(user_data=Depends(verify_token)):
    if user_data.get("role") != UserRole.ROOT_ADMIN.value:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Root admin access required",
        )

    return user_data
