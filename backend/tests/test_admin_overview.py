"""Admin overview: real metrics and read-only lists of requirements and vehicles."""
import pytest

from backend.tests.conftest import CAR, LISTING, MISSING, REQUIREMENT, buys, car, source
from backend.tests.test_quotes import accept, quote, setup_request
from backend.tests.test_sell_side import accept as accept_offer
from backend.tests.test_sell_side import offer, seller_with_dealers


@pytest.mark.parametrize("path", ["/api/admin/requirements", "/api/admin/vehicles"])
def test_lists_need_an_admin(client, actors, path):
    assert client.get(path).status_code in (401, 403)
    for who in (actors.customer(), actors.dealer(approved=True)):
        assert client.get(path, headers=who).status_code == 403


def test_metrics_are_counted_from_the_database(client, actors):
    admin = actors.admin()
    empty = client.get("/api/admin/metrics", headers=admin).json()
    assert empty["open_requirements"] == 0 and empty["open_listings"] == 0
    assert empty["active_vehicles"] == 0 and empty["deals_last_30_days"] == 0 and empty["deal_value_last_30_days"] == 0

    customer, (d,), rid = setup_request(client, actors)
    client.post("/api/inventory", headers=d, json=car())
    qid = quote(client, d, rid, 650_000).json()["id"]
    seller, (buyer,), lid = seller_with_dealers(client, actors)
    oid = offer(client, buyer, lid, 380_000).json()["id"]

    m = client.get("/api/admin/metrics", headers=admin).json()
    assert m["open_requirements"] == 1 and m["open_listings"] == 1 and m["active_vehicles"] == 1
    assert m["deals_last_30_days"] == 0

    assert accept(client, customer, qid, 650_000).status_code == 200
    assert accept_offer(client, seller, oid, 380_000).status_code == 200
    m = client.get("/api/admin/metrics", headers=admin).json()
    assert m["deals_last_30_days"] == 2
    assert m["deal_value_last_30_days"] == 650_000 + 380_000
    assert m["open_requirements"] == 0 and m["open_listings"] == 0


def test_a_lowered_final_price_is_what_counts_as_deal_value(client, actors):
    admin = actors.admin()
    seller, (d,), lid = seller_with_dealers(client, actors)
    oid = offer(client, d, lid, 400_000).json()["id"]
    accept_offer(client, seller, oid, 400_000)
    client.post(f"/api/offers/{oid}/final", headers=d, json={"price": 390_000, "reason_code": "OTHER"})
    client.post(f"/api/offers/{oid}/final/respond", headers=seller, json={"action": "ACCEPT"})
    assert client.get("/api/admin/metrics", headers=admin).json()["deal_value_last_30_days"] == 390_000


def test_requirements_list_shows_demand_with_reach_and_response(client, actors):
    admin = actors.admin()
    customer, (a, b), rid = setup_request(client, actors, 2)
    quote(client, a, rid, 650_000)
    page = client.get("/api/admin/requirements", headers=admin).json()
    assert page["total"] == 1 and page["limit"] == 50
    row = page["items"][0]
    assert row["title"] == "Hyundai i20" and row["city"] == "Bengaluru" and row["customer_name"] == "Cust"
    assert row["quotes_count"] == 1 and row["matches_count"] == 2 and row["status"] == "OPEN"
    assert client.get("/api/admin/requirements", headers=admin, params={"status": "CANCELLED"}).json()["total"] == 0
    assert client.get("/api/admin/requirements", headers=admin, params={"limit": 201}).status_code == 422
    assert client.get("/api/admin/requirements", headers=admin, params={"offset": -1}).status_code == 422


def test_vehicles_list_hides_the_private_floor_price(client, actors):
    admin = actors.admin()
    d = actors.dealer(approved=True)
    client.post("/api/inventory", headers=d, json={**car(), "min_price": 500_000})
    page = client.get("/api/admin/vehicles", headers=admin).json()
    row = page["items"][0]
    assert page["total"] == 1 and row["dealer_name"] == "Test Motors" and row["status"] == "AVAILABLE"
    assert "min_price" not in row and "500000" not in str(row)
    assert client.get("/api/admin/vehicles", headers=admin, params={"status": "SOLD"}).json()["total"] == 0
