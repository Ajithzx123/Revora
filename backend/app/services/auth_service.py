from backend.app.models.user_model import User
from backend.app.models.session_model import UserSession
from backend.app.models.password_reset_model import PasswordResetToken
from backend.app.models.email_verification_model import EmailVerificationToken
from sqlmodel import Session, select
from backend.app.database.connection import engine
from datetime import datetime
from backend.app.services.email_service import (
    send_email_verification_email,
    send_password_reset_email,
)


from backend.app.core.security import (
    create_access_token,
    create_refresh_token,
    email_verification_token_expiry,
    hash_password,
    hash_token,
    password_reset_token_expiry,
    refresh_token_expiry,
    verify_password,
)


def serialize_user(user: User):
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "role": user.role,
        "email_verified": user.email_verified,
        "email_verified_at": user.email_verified_at,
    }


def create_token_pair(session: Session, user: User, device_id=None, ip_address=None, user_agent=None):
    access_token = create_access_token(
        {
            "user_id": user.id,
            "email": user.email,
            "role": user.role,
        }
    )
    refresh_token = create_refresh_token()

    user_session = UserSession(
        user_id=user.id,
        refresh_token_hash=hash_token(refresh_token),
        device_id=device_id,
        ip_address=ip_address,
        user_agent=user_agent,
        expires_at=refresh_token_expiry(),
    )

    session.add(user_session)
    session.commit()
    session.refresh(user_session)

    return {
        "access_token": access_token,
        "token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "session_id": user_session.id,
    }


def signup_user(name: str, email: str, password: str, phone: str):

    hashed_password = hash_password(password)

    new_user = User(
        name=name,
        email=email,
        password=hashed_password,
        phone=phone,
    )

    with Session(engine) as session:
        session.add(new_user)
        session.commit()
        session.refresh(new_user)
        create_email_verification(session, new_user)

    return serialize_user(new_user)


def create_email_verification(session: Session, user: User):
    previous_statement = select(EmailVerificationToken).where(
        EmailVerificationToken.user_id == user.id,
        EmailVerificationToken.used_at == None,
    )
    previous_tokens = session.exec(previous_statement).all()

    for previous_token in previous_tokens:
        previous_token.used_at = datetime.utcnow()
        session.add(previous_token)

    verification_token = create_refresh_token()
    token = EmailVerificationToken(
        user_id=user.id,
        token_hash=hash_token(verification_token),
        expires_at=email_verification_token_expiry(),
    )

    session.add(token)
    session.commit()

    send_email_verification_email(user.email, verification_token)

    return verification_token


def login_user(email: str, password: str, device_id=None, ip_address=None, user_agent=None):

    with Session(engine) as session:

        statement = select(User).where(User.email == email)

        user = session.exec(statement).first()

        if user is None:
            return None

        password_match = verify_password(password, user.password)

        if not password_match:
            return None

        tokens = create_token_pair(
            session,
            user,
            device_id=device_id,
            ip_address=ip_address,
            user_agent=user_agent,
        )

        return {
            **tokens,
            "user": serialize_user(user),
        }


def forgot_password(email: str):
    with Session(engine) as session:
        statement = select(User).where(User.email == email)
        user = session.exec(statement).first()

        if user is None:
            return True

        reset_token = create_refresh_token()
        previous_statement = select(PasswordResetToken).where(
            PasswordResetToken.user_id == user.id,
            PasswordResetToken.used_at == None,
        )
        previous_tokens = session.exec(previous_statement).all()

        for previous_token in previous_tokens:
            previous_token.used_at = datetime.utcnow()
            session.add(previous_token)

        password_reset = PasswordResetToken(
            user_id=user.id,
            token_hash=hash_token(reset_token),
            expires_at=password_reset_token_expiry(),
        )

        session.add(password_reset)
        session.commit()

        send_password_reset_email(user.email, reset_token)

        return True


def reset_password(token: str, new_password: str):
    token_hash = hash_token(token)

    with Session(engine) as session:
        statement = select(PasswordResetToken).where(
            PasswordResetToken.token_hash == token_hash
        )
        password_reset = session.exec(statement).first()

        if password_reset is None:
            return False

        if password_reset.used_at is not None:
            return False

        if password_reset.expires_at <= datetime.utcnow():
            return False

        user = session.get(User, password_reset.user_id)

        if user is None:
            return False

        user.password = hash_password(new_password)
        password_reset.used_at = datetime.utcnow()

        session.add(user)
        session.add(password_reset)
        session.commit()

        revoke_all_user_sessions(session, user.id)

        return True


