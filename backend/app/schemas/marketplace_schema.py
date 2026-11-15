from uuid import UUID

from pydantic import BaseModel, Field, field_validator, model_validator

from backend.app.core import master_data as md
from typing import Optional, List
from datetime import datetime


# --- Sell Listings ---
def _one_of(value: str, allowed: list[str], label: str) -> str:
    match = next((a for a in allowed if a.lower() == value.strip().lower()), None)
    if match is None:
        raise ValueError(f"{label} must be one of: {', '.join(allowed)}")
    return match


class SellListingCreate(BaseModel):
    make: str
    model: str = Field(min_length=1, max_length=60)
    year: int
    fuel: str
    transmission: str
    km: int = Field(ge=0, le=1_000_000)
    expected_price: int = Field(ge=10_000, le=500_000_000)
    city: str
    images: List[str] = Field(default_factory=list, max_length=12)
    variant: Optional[str] = Field(default=None, max_length=60)
    owners: int = Field(default=1, ge=1, le=10)
    color: Optional[str] = None
    urgency: str = Field(default="NORMAL", pattern="^(URGENT|NORMAL|MAX_PRICE)$")
    loan_outstanding: bool = False
    loan_amount: Optional[int] = Field(default=None, ge=0, le=500_000_000)
    challans_amount: Optional[int] = Field(default=None, ge=0, le=10_000_000)
    insurance_valid: Optional[bool] = None
    description: Optional[str] = Field(default=None, max_length=1000)

    @field_validator("make")
    @classmethod
    def _make(cls, v: str) -> str:
        return _one_of(v, list(md.MAKES_AND_MODELS), "Make")

    @field_validator("fuel")
    @classmethod
    def _fuel(cls, v: str) -> str:
        return _one_of(v, md.FUELS, "Fuel")

    @field_validator("transmission")
    @classmethod
    def _transmission(cls, v: str) -> str:
        return _one_of(v, md.TRANSMISSIONS, "Transmission")

    @field_validator("city")
    @classmethod
    def _city(cls, v: str) -> str:
        return _one_of(v, md.CITIES, "City")

    @field_validator("color")
    @classmethod
    def _color(cls, v: Optional[str]) -> Optional[str]:
        return None if v is None else _one_of(v, md.COLORS, "Colour")

    @field_validator("images")
    @classmethod
    def _images(cls, v: List[str]) -> List[str]:
        if any((not u) or len(u) > 500 or "," in u for u in v):
            raise ValueError("Each image must be a URL under 500 characters without commas")
        return v

    @model_validator(mode="after")
    def _consistent(self):
        if not (md.MIN_YEAR <= self.year <= datetime.utcnow().year + 1):
            raise ValueError(f"Year must be between {md.MIN_YEAR} and {datetime.utcnow().year + 1}")
        if self.loan_amount is not None and not self.loan_outstanding:
            raise ValueError("Loan amount needs 'loan outstanding' to be set")
        return self


class SellListingPrice(BaseModel):
    expected_price: int = Field(ge=10_000, le=500_000_000)


class SellListingClose(BaseModel):
    """Closing without a sale, or recording that the car was sold elsewhere."""

    reason: Optional[str] = Field(default=None, max_length=500)
    sold_elsewhere: bool = False


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
    variant: Optional[str] = None
    owners: int = 1
    color: Optional[str] = None
    urgency: str = "NORMAL"
    loan_outstanding: bool = False
    loan_amount: Optional[int] = None
    challans_amount: Optional[int] = None
    insurance_valid: Optional[bool] = None
    description: Optional[str] = None
    expires_at: Optional[datetime] = None
    status_reason: Optional[str] = None


class SellLeadResponse(SellListingResponse):
    """A matched listing as the dealer sees it: no seller identity, plus why it matched."""

    match_score: int = 0
    match_reasons: List[str] = []
    my_offer_status: Optional[str] = None


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
    offered_price: int = Field(gt=0, le=500_000_000)
    message: Optional[str] = Field(default=None, max_length=1000)
    valid_hours: int = Field(default=48, ge=1, le=168)
    inspection_required: bool = True
    pickup_days: Optional[int] = Field(default=None, ge=0, le=60)


class OfferRevise(BaseModel):
    offered_price: int = Field(gt=0, le=500_000_000)
    message: Optional[str] = Field(default=None, max_length=1000)
    valid_hours: Optional[int] = Field(default=None, ge=1, le=168)
    pickup_days: Optional[int] = Field(default=None, ge=0, le=60)


class AcceptOffer(BaseModel):
    """The price the seller saw. If the dealer changed it meanwhile, accepting is refused."""

    expected_price: int = Field(gt=0)


FINAL_REASON_CODES = [
    "ODOMETER_MISMATCH",
    "UNDISCLOSED_ACCIDENT",
    "MECHANICAL_ISSUE",
    "BODY_CONDITION",
    "PAPERWORK_ISSUE",
    "OTHER",
]


class FinalOfferCreate(BaseModel):
    """The price after inspection. Same as the accepted offer confirms it; lower needs a reason,
    and a drop of more than 5% also needs evidence."""

    price: int = Field(gt=0, le=500_000_000)
    reason_code: Optional[str] = None
    reason_note: Optional[str] = Field(default=None, max_length=1000)
    evidence_urls: List[str] = Field(default_factory=list, max_length=8)

    @field_validator("reason_code")
    @classmethod
    def _reason(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        return _one_of(v.replace(" ", "_"), FINAL_REASON_CODES, "Reason")

    @field_validator("evidence_urls")
    @classmethod
    def _evidence(cls, v: List[str]) -> List[str]:
        if any((not u) or len(u) > 500 or "," in u for u in v):
            raise ValueError("Each evidence link must be under 500 characters without commas")
        return v


class FinalOfferRespond(BaseModel):
    action: str = Field(pattern="^(ACCEPT|DECLINE)$")


class OfferRoundResponse(BaseModel):
    id: UUID
    round_no: int
    by: str
    price: int
    note: Optional[str]
    status: str
    valid_until: datetime


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
    status_reason: Optional[str] = None
    revision: int = 1
    valid_until: Optional[datetime] = None
    inspection_required: bool = True
    pickup_days: Optional[int] = None
    loan_settlement_required: bool = False
    rounds: List[OfferRoundResponse] = []
    final_status: Optional[str] = None
    final_price: Optional[int] = None
    final_drop_percent: Optional[float] = None
    final_reason_code: Optional[str] = None
    final_reason_note: Optional[str] = None
    final_evidence: List[str] = []


class MyOfferResponse(DealerOfferResponse):
    """A dealer's own offer with a summary of the listing. Contact appears only once accepted."""

    listing_title: str = ""
    listing_city: str = ""
    listing_status: str = ""
    seller_first_name: str = "Seller"
    seller_name: Optional[str] = None
    seller_phone: Optional[str] = None
