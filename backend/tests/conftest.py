import os
import sys
import tempfile
import time
import uuid
from pathlib import Path

# Must run before any backend import: throwaway database + uploads, test signing secret.
_tmp = tempfile.TemporaryDirectory()
TEST_JWT_SECRET = "test-secret-test-secret-test-secret-0123456789"
os.environ["DATABASE_URL"] = f"sqlite:///{_tmp.name}/test.db"
os.environ["UPLOAD_DIR"] = f"{_tmp.name}/uploads"
os.environ["ENVIRONMENT"] = "dev"
os.environ["SUPABASE_JWT_SECRET"] = TEST_JWT_SECRET
os.environ.pop("SUPABASE_URL", None)
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from jose import jwt  # noqa: E402
from sqlmodel import Session, SQLModel  # noqa: E402

from backend.app.database.base import create_db  # noqa: E402
from backend.app.database.connection import engine  # noqa: E402
from backend.app.models.marketplace_models import Dealer, DealerStatus  # noqa: E402
from backend.app.models.user_model import User, UserRole  # noqa: E402
from backend.main import app  # noqa: E402

PDF = b"%PDF-1.4\n1 0 obj<<>>endobj\n%%EOF"
PNG = b"\x89PNG\r\n\x1a\n" + bytes(40)
WEBP = b"RIFF\x24\x00\x00\x00WEBPVP8 " + bytes(40)
JPEG = b"\xff\xd8\xff\xe0" + bytes(32)


def make_token(uid, email, *, secret=TEST_JWT_SECRET, alg="HS256", aud="authenticated", exp_in=3600):
    claims = {
        "sub": str(uid),
        "email": email,
        "aud": aud,
        "role": "authenticated",
        "exp": int(time.time()) + exp_in,
    }
    return jwt.encode(claims, secret, algorithm=alg)


@pytest.fixture(autouse=True)
def fresh_db():
    SQLModel.metadata.drop_all(engine)
    create_db()
    yield


@pytest.fixture
def client():
    return TestClient(app)


class Auth(dict):
    """Authorization headers, plus the actor's ids for convenience."""

    user_id: uuid.UUID
    dealer_id: uuid.UUID | None = None


class Actors:
    def __init__(self, client):
        self.client = client
        self._n = 0

    def _identity(self, prefix):
        self._n += 1
        uid = uuid.uuid4()
        email = f"{prefix}{self._n}@example.com"
        h = Auth(Authorization=f"Bearer {make_token(uid, email)}")
        h.user_id = uid
        return h

    def customer(self):
        h = self._identity("customer")
        r = self.client.post("/api/profile", headers=h, json={"name": "Cust", "city": "Bengaluru"})
        assert r.status_code == 201, r.text
        return h

    def dealer(self, *, approved=False):
        h = self._identity("dealer")
        r = self.client.post(
            "/api/profile",
            headers=h,
            json={"name": "Dealer", "account_type": "DEALER", "business_name": "Test Motors", "city": "Bengaluru"},
        )
        assert r.status_code == 201, r.text
        h.dealer_id = uuid.UUID(self.client.get("/api/dealers/me", headers=h).json()["id"])
        if approved:
            force_status(h.dealer_id, DealerStatus.APPROVED)
        return h

    def admin(self):
        h = self._identity("admin")
        with Session(engine) as s:
            s.add(User(id=h.user_id, name="Admin", email=f"admin{self._n}@example.com", role=UserRole.ADMIN))
            s.commit()
        # token email must match the stored profile only for display; role comes from the DB
        return h


def force_status(dealer_id, status):
    """Test shortcut that skips the onboarding workflow (workflow tests do not use it)."""
    with Session(engine) as s:
        d = s.get(Dealer, dealer_id)
        d.status = status
        s.add(d)
        s.commit()


@pytest.fixture
def actors(client):
    return Actors(client)


REQUIREMENT = {
    "make": "Hyundai",
    "model": "i20",
    "year_min": 2021,
    "budget_max": 700000,
    "city": "Bengaluru",
}
LISTING = {
    "make": "Maruti Suzuki",
    "model": "Swift",
    "year": 2018,
    "fuel": "Petrol",
    "transmission": "Manual",
    "km": 40000,
    "expected_price": 400000,
    "city": "Bengaluru",
}
CAR = {
    "registration_no": "KA01AB1001",
    "make": "Hyundai", "model": "i20", "year": 2021, "fuel": "Petrol",
    "transmission": "Manual", "km": 20000, "price": 650000,
}


def car(n=1, **overrides):
    """A valid vehicle payload with its own registration number."""
    return {**CAR, "registration_no": f"KA01AB{1000 + n}", **overrides}
MISSING = "00000000-0000-0000-0000-000000000001"
