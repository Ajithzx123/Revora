"""S6c: seller/dealer counter-offers, and the inspection stage (final offer)."""
import uuid
from datetime import datetime, timedelta

import pytest
from sqlmodel import Session, select

from backend.app.database.session import engine
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import DealerOffer, OfferRevision, OfferRound, SellListing
from backend.tests.conftest import MISSING
from backend.tests.test_sell_side import accept, force, offer, seller_with_dealers, types


def counter(client, who, oid, price, note=None):
    return client.post(f"/api/offers/{oid}/counter", headers=who, json={"price": price, "note": note})


def dealer_reply(client, who, oid, action, price=None):
    return client.post(f"/api/offers/{oid}/negotiation", headers=who, json={"action": action, "price": price})


def seller_reply(client, who, oid, action):
    return client.post(f"/api/offers/{oid}/negotiation/respond", headers=who, json={"action": action})


def final(client, who, oid, price, **extra):
    return client.post(f"/api/offers/{oid}/final", headers=who, json={"price": price, **extra})


def final_reply(client, who, oid, action):
    return client.post(f"/api/offers/{oid}/final/respond", headers=who, json={"action": action})


def listing_status(client, seller, lid):
    return client.get(f"/api/sell-listings/{lid}", headers=seller).json()["status"]


def accepted_offer(client, actors, price=400_000, **offer_extra):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, price, **offer_extra).json()["id"]
    assert accept(client, seller, oid, price).status_code == 200
    return seller, d, lid, oid


def audit(action):
    with Session(engine) as s:
        return [e for e in s.exec(select(AuditEvent)).all() if e.action == action]


# ---------- counter-offers ----------
def test_seller_counters_higher_and_dealer_accepts_the_new_price(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 380_000).json()["id"]

    assert counter(client, seller, oid, 380_000).status_code == 422  # must be higher
    assert counter(client, seller, oid, 370_000).status_code == 422
    r = counter(client, seller, oid, 400_000, "Cash today")
    assert r.status_code == 200 and r.json()["rounds"][0]["status"] == "OPEN" and r.json()["rounds"][0]["by"] == "SELLER"
    assert "OFFER_COUNTER_RECEIVED" in types(client, d)

    r = dealer_reply(client, d, oid, "ACCEPT")
    o = r.json()
    assert o["offered_price"] == 400_000 and o["revision"] == 2 and o["rounds"][0]["status"] == "AGREED"
    assert "OFFER_COUNTER_ACCEPTED" in types(client, seller)
    with Session(engine) as s:
        assert [(x.revision, x.price) for x in s.exec(select(OfferRevision)).all()] == [(1, 380_000)]
    assert accept(client, seller, oid, 380_000).status_code == 409  # stale price
    assert accept(client, seller, oid, 400_000).status_code == 200


def test_dealer_counters_back_between_the_two_prices(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 380_000).json()["id"]
    counter(client, seller, oid, 410_000)
    assert dealer_reply(client, d, oid, "COUNTER", 420_000).status_code == 422  # above the ask
    assert dealer_reply(client, d, oid, "COUNTER", 380_000).status_code == 422  # not above their own offer
    assert dealer_reply(client, d, oid, "COUNTER").status_code == 422           # price required
    r = dealer_reply(client, d, oid, "COUNTER", 395_000)
    assert [x["by"] for x in r.json()["rounds"]] == ["SELLER", "DEALER"]
    assert "OFFER_COUNTER_RECEIVED" in types(client, seller)

    # the seller can only accept or decline the dealer's counter
    assert client.post(f"/api/offers/{oid}/negotiation/respond", headers=seller, json={"action": "COUNTER", "price": 400_000}).status_code == 422
    assert seller_reply(client, seller, oid, "ACCEPT").json()["offered_price"] == 395_000


