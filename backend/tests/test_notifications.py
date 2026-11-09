"""S5a: notification events, in-app feed, preferences, devices and push delivery."""
import uuid
from datetime import datetime, timedelta

import pytest
from sqlmodel import Session, select

from backend.app.database.session import engine
from backend.app.models.notification_models import NotificationDelivery, NotificationEvent
from backend.app.services import notification_service as svc
from backend.app.services import push
from backend.tests.conftest import MISSING
from backend.tests.test_quotes import accept, quote, setup_request

TOKEN = "fcm-token-0123456789"


class FakeSender:
    def __init__(self, fail=False):
        self.sent, self.fail = [], fail

    def send(self, token, title, body, data):
        if self.fail:
            raise RuntimeError("boom")
        self.sent.append((token, title, body, data))


@pytest.fixture
def sender():
    fake = FakeSender()
    push.set_sender(fake)
    yield fake
    push.set_sender(None)


def feed(client, who, **params):
    r = client.get("/api/notifications", headers=who, params=params)
    assert r.status_code == 200, r.text
    return r.json()


def types(client, who):
    return [n["type"] for n in feed(client, who)["items"]]


def deliveries(channel=None):
    with Session(engine) as s:
        q = select(NotificationDelivery)
        if channel:
            q = q.where(NotificationDelivery.channel == channel)
        return s.exec(q).all()


# ---------- access ----------
@pytest.mark.parametrize(
    "method,path",
    [
        ("get", "/api/notifications"),
        ("get", "/api/notifications/unread-count"),
        ("post", "/api/notifications/mark-read"),
        ("get", "/api/notifications/preferences"),
        ("put", "/api/notifications/preferences"),
        ("post", "/api/notifications/devices"),
        ("post", "/api/notifications/devices/remove"),
    ],
)
def test_notification_endpoints_reject_anonymous(client, method, path):
    assert getattr(client, method)(path).status_code in (401, 403)


def test_feed_pagination_is_bounded(client, actors):
    c = actors.customer()
    assert client.get("/api/notifications", headers=c, params={"limit": 0}).status_code == 422
    assert client.get("/api/notifications", headers=c, params={"limit": 101}).status_code == 422
    assert feed(client, c) == {"items": [], "total": 0, "unread_count": 0, "limit": 20, "offset": 0}


# ---------- events from the marketplace flow ----------
def test_posting_a_request_notifies_the_buyer_and_only_the_matched_dealer(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    other = actors.dealer(approved=True)  # approved but offers nothing for this request
    assert types(client, customer) == ["MATCHES_FOUND"]
    assert types(client, d) == ["NEW_LEAD"]
    assert types(client, other) == []


def test_quote_flow_notifies_the_right_people(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    assert "QUOTE_RECEIVED" in types(client, customer)
    assert "QUOTE_RECEIVED" not in types(client, d)

    client.put(f"/api/quotes/{qid}", headers=d, json={"quoted_price": 640_000})
    assert types(client, customer).count("QUOTE_REVISED") == 1

    client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 600_000})
    assert "COUNTER_RECEIVED" in types(client, d)
    client.post(f"/api/quotes/{qid}/negotiation", headers=d, json={"action": "ACCEPT"})
    assert "COUNTER_ACCEPTED" in types(client, customer)

    client.post(f"/api/quotes/{qid}/withdraw", headers=d, json={})
    assert "QUOTE_WITHDRAWN" in types(client, customer)


