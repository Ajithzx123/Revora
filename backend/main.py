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
app.include_router(admin_router, prefix="/api")


@app.on_event("startup")
def startup():
    # Local convenience only. Staging/production schemas come from `alembic upgrade head`.
    if settings.ENVIRONMENT == "dev" and settings.DATABASE_URL.startswith("sqlite"):
        create_db()


@app.get("/")
def home():
    return {
        "status": "online",
        "app": "Revora Marketplace API",
        "docs": "/docs",
    }
