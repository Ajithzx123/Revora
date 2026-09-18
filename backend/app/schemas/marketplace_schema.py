from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


# --- Buy Requirements ---
class BuyRequirementCreate(BaseModel):
    make: str
    model: str
    year_min: int
    budget: int
    fuel: Optional[str] = None
    transmission: Optional[str] = None
    city: str
    notes: Optional[str] = None


class BuyRequirementResponse(BaseModel):
    id: int
    customer_id: int
    make: str
    model: str
    year_min: int
    budget: int
    fuel: Optional[str]
    transmission: Optional[str]
    city: str
    notes: Optional[str]
    status: str
    created_at: datetime
    quote_count: Optional[int] = 0


# --- Sell Listings ---
class SellListingCreate(BaseModel):
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int
    expected_price: int
    city: str
    images: Optional[List[str]] = []


class SellListingResponse(BaseModel):
    id: int
    customer_id: int
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int
    expected_price: int
    city: str
    images: List[str]
    status: str
    created_at: datetime
    offer_count: Optional[int] = 0


# --- Inventory ---
class CarInventoryCreate(BaseModel):
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int
    price: int
    images: Optional[List[str]] = []


class CarInventoryResponse(BaseModel):
    id: int
    dealer_id: int
    make: str
    model: str
    year: int
    fuel: str
    transmission: str
    km: int
    price: int
    images: List[str]
    status: str
    created_at: datetime


# --- Quotes ---
class DealerQuoteCreate(BaseModel):
    requirement_id: int
    car_inventory_id: Optional[int] = None
    quoted_price: int
    message: Optional[str] = None


class DealerQuoteResponse(BaseModel):
    id: int
    dealer_id: int
    dealer_name: Optional[str] = None
    dealer_rating: Optional[float] = None
    requirement_id: int
    car_inventory_id: Optional[int]
    quoted_price: int
    message: Optional[str]
    status: str
    created_at: datetime


# --- Purchase Offers ---
class DealerOfferCreate(BaseModel):
    sell_listing_id: int
    offered_price: int
    message: Optional[str] = None


class DealerOfferResponse(BaseModel):
    id: int
    dealer_id: int
    dealer_name: Optional[str] = None
    dealer_rating: Optional[float] = None
    sell_listing_id: int
    offered_price: int
    message: Optional[str]
    status: str
    created_at: datetime
