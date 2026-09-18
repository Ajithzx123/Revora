from sqlmodel import SQLModel
from backend.app.database.connection import engine
from backend.app.models.user_model import User
from backend.app.models.session_model import UserSession
from backend.app.models.password_reset_model import PasswordResetToken
from backend.app.models.email_verification_model import EmailVerificationToken
from backend.app.models.marketplace_models import (
    Dealer,
    CarInventory,
    BuyRequirement,
    SellListing,
    DealerQuote,
    DealerOffer,
)


def create_db():
    SQLModel.metadata.create_all(engine)
