"""S5b: audit log, quote monitoring, admin voids, suspensions."""
import uuid
from datetime import datetime, timedelta

import pytest
from sqlmodel import Session, select

from backend.app.database.session import engine
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import DealerQuote
from backend.tests.conftest import MISSING
from backend.tests.test_quotes import accept, quote, setup_request


def audit_rows(**where):
    with Session(engine) as s:
        rows = s.exec(select(AuditEvent)).all()
    return [r for r in rows if all(getattr(r, k) == v for k, v in where.items())]


def last(action):
    rows = audit_rows(action=action)
    assert rows, f"no {action} audit event"
    return rows[-1]


# ---------- access ----------
@pytest.mark.parametrize(
    "method,path",
    [
        ("get", "/api/admin/audit"),
        ("get", "/api/admin/quotes"),
        ("post", f"/api/admin/quotes/{MISSING}/void"),
        ("post", f"/api/admin/users/{MISSING}/suspend"),
        ("post", f"/api/admin/users/{MISSING}/reactivate"),
    ],
)
def test_admin_core_endpoints_need_an_admin(client, actors, method, path):
    assert getattr(client, method)(path).status_code in (401, 403)
    for who in (actors.customer(), actors.dealer(approved=True)):
        assert client.request(method.upper(), path, headers=who, json={"reason": "not allowed here"}).status_code == 403


# ---------- audit log ----------
def test_audit_log_is_paginated_filterable_and_read_only(client, actors):
    admin, d = actors.admin(), actors.dealer(approved=True)
    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Customer fraud report"})
    r = client.get("/api/admin/audit", headers=admin, params={"action": "DEALER_SUSPENDED"})
    page = r.json()
    assert page["total"] == 1
    e = page["items"][0]
    assert e["actor_role"] == "ADMIN" and e["actor_name"] == "Admin" and e["reason"] == "Customer fraud report"
    assert e["before"] == {"status": "APPROVED"} and e["after"] == {"status": "SUSPENDED"}
    assert e["entity_type"] == "dealer" and e["entity_id"] == str(d.dealer_id)

    assert client.get("/api/admin/audit", headers=admin, params={"limit": 0}).status_code == 422
    assert client.get("/api/admin/audit", headers=admin, params={"limit": 201}).status_code == 422
    by_entity = client.get("/api/admin/audit", headers=admin, params={"entity_id": str(d.dealer_id)}).json()
    assert by_entity["total"] >= 1 and all(i["entity_id"] == str(d.dealer_id) for i in by_entity["items"])
    # nothing can edit or delete an audit event through the API
    row_id = e["id"]
    for method in ("put", "patch", "delete", "post"):
        assert getattr(client, method)(f"/api/admin/audit/{row_id}", headers=admin).status_code in (404, 405)


def test_audit_rows_cannot_be_updated_or_deleted():
    with Session(engine) as s:
        s.add(AuditEvent(action="X", entity_type="t", entity_id="1"))
        s.commit()
        row = s.exec(select(AuditEvent)).first()
        row.reason = "tampered"
        s.add(row)
        with pytest.raises(RuntimeError, match="append-only"):
            s.commit()
        s.rollback()
        s.delete(s.exec(select(AuditEvent)).first())
        with pytest.raises(RuntimeError, match="append-only"):
            s.commit()


