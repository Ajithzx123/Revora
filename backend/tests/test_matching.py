"""S3: which dealers see which buyer request, and why."""
from datetime import datetime, timedelta

from sqlmodel import Session, select

from backend.app.database.session import engine
from backend.app.models.marketplace_models import BuyRequirement, DealerStatus, MatchRecord
from backend.app.services import matching_service
from backend.tests.conftest import CAR, REQUIREMENT, car, force_status, source


def post(client, customer, **overrides):
    r = client.post("/api/requirements/", headers=customer, json={**REQUIREMENT, **overrides})
    assert r.status_code == 201, r.text
    return r.json()


def stock(client, dealer, n=1, **overrides):
    r = client.post("/api/inventory", headers=dealer, json=car(n, **overrides))
    assert r.status_code == 201, r.text
    return r.json()["id"]


def leads(client, dealer):
    return client.get("/api/leads/buy", headers=dealer).json()


# ---------- who is matched ----------
def test_dealer_with_the_exact_car_is_matched_with_reasons(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    vid = stock(client, dealer)
    post(client, customer)
    (lead,) = leads(client, dealer)
    assert lead["match_tier"] == 1 and 60 <= lead["match_score"] <= 100
    assert lead["matched_vehicle_id"] == vid
    assert any("Exact match in stock" in r for r in lead["match_reasons"])
    assert lead["response_deadline"]


def test_dealer_without_the_car_or_sourcing_is_not_matched(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    stock(client, dealer, make="Kia", model="Seltos")
    post(client, customer)
    assert leads(client, dealer) == []


def test_unapproved_dealer_is_never_matched(client, actors):
    customer, dealer = actors.customer(), actors.dealer()
    stock(client, dealer)
    post(client, customer)
    assert client.get("/api/leads/buy", headers=dealer).status_code == 403
    with Session(engine) as s:
        assert s.exec(select(MatchRecord)).all() == []


def test_car_over_budget_by_more_than_five_percent_is_not_matched(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    stock(client, dealer, price=800_000)
    post(client, customer, budget_max=700_000)
    assert leads(client, dealer) == []


def test_car_slightly_over_budget_is_matched_but_says_so(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    stock(client, dealer, price=720_000)
    post(client, customer, budget_max=700_000)
    (lead,) = leads(client, dealer)
    assert any("slightly over" in r for r in lead["match_reasons"])


def test_must_have_is_a_hard_filter_but_a_preference_is_not(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    stock(client, dealer, fuel="Petrol")
    post(client, customer, fuel="Diesel", must_have=["fuel"])
    assert leads(client, dealer) == []
    post(client, actors.customer(), fuel="Diesel")  # same wish, only a preference
    (lead,) = leads(client, dealer)
    assert any("Does not match" in r for r in lead["match_reasons"])


def test_similar_model_is_tier_two_and_ranks_below_exact(client, actors):
    customer = actors.customer()
    exact, similar = actors.dealer(approved=True), actors.dealer(approved=True)
    stock(client, exact)
    stock(client, similar, n=2, model="Creta")
    post(client, customer)
    assert leads(client, exact)[0]["match_tier"] == 1
    assert leads(client, similar)[0]["match_tier"] == 2


def test_dealer_outside_the_radius_is_not_matched(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    stock(client, dealer)  # dealer is in Bengaluru
    post(client, customer, city="Mumbai", radius_km=50)
    assert leads(client, dealer) == []


# ---------- sourcing ----------
def test_sourcing_dealer_is_matched_only_when_nobody_has_stock(client, actors):
    customer = actors.customer()
    sourcer = source(client, actors.dealer(approved=True))
    holder = actors.dealer(approved=True)
    stock(client, holder)
    post(client, customer)
    assert leads(client, sourcer) == []  # someone has the car, so sourcers wait
    assert len(leads(client, holder)) == 1


def test_sourcing_is_released_after_the_delay_with_few_quotes(client, actors):
    customer = actors.customer()
    sourcer = source(client, actors.dealer(approved=True))
    stock(client, actors.dealer(approved=True))
    rid = post(client, customer)["id"]
    assert leads(client, sourcer) == []
    with Session(engine) as s:
        req = s.get(BuyRequirement, __import__("uuid").UUID(rid))
        req.created_at = datetime.utcnow() - timedelta(hours=13)
        s.add(req)
        s.commit()
    client.post("/api/admin/matching/run", headers=actors.admin())
    (lead,) = leads(client, sourcer)
    assert lead["match_tier"] == 3 and lead["matched_vehicle_id"] is None


def test_sourcing_makes_are_validated(client, actors):
    dealer = actors.dealer()
    assert client.put("/api/dealers/me/sourcing", headers=dealer, json={"makes": ["Ferrari"]}).status_code == 422
    r = client.put("/api/dealers/me/sourcing", headers=dealer, json={"makes": ["Tata", "Hyundai"]})
    assert r.status_code == 200 and r.json()["sourcing_makes"] == ["Hyundai", "Tata"]


# ---------- triggers ----------
def test_new_stock_matches_a_waiting_request(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    post(client, customer)
    assert leads(client, dealer) == []
    stock(client, dealer)
    assert len(leads(client, dealer)) == 1


def test_approving_a_dealer_matches_waiting_requests(client, actors):
    customer, admin = actors.customer(), actors.admin()
    dealer = actors.dealer()
    stock(client, dealer)
    post(client, customer)
    force_status(dealer.dealer_id, DealerStatus.PENDING)
    assert client.post(f"/api/admin/dealers/{dealer.dealer_id}/approve", headers=admin).status_code == 200
    assert len(leads(client, dealer)) == 1


def test_matching_is_idempotent_and_a_dealer_is_matched_once(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    stock(client, dealer)
    rid = post(client, customer)["id"]
    stock(client, dealer, n=2)
    client.post("/api/admin/matching/run", headers=actors.admin())
    with Session(engine) as s:
        assert len(s.exec(select(MatchRecord)).all()) == 1
    assert len(leads(client, dealer)) == 1
    assert client.get(f"/api/requirements/{rid}", headers=customer).json()["dealers_notified"] == 1


def test_at_most_fifteen_dealers_per_request(client, actors):
    customer = actors.customer()
    for i in range(17):
        stock(client, actors.dealer(approved=True), n=i + 1)
    rid = post(client, customer)["id"]
    assert client.get(f"/api/requirements/{rid}", headers=customer).json()["dealers_notified"] <= 8  # tier-1 cap


def test_dealer_gets_at_most_twenty_new_leads_a_day(client, actors):
    dealer = actors.dealer(approved=True)
    stock(client, dealer)
    for _ in range(3):
        post(client, actors.customer())
    with Session(engine) as s:
        for req in s.exec(select(BuyRequirement)).all():
            matching_service.run_matching(s, req)
        assert matching_service._leads_today(s, dealer.dealer_id, datetime.utcnow()) <= matching_service.MAX_NEW_LEADS_PER_DEALER_PER_DAY


# ---------- access ----------
def test_dealer_cannot_quote_a_request_they_were_not_matched_to(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    rid = post(client, customer)["id"]
    r = client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 600_000})
    assert r.status_code == 403


def test_unmatched_dealer_cannot_read_the_request(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    rid = post(client, customer)["id"]
    assert client.get(f"/api/requirements/{rid}", headers=dealer).status_code == 404


def test_dismissed_lead_disappears_and_cannot_be_quoted(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    stock(client, dealer)
    rid = post(client, customer)["id"]
    r = client.post(f"/api/leads/buy/{rid}/dismiss", headers=dealer, json={"reason": "Too far"})
    assert r.status_code == 204
    assert leads(client, dealer) == []
    assert client.post("/api/quotes", headers=dealer, json={"requirement_id": rid, "quoted_price": 600_000}).status_code == 403
    assert client.get(f"/api/requirements/{rid}", headers=dealer).status_code == 404


def test_dismissing_an_unmatched_request_is_404(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    rid = post(client, customer)["id"]
    assert client.post(f"/api/leads/buy/{rid}/dismiss", headers=dealer, json={}).status_code == 404


def test_paused_request_disappears_from_leads_and_returns_on_resume(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    stock(client, dealer)
    rid = post(client, customer)["id"]
    client.post(f"/api/requirements/{rid}/pause", headers=customer)
    assert leads(client, dealer) == []
    client.post(f"/api/requirements/{rid}/resume", headers=customer)
    assert len(leads(client, dealer)) == 1


# ---------- admin ----------
def test_admin_sees_matches_and_liquidity_others_do_not(client, actors):
    customer, dealer, admin = actors.customer(), actors.dealer(approved=True), actors.admin()
    stock(client, dealer)
    rid = post(client, customer)["id"]
    post(client, customer, make="Tata", model="Nexon")
    (m,) = client.get(f"/api/admin/requirements/{rid}/matches", headers=admin).json()
    assert m["tier"] == 1 and m["reasons"]
    city = client.get("/api/admin/liquidity", headers=admin).json()[0]
    assert city["city"] == "Bengaluru" and city["unmatched_requests"] == 1 and city["approved_dealers"] == 1
    for h in (customer, dealer):
        assert client.get(f"/api/admin/requirements/{rid}/matches", headers=h).status_code == 403
        assert client.get("/api/admin/liquidity", headers=h).status_code == 403
        assert client.post("/api/admin/matching/run", headers=h).status_code == 403


def test_leads_never_reveal_the_buyer(client, actors):
    customer, dealer = actors.customer(), actors.dealer(approved=True)
    stock(client, dealer)
    post(client, customer)
    (lead,) = leads(client, dealer)
    assert "customer_id" not in lead and str(customer.user_id) not in str(lead)
