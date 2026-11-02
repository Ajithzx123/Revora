"""Reference data used to validate input and fill dropdowns.

Static for now. Moves to database tables (editable by admins) when the list needs
to change without a deploy.
"""
import re

MAKES_AND_MODELS: dict[str, list[str]] = {
    "Maruti Suzuki": ["Alto K10", "Swift", "Baleno", "Dzire", "WagonR", "Celerio", "Brezza", "Ertiga", "Fronx", "Grand Vitara", "S-Presso"],
    "Hyundai": ["i10 Nios", "i20", "Aura", "Venue", "Exter", "Creta", "Verna", "Alcazar"],
    "Tata": ["Tiago", "Tigor", "Altroz", "Punch", "Nexon", "Harrier", "Safari"],
    "Mahindra": ["Bolero", "XUV 3XO", "Scorpio", "Thar", "XUV700"],
    "Honda": ["Amaze", "City", "Elevate"],
    "Toyota": ["Glanza", "Urban Cruiser Hyryder", "Innova Crysta", "Fortuner", "Hilux"],
    "Kia": ["Sonet", "Seltos", "Carens"],
    "Renault": ["Kwid", "Triber", "Kiger"],
    "Volkswagen": ["Polo", "Virtus", "Taigun"],
    "Skoda": ["Slavia", "Kushaq"],
    "MG": ["Comet EV", "Astor", "Hector", "ZS EV"],
    "Nissan": ["Magnite"],
    "Jeep": ["Compass"],
}

FUELS = ["Petrol", "Diesel", "CNG", "Electric", "Hybrid"]
TRANSMISSIONS = ["Manual", "Automatic"]
BODY_TYPES = ["Hatchback", "Sedan", "SUV", "MUV", "Coupe", "Convertible"]
COLORS = ["White", "Silver", "Grey", "Black", "Red", "Blue", "Brown", "Green", "Orange", "Yellow", "Beige", "Other"]
URGENCIES = ["NOW", "WITHIN_2_WEEKS", "WITHIN_60_DAYS"]
CITIES = [
    "Bengaluru", "Mumbai", "Delhi", "Hyderabad", "Chennai", "Pune", "Kolkata", "Ahmedabad",
    "Jaipur", "Surat", "Lucknow", "Kochi", "Chandigarh", "Indore", "Nagpur", "Coimbatore",
    "Visakhapatnam", "Bhopal", "Patna", "Vadodara", "Gurugram", "Noida", "Thane", "Navi Mumbai",
]
# Preferences a buyer may mark as "must have". Everything else is a soft preference.
MUST_HAVE_FIELDS = ["fuel", "transmission", "body_type", "max_km", "max_owners", "year"]

MIN_BUDGET = 100_000          # Rs 1 lakh
MAX_BUDGET = 50_000_000       # Rs 5 crore
MIN_YEAR = 2000

# KA01AB1234, MH12DE1433, DL1CAB1234 and Bharat-series 22BH1234AA
_REGISTRATION = re.compile(r"^([A-Z]{2}\d{1,2}[A-Z]{0,3}\d{4}|\d{2}BH\d{4}[A-Z]{1,2})$")


def normalize_registration(value: str) -> str:
    return re.sub(r"[\s\-]", "", value or "").upper()


def is_valid_registration(normalized: str) -> bool:
    return bool(_REGISTRATION.match(normalized))


def as_payload() -> dict:
    return {
        "makes": [{"name": make, "models": models} for make, models in MAKES_AND_MODELS.items()],
        "fuels": FUELS,
        "transmissions": TRANSMISSIONS,
        "body_types": BODY_TYPES,
        "colors": COLORS,
        "cities": CITIES,
        "urgencies": URGENCIES,
        "limits": {"min_budget": MIN_BUDGET, "max_budget": MAX_BUDGET, "min_year": MIN_YEAR},
    }
