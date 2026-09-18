from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.database.base import create_db

from backend.app.api.auth_api import router as auth_router
from backend.app.api.requirements_api import router as requirements_router
from backend.app.api.sell_listings_api import router as sell_listings_router
from backend.app.api.dealer_api import router as dealer_router
from backend.app.api.admin_api import router as admin_router

app = FastAPI(
    title="Revora Marketplace API",
    description="Two-Way Car Marketplace connecting buyers, sellers, and dealers.",
    version="1.0.0",
)

# Enable CORS for Flutter Web & Mobile dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Routers
app.include_router(auth_router, prefix="/api")
app.include_router(requirements_router, prefix="/api")
app.include_router(sell_listings_router, prefix="/api")
app.include_router(dealer_router, prefix="/api")
app.include_router(admin_router, prefix="/api")


@app.on_event("startup")
def startup():
    create_db()


@app.get("/")
def home():
    return {
        "status": "online",
        "app": "Revora Marketplace API",
        "docs": "/docs",
    }
