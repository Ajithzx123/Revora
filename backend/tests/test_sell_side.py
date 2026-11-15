"""S6a: sell listings, sell matching, purchase offers, atomic accept, admin controls."""
import threading
import uuid
from datetime import datetime, timedelta

import pytest
from sqlmodel import Session, select

from backend.app.database.session import engine
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import DealerOffer, OfferRevision, SellListing, SellMatch
from backend.tests.conftest import LISTING, MISSING, buys


def seller_with_dealers(client, actors, n=1, **listing):
    seller = actors.customer()
    dealers = [buys(client, actors.dealer(approved=True)) for _ in range(n)]
    r = client.post("/api/sell-listings/", headers=seller, json={**LISTING, **listing})
    assert r.status_code == 201, r.text
    return seller, dealers, r.json()["id"]


def offer(client, dealer, lid, price=380_000, **extra):
    return client.post("/api/offers", headers=dealer, json={"sell_listing_id": lid, "offered_price": price, **extra})


def accept(client, seller, oid, price):
    return client.post(f"/api/offers/{oid}/accept", headers=seller, json={"expected_price": price})


def force(model, ident, **fields):
    with Session(engine) as s:
        row = s.get(model, uuid.UUID(ident) if isinstance(ident, str) else ident)
        for k, v in fields.items():
            setattr(row, k, v)
        s.add(row)
        s.commit()


def types(client, who):
    return [n["type"] for n in client.get("/api/notifications", headers=who).json()["items"]]


# ---------- creating a listing ----------
def test_listing_carries_details_and_an_offer_window(client, actors):
    seller = actors.customer()
    r = client.post("/api/sell-listings/", headers=seller, json={
        **LISTING, "variant": "ZXi", "owners": 2, "color": "white", "urgency": "URGENT",
        "loan_outstanding": True, "loan_amount": 120_000, "challans_amount": 1500, "insurance_valid": False,
        "description": "Single driver",
    })
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["status"] == "ACTIVE" and body["owners"] == 2 and body["color"] == "White" and body["loan_outstanding"]
    window = datetime.fromisoformat(body["expires_at"]) - datetime.fromisoformat(body["created_at"])
    assert timedelta(days=1, hours=23) < window < timedelta(days=2, hours=1)


@pytest.mark.parametrize("change", [
    {"make": "Nope"}, {"year": 1950}, {"year": 2999}, {"km": -1}, {"expected_price": 5},
    {"fuel": "Steam"}, {"city": "Atlantis"}, {"owners": 0}, {"urgency": "WHENEVER"},
    {"loan_amount": 1000}, {"images": ["a,b"]}, {"images": ["u"] * 13},
])
def test_listing_validation(client, actors, change):
    assert client.post("/api/sell-listings/", headers=actors.customer(), json={**LISTING, **change}).status_code == 422


def test_only_customers_list_cars_and_only_the_owner_manages_them(client, actors):
    assert client.post("/api/sell-listings/", headers=actors.dealer(approved=True), json=LISTING).status_code == 403
    seller, _, lid = seller_with_dealers(client, actors, 0)
    other = actors.customer()
    for path, body in [("price", {"expected_price": 300_000}), ("close", {})]:
        assert client.request("PUT" if path == "price" else "POST", f"/api/sell-listings/{lid}/{path}", headers=other, json=body).status_code == 404
    assert client.get("/api/sell-listings/", headers=other).json() == []
    assert len(client.get("/api/sell-listings/", headers=seller).json()) == 1


# ---------- matching ----------
def test_listing_is_shown_only_to_dealers_who_buy_that_make_in_range(client, actors):
    seller = actors.customer()
    yes = buys(client, actors.dealer(approved=True))
    wrong_make = buys(client, actors.dealer(approved=True), "Hyundai")
    no_prefs = actors.dealer(approved=True)
    unverified = buys(client, actors.dealer())
    lid = client.post("/api/sell-listings/", headers=seller, json=LISTING).json()["id"]

    assert [l["id"] for l in client.get("/api/leads/sell", headers=yes).json()] == [lid]
    for d in (wrong_make, no_prefs):
        assert client.get("/api/leads/sell", headers=d).json() == []
    assert client.get("/api/leads/sell", headers=unverified).status_code == 403
    assert "SELL_LEAD" in types(client, yes) and "SELL_LEAD" not in types(client, wrong_make)
    assert "SELL_MATCHES_FOUND" in types(client, seller)


