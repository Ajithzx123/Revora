"""Permission matrix: who may call what. Regression tests for the S0 security fixes."""
import pytest

from backend.tests.conftest import LISTING, REQUIREMENT, verify_dealer


# ---------- authentication required ----------
@pytest.mark.parametrize(
    "method,path",
    [
        ("get", "/api/admin/metrics"),
        ("get", "/api/admin/dealers"),
        ("patch", "/api/admin/dealers/1/verify"),
        ("get", "/api/leads/buy"),
        ("get", "/api/leads/sell"),
        ("post", "/api/quotes"),
        ("post", "/api/offers"),
        ("get", "/api/inventory"),
        ("post", "/api/requirements/"),
        ("get", "/api/requirements/1"),
        ("get", "/api/requirements/1/quotes"),
        ("patch", "/api/requirements/1/close"),
        ("get", "/api/sell-listings/1"),
        ("get", "/api/sell-listings/1/offers"),
    ],
)
def test_endpoints_reject_anonymous(client, method, path):
    r = getattr(client, method)(path)
    assert r.status_code in (401, 403), (path, r.status_code)


# ---------- roles ----------
def test_customer_cannot_use_admin_endpoints(client, actors):
    h = actors.customer()
    assert client.get("/api/admin/metrics", headers=h).status_code == 403
    assert client.get("/api/admin/dealers", headers=h).status_code == 403
    assert client.patch("/api/admin/dealers/1/verify", headers=h).status_code == 403


def test_dealer_cannot_use_admin_endpoints(client, actors):
    h = actors.dealer()
    assert client.get("/api/admin/metrics", headers=h).status_code == 403
    assert client.patch("/api/admin/dealers/1/verify", headers=h).status_code == 403


def test_admin_can_read_metrics(client, actors):
    r = client.get("/api/admin/metrics", headers=actors.admin())
    assert r.status_code == 200
    assert r.json()["total_users"] == 1


def test_customer_cannot_use_dealer_endpoints(client, actors):
    h = actors.customer()
    assert client.get("/api/inventory", headers=h).status_code == 403
    assert client.get("/api/leads/buy", headers=h).status_code == 403
    assert client.post("/api/quotes", headers=h, json={"requirement_id": 1, "quoted_price": 1}).status_code == 403
    assert client.post("/api/offers", headers=h, json={"sell_listing_id": 1, "offered_price": 1}).status_code == 403


def test_dealer_cannot_post_customer_requests(client, actors):
    h = actors.dealer()
    assert client.post("/api/requirements/", headers=h, json=REQUIREMENT).status_code == 403
    assert client.post("/api/sell-listings/", headers=h, json=LISTING).status_code == 403


def test_signup_cannot_create_admin(client):
    r = client.post(
        "/api/signup",
        json={
            "name": "Evil",
            "email": "evil@example.com",
            "password": "Passw0rd!x",
            "phone": "9000000000",
            "account_type": "ADMIN",
        },
    )
    assert r.status_code == 422


def test_dealer_signup_requires_business_details(client):
    r = client.post(
        "/api/signup",
        json={
            "name": "D",
            "email": "d@example.com",
            "password": "Passw0rd!x",
            "phone": "9000000001",
            "account_type": "DEALER",
        },
    )
    assert r.status_code == 422


# ---------- dealer verification (S1 fix: never auto-verified) ----------
def test_new_dealer_is_unverified_and_blocked_from_leads_and_quotes(client, actors):
    h = actors.dealer()
    assert client.get("/api/leads/buy", headers=h).status_code == 403
    assert client.get("/api/leads/sell", headers=h).status_code == 403
    r = client.post("/api/quotes", headers=h, json={"requirement_id": 1, "quoted_price": 100000})
    assert r.status_code == 403
    r = client.post("/api/offers", headers=h, json={"sell_listing_id": 1, "offered_price": 100000})
    assert r.status_code == 403