def test_declining_a_counter_leaves_the_price(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 380_000).json()["id"]
    counter(client, seller, oid, 410_000)
    r = dealer_reply(client, d, oid, "DECLINE")
    assert r.json()["offered_price"] == 380_000 and r.json()["rounds"][0]["status"] == "DECLINED"
    assert "OFFER_COUNTER_DECLINED" in types(client, seller)
    assert dealer_reply(client, d, oid, "ACCEPT").status_code == 409  # nothing left to answer


def test_counter_rules(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 380_000).json()["id"]
    assert dealer_reply(client, d, oid, "ACCEPT").status_code == 409                # nothing to answer
    assert counter(client, seller, oid, 410_000).status_code == 200
    assert counter(client, seller, oid, 405_000).status_code == 409                 # one at a time
    assert seller_reply(client, seller, oid, "ACCEPT").status_code == 409          # not their turn
    assert counter(client, d, oid, 400_000).status_code == 403                      # a dealer cannot use the seller route


def test_at_most_five_rounds(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 380_000).json()["id"]
    counter(client, seller, oid, 450_000)                       # 1
    dealer_reply(client, d, oid, "COUNTER", 440_000)            # 2
    dealer_reply(client, d, oid, "DECLINE")                     # seller's counter is gone, ours stays open
    with Session(engine) as s:
        for r in s.exec(select(OfferRound)).all():
            r.status = "DECLINED"
            s.add(r)
        s.commit()
    for i in range(3):
        assert counter(client, seller, oid, 460_000 + i).status_code == 200
        with Session(engine) as s:
            open_round = s.exec(select(OfferRound).where(OfferRound.status == "OPEN")).first()
            open_round.status = "DECLINED"
            s.add(open_round)
            s.commit()
    assert counter(client, seller, oid, 470_000).status_code == 409


def test_a_counter_expires_after_a_day(client, actors):
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 380_000).json()["id"]
    counter(client, seller, oid, 410_000)
    with Session(engine) as s:
        r = s.exec(select(OfferRound)).first()
        r.valid_until = datetime.utcnow() - timedelta(minutes=1)
        s.add(r)
        s.commit()
    assert dealer_reply(client, d, oid, "ACCEPT").status_code == 409
    assert counter(client, seller, oid, 405_000).status_code == 200  # a new one can start


def test_a_revision_a_withdrawal_or_an_accept_closes_an_open_counter(client, actors):
    seller, (a, b), lid = seller_with_dealers(client, actors, 2)
    oa = offer(client, a, lid, 380_000).json()["id"]
    ob = offer(client, b, lid, 385_000).json()["id"]
    counter(client, seller, oa, 410_000)
    counter(client, seller, ob, 415_000)
    r = client.put(f"/api/offers/{oa}", headers=a, json={"offered_price": 390_000})
    assert [x["status"] for x in r.json()["rounds"]] == ["SUPERSEDED"]
    assert accept(client, seller, oa, 390_000).status_code == 200
    with Session(engine) as s:
        assert {r.status for r in s.exec(select(OfferRound)).all()} == {"SUPERSEDED"}  # the other dealer's counter closed too


def test_only_the_parties_can_negotiate(client, actors):
    seller, (a, b), lid = seller_with_dealers(client, actors, 2)
    other = actors.customer()
    oid = offer(client, a, lid, 380_000).json()["id"]
    assert counter(client, other, oid, 410_000).status_code == 404
    counter(client, seller, oid, 410_000)
    assert dealer_reply(client, b, oid, "ACCEPT").status_code == 404
    assert client.post(f"/api/offers/{oid}/negotiation/respond", headers=other, json={"action": "ACCEPT"}).status_code == 404
    admin = actors.admin()
    assert counter(client, admin, oid, 420_000).status_code == 403
    assert dealer_reply(client, admin, oid, "ACCEPT").status_code == 403


@pytest.mark.parametrize("method,path", [
    ("post", f"/api/offers/{MISSING}/counter"), ("post", f"/api/offers/{MISSING}/negotiation"),
    ("post", f"/api/offers/{MISSING}/negotiation/respond"), ("post", f"/api/offers/{MISSING}/final"),
    ("post", f"/api/offers/{MISSING}/final/respond"),
])
def test_negotiation_endpoints_reject_anonymous(client, method, path):
    assert getattr(client, method)(path).status_code in (401, 403)


