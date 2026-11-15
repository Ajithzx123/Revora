"""Per-user rate limiting for write endpoints.

A sliding window kept in this process's memory. That is right for one server process; when the
API runs on several workers or machines the counters must move to a shared store (Redis), because
each process would otherwise count on its own. Reads are not limited here.

Limits are generous on purpose: they stop scripts and runaway clients, not people.
"""
import threading
import time
from collections import defaultdict, deque
from typing import Callable

from fastapi import Depends, HTTPException, status

from backend.app.core.dependencies import verify_identity, verify_token

# name -> (maximum calls, per this many seconds)
LIMITS: dict[str, tuple[int, int]] = {
    "create": (30, 3600),     # new requests, listings, cars
    "submit": (120, 3600),    # a dealer's quotes and offers
    "upload": (60, 3600),     # documents and photos
    "profile": (10, 3600),    # creating a profile
    "action": (120, 60),      # every other change: revise, accept, counter, ...
}

_lock = threading.Lock()
_hits: dict[str, deque] = defaultdict(deque)
_clock: Callable[[], float] = time.monotonic


def reset() -> None:
    """Forget every counter (tests, and a clean slate after a deploy)."""
    with _lock:
        _hits.clear()


def check(name: str, subject: str) -> None:
    """Count one call by `subject` against limit `name`; raise 429 when it is over."""
    limit, window = LIMITS[name]
    now = _clock()
    key = f"{name}:{subject}"
    with _lock:
        q = _hits[key]
        while q and now - q[0] >= window:
            q.popleft()
        if len(q) >= limit:
            retry = max(1, int(window - (now - q[0])) + 1)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Too many requests. Try again in {retry} seconds.",
                headers={"Retry-After": str(retry)},
            )
        q.append(now)


def _limited(name: str):
    def dependency(user_data: dict = Depends(verify_token)):
        check(name, str(user_data["user_id"]))

    return dependency


def _limited_identity(name: str):
    def dependency(claims: dict = Depends(verify_identity)):
        check(name, str(claims["uid"]))

    return dependency


create = _limited("create")
submit = _limited("submit")
upload = _limited("upload")
action = _limited("action")
profile = _limited_identity("profile")
