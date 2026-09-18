from fastapi import APIRouter, Depends, Request
from backend.app.schemas.auth_schema import (
    ForgotPasswordRequest,
    LogoutRequest,
    RefreshTokenRequest,
    ResetPasswordRequest,
    SendVerificationEmailRequest,
    SignupRequest,
    LoginRequest,
    VerifyEmailRequest,
)
from backend.app.services.auth_service import (
    forgot_password,
    get_user_profile,
    list_user_sessions,
    login_user,
    logout_all_user_sessions,
    logout_user,
    refresh_user_session,
    reset_password,
    revoke_user_session,
    send_verification_email,
    signup_user,
    verify_email,
)
from backend.app.core.dependencies import require_auth


router = APIRouter()


@router.post("/signup")
def signup(request: SignupRequest):

    user = signup_user(
        request.name,
        request.email,
        request.password,
        request.phone,
    )

    return {"status": True, "message": "User Created", "data": user}


@router.post("/login")
def login(request: LoginRequest, http_request: Request):
    result = login_user(
        request.email,
        request.password,
        device_id=request.device_id,
        ip_address=http_request.client.host if http_request.client else None,
        user_agent=http_request.headers.get("user-agent"),
    )

    if result is None:

        return {"status": False, "message": "Invalid credentials"}

    return {"status": True, "message": "Login successful", "data": result}


@router.post("/refresh")
def refresh_token(request: RefreshTokenRequest):
    result = refresh_user_session(request.refresh_token)

    if result is None:
        return {"status": False, "message": "Invalid or expired refresh token"}

    return {"status": True, "message": "Token refreshed", "data": result}


@router.post("/logout")
def logout(request: LogoutRequest):
    logout_user(request.refresh_token)

    return {"status": True, "message": "Logout successful"}


@router.post("/logout-all")
def logout_all(user_data=Depends(require_auth)):
    logout_all_user_sessions(user_data["user_id"])

    return {"status": True, "message": "All sessions logged out"}


@router.post("/forgot-password")
def forgot_password_request(request: ForgotPasswordRequest):
    forgot_password(request.email)

    return {
        "status": True,
        "message": "If this account exists, reset instructions have been sent",
    }


@router.post("/reset-password")
def reset_password_request(request: ResetPasswordRequest):
    password_reset = reset_password(request.token, request.new_password)

    if not password_reset:
        return {"status": False, "message": "Invalid or expired reset token"}

    return {"status": True, "message": "Password reset successful"}


@router.post("/send-verification-email")
def send_verification_email_request(request: SendVerificationEmailRequest):
    send_verification_email(request.email)

    return {
        "status": True,
        "message": "If this account exists, verification instructions have been sent",
    }


@router.post("/verify-email")
def verify_email_request(request: VerifyEmailRequest):
    email_verified = verify_email(request.token)

    if not email_verified:
        return {"status": False, "message": "Invalid or expired verification token"}

    return {"status": True, "message": "Email verified successfully"}


@router.get("/sessions")
def get_sessions(user_data=Depends(require_auth)):
    sessions = list_user_sessions(user_data["user_id"])

    return {"status": True, "message": "Sessions fetched", "data": sessions}


@router.delete("/sessions/{session_id}")
def revoke_session(session_id: int, user_data=Depends(require_auth)):
    revoked = revoke_user_session(user_data["user_id"], session_id)

    if not revoked:
        return {"status": False, "message": "Session not found"}

    return {"status": True, "message": "Session revoked"}


@router.get("/me")
def get_me(user_data=Depends(require_auth)):

    profile = get_user_profile(user_data["user_id"])

    if profile is None:
        return {"status": False, "message": "User not found"}

    return {"status": True, "message": "Profile fetched", "data": profile}
