from enum import Enum
from datetime import datetime
from sqlmodel import SQLModel, Field
from typing import Optional


class UserRole(str, Enum):
    CUSTOMER = "CUSTOMER"
    DEALER = "DEALER"
    USER = "USER"
    ADMIN = "ADMIN"
    ROOT_ADMIN = "ROOT_ADMIN"


class User(SQLModel, table=True):
    id: Optional[int] = Field(
        default=None,
        primary_key=True
    )

    name: str
    email: str = Field(unique=True, index=True)
    password: str
    phone: Optional[str] = None
    role: UserRole = Field(default=UserRole.CUSTOMER)
    city: Optional[str] = None
    avatar_url: Optional[str] = None
    email_verified: bool = Field(default=False)
    email_verified_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
