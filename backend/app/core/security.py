from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta
import hashlib
import secrets


SECRET_KEY = "revora_secret_key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 30
PASSWORD_RESET_TOKEN_EXPIRE_MINUTES = 30
EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS = 24

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str):
    return pwd_context.hash(password)


def verify_password(password: str, hashed_password: str):
    return pwd_context.verify(password, hashed_password)


def create_access_token(data: dict):

    to_encode = data.copy()

    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire, "type": "access"})

    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token():
    return secrets.token_urlsafe(64)


def hash_token(token: str):
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def refresh_token_expiry():
    return datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)


def password_reset_token_expiry():
    return datetime.utcnow() + timedelta(minutes=PASSWORD_RESET_TOKEN_EXPIRE_MINUTES)


def email_verification_token_expiry():
    return datetime.utcnow() + timedelta(hours=EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS)