def test_unverified_dealer_can_still_manage_own_inventory(client, actors):
    h = actors.dealer()
    car = {
        "make": "Hyundai", "model": "i20", "year": 2021, "fuel": "Petrol",
        "transmission": "Manual", "km": 20000, "price": 650000,
    }
    assert client.post("/api/inventory", headers=h, json=car).status_code == 200
    assert len(client.get("/api/inventory", headers=h).json()) == 1


def test_admin_verification_is_audited(client, actors):
    actors.dealer()
    admin = actors.admin()
    verify_dealer(client, admin)
    from sqlmodel import Session, select
    from backend.app.database.connection import engine
    from backend.app.models.audit_model import AuditEvent

    with Session(engine) as s:
        events = s.exec(select(AuditEvent)).all()
    assert [(e.action, e.entity_id) for e in events] == [("DEALER_VERIFIED", 1)]


# ---------- ownership + sealed bidding ----------
def _post_requirement(client, headers):
    r = client.post("/api/requirements/", headers=headers, json=REQUIREMENT)
    assert r.status_code == 200, r.text
    return r.json()


def test_requirement_belongs_to_authenticated_user(client, actors):
    h = actors.customer()
    req = _post_requirement(client, h)
    assert req["customer_id"] == 1  # regression: token claim is user_id, not sub
    assert len(client.get("/api/requirements/", headers=h).json()) == 1


def test_other_customer_cannot_see_or_close_requirement(client, actors):
    owner = actors.customer()
    other = actors.customer()
    req = _post_requirement(client, owner)
    rid = req["id"]
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
    dealer = actors.dealer()
    admin = actors.admin()
    verify_dealer(client, admin)
    rid = _post_requirement(client, customer)["id"]
    q = client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 650000})
    assert q.status_code == 200, q.text
    assert client.get(f"/api/requirements/{rid}/quotes", headers=dealer).status_code == 404
    assert len(client.get(f"/api/requirements/{rid}/quotes", headers=customer).json()) == 1


# ---------- quote / offer validation ----------
def test_verified_dealer_quote_rules(client, actors):
    customer = actors.customer()
    dealer = actors.dealer()
    verify_dealer(client, actors.admin())
    rid = _post_requirement(client, customer)["id"]

    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 0}).status_code == 422
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": 999, "quoted_price": 5}).status_code == 404
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 650000}).status_code == 200
    # one quote per dealer per requirement
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 640000}).status_code == 409
    # cannot quote a closed requirement
    client.patch(f"/api/requirements/{rid}/close", headers=customer)
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 1}).status_code in (404, 409)


def test_dealer_cannot_attach_another_dealers_car(client, actors):
    customer = actors.customer()
    d1 = actors.dealer()
    d2 = actors.dealer()
    verify_dealer(client, actors.admin(), 1)
    verify_dealer(client, actors.admin(), 2)
    car = {"make": "Hyundai", "model": "i20", "year": 2021, "fuel": "Petrol",
           "transmission": "Manual", "km": 1, "price": 1}
    car_id = client.post("/api/inventory", headers=d1, json=car).json()["id"]
    rid = _post_requirement(client, customer)["id"]
    r = client.post("/api/quotes", headers=d2, json={"requirement_id": rid, "quoted_price": 5, "car_inventory_id": car_id})
    assert r.status_code == 404


def test_offer_rules(client, actors):
    seller = actors.customer()
    dealer = actors.dealer()
    verify_dealer(client, actors.admin())
    lid = client.post("/api/sell-listings/", headers=seller, json=LISTING).json()["id"]
    assert client.post("/api/offers", headers=dealer, json={"sell_listing_id": lid, "offered_price": -1}).status_code == 422
    assert client.post("/api/offers", headers=dealer, json={"sell_listing_id": lid, "offered_price": 380000}).status_code == 200
    assert client.post("/api/offers", headers=dealer, json={"sell_listing_id": lid, "offered_price": 390000}).status_code == 409
    assert len(client.get(f"/api/sell-listings/{lid}/offers", headers=seller).json()) == 1
