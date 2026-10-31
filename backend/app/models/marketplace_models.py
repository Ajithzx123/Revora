import uuid
from datetime import date, datetime
from enum import Enum
from typing import Optional
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
    created_at: datetime = Field(default_factory=datetime.utcnow)

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


class CarInventory(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    dealer_id: uuid.UUID = Field(foreign_key="dealer.id", index=True)
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
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    customer_id: uuid.UUID = Field(foreign_key="user.id", index=True)
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
    status: str = Field(default="ACTIVE")  # ACTIVE, CLOSED, SOLD
    created_at: datetime = Field(default_factory=datetime.utcnow)


class DealerQuote(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    dealer_id: uuid.UUID = Field(foreign_key="dealer.id", index=True)
    requirement_id: uuid.UUID = Field(foreign_key="buyrequirement.id", index=True)
    car_inventory_id: Optional[uuid.UUID] = Field(default=None, foreign_key="carinventory.id")
    quoted_price: int
    message: Optional[str] = None
    status: str = Field(default="PENDING")  # PENDING, ACCEPTED, REJECTED, EXPIRED
    created_at: datetime = Field(default_factory=datetime.utcnow)


class DealerOffer(SQLModel, table=True):
    id: uuid.UUID = Field(default_factory=_id, primary_key=True)
    dealer_id: uuid.UUID = Field(foreign_key="dealer.id", index=True)
    sell_listing_id: uuid.UUID = Field(foreign_key="selllisting.id", index=True)
    offered_price: int
    message: Optional[str] = None
    status: str = Field(default="PENDING")  # PENDING, ACCEPTED, REJECTED, EXPIRED
    created_at: datetime = Field(default_factory=datetime.utcnow)
