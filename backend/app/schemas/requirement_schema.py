from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator, model_validator

from backend.app.core import master_data as md
from backend.app.models.marketplace_models import RequirementStatus, Urgency


def _one_of(value: Optional[str], allowed: list[str], label: str) -> Optional[str]:
    if value is None:
        return None
    match = next((a for a in allowed if a.lower() == value.strip().lower()), None)
    if match is None:
        raise ValueError(f"{label} must be one of: {', '.join(allowed)}")
    return match


class RequirementFields(BaseModel):
    """Validation shared by create and edit. Every field is optional here;
    `RequirementCreate` makes the mandatory ones required."""

    make: Optional[str] = None
    model: Optional[str] = Field(default=None, max_length=60)
    variant: Optional[str] = Field(default=None, max_length=60)
    year_min: Optional[int] = None
    year_max: Optional[int] = None
    budget_min: Optional[int] = None
    budget_max: Optional[int] = None
    fuel: Optional[str] = None
    transmission: Optional[str] = None
    body_type: Optional[str] = None
    max_km: Optional[int] = Field(default=None, ge=0, le=500_000)
    max_owners: Optional[int] = Field(default=None, ge=1, le=6)
    city: Optional[str] = None
    radius_km: Optional[int] = Field(default=None, ge=5, le=500)
    urgency: Optional[Urgency] = None
    needs_finance: Optional[bool] = None
    has_exchange: Optional[bool] = None
    must_have: Optional[List[str]] = None
    notes: Optional[str] = Field(default=None, max_length=500)

    @field_validator("make")
    @classmethod
    def _make(cls, v):
        return _one_of(v, list(md.MAKES_AND_MODELS), "make")

    @field_validator("fuel")
    @classmethod
    def _fuel(cls, v):
        return _one_of(v, md.FUELS, "fuel")

    @field_validator("transmission")
    @classmethod
    def _transmission(cls, v):
        return _one_of(v, md.TRANSMISSIONS, "transmission")

    @field_validator("body_type")
    @classmethod
    def _body(cls, v):
        return _one_of(v, md.BODY_TYPES, "body_type")

    @field_validator("city")
    @classmethod
    def _city(cls, v):
        return _one_of(v, md.CITIES, "city")

    @field_validator("year_min", "year_max")
    @classmethod
    def _year(cls, v):
        if v is None:
            return v
        latest = datetime.utcnow().year + 1
        if not (md.MIN_YEAR <= v <= latest):
            raise ValueError(f"year must be between {md.MIN_YEAR} and {latest}")
        return v

    @field_validator("budget_min", "budget_max")
    @classmethod
    def _budget(cls, v):
        if v is None:
            return v
        if v < 0 or v > md.MAX_BUDGET:
            raise ValueError(f"budget must be between 0 and {md.MAX_BUDGET}")
        return v

    @field_validator("must_have")
    @classmethod
    def _must_have(cls, v):
        if v is None:
            return v
        unknown = sorted(set(v) - set(md.MUST_HAVE_FIELDS))
        if unknown:
            raise ValueError(f"unknown must-have fields: {', '.join(unknown)}")
        return sorted(set(v))

    @model_validator(mode="after")
    def _cross_checks(self):
        if self.make and self.model and self.model not in md.MAKES_AND_MODELS[self.make]:
            raise ValueError(f"{self.model} is not a known {self.make} model")
        if self.year_min and self.year_max and self.year_max < self.year_min:
            raise ValueError("year_max cannot be before year_min")
        if self.budget_min is not None and self.budget_max is not None and self.budget_max < self.budget_min:
            raise ValueError("budget_max cannot be below budget_min")
        if self.budget_max is not None and self.budget_max < md.MIN_BUDGET:
            raise ValueError(f"budget_max must be at least {md.MIN_BUDGET}")
        return self


class RequirementCreate(RequirementFields):
    make: str
    year_min: int
    budget_max: int
    city: str
    budget_min: int = 0
    radius_km: int = Field(default=50, ge=5, le=500)
    urgency: Urgency = Urgency.WITHIN_2_WEEKS
    needs_finance: bool = False
    has_exchange: bool = False
    must_have: List[str] = []


class RequirementUpdate(RequirementFields):
    """Partial edit. Only the fields sent are changed."""


class RequirementResponse(BaseModel):
    id: UUID
    customer_id: UUID
    make: str
    model: Optional[str]
    variant: Optional[str]
    year_min: int
    year_max: Optional[int]
    budget_min: int
    budget_max: int
    fuel: Optional[str]
    transmission: Optional[str]
    body_type: Optional[str]
    max_km: Optional[int]
    max_owners: Optional[int]
    city: str
    radius_km: int
    urgency: Urgency
    needs_finance: bool
    has_exchange: bool
    must_have: List[str]
    notes: Optional[str]
    status: RequirementStatus
    expires_at: datetime
    created_at: datetime
    quote_count: int = 0


class BuyLeadResponse(BaseModel):
    """What a verified dealer sees. No buyer id, surname or contact details."""

    id: UUID
    buyer_first_name: str
    city: str
    make: str
    model: Optional[str]
    variant: Optional[str]
    year_min: int
    year_max: Optional[int]
    budget_min: int
    budget_max: int
    fuel: Optional[str]
    transmission: Optional[str]
    body_type: Optional[str]
    max_km: Optional[int]
    max_owners: Optional[int]
    radius_km: int
    urgency: Urgency
    needs_finance: bool
    has_exchange: bool
    must_have: List[str]
    notes: Optional[str]
    expires_at: datetime
    created_at: datetime
    quote_count: int = 0
