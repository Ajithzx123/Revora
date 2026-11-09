from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator, model_validator

from backend.app.core import master_data as md
from backend.app.models.marketplace_models import VehicleStatus
from backend.app.schemas.requirement_schema import _one_of


class VehicleFields(BaseModel):
    registration_no: Optional[str] = None
    make: Optional[str] = None
    model: Optional[str] = Field(default=None, max_length=60)
    variant: Optional[str] = Field(default=None, max_length=60)
    year: Optional[int] = None
    fuel: Optional[str] = None
    transmission: Optional[str] = None
    km: Optional[int] = Field(default=None, ge=0, le=1_000_000)
    owners: Optional[int] = Field(default=None, ge=1, le=10)
    color: Optional[str] = None
    body_type: Optional[str] = None
    price: Optional[int] = Field(default=None, ge=md.MIN_BUDGET // 2, le=md.MAX_BUDGET)
    min_price: Optional[int] = Field(default=None, ge=0, le=md.MAX_BUDGET)
    description: Optional[str] = Field(default=None, max_length=1000)

    @field_validator("registration_no")
    @classmethod
    def _registration(cls, v):
        if v is None:
            return v
        normalized = md.normalize_registration(v)
        if not md.is_valid_registration(normalized):
            raise ValueError("registration number looks wrong (example: KA01AB1234)")
        return normalized

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

    @field_validator("color")
    @classmethod
    def _color(cls, v):
        return _one_of(v, md.COLORS, "color")

    @field_validator("year")
    @classmethod
    def _year(cls, v):
        if v is None:
            return v
        latest = datetime.utcnow().year + 1
        if not (md.MIN_YEAR <= v <= latest):
            raise ValueError(f"year must be between {md.MIN_YEAR} and {latest}")
        return v

    @model_validator(mode="after")
    def _cross(self):
        if self.make and self.model and self.model not in md.MAKES_AND_MODELS[self.make]:
            raise ValueError(f"{self.model} is not a known {self.make} model")
        if self.price is not None and self.min_price is not None and self.min_price > self.price:
            raise ValueError("min_price cannot be above the asking price")
        return self


class VehicleCreate(VehicleFields):
    registration_no: str
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int = Field(ge=0, le=1_000_000)
    price: int = Field(ge=md.MIN_BUDGET // 2, le=md.MAX_BUDGET)
    owners: int = Field(default=1, ge=1, le=10)


class VehicleUpdate(VehicleFields):
    status: Optional[VehicleStatus] = None


class MediaResponse(BaseModel):
    id: UUID
    url: str
    position: int


class VehicleResponse(BaseModel):
    """The dealer's own view of a vehicle (includes the private minimum price)."""

    id: UUID
    dealer_id: UUID
    registration_no: str
    make: str
    model: str
    variant: Optional[str]
    year: int
    fuel: str
    transmission: str
    km: int
    owners: int
    color: Optional[str]
    body_type: Optional[str]
    price: int
    min_price: Optional[int]
    description: Optional[str]
    status: VehicleStatus
    images: List[MediaResponse]
    created_at: datetime


class MediaOrder(BaseModel):
    """New photo order; the first id becomes the cover."""

    ids: List[UUID]