# ---------- inspection: the final offer ----------
def test_the_same_price_is_confirmed_at_once(client, actors):
    seller, d, lid, oid = accepted_offer(client, actors)
    r = final(client, d, oid, 400_000)
    assert r.status_code == 200
    assert r.json()["final_status"] == "ACCEPTED" and r.json()["final_drop_percent"] == 0
    assert listing_status(client, seller, lid) == "FINAL_ACCEPTED"
    assert "FINAL_OFFER_RECEIVED" in types(client, seller)
    assert audit("OFFER_FINAL_CONFIRMED")


def test_a_lower_price_needs_a_reason_and_a_big_drop_needs_evidence(client, actors):
    seller, d, lid, oid = accepted_offer(client, actors)
    assert final(client, d, oid, 390_000).status_code == 422                                  # lower, no reason
    assert final(client, d, oid, 390_000, reason_code="NOPE").status_code == 422              # unknown reason
    assert final(client, d, oid, 410_000, reason_code="OTHER").status_code == 422             # higher than accepted
    assert final(client, d, oid, 370_000, reason_code="MECHANICAL_ISSUE").status_code == 422  # 7.5% drop, no evidence
    assert listing_status(client, seller, lid) == "OFFER_ACCEPTED"                            # nothing changed
    r = final(client, d, oid, 390_000, reason_code="body condition")                          # 2.5% drop: reason is enough
    assert r.status_code == 200 and r.json()["final_status"] == "SUBMITTED" and r.json()["final_reason_code"] == "BODY_CONDITION"
    assert listing_status(client, seller, lid) == "OFFER_ACCEPTED"                            # waits for the seller
    assert audit("OFFER_FINAL_LARGE_DROP") == []


def test_a_big_drop_with_evidence_is_flagged_and_explained_to_the_seller(client, actors):
    seller, d, lid, oid = accepted_offer(client, actors)
    r = final(client, d, oid, 360_000, reason_code="UNDISCLOSED_ACCIDENT", reason_note="Rear panel repaired",
              evidence_urls=["https://files.example/p1.jpg", "https://files.example/report.pdf"])
    assert r.status_code == 200
    o = r.json()
    assert o["final_status"] == "SUBMITTED" and o["final_drop_percent"] == 10.0 and len(o["final_evidence"]) == 2
    note = [n for n in client.get("/api/notifications", headers=seller).json()["items"] if n["type"] == "FINAL_OFFER_RECEIVED"][0]
    assert "lower" in note["body"] and "undisclosed accident" in note["body"] and note["critical"]
    flag = audit("OFFER_FINAL_LARGE_DROP")[0]
    assert flag.actor_role == "DEALER" and flag.entity_id == oid
    shown = client.get(f"/api/sell-listings/{lid}/offers", headers=seller).json()[0]
    assert shown["final_price"] == 360_000 and shown["final_reason_note"] == "Rear panel repaired"


def test_a_final_offer_needs_an_accepted_offer_that_is_subject_to_inspection(client, actors):
    seller, (d, other), lid = seller_with_dealers(client, actors, 2)
    oid = offer(client, d, lid, 400_000).json()["id"]
    assert final(client, d, oid, 400_000).status_code == 409                 # not accepted yet
    accept(client, seller, oid, 400_000)
    assert final(client, other, oid, 400_000).status_code == 404             # not their offer
    assert final(client, d, oid, 400_000).status_code == 200
    assert final(client, d, oid, 390_000, reason_code="OTHER").status_code == 409  # only one final offer

    seller2, d2, lid2, oid2 = accepted_offer(client, actors, inspection_required=False)
    assert final(client, d2, oid2, 390_000, reason_code="OTHER").status_code == 409


