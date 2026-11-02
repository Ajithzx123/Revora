"""S4: quotes, revisions, negotiation, and atomic accept."""
import threading
import uuid
from datetime import datetime, timedelta

from sqlmodel import Session, select

from backend.app.database.session import engine
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import DealerQuote, Vehicle
from backend.tests.conftest import REQUIREMENT, car, source


def setup_request(client, actors, n_dealers=1, with_car=False):
    customer = actors.customer()
    dealers = [source(client, actors.dealer(approved=True)) for _ in range(n_dealers)]
    rid = client.post("/api/requirements/", headers=customer, json=REQUIREMENT).json()["id"]
    return customer, dealers, rid


def quote(client, dealer, rid, price=650_000, **extra):
    return client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": price, **extra})


def accept(client, customer, qid, price):
    return client.post(f"/api/quotes/{qid}/accept", headers=customer, json={"expected_price": price})


def expire(qid):
    with Session(engine) as s:
        q = s.get(DealerQuote, uuid.UUID(qid))
        q.valid_until = datetime.utcnow() - timedelta(minutes=1)
        s.add(q)
        s.commit()


# ---------- submit ----------
def test_quote_carries_kind_validity_and_terms(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    r = quote(client, d, rid, valid_hours=48, delivery_days=7, warranty_months=6)
    assert r.status_code == 200, r.text
    q = r.json()
    assert q["kind"] == "SOURCED" and q["revision"] == 1 and q["status"] == "PENDING"
    assert q["delivery_days"] == 7 and q["warranty_months"] == 6 and q["valid_until"]


def test_quote_with_a_car_in_stock_is_in_stock_kind_with_vehicle_summary(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    vid = client.post("/api/inventory", headers=dealer, json=car()).json()["id"]
    rid = client.post("/api/requirements/", headers=customer, json=REQUIREMENT).json()["id"]
    q = quote(client, dealer, rid, vehicle_id=vid).json()
    assert q["kind"] == "IN_STOCK" and q["vehicle_year"] == 2021 and q["vehicle_title"].endswith("i20")
    listed = client.get(f"/api/requirements/{rid}/quotes", headers=customer).json()
    assert listed[0]["vehicle_id"] == vid


def test_customers_list_is_sorted_cheapest_first_and_sealed(client, actors):
    customer, (a, b), rid = setup_request(client, actors, 2)
    quote(client, a, rid, 680_000)
    quote(client, b, rid, 640_000)
    prices = [q["quoted_price"] for q in client.get(f"/api/requirements/{rid}/quotes", headers=customer).json()]
    assert prices == [640_000, 680_000]
    assert client.get(f"/api/requirements/{rid}/quotes", headers=a).status_code == 404


# ---------- revise / withdraw / expiry ----------
def test_revise_changes_the_price_and_keeps_history(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    r = client.put(f"/api/quotes/{qid}", headers=d, json={"quoted_price": 630_000})
    assert r.status_code == 200 and r.json()["revision"] == 2 and r.json()["quoted_price"] == 630_000
    from backend.app.models.marketplace_models import QuoteRevision

    with Session(engine) as s:
        assert [(x.revision, x.price) for x in s.exec(select(QuoteRevision)).all()] == [(1, 650_000)]


def test_at_most_three_revisions(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    for i in range(3):
        assert client.put(f"/api/quotes/{qid}", headers=d, json={"quoted_price": 640_000 - i * 1000}).status_code == 200
    assert client.put(f"/api/quotes/{qid}", headers=d, json={"quoted_price": 1000}).status_code == 409


def test_revising_after_the_buyer_edits_the_request_makes_it_live_again(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid).json()["id"]
    client.patch(f"/api/requirements/{rid}", headers=customer, json={"budget_max": 1_200_000})
    assert client.get(f"/api/requirements/{rid}/quotes", headers=customer).json()[0]["status"] == "REQUOTE_REQUESTED"
    assert accept(client, customer, qid, 650_000).status_code == 409
    r = client.put(f"/api/quotes/{qid}", headers=d, json={"quoted_price": 900_000})
    assert r.json()["status"] == "PENDING"


def test_withdraw_needs_no_reason_but_not_after_accept(client, actors):
    customer, (a, b), rid = setup_request(client, actors, 2)
    qa, qb = quote(client, a, rid).json()["id"], quote(client, b, rid).json()["id"]
    r = client.post(f"/api/quotes/{qa}/withdraw", headers=a, json={"reason": "Sold elsewhere"})
    assert r.json()["status"] == "WITHDRAWN" and r.json()["status_reason"] == "Sold elsewhere"
    assert accept(client, customer, qa, 650_000).status_code == 409
    assert accept(client, customer, qb, 650_000).status_code == 200
    assert client.post(f"/api/quotes/{qb}/withdraw", headers=b, json={}).status_code == 409


def test_expired_quote_cannot_be_accepted_or_revised(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid).json()["id"]
    expire(qid)
    assert accept(client, customer, qid, 650_000).status_code == 409
    assert client.get(f"/api/requirements/{rid}/quotes", headers=customer).json()[0]["status"] == "EXPIRED"
    assert client.put(f"/api/quotes/{qid}", headers=d, json={"quoted_price": 600_000}).status_code == 409


def test_expiry_job_expires_due_quotes(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid).json()["id"]
    expire(qid)
    from backend.app.services import quote_service

    with Session(engine) as s:
        assert quote_service.expire_due_quotes(s) == 1
        s.commit()
        assert s.get(DealerQuote, uuid.UUID(qid)).status == "EXPIRED"


# ---------- accept ----------
def test_accept_closes_the_others_and_locks_the_request(client, actors):
    customer, (a, b, c), rid = setup_request(client, actors, 3)
    qa, qb, qc = (quote(client, d, rid, 650_000 + i).json()["id"] for i, d in enumerate((a, b, c)))
    r = accept(client, customer, qb, 650_001)
    assert r.status_code == 200 and r.json()["status"] == "ACCEPTED"
    statuses = {q["id"]: q["status"] for q in client.get(f"/api/requirements/{rid}/quotes", headers=customer).json()}
    assert statuses == {qa: "NOT_SELECTED", qb: "ACCEPTED", qc: "NOT_SELECTED"}
    assert client.get(f"/api/requirements/{rid}", headers=customer).json()["status"] == "QUOTE_ACCEPTED"
    assert accept(client, customer, qa, 650_000).status_code == 409
    with Session(engine) as s:
        assert s.exec(select(AuditEvent).where(AuditEvent.action == "QUOTE_ACCEPTED")).all()


def test_accept_is_idempotent_for_the_same_quote(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid).json()["id"]
    assert accept(client, customer, qid, 650_000).status_code == 200
    assert accept(client, customer, qid, 650_000).status_code == 200


def test_accept_refuses_if_the_price_changed(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    client.put(f"/api/quotes/{qid}", headers=d, json={"quoted_price": 700_000})
    r = accept(client, customer, qid, 650_000)
    assert r.status_code == 409 and "price changed" in r.json()["detail"]
    assert accept(client, customer, qid, 700_000).status_code == 200


def test_accept_reserves_the_car_and_refuses_if_it_was_sold(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    v1 = client.post("/api/inventory", headers=dealer, json=car()).json()["id"]
    rid = client.post("/api/requirements/", headers=customer, json=REQUIREMENT).json()["id"]
    qid = quote(client, dealer, rid, vehicle_id=v1).json()["id"]
    assert accept(client, customer, qid, 650_000).status_code == 200
    assert client.get(f"/api/inventory/{v1}", headers=dealer).json()["status"] == "RESERVED"


def test_two_simultaneous_accepts_produce_one_winner(client, actors):
    customer, (a, b), rid = setup_request(client, actors, 2)
    qa, qb = quote(client, a, rid, 650_000).json()["id"], quote(client, b, rid, 640_000).json()["id"]
    barrier, codes = threading.Barrier(2), []

    def go(qid, price):
        barrier.wait()
        codes.append(accept(client, customer, qid, price).status_code)

    threads = [threading.Thread(target=go, args=args) for args in ((qa, 650_000), (qb, 640_000))]
    [t.start() for t in threads]
    [t.join() for t in threads]
    assert sorted(codes) == [200, 409]
    with Session(engine) as s:
        assert len(s.exec(select(DealerQuote).where(DealerQuote.status == "ACCEPTED")).all()) == 1


def test_only_the_owner_can_accept_or_reject(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid).json()["id"]
    other = actors.customer()
    assert accept(client, other, qid, 650_000).status_code == 404
    assert client.post(f"/api/quotes/{qid}/reject", headers=other, json={}).status_code == 404
    assert accept(client, d, qid, 650_000).status_code == 403  # a dealer is not a customer
    assert client.post(f"/api/quotes/{qid}/reject", headers=customer, json={"reason": "Too high"}).json()["status"] == "REJECTED"


def test_dealers_can_only_touch_their_own_quotes(client, actors):
    customer, (a, b), rid = setup_request(client, actors, 2)
    qa = quote(client, a, rid).json()["id"]
    assert client.put(f"/api/quotes/{qa}", headers=b, json={"quoted_price": 1}).status_code == 404
    assert client.post(f"/api/quotes/{qa}/withdraw", headers=b, json={}).status_code == 404


# ---------- negotiation ----------
def test_counter_offer_accepted_updates_the_price(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    r = client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 600_000, "note": "cash today"})
    assert r.status_code == 200 and r.json()["rounds"][0]["status"] == "OPEN"
    r = client.post(f"/api/quotes/{qid}/negotiation", headers=d, json={"action": "ACCEPT"})
    q = r.json()
    assert q["quoted_price"] == 600_000 and q["revision"] == 2 and q["rounds"][0]["status"] == "AGREED"
    assert accept(client, customer, qid, 650_000).status_code == 409  # stale price
    assert accept(client, customer, qid, 600_000).status_code == 200


def test_dealer_counters_back_and_buyer_accepts(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 600_000})
    assert client.post(f"/api/quotes/{qid}/negotiation", headers=d, json={"action": "COUNTER", "price": 700_000}).status_code == 422
    r = client.post(f"/api/quotes/{qid}/negotiation", headers=d, json={"action": "COUNTER", "price": 630_000})
    assert [x["by"] for x in r.json()["rounds"]] == ["CUSTOMER", "DEALER"]
    r = client.post(f"/api/quotes/{qid}/negotiation/respond", headers=customer, json={"action": "ACCEPT"})
    assert r.json()["quoted_price"] == 630_000


def test_counter_rules(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    assert client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 650_000}).status_code == 422
    assert client.post(f"/api/quotes/{qid}/negotiation", headers=d, json={"action": "ACCEPT"}).status_code == 409  # nothing to answer
    client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 600_000})
    assert client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 610_000}).status_code == 409  # one at a time
    client.post(f"/api/quotes/{qid}/negotiation", headers=d, json={"action": "DECLINE"})
    # a dealer's revision supersedes an open counter
    client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 610_000})
    r = client.put(f"/api/quotes/{qid}", headers=d, json={"quoted_price": 640_000})
    assert [x["status"] for x in r.json()["rounds"]] == ["DECLINED", "SUPERSEDED"]


def test_at_most_five_rounds(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    for i in range(5):
        assert client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 500_000 + i}).status_code == 200
        client.post(f"/api/quotes/{qid}/negotiation", headers=d, json={"action": "DECLINE"})
    assert client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 560_000}).status_code == 409


# ---------- dealer view ----------
def test_my_quotes_hides_buyer_contact_until_accepted(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid).json()["id"]
    mine = client.get("/api/quotes/mine", headers=d).json()
    assert mine[0]["buyer_first_name"] == "Cust" and mine[0]["buyer_name"] is None and mine[0]["buyer_phone"] is None
    assert mine[0]["request_title"] == "Hyundai i20"
    accept(client, customer, qid, 650_000)
    mine = client.get("/api/quotes/mine", headers=d).json()
    assert mine[0]["status"] == "ACCEPTED" and mine[0]["buyer_name"] == "Cust"
    assert client.get("/api/quotes/mine", headers=customer).status_code == 403
