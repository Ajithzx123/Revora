import uuid
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
    """Local profile for an identity managed by Supabase Auth.

    `id` is the Supabase auth user id (the JWT `sub`). Passwords, OTPs and
    sessions live in Supabase, never here. `role` is authoritative here and is
    never taken from token metadata, which the client can edit.
    """

    id: uuid.UUID = Field(primary_key=True)

    name: str
    email: str = Field(unique=True, index=True)
    phone: Optional[str] = None
    role: UserRole = Field(default=UserRole.CUSTOMER)
    city: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: bool = Field(default=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
