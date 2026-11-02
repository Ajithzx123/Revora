from sqlmodel import SQLModel
from backend.app.database.connection import engine
from backend.app.models.user_model import User
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import (
    Dealer,
    DealerDocument,
    Vehicle,
    VehicleMedia,
    BuyRequirement,
    MatchRecord,
    SellListing,
    DealerQuote,
    DealerOffer,
)


def create_db():
    """Dev/test convenience. Production schemas are managed by Alembic."""
    SQLModel.metadata.create_all(engine)