def test_counter_decline_and_dealer_counter_notify_the_other_side(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    qid = quote(client, d, rid, 650_000).json()["id"]
    client.post(f"/api/quotes/{qid}/counter", headers=customer, json={"price": 600_000})
    client.post(f"/api/quotes/{qid}/negotiation", headers=d, json={"action": "COUNTER", "price": 630_000})
    assert "COUNTER_RECEIVED" in types(client, customer)
    client.post(f"/api/quotes/{qid}/negotiation/respond", headers=customer, json={"action": "DECLINE"})
    assert "COUNTER_DECLINED" in types(client, d)


def test_accept_tells_the_winner_and_the_losers_without_revealing_the_deal(client, actors):
    customer, (win, lose), rid = setup_request(client, actors, 2)
    qw = quote(client, win, rid, 650_000).json()["id"]
    quote(client, lose, rid, 690_000)
    assert accept(client, customer, qw, 650_000).status_code == 200

    won = [n for n in feed(client, win)["items"] if n["type"] == "QUOTE_ACCEPTED"]
    assert len(won) == 1 and won[0]["critical"] is True and won[0]["category"] == "DEALS"
    lost = [n for n in feed(client, lose)["items"] if n["type"] == "QUOTE_NOT_SELECTED"]
    assert len(lost) == 1
    text = lost[0]["title"] + lost[0]["body"]
    assert "6.50" not in text and "lakh" not in text and "Test Motors" not in text  # no price, no winner
    # repeating the same accept does not notify again
    accept(client, customer, qw, 650_000)
    assert [n["type"] for n in feed(client, win)["items"]].count("QUOTE_ACCEPTED") == 1


def test_dealer_decisions_notify_the_dealer(client, actors):
    d, admin = actors.dealer(approved=True), actors.admin()
    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Customer fraud report"})
    client.post(f"/api/admin/dealers/{d.dealer_id}/reactivate", headers=admin)
    items = feed(client, d)["items"]
    assert {n["type"] for n in items} >= {"DEALER_SUSPENDED", "DEALER_REACTIVATED"}
    suspended = next(n for n in items if n["type"] == "DEALER_SUSPENDED")
    assert "Customer fraud report" in suspended["body"] and suspended["critical"] and suspended["category"] == "ACCOUNT"


# ---------- dedupe ----------
def test_same_event_is_recorded_once():
    uid, eid = uuid.uuid4(), uuid.uuid4()
    with Session(engine) as s:
        from backend.app.models.user_model import User

        s.add(User(id=uid, name="U", email="u@example.com"))
        s.commit()
        first = svc.notify(s, uid, "QUOTE_RECEIVED", "t", "b", entity_id=eid)
        again = svc.notify(s, uid, "QUOTE_RECEIVED", "t", "b", entity_id=eid)
        other_window = svc.notify(s, uid, "QUOTE_RECEIVED", "t", "b", entity_id=eid, window="2")
        s.commit()
        assert first is not None and again is None and other_window is not None
        assert len(s.exec(select(NotificationEvent)).all()) == 2


# ---------- read state ----------
def test_mark_read_only_touches_the_callers_own_notifications(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    assert client.get("/api/notifications/unread-count", headers=customer).json() == {"unread_count": 1}
    dealer_item = feed(client, d)["items"][0]["id"]

    r = client.post("/api/notifications/mark-read", headers=customer, json={"ids": [dealer_item, MISSING]})
    assert r.json() == {"marked": 0, "unread_count": 1}  # someone else's id is ignored, not an error
    assert feed(client, d)["unread_count"] == 1

    r = client.post("/api/notifications/mark-read", headers=customer, json={})
    assert r.json() == {"marked": 1, "unread_count": 0}
    assert feed(client, customer, unread_only=True)["items"] == []
    assert feed(client, customer)["items"][0]["read"] is True


# ---------- preferences ----------
def test_preferences_default_on_and_reject_unknown_or_critical_categories(client, actors):
    c = actors.customer()
    prefs = client.get("/api/notifications/preferences", headers=c).json()["preferences"]
    assert prefs == {"LEADS": True, "QUOTES": True, "DEALS": True, "MARKETING": True}
    r = client.put("/api/notifications/preferences", headers=c, json={"preferences": {"QUOTES": False}})
    assert r.json()["preferences"]["QUOTES"] is False
    assert client.put("/api/notifications/preferences", headers=c, json={"preferences": {"ACCOUNT": False}}).status_code == 422
    assert client.put("/api/notifications/preferences", headers=c, json={"preferences": {"NOPE": False}}).status_code == 422


def test_switching_a_category_off_stops_push_but_keeps_the_in_app_record(client, actors):
    customer, (d,), rid = setup_request(client, actors)
    client.put("/api/notifications/preferences", headers=customer, json={"preferences": {"QUOTES": False}})
    before = len(deliveries("PUSH"))
    quote(client, d, rid, 650_000)
    assert "QUOTE_RECEIVED" in types(client, customer)
    assert len(deliveries("PUSH")) == before


def test_critical_events_ignore_preferences(client, actors):
    d, admin = actors.dealer(approved=True), actors.admin()
    client.put("/api/notifications/preferences", headers=d, json={"preferences": {c: False for c in svc.PREFERENCE_CATEGORIES}})
    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Policy breach"})
    assert any(x.status == "PENDING" for x in deliveries("PUSH"))


# ---------- devices and push delivery ----------
def test_register_and_remove_device_is_scoped_to_the_owner(client, actors):
    a, b = actors.customer(), actors.customer()
    body = {"token": TOKEN, "platform": "android"}
    assert client.post("/api/notifications/devices", headers=a, json=body).status_code == 204
    assert client.post("/api/notifications/devices", headers=a, json=body).status_code == 204  # idempotent
    assert client.post("/api/notifications/devices", headers=a, json={"token": "x", "platform": "android"}).status_code == 422
    assert client.post("/api/notifications/devices", headers=a, json={"token": TOKEN, "platform": "toaster"}).status_code == 422

    client.post("/api/notifications/devices/remove", headers=b, json=body)  # not b's token: no effect
    from backend.app.models.notification_models import DeviceToken

    with Session(engine) as s:
        assert [t.user_id for t in s.exec(select(DeviceToken)).all()] == [a.user_id]
    client.post("/api/notifications/devices/remove", headers=a, json=body)
    with Session(engine) as s:
        assert s.exec(select(DeviceToken)).all() == []


def test_a_token_moves_to_the_user_who_signs_in_on_that_device(client, actors):
    a, b = actors.customer(), actors.customer()
    body = {"token": TOKEN, "platform": "ios"}
    client.post("/api/notifications/devices", headers=a, json=body)
    client.post("/api/notifications/devices", headers=b, json=body)
    from backend.app.models.notification_models import DeviceToken

    with Session(engine) as s:
        assert [t.user_id for t in s.exec(select(DeviceToken)).all()] == [b.user_id]


def test_push_is_sent_to_registered_devices(client, actors, sender):
    d, admin = actors.dealer(approved=True), actors.admin()
    client.post("/api/notifications/devices", headers=d, json={"token": TOKEN, "platform": "android"})
    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Policy breach"})
    with Session(engine) as s:
        assert svc.dispatch_pending(s) == 1
        assert svc.dispatch_pending(s) == 0  # nothing is sent twice
    assert sender.sent[0][0] == TOKEN and sender.sent[0][3]["type"] == "DEALER_SUSPENDED"
    assert all(x.status == "SENT" for x in deliveries())


def test_push_without_a_device_is_skipped_not_retried(client, actors, sender):
    d, admin = actors.dealer(approved=True), actors.admin()
    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Policy breach"})
    with Session(engine) as s:
        assert svc.dispatch_pending(s) == 0
    push_row = deliveries("PUSH")[0]
    assert push_row.status == "SKIPPED" and sender.sent == []


def test_failed_push_retries_with_backoff_then_gives_up(client, actors):
    d, admin = actors.dealer(approved=True), actors.admin()
    client.post("/api/notifications/devices", headers=d, json={"token": TOKEN, "platform": "android"})
    client.post(f"/api/admin/dealers/{d.dealer_id}/suspend", headers=admin, json={"reason": "Policy breach"})
    push.set_sender(FakeSender(fail=True))
    try:
        now = datetime.utcnow() + timedelta(minutes=1)
        with Session(engine) as s:
            svc.dispatch_pending(s, now=now)
        row = deliveries("PUSH")[0]
        assert row.status == "PENDING" and row.attempts == 1 and row.deliver_after == now + timedelta(minutes=2)
        with Session(engine) as s:
            svc.dispatch_pending(s, now=now + timedelta(minutes=1))  # too early: backoff not over
        assert deliveries("PUSH")[0].attempts == 1
        t = now
        for _ in range(2):
            t += timedelta(minutes=10)
            with Session(engine) as s:
                svc.dispatch_pending(s, now=t)
        row = deliveries("PUSH")[0]
        assert row.status == "FAILED" and row.attempts == 3 and row.last_error == "RuntimeError"
    finally:
        push.set_sender(None)
    # the in-app record survives a push failure
    assert "DEALER_SUSPENDED" in types(client, d)


def test_quiet_hours_hold_non_critical_push_until_morning():
    assert svc.after_quiet_hours(datetime(2026, 1, 1, 17, 30)) == datetime(2026, 1, 2, 2, 30)  # 23:00 IST -> 08:00 IST
    assert svc.after_quiet_hours(datetime(2026, 1, 1, 22, 0)) == datetime(2026, 1, 2, 2, 30)   # 03:30 IST same night
    assert svc.after_quiet_hours(datetime(2026, 1, 1, 6, 0)) == datetime(2026, 1, 1, 6, 0)     # 11:30 IST


def test_non_critical_push_is_delayed_but_critical_is_not(client, actors, sender):
    uid_c = actors.customer()
    night = datetime(2026, 1, 1, 17, 30)  # 23:00 IST
    with Session(engine) as s:
        svc.notify(s, uid_c.user_id, "QUOTE_RECEIVED", "t", "b", entity_id=uuid.uuid4(), now=night)
        svc.notify(s, uid_c.user_id, "DEALER_SUSPENDED", "t", "b", entity_id=uuid.uuid4(), now=night)
        s.commit()
    by_critical = {}
    with Session(engine) as s:
        for x in s.exec(select(NotificationDelivery).where(NotificationDelivery.channel == "PUSH")).all():
            by_critical[s.get(NotificationEvent, x.event_id).critical] = x.deliver_after
    assert by_critical[True] == night and by_critical[False] == datetime(2026, 1, 2, 2, 30)
