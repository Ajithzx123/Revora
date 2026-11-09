"""Supabase token verification: what is accepted and what is refused."""
import time
import uuid

from jose import jwt

from backend.tests.conftest import TEST_JWT_SECRET, make_token


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def test_valid_token_is_accepted(client, actors):
    h = actors.customer()
    assert client.get("/api/me", headers=h).status_code == 200


def test_missing_and_garbage_tokens_are_refused(client):
    assert client.get("/api/me").status_code in (401, 403)
    assert client.get("/api/me", headers=bearer("not-a-token")).status_code == 401


def test_expired_token_is_refused(client):
    token = make_token(uuid.uuid4(), "a@example.com", exp_in=-10)
    assert client.get("/api/me", headers=bearer(token)).status_code == 401


def test_wrong_secret_is_refused(client):
    token = make_token(uuid.uuid4(), "a@example.com", secret="another-secret-another-secret-another-0123")
    assert client.get("/api/me", headers=bearer(token)).status_code == 401


def test_wrong_audience_is_refused(client):
    token = make_token(uuid.uuid4(), "a@example.com", aud="somebody-else")
    assert client.get("/api/me", headers=bearer(token)).status_code == 401


def test_unsigned_token_is_refused(client):
    import base64, json

    def b64(d):
        return base64.urlsafe_b64encode(json.dumps(d).encode()).rstrip(b"=").decode()

    token = f"{b64({'alg': 'none', 'typ': 'JWT'})}.{b64({'sub': str(uuid.uuid4()), 'aud': 'authenticated', 'exp': int(time.time()) + 600})}."
    assert client.get("/api/me", headers=bearer(token)).status_code == 401


def test_hs512_is_refused(client):
    claims = {"sub": str(uuid.uuid4()), "aud": "authenticated", "exp": int(time.time()) + 600}
    token = jwt.encode(claims, TEST_JWT_SECRET, algorithm="HS512")
    assert client.get("/api/me", headers=bearer(token)).status_code == 401


def test_non_uuid_subject_is_refused(client):
    claims = {"sub": "1", "email": "a@example.com", "aud": "authenticated", "exp": int(time.time()) + 600}
    token = jwt.encode(claims, TEST_JWT_SECRET, algorithm="HS256")
    assert client.get("/api/me", headers=bearer(token)).status_code == 401


def test_duplicate_email_cannot_get_second_profile(client, actors):
    actors.customer()  # customer1@example.com
    token = make_token(uuid.uuid4(), "customer1@example.com")
    r = client.post("/api/profile", headers=bearer(token), json={"name": "Other"})
    assert r.status_code == 409
