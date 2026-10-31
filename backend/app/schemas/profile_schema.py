from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class ProfileCreate(BaseModel):
    """First-time profile for an authenticated Supabase user.

    Self-service can only create customers or dealer applicants; admin roles are
    never assignable from the API.
    """

    name: str = Field(min_length=1, max_length=120)
    phone: Optional[str] = Field(default=None, max_length=20)
    city: Optional[str] = Field(default=None, max_length=100)
    account_type: Literal["CUSTOMER", "DEALER"] = "CUSTOMER"
    business_name: Optional[str] = Field(default=None, max_length=200)

    @model_validator(mode="after")
    def dealer_needs_business_details(self):
        if self.account_type == "DEALER" and not (self.business_name and self.city):
            raise ValueError("business_name and city are required for dealer accounts")
        return self


class ProfileUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    phone: Optional[str] = Field(default=None, max_length=20)
    city: Optional[str] = Field(default=None, max_length=100)


class ProfileResponse(BaseModel):
    id: UUID
    name: str
    email: str
    phone: Optional[str]
    city: Optional[str]
    role: str
    dealer_status: Optional[str] = None