def test_every_admin_action_writes_an_audit_event_with_role_and_reason(client, actors):
    admin = actors.admin()
    pending = actors.dealer()  # DRAFT dealer, for document-free actions
    d = actors.dealer(approved=True)
    customer, (qd,), rid = setup_request(client, actors)
    qid = quote(client, qd, rid).json()["id"]

    calls = [
        ("DEALER_SUSPENDED", lambda: client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Policy breach"})),
        ("DEALER_APPROVED", lambda: client.post(f"/api/admin/dealers/{d.dealer_id}/reactivate", headers=admin)),
        ("QUOTE_VOIDED_BY_ADMIN", lambda: client.post(f"/api/admin/quotes/{qid}/void", headers=admin, json={"reason": "Suspicious pricing"})),
        ("USER_SUSPENDED", lambda: client.post(f"/api/admin/users/{customer.user_id}/suspend", headers=admin, json={"reason": "Abusive messages"})),
        ("USER_REACTIVATED", lambda: client.post(f"/api/admin/users/{customer.user_id}/reactivate", headers=admin)),
        ("MATCHING_RUN", lambda: client.post("/api/admin/matching/run", headers=admin)),
    ]
    for action, call in calls:
        assert call().status_code == 200, action
        e = last(action)
        assert e.actor_user_id == admin.user_id and e.actor_role == "ADMIN", action
    for action in ("DEALER_SUSPENDED", "QUOTE_VOIDED_BY_ADMIN", "USER_SUSPENDED"):
        assert last(action).reason, action


# ---------- quote monitoring and void ----------
def test_admin_monitors_quotes_with_filters(client, actors):
    admin = actors.admin()
    customer, (a, b), rid = setup_request(client, actors, 2)
    quote(client, a, rid, 650_000)
    qb = quote(client, b, rid, 690_000).json()["id"]
    client.post(f"/api/quotes/{qb}/withdraw", headers=b, json={})

    allq = client.get("/api/admin/quotes", headers=admin).json()
    assert allq["total"] == 2 and {i["quoted_price"] for i in allq["items"]} == {650_000, 690_000}
    assert allq["items"][0]["dealer_name"] == "Test Motors" and allq["items"][0]["request_title"] == "Hyundai i20"
    assert client.get("/api/admin/quotes", headers=admin, params={"status": "WITHDRAWN"}).json()["total"] == 1
    assert client.get("/api/admin/quotes", headers=admin, params={"dealer_id": str(a.dealer_id)}).json()["total"] == 1
    assert client.get("/api/admin/quotes", headers=admin, params={"limit": 1}).json()["items"].__len__() == 1


def test_void_needs_a_reason_and_never_changes_the_price(client, actors):
    admin = actors.admin()
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]

    assert client.post(f"/api/admin/quotes/{qid}/void", headers=admin, json={}).status_code == 422
    assert client.post(f"/api/admin/quotes/{qid}/void", headers=admin, json={"reason": "no"}).status_code == 422
    r = client.post(f"/api/admin/quotes/{qid}/void", headers=admin, json={"reason": "Price looks fraudulent"})
    assert r.status_code == 200 and r.json()["status"] == "VOID_ADMIN" and r.json()["quoted_price"] == 650_000
    e = last("QUOTE_VOIDED_BY_ADMIN")
    assert e.before_json and '"PENDING"' in e.before_json and '"VOID_ADMIN"' in e.after_json

    # a voided quote cannot be accepted, revised or voided again
    assert accept(client, customer, qid, 650_000).status_code == 409
    assert client.put(f"/api/quotes/{qid}", headers=d, json={"quoted_price": 600_000}).status_code == 409
    assert client.post(f"/api/admin/quotes/{qid}/void", headers=admin, json={"reason": "Second try here"}).status_code == 409
    assert client.post(f"/api/admin/quotes/{uuid.uuid4()}/void", headers=admin, json={"reason": "Does not exist"}).status_code == 404


def test_void_tells_the_buyer_and_the_dealer(client, actors):
    admin = actors.admin()
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid).json()["id"]
    client.post(f"/api/admin/quotes/{qid}/void", headers=admin, json={"reason": "Price looks fraudulent"})
    mine = [n for n in client.get("/api/notifications", headers=d).json()["items"] if n["type"] == "QUOTE_VOIDED"]
    assert len(mine) == 1 and "Price looks fraudulent" in mine[0]["body"]
    theirs = [n for n in client.get("/api/notifications", headers=customer).json()["items"] if n["type"] == "QUOTE_VOIDED"]
    assert len(theirs) == 1 and "Price looks fraudulent" not in theirs[0]["body"]


def test_an_accepted_deal_cannot_be_voided_and_admins_cannot_edit_prices(client, actors):
    admin = actors.admin()
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    accept(client, customer, qid, 650_000)
    assert client.post(f"/api/admin/quotes/{qid}/void", headers=admin, json={"reason": "Trying to undo"}).status_code == 409
    # no admin route edits a quote: the dealer and buyer routes refuse an admin token
    assert client.put(f"/api/quotes/{qid}", headers=admin, json={"quoted_price": 1}).status_code == 403
    assert client.post(f"/api/quotes/{qid}/counter", headers=admin, json={"price": 1}).status_code == 403
    with Session(engine) as s:
        assert s.get(DealerQuote, uuid.UUID(qid)).quoted_price == 650_000


