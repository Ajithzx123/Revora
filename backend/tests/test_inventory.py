"""Dealer inventory: vehicles, duplicates, photos, and what happens when a car is sold."""
import pytest

from backend.tests.conftest import JPEG, PDF, PNG, REQUIREMENT, WEBP, car


def add(client, h, n=1, **overrides):
    return client.post("/api/inventory", headers=h, json=car(n, **overrides))


def photo(client, h, vid, content=JPEG, name="p.jpg"):
    return client.post(
        f"/api/inventory/{vid}/media", headers=h,
        files={"file": (name, content, "application/octet-stream")},
    )


# ---------- create ----------
def test_add_vehicle_returns_the_full_record(client, actors):
    h = actors.dealer()
    r = add(client, h, variant="Asta", owners=2, color="White", body_type="Hatchback", min_price=600000)
    assert r.status_code == 201, r.text
    v = r.json()
    assert v["registration_no"] == "KA01AB1001" and v["status"] == "AVAILABLE"
    assert v["owners"] == 2 and v["min_price"] == 600000 and v["images"] == []


def test_registration_number_is_normalised(client, actors):
    h = actors.dealer()
    assert add(client, h, registration_no="ka 01-ab 1234").json()["registration_no"] == "KA01AB1234"
    assert add(client, h, registration_no="22BH1234AA").status_code == 201  # Bharat series


@pytest.mark.parametrize(
    "override",
    [
        {"registration_no": "NOTAREG"},
        {"registration_no": "1234"},
        {"make": "Ferrari"},
        {"model": "Nexon"},
        {"year": 1980},
        {"fuel": "Steam"},
        {"km": -5},
        {"owners": 0},
        {"price": 10},
        {"price": 650000, "min_price": 700000},
        {"color": "Plaid"},
        {"description": "x" * 1001},
    ],
)
def test_invalid_vehicles_are_rejected(client, actors, override):
    assert add(client, actors.dealer(), **override).status_code == 422


def test_duplicate_registration_is_blocked_across_dealers(client, actors):
    d1, d2 = actors.dealer(), actors.dealer()
    assert add(client, d1).status_code == 201
    for h in (d1, d2):
        r = add(client, h)
        assert r.status_code == 409 and "already listed" in r.json()["detail"]
    r = add(client, d2, registration_no="ka01 ab1001")  # same car, different spelling
    assert r.status_code == 409


# ---------- read / update / delete ----------
def test_dealers_only_see_their_own_stock(client, actors):
    d1, d2 = actors.dealer(), actors.dealer()
    vid = add(client, d1).json()["id"]
    assert len(client.get("/api/inventory", headers=d1).json()) == 1
    assert client.get("/api/inventory", headers=d2).json() == []
    assert client.get(f"/api/inventory/{vid}", headers=d2).status_code == 404
    assert client.patch(f"/api/inventory/{vid}", headers=d2, json={"price": 500000}).status_code == 404
    assert client.delete(f"/api/inventory/{vid}", headers=d2).status_code == 404


def test_update_changes_only_what_was_sent(client, actors):
    h = actors.dealer()
    vid = add(client, h).json()["id"]
    r = client.patch(f"/api/inventory/{vid}", headers=h, json={"price": 600000, "color": "Silver"})
    assert r.status_code == 200
    assert r.json()["price"] == 600000 and r.json()["color"] == "Silver" and r.json()["km"] == 20000


def test_update_validation(client, actors):
    h = actors.dealer()
    vid = add(client, h, min_price=500000).json()["id"]
    assert client.patch(f"/api/inventory/{vid}", headers=h, json={"price": None}).status_code == 422
    assert client.patch(f"/api/inventory/{vid}", headers=h, json={"price": 400000}).status_code == 422  # below min_price
    assert client.patch(f"/api/inventory/{vid}", headers=h, json={"model": "Nexon"}).status_code == 422
    other = add(client, h, 2).json()
    assert client.patch(f"/api/inventory/{vid}", headers=h, json={"registration_no": other["registration_no"]}).status_code == 409
    assert client.patch(f"/api/inventory/{vid}", headers=h, json={"registration_no": "KA01AB1001"}).status_code == 200  # own number


def test_status_filter(client, actors):
    h = actors.dealer()
    a = add(client, h, 1).json()["id"]
    add(client, h, 2)
    client.patch(f"/api/inventory/{a}", headers=h, json={"status": "RESERVED"})
    assert len(client.get("/api/inventory?status=AVAILABLE", headers=h).json()) == 1
    assert len(client.get("/api/inventory?status=RESERVED", headers=h).json()) == 1


def test_delete_vehicle_and_its_photos(client, actors):
    h = actors.dealer()
    vid = add(client, h).json()["id"]
    url = photo(client, h, vid).json()["images"][0]["url"]
    assert client.get(url).status_code == 200
    assert client.delete(f"/api/inventory/{vid}", headers=h).status_code == 204
    assert client.get(f"/api/inventory/{vid}", headers=h).status_code == 404
    assert client.get(url).status_code == 404