def test_far_away_dealers_are_not_matched(client, actors):
    seller = actors.customer()
    d = buys(client, actors.dealer(approved=True))
    r = client.post("/api/sell-listings/", headers=seller, json={**LISTING, "city": "Kolkata"})  # ~1,500 km from Bengaluru
    assert client.get("/api/leads/sell", headers=d).json() == []
    assert r.status_code == 201


def test_a_listing_is_matched_to_at_most_ten_dealers_and_never_twice(client, actors):
    seller, dealers, lid = seller_with_dealers(client, actors, 12)
    with Session(engine) as s:
        assert len(s.exec(select(SellMatch)).all()) == 10
    from backend.app.services import sell_service

    with Session(engine) as s:
        assert sell_service.rematch_open_listings(s) == 0
        s.commit()
    with Session(engine) as s:
        assert len(s.exec(select(SellMatch)).all()) == 10


def test_a_dealer_who_starts_buying_a_make_later_gets_existing_listings(client, actors):
    seller = actors.customer()
    d = actors.dealer(approved=True)
    lid = client.post("/api/sell-listings/", headers=seller, json=LISTING).json()["id"]
    assert client.get("/api/leads/sell", headers=d).json() == []
    buys(client, d)
    assert [l["id"] for l in client.get("/api/leads/sell", headers=d).json()] == [lid]


def test_dealer_leads_hide_offer_counts_and_competitors(client, actors):
    seller, (a, b), lid = seller_with_dealers(client, actors, 2)
    offer(client, a, lid, 380_000)
    lead = client.get("/api/leads/sell", headers=b).json()[0]
    assert lead["offer_count"] == 0 and lead["my_offer_status"] is None and lead["match_reasons"]
    assert client.get("/api/leads/sell", headers=a).json()[0]["my_offer_status"] == "PENDING"


# ---------- submitting offers ----------
def test_unmatched_dealers_cannot_offer_or_open_the_listing(client, actors):
    seller, _, lid = seller_with_dealers(client, actors, 0)
    outsider = actors.dealer(approved=True)
    assert offer(client, outsider, lid).status_code == 404
    assert client.get(f"/api/sell-listings/{lid}", headers=outsider).status_code == 404


