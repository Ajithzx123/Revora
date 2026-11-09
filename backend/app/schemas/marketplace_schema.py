from uuid import UUID

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# --- Sell Listings ---
class SellListingCreate(BaseModel):
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int
    expected_price: int
    city: str
    images: Optional[List[str]] = []


class SellListingResponse(BaseModel):
    id: UUID
    customer_id: UUID
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int
    expected_price: int
    city: str
    images: List[str]
    status: str
    created_at: datetime
    offer_count: Optional[int] = 0


# --- Quotes ---
class DealerQuoteCreate(BaseModel):
    requirement_id: UUID
    vehicle_id: Optional[UUID] = None
    quoted_price: int = Field(gt=0, le=500_000_000)
    message: Optional[str] = Field(default=None, max_length=1000)
    valid_hours: int = Field(default=72, ge=1, le=720)
    delivery_days: Optional[int] = Field(default=None, ge=0, le=180)
    warranty_months: Optional[int] = Field(default=None, ge=0, le=120)


class QuoteRevise(BaseModel):
    quoted_price: int = Field(gt=0, le=500_000_000)
    message: Optional[str] = Field(default=None, max_length=1000)
    valid_hours: Optional[int] = Field(default=None, ge=1, le=720)
    delivery_days: Optional[int] = Field(default=None, ge=0, le=180)
    warranty_months: Optional[int] = Field(default=None, ge=0, le=120)


class ReasonOptional(BaseModel):
    reason: Optional[str] = Field(default=None, max_length=500)


class AcceptQuote(BaseModel):
    """The total the buyer saw. If the dealer changed it meanwhile, accepting is refused."""

    expected_price: int = Field(gt=0)


class CounterCreate(BaseModel):
    price: int = Field(gt=0, le=500_000_000)
    note: Optional[str] = Field(default=None, max_length=500)


class NegotiationReply(BaseModel):
    action: str = Field(pattern="^(ACCEPT|DECLINE|COUNTER)$")
    price: Optional[int] = Field(default=None, gt=0, le=500_000_000)
    note: Optional[str] = Field(default=None, max_length=500)


class QuoteRoundResponse(BaseModel):
    id: UUID
    round_no: int
    by: str
    price: int
    note: Optional[str]
    status: str
    valid_until: datetime


class DealerQuoteResponse(BaseModel):
    id: UUID
    dealer_id: UUID
    dealer_name: Optional[str] = None
    dealer_rating: Optional[float] = None
    requirement_id: UUID
    vehicle_id: Optional[UUID]
    quoted_price: int
    message: Optional[str]
    status: str
    created_at: datetime
    status_reason: Optional[str] = None
    kind: str = "IN_STOCK"
    revision: int = 1
    valid_until: Optional[datetime] = None
    delivery_days: Optional[int] = None
    warranty_months: Optional[int] = None
    vehicle_title: Optional[str] = None
    vehicle_year: Optional[int] = None
    vehicle_km: Optional[int] = None
    vehicle_fuel: Optional[str] = None
    vehicle_transmission: Optional[str] = None
    vehicle_image_url: Optional[str] = None
    list_price: Optional[int] = None  # the dealer's asking price on the car, for context
    rounds: List[QuoteRoundResponse] = []


class MyQuoteResponse(DealerQuoteResponse):
    """A dealer's own quote with a summary of the request. Contact appears only once accepted."""

    request_title: str = ""
    request_city: str = ""
    request_status: str = ""
    buyer_first_name: str = "Buyer"
    buyer_name: Optional[str] = None
    buyer_phone: Optional[str] = None


# --- Purchase Offers ---
class DealerOfferCreate(BaseModel):
    sell_listing_id: UUID
    offered_price: int
    message: Optional[str] = None


class DealerOfferResponse(BaseModel):
    id: UUID
    dealer_id: UUID
    dealer_name: Optional[str] = None
    dealer_rating: Optional[float] = None
    sell_listing_id: UUID
    offered_price: int
    message: Optional[str]
    status: str
    created_at: datetime
