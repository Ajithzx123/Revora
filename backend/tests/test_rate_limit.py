"""Write endpoints are rate limited per user; the limit is the same however the requests arrive."""
import pytest

from backend.app.core import rate_limit
from backend.tests.conftest import LISTING, REQUIREMENT, MISSING


@pytest.fixture
def tight(monkeypatch):
    """Shrink one limit so a handful of requests reaches it."""
    def set_limit(name, n, per=3600):
        monkeypatch.setitem(rate_limit.LIMITS, name, (n, per))

    return set_limit


def test_the_window_slides(monkeypatch):
    clock = {"t": 1000.0}
    monkeypatch.setattr(rate_limit, "_clock", lambda: clock["t"])
    monkeypatch.setitem(rate_limit.LIMITS, "action", (3, 60))
    for _ in range(3):
        rate_limit.check("action", "u1")
    with pytest.raises(Exception) as e:
        rate_limit.check("action", "u1")
    assert e.value.status_code == 429 and int(e.value.headers["Retry-After"]) >= 1
    rate_limit.check("action", "u2")                 # another user is unaffected
    clock["t"] += 61
    rate_limit.check("action", "u1")                 # the window has passed


def test_creating_too_many_listings_is_refused_with_retry_after(client, actors, tight):
    tight("create", 3)
    seller = actors.customer()
    for _ in range(3):
        assert client.post("/api/sell-listings/", headers=seller, json=LISTING).status_code == 201
    r = client.post("/api/sell-listings/", headers=seller, json=LISTING)
    assert r.status_code == 429 and "Too many requests" in r.json()["detail"] and int(r.headers["Retry-After"]) >= 1
    other = actors.customer()
    assert client.post("/api/sell-listings/", headers=other, json=LISTING).status_code == 201  # limits are per user


def test_requests_that_fail_validation_still_count(client, actors, tight):
    tight("create", 2)
    c = actors.customer()
    for _ in range(2):
        assert client.post("/api/requirements/", headers=c, json={**REQUIREMENT, "budget_max": 1}).status_code == 422
    assert client.post("/api/requirements/", headers=c, json=REQUIREMENT).status_code == 429


def test_dealer_actions_are_limited(client, actors, tight):
    tight("action", 3)
    d = actors.dealer(approved=True)
    codes = [client.post(f"/api/offers/{MISSING}/withdraw", headers=d).status_code for _ in range(5)]
    assert codes[:3] == [404, 404, 404] and codes[3:] == [429, 429]


def test_profile_creation_is_limited_by_identity(client, actors, tight):
    tight("profile", 2)
    h = actors._identity("p")
    assert client.post("/api/profile", headers=h, json={"name": "A", "city": "Bengaluru"}).status_code == 201
    assert client.post("/api/profile", headers=h, json={"name": "A", "city": "Bengaluru"}).status_code == 409
    assert client.post("/api/profile", headers=h, json={"name": "A", "city": "Bengaluru"}).status_code == 429


def test_unauthenticated_calls_are_rejected_before_counting(client):
    assert client.post(f"/api/offers/{MISSING}/withdraw").status_code in (401, 403)
    assert not rate_limit._hits
