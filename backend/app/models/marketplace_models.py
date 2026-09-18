from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field
from backend.app.models.user_model import User, UserRole


class Dealer(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", unique=True)
    business_name: str
    gstin: Optional[str] = None
    address: Optional[str] = None
    city: str
    verified: bool = Field(default=False)
    rating: float = Field(default=5.0)
    total_deals: int = Field(default=0)
    created_at: datetime = Field(default_factory=datetime.utcnow)


class CarInventory(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    dealer_id: int = Field(foreign_key="dealer.id")
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int
    price: int
    images_csv: str = Field(default="")  # Comma-separated URLs
    status: str = Field(default="AVAILABLE")  # AVAILABLE, RESERVED, SOLD
    created_at: datetime = Field(default_factory=datetime.utcnow)


class BuyRequirement(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    customer_id: int = Field(foreign_key="user.id")
    make: str
    model: str
    year_min: int
    budget: int
    fuel: Optional[str] = None
    transmission: Optional[str] = None
    city: str
    notes: Optional[str] = None
    status: str = Field(default="ACTIVE")  # ACTIVE, CLOSED, FULFILLED
    created_at: datetime = Field(default_factory=datetime.utcnow)


class SellListing(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    customer_id: int = Field(foreign_key="user.id")
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int
    expected_price: int
    city: str
    images_csv: str = Field(default="")  # Comma-separated URLs
    status: str = Field(default="ACTIVE")  # ACTIVE, CLOSED, SOLD
    created_at: datetime = Field(default_factory=datetime.utcnow)


class DealerQuote(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    dealer_id: int = Field(foreign_key="dealer.id")
    requirement_id: int = Field(foreign_key="buyrequirement.id")
    car_inventory_id: Optional[int] = Field(default=None, foreign_key="carinventory.id")
    quoted_price: int
    message: Optional[str] = None
    status: str = Field(default="PENDING")  # PENDING, ACCEPTED, REJECTED, EXPIRED
    created_at: datetime = Field(default_factory=datetime.utcnow)


class DealerOffer(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    dealer_id: int = Field(foreign_key="dealer.id")
    sell_listing_id: int = Field(foreign_key="selllisting.id")
    offered_price: int
    message: Optional[str] = None
    status: str = Field(default="PENDING")  # PENDING, ACCEPTED, REJECTED, EXPIRED
    created_at: datetime = Field(default_factory=datetime.utcnow)