def test_cannot_delete_a_vehicle_with_quotes_but_can_mark_it_sold(client, actors):
    customer = actors.customer()
    h = actors.dealer(approved=True)
    vid = add(client, h).json()["id"]
    rid = client.post("/api/requirements/", headers=customer, json=REQUIREMENT).json()["id"]
    assert client.post("/api/quotes", headers=h, json={"requirement_id": rid, "quoted_price": 650000, "vehicle_id": vid}).status_code == 200
    r = client.delete(f"/api/inventory/{vid}", headers=h)
    assert r.status_code == 409 and "sold" in r.json()["detail"].lower()

    client.patch(f"/api/inventory/{vid}", headers=h, json={"status": "SOLD"})
    quotes = client.get(f"/api/requirements/{rid}/quotes", headers=customer).json()
    assert [q["status"] for q in quotes] == ["UNAVAILABLE"]  # buyers can no longer accept it


def test_cannot_quote_a_vehicle_that_is_not_available(client, actors):
    customer = actors.customer()
    h = actors.dealer(approved=True)
    vid = add(client, h).json()["id"]
    client.patch(f"/api/inventory/{vid}", headers=h, json={"status": "RESERVED"})
    rid = client.post("/api/requirements/", headers=customer, json=REQUIREMENT).json()["id"]
    r = client.post("/api/quotes", headers=h, json={"requirement_id": rid, "quoted_price": 1, "vehicle_id": vid})
    assert r.status_code == 409


# ---------- photos ----------
def test_upload_photos_in_every_allowed_format(client, actors):
    h = actors.dealer()
    vid = add(client, h).json()["id"]
    for content, name in ((JPEG, "a.jpg"), (PNG, "b.png"), (WEBP, "c.webp")):
        assert photo(client, h, vid, content, name).status_code == 201
    images = client.get(f"/api/inventory/{vid}", headers=h).json()["images"]
    assert [i["position"] for i in images] == [0, 1, 2]
    for image in images:
        r = client.get(image["url"])  # public: shown to buyers, no login needed
        assert r.status_code == 200 and "immutable" in r.headers["cache-control"]


@pytest.mark.parametrize("content,expected", [(PDF, 415), (b"MZ\x90\x00not an image", 415), (b"", 422)])
def test_photo_validation(client, actors, content, expected):
    h = actors.dealer()
    vid = add(client, h).json()["id"]
    assert photo(client, h, vid, content).status_code == expected


def test_photo_size_limit(client, actors):
    h = actors.dealer()
    vid = add(client, h).json()["id"]
    assert photo(client, h, vid, JPEG + b"0" * (5 * 1024 * 1024)).status_code == 413


def test_photo_count_limit(client, actors):
    h = actors.dealer()
    vid = add(client, h).json()["id"]
    for _ in range(8):
        assert photo(client, h, vid).status_code == 201
    r = photo(client, h, vid)
    assert r.status_code == 409 and "at most 8" in r.json()["detail"]


def test_only_the_owner_can_add_or_remove_photos(client, actors):
    d1, d2 = actors.dealer(), actors.dealer()
    vid = add(client, d1).json()["id"]
    mid = photo(client, d1, vid).json()["images"][0]["id"]
    assert photo(client, d2, vid).status_code == 404
    assert client.delete(f"/api/inventory/{vid}/media/{mid}", headers=d2).status_code == 404
    assert client.delete(f"/api/inventory/{vid}/media/{mid}", headers=d1).status_code == 200


def test_removing_a_photo_renumbers_the_rest(client, actors):
    h = actors.dealer()
    vid = add(client, h).json()["id"]
    for _ in range(3):
        photo(client, h, vid)
    images = client.get(f"/api/inventory/{vid}", headers=h).json()["images"]
    after = client.delete(f"/api/inventory/{vid}/media/{images[0]['id']}", headers=h).json()["images"]
    assert [i["id"] for i in after] == [images[1]["id"], images[2]["id"]]
    assert [i["position"] for i in after] == [0, 1]


def test_reorder_sets_the_cover(client, actors):
    h = actors.dealer()
    vid = add(client, h).json()["id"]
    for _ in range(3):
        photo(client, h, vid)
    ids = [i["id"] for i in client.get(f"/api/inventory/{vid}", headers=h).json()["images"]]
    new_order = [ids[2], ids[0], ids[1]]
    r = client.put(f"/api/inventory/{vid}/media/order", headers=h, json={"ids": new_order})
    assert [i["id"] for i in r.json()["images"]] == new_order
    assert client.put(f"/api/inventory/{vid}/media/order", headers=h, json={"ids": ids[:2]}).status_code == 422
    assert client.put(f"/api/inventory/{vid}/media/order", headers=h, json={"ids": [ids[0]] * 3}).status_code == 422


def test_unknown_photo_is_404(client):
    assert client.get("/api/media/00000000-0000-0000-0000-000000000009").status_code == 404


# ---------- permissions ----------
def test_customers_cannot_use_inventory(client, actors):
    h = actors.customer()
    assert add(client, h).status_code == 403
    assert client.get("/api/inventory", headers=h).status_code == 403


def test_inventory_requires_login(client):
    assert client.get("/api/inventory").status_code in (401, 403)
    assert client.post("/api/inventory", json=car()).status_code in (401, 403)
