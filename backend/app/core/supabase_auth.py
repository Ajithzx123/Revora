"""Verification of Supabase Auth access tokens.

Supports both signing modes a Supabase project can use:
- legacy shared secret (HS256)  -> SUPABASE_JWT_SECRET
- asymmetric keys (RS256/ES256) -> public keys fetched from <SUPABASE_URL>/auth/v1/.well-known/jwks.json
"""
import time
from typing import Optional

import httpx
from fastapi import HTTPException, status
from jose import JWTError, jwt

from backend.app.core.config import settings

_JWKS_TTL_SECONDS = 3600
_jwks_cache: dict = {"keys": [], "fetched_at": 0.0}

_ASYMMETRIC_ALGS = ("RS256", "ES256")


def _unauthorized(detail: str = "Invalid or expired token") -> HTTPException:
    return HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=detail)


def _issuer() -> Optional[str]:
    return f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1" if settings.SUPABASE_URL else None


def _fetch_jwks(force: bool = False) -> list:
    fresh = time.time() - _jwks_cache["fetched_at"] < _JWKS_TTL_SECONDS
    if _jwks_cache["keys"] and fresh and not force:
        return _jwks_cache["keys"]
    if not settings.SUPABASE_URL:
        raise _unauthorized()
    url = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/.well-known/jwks.json"
    try:
        keys = httpx.get(url, timeout=5.0).raise_for_status().json().get("keys", [])
    except (httpx.HTTPError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Identity service unavailable",
        ) from exc
    _jwks_cache.update(keys=keys, fetched_at=time.time())
    return keys


def _key_for(kid: Optional[str]) -> dict:
    for force in (False, True):  # retry once with a fresh key set in case keys rotated
        for key in _fetch_jwks(force=force):
            if key.get("kid") == kid:
                return key
    raise _unauthorized()


def decode_supabase_token(token: str) -> dict:
    """Return the verified claims, or raise 401. Never trusts the token's own algorithm choice."""
    try:
        alg = jwt.get_unverified_header(token).get("alg")
        options = {"verify_aud": True}
        if alg == "HS256":
            if not settings.SUPABASE_JWT_SECRET:
                raise _unauthorized()
            key = settings.SUPABASE_JWT_SECRET
            algorithms = ["HS256"]
        elif alg in _ASYMMETRIC_ALGS:
            key = _key_for(jwt.get_unverified_header(token).get("kid"))
            algorithms = list(_ASYMMETRIC_ALGS)
        else:  # includes "none"
            raise _unauthorized()

        return jwt.decode(
            token,
            key,
            algorithms=algorithms,
            audience="authenticated",
            issuer=_issuer(),
            options=options,
        )
    except HTTPException:
        raise
    except JWTError as exc:
        raise _unauthorized() from exc
