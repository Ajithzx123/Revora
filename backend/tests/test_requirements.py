"""Buy requests: validation, lifecycle, edits, privacy."""
from datetime import datetime, timedelta

import pytest
from sqlmodel import Session

from backend.app.database.connection import engine
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import BuyRequirement
from backend.tests.conftest import REQUIREMENT, source

FULL = {
    **REQUIREMENT,
    "variant": "Asta",
    "year_max": 2024,
    "budget_min": 500000,
    "fuel": "Petrol",
    "transmission": "Automatic",
    "body_type": "Hatchback",
    "max_km": 40000,
    "max_owners": 1,
    "radius_km": 100,
    "urgency": "NOW",
    "needs_finance": True,
    "has_exchange": True,
    "must_have": ["transmission", "fuel"],
    "notes": "Prefer white or silver",
}


def post(client, h, body=None):
    return client.post("/api/requirements/", headers=h, json=body or REQUIREMENT)


# ---------- master data ----------
def test_master_data_is_public_and_complete(client):
    r = client.get("/api/master-data")
    assert r.status_code == 200
    data = r.json()
    hyundai = next(m for m in data["makes"] if m["name"] == "Hyundai")
    assert "i20" in hyundai["models"]
    assert "Bengaluru" in data["cities"] and "Automatic" in data["transmissions"]
    assert data["limits"]["min_budget"] == 100000


# ---------- create ----------
def test_create_full_requirement(client, actors):
    h = actors.customer()
    r = post(client, h, FULL)
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["status"] == "OPEN"
    assert body["must_have"] == ["fuel", "transmission"]  # sorted, de-duplicated
    assert body["urgency"] == "NOW" and body["needs_finance"] is True
    expires = datetime.fromisoformat(body["expires_at"])
    assert timedelta(days=13) < expires - datetime.utcnow() <= timedelta(days=14)


def test_minimal_requirement_uses_defaults(client, actors):
    body = post(client, actors.customer()).json()
    assert body["model"] == "i20" and body["budget_min"] == 0
    assert body["radius_km"] == 50 and body["urgency"] == "WITHIN_2_WEEKS" and body["must_have"] == []


def test_any_model_is_allowed(client, actors):
    r = post(client, actors.customer(), {**REQUIREMENT, "model": None})
    assert r.status_code == 201 and r.json()["model"] is None


@pytest.mark.parametrize(
    "override",
    [
        {"make": "Ferrari"},
        {"model": "Nexon"},                       # a Tata, not a Hyundai
        {"city": "Atlantis"},
        {"fuel": "Steam"},
        {"transmission": "CVT-ish"},
        {"year_min": 1985},
        {"year_min": 2100},
        {"year_min": 2022, "year_max": 2020},
        {"budget_max": 5000},                     # below the 1 lakh floor
        {"budget_min": 800000, "budget_max": 700000},
        {"max_km": -1},
        {"max_owners": 0},
        {"radius_km": 2},
        {"urgency": "WHENEVER"},
        {"must_have": ["colour"]},
        {"notes": "x" * 501},
    ],
)
def test_invalid_requirements_are_rejected(client, actors, override):
    assert post(client, actors.customer(), {**REQUIREMENT, **override}).status_code == 422


def test_pick_list_values_are_case_insensitive(client, actors):
    r = post(client, actors.customer(), {**REQUIREMENT, "make": "hyundai", "city": "bengaluru", "fuel": "PETROL"})
    assert r.status_code == 201
    assert (r.json()["make"], r.json()["city"], r.json()["fuel"]) == ("Hyundai", "Bengaluru", "Petrol")


def test_duplicate_request_is_blocked(client, actors):
    h = actors.customer()
    assert post(client, h).status_code == 201
    r = post(client, h)
    assert r.status_code == 409 and "already have an open request" in r.json()["detail"]
    assert post(client, h, {**REQUIREMENT, "city": "Mumbai"}).status_code == 201


def test_open_request_limit(client, actors):
    h = actors.customer()
    for i in range(5):
        assert post(client, h, {**REQUIREMENT, "budget_max": 700000 + i * 10000}).status_code == 201
    r = post(client, h, {**REQUIREMENT, "budget_max": 900000})
    assert r.status_code == 409 and "5 open requests" in r.json()["detail"]


# ---------- lifecycle ----------
def test_pause_resume_cancel(client, actors):
    h = actors.customer()
    rid = post(client, h).json()["id"]
    assert client.post(f"/api/requirements/{rid}/pause", headers=h).json()["status"] == "PAUSED"
    assert client.post(f"/api/requirements/{rid}/pause", headers=h).status_code == 409  # already paused
    assert client.post(f"/api/requirements/{rid}/resume", headers=h).json()["status"] == "OPEN"
    assert client.post(f"/api/requirements/{rid}/cancel", headers=h).json()["status"] == "CANCELLED"
    for action in ("pause", "resume", "cancel"):
        assert client.post(f"/api/requirements/{rid}/{action}", headers=h).status_code == 409


def test_paused_request_is_hidden_from_dealers(client, actors):
    h = actors.customer()
    dealer = source(client, actors.dealer(approved=True))
    rid = post(client, h).json()["id"]
    assert len(client.get("/api/leads/buy", headers=dealer).json()) == 1
    client.post(f"/api/requirements/{rid}/pause", headers=h)
    assert client.get("/api/leads/buy", headers=dealer).json() == []
    client.post(f"/api/requirements/{rid}/resume", headers=h)
    assert len(client.get("/api/leads/buy", headers=dealer).json()) == 1


