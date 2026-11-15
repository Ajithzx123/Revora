import uuid
from datetime import date, datetime
from enum import Enum
from typing import Optional
from sqlalchemy import UniqueConstraint
from sqlmodel import SQLModel, Field
from backend.app.models.user_model import User, UserRole  # noqa: F401  (registers the table)


def _id() -> uuid.UUID:
    return uuid.uuid4()


class DealerStatus(str, Enum):
    DRAFT = "DRAFT"                  # filling in details and documents
    PENDING = "PENDING"              # submitted, waiting for admin review
    NEEDS_CHANGES = "NEEDS_CHANGES"  # admin asked for fixes; dealer may resubmit
    APPROVED = "APPROVED"            # verified: may see leads, quote, make offers
    REJECTED = "REJECTED"            # application declined
    SUSPENDED = "SUSPENDED"          # was approved, now blocked by admin


class DocumentType(str, Enum):
    OWNER_ID = "OWNER_ID"
    BUSINESS_PROOF = "BUSINESS_PROOF"            # trade licence / shop registration
    ADDRESS_PROOF = "ADDRESS_PROOF"
    GST_CERTIFICATE = "GST_CERTIFICATE"          # optional
    BRAND_AUTHORISATION = "BRAND_AUTHORISATION"  # optional, only if claiming authorised dealer
    SHOWROOM_PHOTO = "SHOWROOM_PHOTO"            # optional


REQUIRED_DOCUMENTS = (
    DocumentType.OWNER_ID,
    DocumentType.BUSINESS_PROOF,
    DocumentType.ADDRESS_PROOF,
)


