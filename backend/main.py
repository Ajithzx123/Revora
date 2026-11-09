import asyncio
import logging
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.core.config import settings
from backend.app.database.base import create_db

from backend.app.api.auth_api import router as auth_router
from backend.app.api.requirements_api import router as requirements_router
from backend.app.api.sell_listings_api import router as sell_listings_router
from backend.app.api.dealer_api import router as dealer_router
from backend.app.api.admin_api import router as admin_router
from backend.app.api.dealer_onboarding_api import router as dealer_onboarding_router
from backend.app.api.inventory_api import router as inventory_router
from backend.app.api.quotes_api import router as quotes_router
from backend.app.api.notifications_api import router as notifications_router
from backend.app.core.master_data import as_payload as master_data_payload

app = FastAPI(
    title="Revora Marketplace API",
    description="Two-Way Car Marketplace connecting buyers, sellers, and dealers.",
    version="1.0.0",
)

# Browser origins come from CORS_ORIGINS (dev also allows any localhost port).
# Mobile apps are not subject to CORS.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=settings.CORS_ORIGIN_REGEX,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Routers
app.include_router(auth_router, prefix="/api")
app.include_router(requirements_router, prefix="/api")
app.include_router(sell_listings_router, prefix="/api")
app.include_router(dealer_router, prefix="/api")
app.include_router(dealer_onboarding_router, prefix="/api")
app.include_router(inventory_router, prefix="/api")
app.include_router(quotes_router, prefix="/api")
app.include_router(notifications_router, prefix="/api")
app.include_router(admin_router, prefix="/api")


@app.on_event("startup")
def startup():
    # Local convenience only. Staging/production schemas come from `alembic upgrade head`.
    if settings.ENVIRONMENT == "dev" and settings.DATABASE_URL.startswith("sqlite"):
        create_db()
    interval = int(os.getenv("MATCHING_INTERVAL_SECONDS", "600"))
    if interval > 0 and "PYTEST_CURRENT_TEST" not in os.environ:
        asyncio.create_task(_matching_loop(interval))
    if "PYTEST_CURRENT_TEST" not in os.environ:
        asyncio.create_task(_push_loop(int(os.getenv("PUSH_INTERVAL_SECONDS", "30"))))


async def _matching_loop(interval: int) -> None:
    """Releases sourcing-tier matches once a request has waited long enough, and picks up
    anything a trigger missed. Single instance only; move to a scheduler when scaled out."""
    from sqlmodel import Session

    from backend.app.database.session import engine
    from backend.app.services import matching_service, quote_service

    while True:
        await asyncio.sleep(interval)
        try:
            with Session(engine) as session:
                created = matching_service.rematch_open_requests(session)
                quote_service.expire_due_quotes(session)
                session.commit()
            if created:
                logging.getLogger("revora.matching").info("periodic matching created %s matches", created)
        except Exception:  # never let the loop die
            logging.getLogger("revora.matching").exception("periodic matching failed")


async def _push_loop(interval: int) -> None:
    """Sends due push notifications (and retries failed ones). Single instance only."""
    from sqlmodel import Session

    from backend.app.database.session import engine
    from backend.app.services import notification_service

    while interval > 0:
        await asyncio.sleep(interval)
        try:
            with Session(engine) as session:
                notification_service.dispatch_pending(session)
        except Exception:
            logging.getLogger("revora.push").exception("push dispatch failed")


@app.get("/api/master-data", tags=["Reference"])
def master_data():
    """Makes, models, cities and other pick-lists. Public: the sign-up forms need it."""
    return master_data_payload()


@app.get("/")
def home():
    return {
        "status": "online",
        "app": "Revora Marketplace API",
        "docs": "/docs",
    }