def test_offer_rules(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    assert offer(client, d, lid, -1).status_code == 422
    assert offer(client, d, lid, valid_hours=0).status_code == 422
    r = offer(client, d, lid, 380_000, valid_hours=24, pickup_days=3)
    assert r.status_code == 200, r.text
    o = r.json()
    assert o["status"] == "PENDING" and o["revision"] == 1 and o["pickup_days"] == 3 and o["inspection_required"]
    assert offer(client, d, lid, 390_000).status_code == 409
    assert "OFFER_RECEIVED" in types(client, seller)


def test_loan_listings_flag_loan_settlement_on_offers(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors, loan_outstanding=True, loan_amount=100_000)
    offer(client, d, lid)
    assert client.get(f"/api/sell-listings/{lid}/offers", headers=seller).json()[0]["loan_settlement_required"] is True


def test_seller_sees_offers_highest_first_and_dealers_cannot_see_them(client, actors):
    seller, (a, b, c), lid = seller_with_dealers(client, actors, 3)
    offer(client, a, lid, 360_000)
    offer(client, b, lid, 395_000)
    offer(client, c, lid, 380_000)
    prices = [o["offered_price"] for o in client.get(f"/api/sell-listings/{lid}/offers", headers=seller).json()]
    assert prices == [395_000, 380_000, 360_000]
    assert client.get(f"/api/sell-listings/{lid}/offers", headers=a).status_code == 404


# ---------- revise / withdraw / expiry ----------
def test_revise_keeps_history_and_is_limited_to_three(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 360_000).json()["id"]
    for i, price in enumerate([365_000, 370_000, 375_000], start=2):
        r = client.put(f"/api/offers/{oid}", headers=d, json={"offered_price": price})
        assert r.status_code == 200 and r.json()["revision"] == i
    assert client.put(f"/api/offers/{oid}", headers=d, json={"offered_price": 380_000}).status_code == 409
    with Session(engine) as s:
        assert [(x.revision, x.price) for x in s.exec(select(OfferRevision).order_by(OfferRevision.revision)).all()] == [
            (1, 360_000), (2, 365_000), (3, 370_000)]
    assert types(client, seller).count("OFFER_REVISED") == 3


def test_withdraw_then_it_cannot_be_accepted(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid).json()["id"]
    assert client.post(f"/api/offers/{oid}/withdraw", headers=d).json()["status"] == "WITHDRAWN"
    assert "OFFER_WITHDRAWN" in types(client, seller)
    assert accept(client, seller, oid, 380_000).status_code == 409
    assert client.post(f"/api/offers/{oid}/withdraw", headers=d).status_code == 409


def test_only_the_offers_dealer_can_change_it(client, actors):
    seller, (a, b), lid = seller_with_dealers(client, actors, 2)
    oid = offer(client, a, lid).json()["id"]
    assert client.put(f"/api/offers/{oid}", headers=b, json={"offered_price": 1}).status_code == 404
    assert client.post(f"/api/offers/{oid}/withdraw", headers=b).status_code == 404
    assert client.put(f"/api/offers/{oid}", headers=seller, json={"offered_price": 1}).status_code == 403


def test_expired_offer_cannot_be_accepted_or_revised(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid).json()["id"]
    force(DealerOffer, oid, valid_until=datetime.utcnow() - timedelta(minutes=1))
    assert accept(client, seller, oid, 380_000).status_code == 409
    with Session(engine) as s:
        assert s.get(DealerOffer, uuid.UUID(oid)).status == "EXPIRED"
    assert client.put(f"/api/offers/{oid}", headers=d, json={"offered_price": 390_000}).status_code == 409


def test_expiry_job_expires_offers_and_listings(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid).json()["id"]
    force(DealerOffer, oid, valid_until=datetime.utcnow() - timedelta(minutes=1))
    force(SellListing, lid, expires_at=datetime.utcnow() - timedelta(minutes=1))
    from backend.app.services import offer_service

    with Session(engine) as s:
        assert offer_service.expire_due_offers(s) == 2
        s.commit()
    assert client.get(f"/api/sell-listings/{lid}", headers=seller).json()["status"] == "EXPIRED"
    assert offer(client, d, lid).status_code == 404  # closed to new offers


# ---------- accept ----------
def test_accept_closes_the_others_and_releases_contact_only_to_the_winner(client, actors):
    seller, (win, lose), lid = seller_with_dealers(client, actors, 2)
    ow = offer(client, win, lid, 390_000).json()["id"]
    ol = offer(client, lose, lid, 380_000).json()["id"]
    assert client.get("/api/offers/mine", headers=win).json()[0]["seller_phone"] is None  # hidden before acceptance

    r = accept(client, seller, ow, 390_000)
    assert r.status_code == 200 and r.json()["status"] == "ACCEPTED"
    assert client.get(f"/api/sell-listings/{lid}", headers=seller).json()["status"] == "OFFER_ACCEPTED"
    mine_win = client.get("/api/offers/mine", headers=win).json()[0]
    mine_lose = client.get("/api/offers/mine", headers=lose).json()[0]
    assert mine_win["seller_name"] == "Cust" and mine_lose["status"] == "NOT_SELECTED" and mine_lose["seller_name"] is None

    won = [n for n in client.get("/api/notifications", headers=win).json()["items"] if n["type"] == "OFFER_ACCEPTED"]
    assert len(won) == 1 and won[0]["critical"]
    lost = [n for n in client.get("/api/notifications", headers=lose).json()["items"] if n["type"] == "OFFER_NOT_SELECTED"]
    assert len(lost) == 1 and "lakh" not in lost[0]["body"] and "Test Motors" not in lost[0]["body"]
    assert offer(client, win, lid).status_code in (404, 409)  # the listing no longer takes offers
    del ol


def test_accept_is_idempotent_and_refuses_a_changed_price(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 380_000).json()["id"]
    client.put(f"/api/offers/{oid}", headers=d, json={"offered_price": 370_000})
    assert accept(client, seller, oid, 380_000).status_code == 409  # stale price
    assert accept(client, seller, oid, 370_000).status_code == 200
    assert accept(client, seller, oid, 370_000).status_code == 200  # repeat is harmless
    assert types(client, d).count("OFFER_ACCEPTED") == 1


def test_two_simultaneous_accepts_produce_one_winner(client, actors):
    seller, (a, b), lid = seller_with_dealers(client, actors, 2)
    oa = offer(client, a, lid, 380_000).json()["id"]
    ob = offer(client, b, lid, 385_000).json()["id"]
    results = []
    barrier = threading.Barrier(2)

    def go(oid, price):
        barrier.wait()
        results.append(accept(client, seller, oid, price).status_code)

    threads = [threading.Thread(target=go, args=(oa, 380_000)), threading.Thread(target=go, args=(ob, 385_000))]
    [t.start() for t in threads]
    [t.join() for t in threads]
    assert sorted(results) == [200, 409]
    with Session(engine) as s:
        assert sorted(o.status for o in s.exec(select(DealerOffer)).all()) == ["ACCEPTED", "NOT_SELECTED"]


def test_only_the_listings_owner_can_accept_or_reject(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    other = actors.customer()
    oid = offer(client, d, lid).json()["id"]
    for path in ("accept", "reject"):
        assert client.post(f"/api/offers/{oid}/{path}", headers=other, json={"expected_price": 380_000}).status_code == 404
        assert client.post(f"/api/offers/{oid}/{path}", headers=d, json={"expected_price": 380_000}).status_code == 403


def test_reject_closes_one_offer_and_keeps_the_listing_open(client, actors):
    seller, (a, b), lid = seller_with_dealers(client, actors, 2)
    oa = offer(client, a, lid).json()["id"]
    offer(client, b, lid, 385_000)
    r = client.post(f"/api/offers/{oa}/reject", headers=seller, json={"reason": "Too low"})
    assert r.json()["status"] == "REJECTED"
    assert client.get(f"/api/sell-listings/{lid}", headers=seller).json()["status"] == "ACTIVE"
    assert client.post(f"/api/offers/{oa}/reject", headers=seller, json={}).status_code == 409


# ---------- seller changes ----------
def test_price_change_keeps_offers_valid_and_tells_those_dealers(client, actors):
    seller, (a, b), lid = seller_with_dealers(client, actors, 2)
    offer(client, a, lid)
    r = client.put(f"/api/sell-listings/{lid}/price", headers=seller, json={"expected_price": 350_000})
    assert r.json()["expected_price"] == 350_000
    assert "LISTING_PRICE_CHANGED" in types(client, a) and "LISTING_PRICE_CHANGED" not in types(client, b)
    assert client.get("/api/offers/mine", headers=a).json()[0]["status"] == "PENDING"
    audit = [e for e in _audit("SELL_LISTING_PRICE_CHANGED")]
    assert audit and audit[0].before_json and "400000" in audit[0].before_json and "350000" in audit[0].after_json


def test_sold_elsewhere_closes_the_listing_and_every_offer(client, actors):
    seller, (a, b), lid = seller_with_dealers(client, actors, 2)
    offer(client, a, lid)
    offer(client, b, lid, 385_000)
    r = client.post(f"/api/sell-listings/{lid}/close", headers=seller, json={"sold_elsewhere": True})
    assert r.json()["status"] == "CLOSED" and r.json()["status_reason"] == "Sold elsewhere"
    assert {o["status"] for o in client.get("/api/offers/mine", headers=a).json()} == {"NOT_SELECTED"}
    assert "LISTING_CLOSED" in types(client, b)
    assert client.post(f"/api/sell-listings/{lid}/close", headers=seller, json={}).status_code == 409
    assert client.put(f"/api/sell-listings/{lid}/price", headers=seller, json={"expected_price": 300_000}).status_code == 409


# ---------- admin ----------
def _audit(action):
    with Session(engine) as s:
        return [e for e in s.exec(select(AuditEvent)).all() if e.action == action]


def test_admin_monitors_and_voids_offers_without_touching_the_price(client, actors):
    admin = actors.admin()
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 380_000).json()["id"]
    page = client.get("/api/admin/offers", headers=admin).json()
    assert page["total"] == 1 and page["items"][0]["listing_title"] == "2018 Maruti Suzuki Swift"

    assert client.post(f"/api/admin/offers/{oid}/void", headers=admin, json={"reason": "no"}).status_code == 422
    r = client.post(f"/api/admin/offers/{oid}/void", headers=admin, json={"reason": "Suspicious pricing pattern"})
    assert r.status_code == 200 and r.json()["status"] == "VOID_ADMIN" and r.json()["offered_price"] == 380_000
    e = _audit("OFFER_VOIDED_BY_ADMIN")[0]
    assert e.actor_role == "ADMIN" and e.reason == "Suspicious pricing pattern"
    assert "OFFER_VOIDED" in types(client, seller) and "OFFER_VOIDED" in types(client, d)
    assert accept(client, seller, oid, 380_000).status_code == 409
    assert client.post(f"/api/admin/offers/{oid}/void", headers=admin, json={"reason": "Second try here"}).status_code == 409
    assert client.put(f"/api/offers/{oid}", headers=admin, json={"offered_price": 1}).status_code == 403  # admins cannot edit


def test_accepted_offers_cannot_be_voided(client, actors):
    admin = actors.admin()
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid).json()["id"]
    accept(client, seller, oid, 380_000)
    assert client.post(f"/api/admin/offers/{oid}/void", headers=admin, json={"reason": "Trying to undo"}).status_code == 409