class DocumentStatus(str, Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"


class Dealer(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    user_id: uuid.UUID = Field(foreign_key="user.id", unique=True)
    business_name: str
    gstin: Optional[str] = None
    address: Optional[str] = None
    city: str
    status: DealerStatus = Field(default=DealerStatus.DRAFT, index=True)
    status_reason: Optional[str] = None   # last admin reason (changes requested / rejected / suspended)
    submitted_at: Optional[datetime] = None
    reviewed_at: Optional[datetime] = None
    reviewed_by: Optional[uuid.UUID] = None
    rating: float = Field(default=5.0)
    total_deals: int = Field(default=0)
    # Makes this dealer will source on request even without a matching car in stock.
    sourcing_makes_csv: str = Field(default="")
    # Makes this dealer buys from sellers; sell listings are matched on this.
    buy_makes_csv: str = Field(default="")
    created_at: datetime = Field(default_factory=datetime.utcnow)

    @property
    def sourcing_makes(self) -> list[str]:
        return [m for m in self.sourcing_makes_csv.split(",") if m]

    @property
    def buy_makes(self) -> list[str]:
        return [m for m in self.buy_makes_csv.split(",") if m]

    @property
    def verified(self) -> bool:
        return self.status == DealerStatus.APPROVED


class DealerDocument(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    dealer_id: uuid.UUID = Field(foreign_key="dealer.id", index=True)
    doc_type: DocumentType
    storage_key: str                       # opaque server-side file name, never exposed to clients
    original_name: str
    content_type: str
    size_bytes: int
    status: DocumentStatus = Field(default=DocumentStatus.PENDING)
    review_note: Optional[str] = None
    expires_on: Optional[date] = None
    is_current: bool = Field(default=True)  # newer upload of the same type supersedes older ones
    uploaded_at: datetime = Field(default_factory=datetime.utcnow)


class VehicleStatus(str, Enum):
    AVAILABLE = "AVAILABLE"
    RESERVED = "RESERVED"
    SOLD = "SOLD"


class Vehicle(SQLModel, table=True):
    """A car in a dealer's stock. Separate from quotes: a quote *refers* to a vehicle."""

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    dealer_id: uuid.UUID = Field(foreign_key="dealer.id", index=True)
    registration_no: str = Field(unique=True, index=True)  # normalised, e.g. KA01AB1234
    make: str
    model: str
    variant: Optional[str] = None
    year: int
    fuel: str
    transmission: str
    km: int
    owners: int = Field(default=1)
    color: Optional[str] = None
    body_type: Optional[str] = None
    price: int                                   # asking price, Rs
    min_price: Optional[int] = None              # private floor; never sent to buyers
    description: Optional[str] = None
    status: VehicleStatus = Field(default=VehicleStatus.AVAILABLE, index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class VehicleMedia(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    vehicle_id: uuid.UUID = Field(foreign_key="vehicle.id", index=True)
    storage_key: str
    content_type: str
    size_bytes: int
    position: int = Field(default=0)  # 0 is the cover photo
    created_at: datetime = Field(default_factory=datetime.utcnow)


class RequirementStatus(str, Enum):
    OPEN = "OPEN"
    PAUSED = "PAUSED"
    QUOTE_ACCEPTED = "QUOTE_ACCEPTED"
    IN_TRANSACTION = "IN_TRANSACTION"
    COMPLETED = "COMPLETED"
    EXPIRED = "EXPIRED"
    CANCELLED = "CANCELLED"


class Urgency(str, Enum):
    NOW = "NOW"
    WITHIN_2_WEEKS = "WITHIN_2_WEEKS"
    WITHIN_60_DAYS = "WITHIN_60_DAYS"


class BuyRequirement(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    customer_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    make: str
    model: Optional[str] = None            # None = any model of this make
    variant: Optional[str] = None
    year_min: int
    year_max: Optional[int] = None
    budget_min: int = Field(default=0)
    budget_max: int
    fuel: Optional[str] = None
    transmission: Optional[str] = None
    body_type: Optional[str] = None
    max_km: Optional[int] = None
    max_owners: Optional[int] = None
    city: str
    radius_km: int = Field(default=50)
    urgency: Urgency = Field(default=Urgency.WITHIN_2_WEEKS)
    needs_finance: bool = Field(default=False)
    has_exchange: bool = Field(default=False)
    # Comma-separated field names the buyer marked as hard requirements; the rest are soft.
    must_have_csv: str = Field(default="")
    notes: Optional[str] = None
    status: RequirementStatus = Field(default=RequirementStatus.OPEN, index=True)
    expires_at: datetime
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class MatchRecord(SQLModel, table=True):
    """One dealer being shown one buyer request, and why. Written once per pair."""

    __table_args__ = (UniqueConstraint("requirement_id", "dealer_id", name="uq_match_requirement_dealer"),)

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    requirement_id: uuid.UUID = Field(foreign_key="buyrequirement.id", index=True)
    dealer_id: uuid.UUID = Field(foreign_key="dealer.id", index=True)
    vehicle_id: Optional[uuid.UUID] = Field(default=None, foreign_key="vehicle.id")  # best car; None = sourcing
    tier: int = Field(default=1)          # 1 exact in stock, 2 alternative in stock, 3 can source
    score: int = Field(default=0)         # 0-100, see matching_service for the breakdown
    reasons_csv: str = Field(default="")  # human-readable "why", separated by |
    dismissed_at: Optional[datetime] = None
    dismissed_reason: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)

    @property
    def reasons(self) -> list[str]:
        return [r for r in self.reasons_csv.split("|") if r]


class SellListing(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    customer_id: uuid.UUID = Field(foreign_key="user.id", index=True)
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int
    expected_price: int
    city: str
    images_csv: str = Field(default="")  # Comma-separated URLs
    # ACTIVE (open for offers), OFFER_ACCEPTED, FINAL_ACCEPTED, SOLD, CLOSED, EXPIRED, FROZEN
    status: str = Field(default="ACTIVE")
    status_reason: Optional[str] = None
    variant: Optional[str] = None
    owners: int = Field(default=1)
    color: Optional[str] = None
    urgency: str = Field(default="NORMAL")      # URGENT (2 days), NORMAL (14 days), MAX_PRICE (5 days)
    loan_outstanding: bool = Field(default=False)
    loan_amount: Optional[int] = None
    challans_amount: Optional[int] = None        # declared pending challans, Rs
    insurance_valid: Optional[bool] = None
    description: Optional[str] = None
    expires_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None


class SellMatch(SQLModel, table=True):
    """A dealer who was shown a sell listing. Offers are only accepted from matched dealers."""

    __table_args__ = (UniqueConstraint("listing_id", "dealer_id", name="uq_sellmatch_listing_dealer"),)

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    listing_id: uuid.UUID = Field(foreign_key="selllisting.id", index=True)
    dealer_id: uuid.UUID = Field(foreign_key="dealer.id", index=True)
    score: int = Field(default=0)
    reasons_csv: str = Field(default="")
    dismissed_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    @property
    def reasons(self) -> list[str]:
        return [r for r in self.reasons_csv.split("|") if r]


class DealerQuote(SQLModel, table=True):
    """One dealer's current price for one request. Earlier prices live in QuoteRevision."""

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    dealer_id: uuid.UUID = Field(foreign_key="dealer.id", index=True)
    requirement_id: uuid.UUID = Field(foreign_key="buyrequirement.id", index=True)
    vehicle_id: Optional[uuid.UUID] = Field(default=None, foreign_key="vehicle.id")
    quoted_price: int  # the all-in total the buyer pays, Rs
    message: Optional[str] = None
    # PENDING (live), ACCEPTED, REJECTED, NOT_SELECTED, WITHDRAWN, EXPIRED, UNAVAILABLE,
    # REQUOTE_REQUESTED, CLOSED_BY_CUSTOMER, VOID_ADMIN
    status: str = Field(default="PENDING")
    status_reason: Optional[str] = None
    void_cause: Optional[str] = None  # set with status VOID_ADMIN: ADMIN or DEALER_SUSPENDED
    kind: str = Field(default="IN_STOCK")  # IN_STOCK, ALTERNATIVE (other model), SOURCED (not in stock)
    revision: int = Field(default=1)
    valid_until: Optional[datetime] = None
    delivery_days: Optional[int] = None
    warranty_months: Optional[int] = None
    accepted_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None


class QuoteRevision(SQLModel, table=True):
    """Every price a quote has had, so a revision never erases history."""

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    quote_id: uuid.UUID = Field(foreign_key="dealerquote.id", index=True)
    revision: int
    price: int
    message: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class QuoteRound(SQLModel, table=True):
    """One counter-offer in a price negotiation on a quote (at most 5 per quote)."""

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    quote_id: uuid.UUID = Field(foreign_key="dealerquote.id", index=True)
    round_no: int
    by: str  # CUSTOMER or DEALER
    price: int
    note: Optional[str] = None
    status: str = Field(default="OPEN")  # OPEN, AGREED, DECLINED, COUNTERED, SUPERSEDED, EXPIRED
    valid_until: datetime
    created_at: datetime = Field(default_factory=datetime.utcnow)


class DealerOffer(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    dealer_id: uuid.UUID = Field(foreign_key="dealer.id", index=True)
    sell_listing_id: uuid.UUID = Field(foreign_key="selllisting.id", index=True)
    offered_price: int
    message: Optional[str] = None
    # PENDING (live), ACCEPTED, REJECTED, NOT_SELECTED, WITHDRAWN, EXPIRED, VOID_ADMIN
    status: str = Field(default="PENDING")
    status_reason: Optional[str] = None
    void_cause: Optional[str] = None        # with VOID_ADMIN: ADMIN or DEALER_SUSPENDED
    revision: int = Field(default=1)
    valid_until: Optional[datetime] = None
    inspection_required: bool = Field(default=True)
    pickup_days: Optional[int] = None
    accepted_at: Optional[datetime] = None
    # The inspection stage, after the seller accepts: the dealer confirms or lowers the price.
    # None (no final offer yet), SUBMITTED, ACCEPTED, DECLINED.
    final_status: Optional[str] = None
    final_price: Optional[int] = None
    final_reason_code: Optional[str] = None
    final_reason_note: Optional[str] = None
    final_evidence_csv: str = Field(default="")
    final_submitted_at: Optional[datetime] = None
    final_decided_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None

    @property
    def final_evidence(self) -> list[str]:
        return [u for u in self.final_evidence_csv.split(",") if u]


class OfferRound(SQLModel, table=True):
    """One counter-offer in a price negotiation on an offer (at most 5 per offer)."""

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    offer_id: uuid.UUID = Field(foreign_key="dealeroffer.id", index=True)
    round_no: int
    by: str  # SELLER or DEALER
    price: int
    note: Optional[str] = None
    status: str = Field(default="OPEN")  # OPEN, AGREED, DECLINED, COUNTERED, SUPERSEDED, EXPIRED
    valid_until: datetime
    created_at: datetime = Field(default_factory=datetime.utcnow)


class OfferRevision(SQLModel, table=True):
    """Every price an offer has had, so a revision never erases history."""

    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    offer_id: uuid.UUID = Field(foreign_key="dealeroffer.id", index=True)
    revision: int
    price: int
    message: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