def test_the_seller_accepts_the_lower_price(client, actors):
    seller, d, lid, oid = accepted_offer(client, actors)
    final(client, d, oid, 380_000, reason_code="BODY_CONDITION")
    r = final_reply(client, seller, oid, "ACCEPT")
    assert r.status_code == 200 and r.json()["final_status"] == "ACCEPTED" and r.json()["final_price"] == 380_000
    assert listing_status(client, seller, lid) == "FINAL_ACCEPTED"
    assert "FINAL_OFFER_ACCEPTED" in types(client, d)
    assert final_reply(client, seller, oid, "ACCEPT").status_code == 200   # repeating is harmless
    assert final_reply(client, seller, oid, "DECLINE").status_code == 409  # a decided answer cannot flip


def test_declining_is_free_and_reopens_the_listing_with_the_other_valid_offers(client, actors):
    seller, (first, second, third), lid = seller_with_dealers(client, actors, 3)
    o1 = offer(client, first, lid, 400_000).json()["id"]
    o2 = offer(client, second, lid, 390_000).json()["id"]
    o3 = offer(client, third, lid, 385_000).json()["id"]
    force(DealerOffer, o3, valid_until=datetime.utcnow() + timedelta(seconds=1))
    accept(client, seller, o1, 400_000)
    final(client, first, o1, 360_000, reason_code="MECHANICAL_ISSUE", evidence_urls=["https://files.example/r.pdf"])
    force(DealerOffer, o3, valid_until=datetime.utcnow() - timedelta(minutes=1))  # the third ran out meanwhile

    r = final_reply(client, seller, o1, "DECLINE")
    assert r.status_code == 200 and r.json()["final_status"] == "DECLINED" and r.json()["status"] == "REJECTED"
    assert listing_status(client, seller, lid) == "ACTIVE"
    assert "FINAL_OFFER_DECLINED" in types(client, first)
    assert "OFFER_REOPENED" in types(client, second) and "OFFER_REOPENED" not in types(client, third)
    with Session(engine) as s:
        assert s.get(DealerOffer, uuid.UUID(o2)).status == "PENDING"
        assert s.get(DealerOffer, uuid.UUID(o3)).status == "NOT_SELECTED"  # no longer valid: not revived
    assert accept(client, seller, o2, 390_000).status_code == 200            # the next-best offer can win
    assert listing_status(client, seller, lid) == "OFFER_ACCEPTED"


def test_only_the_owner_answers_and_only_a_waiting_final_offer(client, actors):
    seller, d, lid, oid = accepted_offer(client, actors)
    other = actors.customer()
    assert final_reply(client, seller, oid, "ACCEPT").status_code == 409     # no final offer yet
    final(client, d, oid, 380_000, reason_code="OTHER")
    assert final_reply(client, other, oid, "ACCEPT").status_code == 404
    assert final_reply(client, d, oid, "ACCEPT").status_code == 403
    assert client.post(f"/api/offers/{oid}/final/respond", headers=seller, json={"action": "MAYBE"}).status_code == 422


def test_two_simultaneous_answers_produce_one_outcome(client, actors):
    import threading

    seller, d, lid, oid = accepted_offer(client, actors)
    final(client, d, oid, 380_000, reason_code="OTHER")
    results = []
    barrier = threading.Barrier(2)

    def go(action):
        barrier.wait()
        results.append(final_reply(client, seller, oid, action).status_code)

    threads = [threading.Thread(target=go, args=(a,)) for a in ("ACCEPT", "DECLINE")]
    [t.start() for t in threads]
    [t.join() for t in threads]
    assert sorted(results) == [200, 409]
    with Session(engine) as s:
        row = s.get(DealerOffer, uuid.UUID(oid))
        assert row.final_status in ("ACCEPTED", "DECLINED")
        assert s.get(SellListing, uuid.UUID(lid)).status == ("FINAL_ACCEPTED" if row.final_status == "ACCEPTED" else "ACTIVE")
