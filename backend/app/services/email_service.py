def send_password_reset_email(email: str, reset_token: str):
    reset_link = f"/reset-password?token={reset_token}"
    print(f"Password reset email for {email}: {reset_link}")


def send_email_verification_email(email: str, verification_token: str):
    verification_link = f"/verify-email?token={verification_token}"
    print(f"Email verification email for {email}: {verification_link}")