def test_cancelling_closes_open_quotes(client, actors):
    h = actors.customer()
    dealer = source(client, actors.dealer(approved=True))
    rid = post(client, h).json()["id"]
    client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 650000})
    client.post(f"/api/requirements/{rid}/cancel", headers=h)
    quotes = client.get(f"/api/requirements/{rid}/quotes", headers=h).json()
    assert [q["status"] for q in quotes] == ["CLOSED_BY_CUSTOMER"]


def test_expired_request_is_closed_lazily(client, actors):
    h = actors.customer()
    dealer = source(client, actors.dealer(approved=True))
    rid = post(client, h).json()["id"]
    with Session(engine) as s:
        import uuid
        req = s.get(BuyRequirement, uuid.UUID(rid))
        req.expires_at = datetime.utcnow() - timedelta(minutes=1)
        s.add(req)
        s.commit()
    assert client.get("/api/leads/buy", headers=dealer).json() == []
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 1}).status_code == 404
    assert client.get(f"/api/requirements/{rid}", headers=h).json()["status"] == "EXPIRED"
    assert client.post(f"/api/requirements/{rid}/resume", headers=h).status_code == 409


# ---------- edit ----------
def test_edit_changes_only_what_was_sent(client, actors):
    h = actors.customer()
    rid = post(client, h, FULL).json()["id"]
    r = client.patch(f"/api/requirements/{rid}", headers=h, json={"notes": "White only", "max_km": 30000})
    assert r.status_code == 200
    body = r.json()
    assert body["notes"] == "White only" and body["max_km"] == 30000
    assert body["fuel"] == "Petrol" and body["must_have"] == ["fuel", "transmission"]


def test_edit_can_clear_an_optional_field(client, actors):
    h = actors.customer()
    rid = post(client, h, FULL).json()["id"]
    r = client.patch(f"/api/requirements/{rid}", headers=h, json={"fuel": None})
    assert r.status_code == 200 and r.json()["fuel"] is None


def test_edit_cannot_create_an_impossible_request(client, actors):
    h = actors.customer()
    rid = post(client, h).json()["id"]
    assert client.patch(f"/api/requirements/{rid}", headers=h, json={"model": "Nexon"}).status_code == 422
    assert client.patch(f"/api/requirements/{rid}", headers=h, json={"year_max": 2010}).status_code == 422
    assert client.patch(f"/api/requirements/{rid}", headers=h, json={"city": None}).status_code == 422


def test_material_edit_asks_dealers_to_requote_but_minor_edit_does_not(client, actors):
    h = actors.customer()
    dealer = source(client, actors.dealer(approved=True))
    rid = post(client, h).json()["id"]
    client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 650000})

    client.patch(f"/api/requirements/{rid}", headers=h, json={"notes": "any colour is fine"})
    assert [q["status"] for q in client.get(f"/api/requirements/{rid}/quotes", headers=h).json()] == ["PENDING"]

    client.patch(f"/api/requirements/{rid}", headers=h, json={"budget_max": 710000})  # +1.4%
    assert [q["status"] for q in client.get(f"/api/requirements/{rid}/quotes", headers=h).json()] == ["PENDING"]

    client.patch(f"/api/requirements/{rid}", headers=h, json={"budget_max": 1_200_000})  # +71%
    assert [q["status"] for q in client.get(f"/api/requirements/{rid}/quotes", headers=h).json()] == ["REQUOTE_REQUESTED"]


def test_cannot_edit_a_cancelled_request(client, actors):
    h = actors.customer()
    rid = post(client, h).json()["id"]
    client.post(f"/api/requirements/{rid}/cancel", headers=h)
    assert client.patch(f"/api/requirements/{rid}", headers=h, json={"notes": "x"}).status_code == 409


def test_other_customer_cannot_edit_or_pause(client, actors):
    owner = actors.customer()
    other = actors.customer()
    rid = post(client, owner).json()["id"]
    assert client.patch(f"/api/requirements/{rid}", headers=other, json={"notes": "x"}).status_code == 404
    assert client.post(f"/api/requirements/{rid}/pause", headers=other).status_code == 404


def test_lifecycle_is_audited(client, actors):
    h = actors.customer()
    rid = post(client, h).json()["id"]
    client.patch(f"/api/requirements/{rid}", headers=h, json={"notes": "n"})
    client.post(f"/api/requirements/{rid}/pause", headers=h)
    client.post(f"/api/requirements/{rid}/cancel", headers=h)
    from sqlmodel import select
    with Session(engine) as s:
        actions = [e.action for e in s.exec(select(AuditEvent).order_by(AuditEvent.created_at)).all()]
    assert actions[-4:] == ["REQUIREMENT_POSTED", "REQUIREMENT_EDITED", "REQUIREMENT_PAUSED", "REQUIREMENT_CANCELLED"]


# ---------- dealer view ----------
def test_dealer_leads_hide_the_buyer(client, actors):
    customer = actors.customer()
    dealer = source(client, actors.dealer(approved=True))
    post(client, customer, FULL)
    leads = client.get("/api/leads/buy", headers=dealer).json()
    assert len(leads) == 1
    lead = leads[0]
    assert lead["buyer_first_name"] == "Cust" and lead["city"] == "Bengaluru"
    assert "customer_id" not in lead and "customer_name" not in lead
    assert lead["must_have"] == ["fuel", "transmission"] and lead["urgency"] == "NOW"
    assert str(customer.user_id) not in str(lead)


def test_customers_list_only_their_own(client, actors):
    a, b = actors.customer(), actors.customer()
    post(client, a)
    assert len(client.get("/api/requirements/", headers=a).json()) == 1
    assert client.get("/api/requirements/", headers=b).json() == []
    assert client.get("/api/requirements/?status=CANCELLED", headers=a).json() == []
