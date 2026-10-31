import os
import sys
import tempfile
from pathlib import Path

# Must run before any backend import: use a throwaway database.
_tmp = tempfile.TemporaryDirectory()
os.environ["DATABASE_URL"] = f"sqlite:///{_tmp.name}/test.db"
os.environ["ENVIRONMENT"] = "dev"
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlmodel import Session, SQLModel  # noqa: E402

from backend.app.core.security import hash_password  # noqa: E402
from backend.app.database.base import create_db  # noqa: E402
from backend.app.database.connection import engine  # noqa: E402
from backend.app.models.user_model import User, UserRole  # noqa: E402
from backend.main import app  # noqa: E402


@pytest.fixture(autouse=True)
def fresh_db():
    SQLModel.metadata.drop_all(engine)
    create_db()
    yield


@pytest.fixture
def client():
    return TestClient(app)


class Actors:
    def __init__(self, client):
        self.client = client
        self._n = 0

    def _signup_login(self, **extra):
        self._n += 1
        email = f"user{self._n}@example.com"
        body = {
            "name": f"User {self._n}",
            "email": email,
            "password": "Passw0rd!x",
            "phone": f"90000000{self._n:02d}",
            **extra,
        }
        r = self.client.post("/api/signup", json=body)
        assert r.status_code == 200, r.text
        r = self.client.post("/api/login", json={"email": email, "password": "Passw0rd!x"})
        data = r.json()["data"]
        return {"Authorization": f"Bearer {data['access_token']}"}, r.json()

    def customer(self):
        return self._signup_login()[0]

    def dealer(self):
        return self._signup_login(
            account_type="DEALER", business_name="Test Motors", city="Bengaluru"
        )[0]

    def admin(self):
        self._n += 1
        email = f"admin{self._n}@example.com"
        with Session(engine) as s:
            s.add(
                User(
                    name="Admin",
                    email=email,
                    password=hash_password("Passw0rd!x"),
                    role=UserRole.ADMIN,
                )
            )
            s.commit()
        r = self.client.post("/api/login", json={"email": email, "password": "Passw0rd!x"})
        return {"Authorization": f"Bearer {r.json()['data']['access_token']}"}


@pytest.fixture
def actors(client):
    return Actors(client)


def verify_dealer(client, admin_headers, dealer_id=1):
    r = client.patch(f"/api/admin/dealers/{dealer_id}/verify", headers=admin_headers)
    assert r.status_code == 200, r.text


REQUIREMENT = {
    "make": "Hyundai",
    "model": "i20",
    "year_min": 2021,
    "budget": 700000,
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