# ---------- suspension and reactivation ----------
def test_suspending_a_dealer_voids_their_live_quotes_and_reactivation_restores_valid_ones(client, actors):
    admin = actors.admin()
    customer, (d,), rid = setup_request(client, actors)
    other_customer = actors.customer()
    rid2 = client.post("/api/requirements/", headers=other_customer, json={"make": "Hyundai", "model": "i20", "year_min": 2021, "budget_max": 700000, "city": "Bengaluru"}).json()["id"]
    q1 = quote(client, d, rid, 650_000).json()["id"]
    q2 = quote(client, d, rid2, 660_000).json()["id"]

    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Customer fraud report"})
    for qid in (q1, q2):
        with Session(engine) as s:
            q = s.get(DealerQuote, uuid.UUID(qid))
            assert q.status == "VOID_ADMIN" and q.void_cause == "DEALER_SUSPENDED" and q.quoted_price in (650_000, 660_000)
    assert len(audit_rows(action="QUOTE_VOIDED_BY_ADMIN")) == 2
    assert accept(client, customer, q1, 650_000).status_code == 409
    # the buyer is told; the suspended dealer is not told twice (they get the suspension notice)
    assert any(n["type"] == "QUOTE_VOIDED" for n in client.get("/api/notifications", headers=customer).json()["items"])
    assert not any(n["type"] == "QUOTE_VOIDED" for n in client.get("/api/notifications", headers=d).json()["items"])

    # one quote runs out of time while suspended
    with Session(engine) as s:
        q = s.get(DealerQuote, uuid.UUID(q2))
        q.valid_until = datetime.utcnow() - timedelta(minutes=1)
        s.add(q)
        s.commit()
    client.post(f"/api/admin/dealers/{d.dealer_id}/reactivate", headers=admin)
    with Session(engine) as s:
        assert s.get(DealerQuote, uuid.UUID(q1)).status == "PENDING"
        assert s.get(DealerQuote, uuid.UUID(q2)).status == "EXPIRED"
    assert accept(client, customer, q1, 650_000).status_code == 200


def test_reactivation_does_not_restore_a_quote_the_admin_voided_by_hand(client, actors):
    admin = actors.admin()
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid).json()["id"]
    client.post(f"/api/admin/quotes/{qid}/void", headers=admin, json={"reason": "Price looks fraudulent"})
    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Customer fraud report"})
    client.post(f"/api/admin/dealers/{d.dealer_id}/reactivate", headers=admin)
    with Session(engine) as s:
        assert s.get(DealerQuote, uuid.UUID(qid)).status == "VOID_ADMIN"


def test_reactivation_does_not_resurrect_a_quote_on_a_request_that_closed(client, actors):
    admin = actors.admin()
    customer, (d, other), rid = setup_request(client, actors, 2)
    qd = quote(client, d, rid, 650_000).json()["id"]
    qo = quote(client, other, rid, 640_000).json()["id"]
    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Customer fraud report"})
    accept(client, customer, qo, 640_000)
    client.post(f"/api/admin/dealers/{d.dealer_id}/reactivate", headers=admin)
    with Session(engine) as s:
        assert s.get(DealerQuote, uuid.UUID(qd)).status == "NOT_SELECTED"


# ---------- customer accounts ----------
def test_suspending_a_customer_blocks_them_and_reactivation_restores_access(client, actors):
    admin, customer = actors.admin(), actors.customer()
    assert client.post(f"/api/admin/users/{customer.user_id}/suspend", headers=admin, json={}).status_code == 422  # reason required
    r = client.post(f"/api/admin/users/{customer.user_id}/suspend", headers=admin, json={"reason": "Abusive messages"})
    assert r.json() == {"id": str(customer.user_id), "role": "CUSTOMER", "is_active": False}
    assert client.get("/api/notifications", headers=customer).status_code == 403
    assert client.post(f"/api/admin/users/{customer.user_id}/suspend", headers=admin, json={"reason": "Abusive messages"}).status_code == 409
    assert client.post(f"/api/admin/users/{customer.user_id}/reactivate", headers=admin).json()["is_active"] is True
    assert client.get("/api/notifications", headers=customer).status_code == 200


def test_admins_and_dealers_cannot_be_suspended_through_the_user_endpoint(client, actors):
    admin, other_admin, d = actors.admin(), actors.admin(), actors.dealer(approved=True)
    body = {"reason": "Should not be possible"}
    assert client.post(f"/api/admin/users/{admin.user_id}/suspend", headers=admin, json=body).status_code == 409
    assert client.post(f"/api/admin/users/{other_admin.user_id}/suspend", headers=admin, json=body).status_code == 409
    assert client.post(f"/api/admin/users/{d.user_id}/suspend", headers=admin, json=body).status_code == 409
    assert client.post(f"/api/admin/users/{uuid.uuid4()}/suspend", headers=admin, json=body).status_code == 404