@pytest.mark.parametrize("method,path", [
    ("get", "/api/admin/offers"), ("post", f"/api/admin/offers/{MISSING}/void"),
    ("post", f"/api/admin/sell-listings/{MISSING}/freeze"), ("post", f"/api/admin/sell-listings/{MISSING}/unfreeze"),
])
def test_admin_sell_endpoints_need_an_admin(client, actors, method, path):
    assert client.request(method.upper(), path).status_code in (401, 403)
    for who in (actors.customer(), actors.dealer(approved=True)):
        assert client.request(method.upper(), path, headers=who, json={"reason": "not allowed here"}).status_code == 403


def test_frozen_listing_takes_no_offers_and_no_acceptance(client, actors):
    admin = actors.admin()
    seller, (a, b), lid = seller_with_dealers(client, actors, 2)
    oa = offer(client, a, lid).json()["id"]
    r = client.post(f"/api/admin/sell-listings/{lid}/freeze", headers=admin, json={"reason": "Stolen vehicle report"})
    assert r.json()["status"] == "FROZEN"
    assert _audit("SELL_LISTING_FROZEN")[0].reason == "Stolen vehicle report"
    assert offer(client, b, lid).status_code == 404
    assert accept(client, seller, oa, 380_000).status_code == 409
    assert client.post(f"/api/admin/sell-listings/{lid}/freeze", headers=admin, json={"reason": "Again please"}).status_code == 409
    assert client.post(f"/api/admin/sell-listings/{lid}/unfreeze", headers=admin).json()["status"] == "ACTIVE"
    assert accept(client, seller, oa, 380_000).status_code == 200


