"""Permission matrix: who may call what. Regression tests for the S0/S1 security rules."""
import pytest
from sqlmodel import Session, select

from backend.app.database.connection import engine
from backend.app.models.audit_model import AuditEvent
from backend.tests.conftest import CAR, LISTING, MISSING, REQUIREMENT


# ---------- authentication required ----------
@pytest.mark.parametrize(
    "method,path",
    [
        ("get", "/api/me"),
        ("get", "/api/admin/metrics"),
        ("get", "/api/admin/dealers"),
        ("get", f"/api/admin/dealers/{MISSING}"),
        ("post", f"/api/admin/dealers/{MISSING}/approve"),
        ("get", "/api/dealers/me"),
        ("post", "/api/dealers/me/submit"),
        ("get", "/api/leads/buy"),
        ("get", "/api/leads/sell"),
        ("post", "/api/quotes"),
        ("post", "/api/offers"),
        ("get", "/api/inventory"),
        ("post", "/api/requirements/"),
        ("get", f"/api/requirements/{MISSING}"),
        ("get", f"/api/requirements/{MISSING}/quotes"),
        ("patch", f"/api/requirements/{MISSING}/close"),
        ("get", f"/api/sell-listings/{MISSING}"),
        ("get", f"/api/sell-listings/{MISSING}/offers"),
    ],
)
def test_endpoints_reject_anonymous(client, method, path):
    r = getattr(client, method)(path)
    assert r.status_code in (401, 403), (path, r.status_code)


def test_valid_token_without_profile_is_blocked(client, actors):
    h = actors._identity("noprofile")
    assert client.get("/api/me", headers=h).status_code == 403
    assert client.post("/api/requirements/", headers=h, json=REQUIREMENT).status_code == 403


# ---------- roles ----------
def test_customer_cannot_use_admin_endpoints(client, actors):
    h = actors.customer()
    assert client.get("/api/admin/metrics", headers=h).status_code == 403
    assert client.get("/api/admin/dealers", headers=h).status_code == 403
    assert client.post(f"/api/admin/dealers/{MISSING}/approve", headers=h).status_code == 403


def test_dealer_cannot_use_admin_endpoints(client, actors):
    h = actors.dealer()
    assert client.get("/api/admin/metrics", headers=h).status_code == 403
    assert client.post(f"/api/admin/dealers/{h.dealer_id}/approve", headers=h).status_code == 403


def test_admin_can_read_metrics(client, actors):
    actors.dealer()
    r = client.get("/api/admin/metrics", headers=actors.admin())
    assert r.status_code == 200
    assert r.json()["total_users"] == 2  # the dealer and the admin
    assert r.json()["active_dealers"] == 0
    assert r.json()["pending_dealer_applications"] == 0


def test_customer_cannot_use_dealer_endpoints(client, actors):
    h = actors.customer()
    assert client.get("/api/inventory", headers=h).status_code == 403
    assert client.get("/api/dealers/me", headers=h).status_code == 403
    assert client.get("/api/leads/buy", headers=h).status_code == 403
    assert client.post("/api/quotes", headers=h, json={"requirement_id": MISSING, "quoted_price": 1}).status_code == 403
    assert client.post("/api/offers", headers=h, json={"sell_listing_id": MISSING, "offered_price": 1}).status_code == 403


def test_dealer_cannot_post_customer_requests(client, actors):
    h = actors.dealer()
    assert client.post("/api/requirements/", headers=h, json=REQUIREMENT).status_code == 403
    assert client.post("/api/sell-listings/", headers=h, json=LISTING).status_code == 403


def test_profile_cannot_be_created_as_admin(client, actors):
    h = actors._identity("evil")
    r = client.post("/api/profile", headers=h, json={"name": "Evil", "account_type": "ADMIN"})
    assert r.status_code == 422


def test_role_in_token_metadata_is_ignored(client, actors):
    """A client-editable role claim must never grant access; roles live in our database."""
    from jose import jwt
    from backend.tests.conftest import TEST_JWT_SECRET
    import time

    h = actors.customer()
    token = jwt.encode(
        {
            "sub": str(h.user_id), "email": "customer1@example.com", "aud": "authenticated",
            "exp": int(time.time()) + 600, "role": "ADMIN",
            "user_metadata": {"role": "ADMIN"}, "app_metadata": {"role": "ADMIN"},
        },
        TEST_JWT_SECRET, algorithm="HS256",
    )
    forged = {"Authorization": f"Bearer {token}"}
    assert client.get("/api/admin/metrics", headers=forged).status_code == 403


def test_disabled_account_is_blocked(client, actors):
    h = actors.customer()
    from backend.app.models.user_model import User

    with Session(engine) as s:
        u = s.get(User, h.user_id)
        u.is_active = False
        s.add(u)
        s.commit()
    assert client.get("/api/me", headers=h).status_code == 403


# ---------- profile ----------
def test_profile_created_once(client, actors):
    h = actors.customer()
    r = client.post("/api/profile", headers=h, json={"name": "Again"})
    assert r.status_code == 409
    me = client.get("/api/me", headers=h).json()
    assert me["role"] == "CUSTOMER" and me["dealer_status"] is None


