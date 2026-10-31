"""Tokens signed with Supabase's asymmetric keys (ES256), verified through the JWKS."""
import time
import uuid

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
from jose import jwk, jwt

from backend.app.core import supabase_auth
from backend.app.core.config import settings

URL = "https://example-project.supabase.co"
KID = "test-key-1"


def _keypair():
    private = ec.generate_private_key(ec.SECP256R1())
    private_pem = private.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode()
    public_pem = private.public_key().public_bytes(
        serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode()
    public_jwk = jwk.construct(public_pem, "ES256").to_dict()
    public_jwk.update(kid=KID, use="sig", key_ops=["verify"])
    return private_pem, public_jwk


@pytest.fixture
def keys(monkeypatch):
    private_pem, public_jwk = _keypair()
    monkeypatch.setattr(settings, "SUPABASE_URL", URL)
    monkeypatch.setattr(supabase_auth, "_fetch_jwks", lambda force=False: [public_jwk])
    return private_pem


def token(private_pem, *, kid=KID, iss=f"{URL}/auth/v1", aud="authenticated", uid=None, exp_in=600):
    claims = {
        "sub": str(uid or uuid.uuid4()),
        "email": "es256@example.com",
        "aud": aud,
        "iss": iss,
        "exp": int(time.time()) + exp_in,
    }
    return jwt.encode(claims, private_pem, algorithm="ES256", headers={"kid": kid})


def bearer(t):
    return {"Authorization": f"Bearer {t}"}


def test_es256_token_creates_and_uses_a_profile(client, keys):
    uid = uuid.uuid4()
    h = bearer(token(keys, uid=uid))
    r = client.post("/api/profile", headers=h, json={"name": "Es Two"})
    assert r.status_code == 201, r.text
    assert client.get("/api/me", headers=h).json()["id"] == str(uid)


def test_unknown_key_id_is_refused(client, keys):
    assert client.get("/api/me", headers=bearer(token(keys, kid="other"))).status_code == 401


def test_token_signed_by_a_different_key_is_refused(client, keys):
    other_private, _ = _keypair()
    assert client.get("/api/me", headers=bearer(token(other_private))).status_code == 401


def test_wrong_issuer_is_refused(client, keys):
    t = token(keys, iss="https://evil.supabase.co/auth/v1")
    assert client.get("/api/me", headers=bearer(t)).status_code == 401


def test_wrong_audience_is_refused(client, keys):
    assert client.get("/api/me", headers=bearer(token(keys, aud="anon"))).status_code == 401


def test_expired_token_is_refused(client, keys):
    assert client.get("/api/me", headers=bearer(token(keys, exp_in=-10))).status_code == 401


def test_hs256_token_cannot_be_forged_with_the_public_key(client, keys, monkeypatch):
    """Algorithm-confusion attack: HS256 token signed with a guessed secret must fail."""
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", None)
    forged = jwt.encode(
        {"sub": str(uuid.uuid4()), "aud": "authenticated", "iss": f"{URL}/auth/v1", "exp": int(time.time()) + 600},
        "anything", algorithm="HS256",
    )
    assert client.get("/api/me", headers=bearer(forged)).status_code == 401
