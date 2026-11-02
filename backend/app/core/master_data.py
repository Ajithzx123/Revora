"""Reference data used to validate input and fill dropdowns.

Static for now. Moves to database tables (editable by admins) when the list needs
to change without a deploy.
"""
import math
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
# Approximate city-centre coordinates (latitude, longitude), used to measure how far a
# dealer is from a buyer. Straight-line distance, which is good enough for "within 50 km".
CITY_COORDS: dict[str, tuple[float, float]] = {
    "Bengaluru": (12.9716, 77.5946), "Mumbai": (19.0760, 72.8777), "Delhi": (28.6139, 77.2090),
    "Hyderabad": (17.3850, 78.4867), "Chennai": (13.0827, 80.2707), "Pune": (18.5204, 73.8567),
    "Kolkata": (22.5726, 88.3639), "Ahmedabad": (23.0225, 72.5714), "Jaipur": (26.9124, 75.7873),
    "Surat": (21.1702, 72.8311), "Lucknow": (26.8467, 80.9462), "Kochi": (9.9312, 76.2673),
    "Chandigarh": (30.7333, 76.7794), "Indore": (22.7196, 75.8577), "Nagpur": (21.1458, 79.0882),
    "Coimbatore": (11.0168, 76.9558), "Visakhapatnam": (17.6868, 83.2185), "Bhopal": (23.2599, 77.4126),
    "Patna": (25.5941, 85.1376), "Vadodara": (22.3072, 73.1812), "Gurugram": (28.4595, 77.0266),
    "Noida": (28.5355, 77.3910), "Thane": (19.2183, 72.9781), "Navi Mumbai": (19.0330, 73.0297),
}


def distance_km(city_a: str, city_b: str) -> float:
    """Straight-line distance between two known cities (0 for the same city). Unknown cities are
    treated as infinitely far so they never match by distance."""
    if city_a == city_b:
        return 0.0
    a, b = CITY_COORDS.get(city_a), CITY_COORDS.get(city_b)
    if a is None or b is None:
        return math.inf
    lat1, lon1, lat2, lon2 = map(math.radians, (*a, *b))
    h = math.sin((lat2 - lat1) / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2
    return 6371.0 * 2 * math.asin(math.sqrt(h))


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