def test_dealer_account_starts_as_draft(client, actors):
    h = actors.dealer()
    assert client.get("/api/me", headers=h).json()["dealer_status"] == "DRAFT"


def test_dealer_profile_requires_business_details(client, actors):
    h = actors._identity("d")
    r = client.post("/api/profile", headers=h, json={"name": "D", "account_type": "DEALER"})
    assert r.status_code == 422


# ---------- dealer verification gates marketplace access ----------
def test_unapproved_dealer_blocked_from_leads_quotes_offers(client, actors):
    h = actors.dealer()
    assert client.get("/api/leads/buy", headers=h).status_code == 403
    assert client.get("/api/leads/sell", headers=h).status_code == 403
    assert client.post("/api/quotes", headers=h, json={"requirement_id": MISSING, "quoted_price": 100000}).status_code == 403
    assert client.post("/api/offers", headers=h, json={"sell_listing_id": MISSING, "offered_price": 100000}).status_code == 403


def test_unapproved_dealer_can_still_manage_own_inventory(client, actors):
    h = actors.dealer()
    assert client.post("/api/inventory", headers=h, json=CAR).status_code == 200
    assert len(client.get("/api/inventory", headers=h).json()) == 1


# ---------- ownership + sealed bidding ----------
def _post_requirement(client, headers):
    r = client.post("/api/requirements/", headers=headers, json=REQUIREMENT)
    assert r.status_code == 200, r.text
    return r.json()


def test_requirement_belongs_to_authenticated_user(client, actors):
    h = actors.customer()
    req = _post_requirement(client, h)
    assert req["customer_id"] == str(h.user_id)
    assert len(client.get("/api/requirements/", headers=h).json()) == 1


def test_other_customer_cannot_see_or_close_requirement(client, actors):
    owner = actors.customer()
    other = actors.customer()
    rid = _post_requirement(client, owner)["id"]
    assert client.get(f"/api/requirements/{rid}", headers=other).status_code == 404
    assert client.get(f"/api/requirements/{rid}/quotes", headers=other).status_code == 404
    assert client.patch(f"/api/requirements/{rid}/close", headers=other).status_code == 404
    assert client.patch(f"/api/requirements/{rid}/close", headers=owner).status_code == 200


def test_other_customer_cannot_see_listing_or_offers(client, actors):
    owner = actors.customer()
    other = actors.customer()
    lid = client.post("/api/sell-listings/", headers=owner, json=LISTING).json()["id"]
    assert client.get(f"/api/sell-listings/{lid}", headers=other).status_code == 404
    assert client.get(f"/api/sell-listings/{lid}/offers", headers=other).status_code == 404
    assert client.get(f"/api/sell-listings/{lid}", headers=owner).status_code == 200


def test_sealed_bidding_dealer_cannot_read_quotes(client, actors):
    customer = actors.customer()
    dealer = actors.dealer(approved=True)
    rid = _post_requirement(client, customer)["id"]
    q = client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 650000})
    assert q.status_code == 200, q.text
    assert client.get(f"/api/requirements/{rid}/quotes", headers=dealer).status_code == 404
    assert len(client.get(f"/api/requirements/{rid}/quotes", headers=customer).json()) == 1
    # an approved dealer may read the requirement itself in order to quote
    assert client.get(f"/api/requirements/{rid}", headers=dealer).status_code == 200


def test_unapproved_dealer_cannot_read_requirement(client, actors):
    customer = actors.customer()
    dealer = actors.dealer()
    rid = _post_requirement(client, customer)["id"]
    assert client.get(f"/api/requirements/{rid}", headers=dealer).status_code == 404


# ---------- quote / offer validation ----------
def test_verified_dealer_quote_rules(client, actors):
    customer = actors.customer()
    dealer = actors.dealer(approved=True)
    rid = _post_requirement(client, customer)["id"]

    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 0}).status_code == 422
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": MISSING, "quoted_price": 5}).status_code == 404
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 650000}).status_code == 200
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 640000}).status_code == 409
    client.patch(f"/api/requirements/{rid}/close", headers=customer)
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 1}).status_code in (404, 409)


def test_dealer_cannot_attach_another_dealers_car(client, actors):
    customer = actors.customer()
    d1 = actors.dealer(approved=True)
    d2 = actors.dealer(approved=True)
    car_id = client.post("/api/inventory", headers=d1, json=CAR).json()["id"]
    rid = _post_requirement(client, customer)["id"]
    r = client.post("/api/quotes", headers=d2, json={"requirement_id": rid, "quoted_price": 5, "car_inventory_id": car_id})
    assert r.status_code == 404


def test_offer_rules(client, actors):
    seller = actors.customer()
    dealer = actors.dealer(approved=True)
    lid = client.post("/api/sell-listings/", headers=seller, json=LISTING).json()["id"]
    assert client.post("/api/offers", headers=dealer, json={"sell_listing_id": lid, "offered_price": -1}).status_code == 422
    assert client.post("/api/offers", headers=dealer, json={"sell_listing_id": lid, "offered_price": 380000}).status_code == 200
    assert client.post("/api/offers", headers=dealer, json={"sell_listing_id": lid, "offered_price": 390000}).status_code == 409
    assert len(client.get(f"/api/sell-listings/{lid}/offers", headers=seller).json()) == 1