def send_verification_email(email: str):
    with Session(engine) as session:
        statement = select(User).where(User.email == email)
        user = session.exec(statement).first()

        if user is None:
            return True

        if user.email_verified:
            return True

        create_email_verification(session, user)

        return True


def verify_email(token: str):
    token_hash = hash_token(token)

    with Session(engine) as session:
        statement = select(EmailVerificationToken).where(
            EmailVerificationToken.token_hash == token_hash
        )
        verification = session.exec(statement).first()

        if verification is None:
            return False

        if verification.used_at is not None:
            return False

        if verification.expires_at <= datetime.utcnow():
            return False

        user = session.get(User, verification.user_id)

        if user is None:
            return False

        user.email_verified = True
        user.email_verified_at = datetime.utcnow()
        verification.used_at = datetime.utcnow()

        session.add(user)
        session.add(verification)
        session.commit()

        return True


def refresh_user_session(refresh_token: str):
    token_hash = hash_token(refresh_token)

    with Session(engine) as session:
        statement = select(UserSession).where(UserSession.refresh_token_hash == token_hash)
        user_session = session.exec(statement).first()

        if user_session is None:
            return None

        if not user_session.is_active:
            revoke_all_user_sessions(session, user_session.user_id)
            return None

        if user_session.expires_at <= datetime.utcnow():
            user_session.is_active = False
            user_session.revoked_at = datetime.utcnow()
            session.add(user_session)
            session.commit()
            return None

        user = session.get(User, user_session.user_id)

        if user is None:
            return None

        new_refresh_token = create_refresh_token()
        user_session.refresh_token_hash = hash_token(new_refresh_token)
        user_session.last_used_at = datetime.utcnow()
        user_session.expires_at = refresh_token_expiry()

        session.add(user_session)
        session.commit()
        session.refresh(user_session)

        access_token = create_access_token(
            {
                "user_id": user.id,
                "email": user.email,
                "role": user.role,
            }
        )

        return {
            "access_token": access_token,
            "token": access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer",
            "session_id": user_session.id,
            "user": serialize_user(user),
        }


def logout_user(refresh_token: str):
    token_hash = hash_token(refresh_token)

    with Session(engine) as session:
        statement = select(UserSession).where(UserSession.refresh_token_hash == token_hash)
        user_session = session.exec(statement).first()

        if user_session is None:
            return False

        user_session.is_active = False
        user_session.revoked_at = datetime.utcnow()
        session.add(user_session)
        session.commit()

        return True


def revoke_all_user_sessions(session: Session, user_id: int):
    statement = select(UserSession).where(
        UserSession.user_id == user_id,
        UserSession.is_active == True,
    )
    user_sessions = session.exec(statement).all()

    for user_session in user_sessions:
        user_session.is_active = False
        user_session.revoked_at = datetime.utcnow()
        session.add(user_session)

    session.commit()


def logout_all_user_sessions(user_id: int):
    with Session(engine) as session:
        revoke_all_user_sessions(session, user_id)

    return True


def list_user_sessions(user_id: int):
    with Session(engine) as session:
        statement = select(UserSession).where(UserSession.user_id == user_id)
        user_sessions = session.exec(statement).all()

        return [
            {
                "id": user_session.id,
                "device_id": user_session.device_id,
                "ip_address": user_session.ip_address,
                "user_agent": user_session.user_agent,
                "is_active": user_session.is_active,
                "created_at": user_session.created_at,
                "last_used_at": user_session.last_used_at,
                "expires_at": user_session.expires_at,
                "revoked_at": user_session.revoked_at,
            }
            for user_session in user_sessions
        ]


def revoke_user_session(user_id: int, session_id: int):
    with Session(engine) as session:
        user_session = session.get(UserSession, session_id)

        if user_session is None or user_session.user_id != user_id:
            return False

        user_session.is_active = False
        user_session.revoked_at = datetime.utcnow()
        session.add(user_session)
        session.commit()

        return True


def get_user_profile(user_id: int):

    with Session(engine) as session:

        statement = select(User).where(
            User.id == user_id
        )

        user = session.exec(statement).first()

        if user is None:
            return None

        return serialize_user(user)