def test_suspending_a_dealer_voids_live_offers_and_reactivation_restores_valid_ones(client, actors):
    admin = actors.admin()
    seller, (d,), lid = seller_with_dealers(client, actors)
    seller2 = actors.customer()
    lid2 = client.post("/api/sell-listings/", headers=seller2, json=LISTING).json()["id"]
    o1 = offer(client, d, lid).json()["id"]
    o2 = offer(client, d, lid2, 370_000).json()["id"]

    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Customer fraud report"})
    with Session(engine) as s:
        assert {s.get(DealerOffer, uuid.UUID(i)).status for i in (o1, o2)} == {"VOID_ADMIN"}
    assert accept(client, seller, o1, 380_000).status_code == 409
    assert "OFFER_VOIDED" in types(client, seller) and "OFFER_VOIDED" not in types(client, d)

    force(DealerOffer, o2, valid_until=datetime.utcnow() - timedelta(minutes=1))
    client.post(f"/api/admin/dealers/{d.dealer_id}/reactivate", headers=admin)
    with Session(engine) as s:
        assert s.get(DealerOffer, uuid.UUID(o1)).status == "PENDING"
        assert s.get(DealerOffer, uuid.UUID(o2)).status == "EXPIRED"
    assert accept(client, seller, o1, 380_000).status_code == 200


def test_repeated_offer_accept_races_never_deadlock_or_error(client, actors):
    """Same race as quotes: two offers on one listing accepted at once must give one 200 and one 409."""
    a, b = (buys(client, actors.dealer(approved=True)) for _ in range(2))  # the same two dealers each round
    for _ in range(8):
        seller = actors.customer()
        lid = client.post("/api/sell-listings/", headers=seller, json=LISTING).json()["id"]
        oa = offer(client, a, lid, 380_000).json()["id"]
        ob = offer(client, b, lid, 385_000).json()["id"]
        results, barrier = [], threading.Barrier(2)

        def go(oid, price):
            barrier.wait()
            results.append(accept(client, seller, oid, price).status_code)

        threads = [threading.Thread(target=go, args=(oa, 380_000)), threading.Thread(target=go, args=(ob, 385_000))]
        [t.start() for t in threads]
        [t.join() for t in threads]
        assert sorted(results) == [200, 409], results
