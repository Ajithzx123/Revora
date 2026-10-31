from typing import Literal

from pydantic import BaseModel, EmailStr, model_validator


class SignupRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    phone: str
    # Self-service signup can only create customers or dealer applicants.
    # Admin roles are never assignable from this endpoint.
    account_type: Literal["CUSTOMER", "DEALER"] = "CUSTOMER"
    business_name: str | None = None
    city: str | None = None

    @model_validator(mode="after")
    def dealer_needs_business_details(self):
        if self.account_type == "DEALER" and not (self.business_name and self.city):
            raise ValueError("business_name and city are required for dealer signup")
        return self


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    device_id: str | None = None


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str


class SendVerificationEmailRequest(BaseModel):
    email: EmailStr


class VerifyEmailRequest(BaseModel):
    token: str
