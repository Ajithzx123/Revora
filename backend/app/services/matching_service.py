"""Decides which dealers are shown which buyer request, and why.

Plain rules, no machine learning (that comes after there is data to learn from).

Hard requirements: a dealer's car must pass ALL of these or the dealer is not matched.
  - dealer is approved and within the buyer's radius
  - the car is available, of the requested make (and model, for an exact match)
  - price is within the budget (up to 5% over is allowed, and scores lower)
  - registered in the requested year range
  - any preference the buyer marked as a must-have (fuel, gearbox, body type, km, owners)

Everything else is a soft preference: it changes the score but never excludes a dealer.

Score (0-100): model 30 + price 20 + year/km 10 + distance 10 + soft preferences 10
               + responsiveness 10 + in stock 10.

Tiers: 1 exact car in stock, 2 similar car in stock, 3 dealer who sources this make.
Limits: 15 dealers per request (8 / 4 / 3 by tier), 20 new leads per dealer per day,
one match per dealer per request, ever.
"""
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Optional

from sqlmodel import Session, func, select

from backend.app.core import master_data as md
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import (
    BuyRequirement,
    Dealer,
    DealerQuote,
    DealerStatus,
    MatchRecord,
    RequirementStatus,
    Urgency,
    Vehicle,
    VehicleStatus,
)

MAX_DEALERS_PER_REQUEST = 15
TIER_CAPS = {1: 8, 2: 4, 3: 3}
MAX_NEW_LEADS_PER_DEALER_PER_DAY = 20
BUDGET_TOLERANCE = 1.05

# Dealers who only source (no car in stock) are shown a request when nobody has the car,
# or when it has had little interest for this long.
SOURCING_DELAY = timedelta(hours=12)
MIN_QUOTES_BEFORE_SOURCING = 3

RESPONSIVENESS_MIN_SAMPLE = 5
RESPONSIVENESS_WINDOW = timedelta(days=30)


@dataclass
class Candidate:
    dealer: Dealer
    tier: int
    score: int
    vehicle: Optional[Vehicle]
    reasons: list[str] = field(default_factory=list)


# ---------------------------------------------------------------- helpers
def _lakh(amount: int) -> str:
    return f"₹{amount / 100000:.1f} L"


def must_have(req: BuyRequirement) -> set[str]:
    return {m for m in req.must_have_csv.split(",") if m}


def response_deadline(req: BuyRequirement, matched_at: datetime) -> datetime:
    """Urgent requests expect a reply within a day, the rest within three."""
    return matched_at + (timedelta(hours=24) if req.urgency == Urgency.NOW else timedelta(hours=72))


def _soft_preferences(req: BuyRequirement, car: Vehicle) -> list[tuple[str, bool]]:
    """(label, satisfied) for every preference the buyer set."""
    prefs: list[tuple[str, bool]] = []
    if req.fuel:
        prefs.append((f"{req.fuel}", car.fuel == req.fuel))
    if req.transmission:
        prefs.append((f"{req.transmission}", car.transmission == req.transmission))
    if req.body_type:
        prefs.append((f"{req.body_type}", car.body_type == req.body_type))
    if req.max_km is not None:
        prefs.append((f"under {req.max_km:,} km", car.km <= req.max_km))
    if req.max_owners is not None:
        prefs.append((f"{req.max_owners} owner{'s' if req.max_owners > 1 else ''} or fewer", car.owners <= req.max_owners))
    return prefs


def passes_hard_requirements(req: BuyRequirement, car: Vehicle) -> bool:
    if car.status != VehicleStatus.AVAILABLE or car.make != req.make:
        return False
    if car.price > req.budget_max * BUDGET_TOLERANCE:
        return False
    if car.year < req.year_min or (req.year_max is not None and car.year > req.year_max):
        return False
    hard = must_have(req)
    for label, ok in {
        "fuel": (req.fuel, car.fuel == req.fuel),
        "transmission": (req.transmission, car.transmission == req.transmission),
        "body_type": (req.body_type, car.body_type == req.body_type),
        "max_km": (req.max_km, req.max_km is not None and car.km <= req.max_km),
        "max_owners": (req.max_owners, req.max_owners is not None and car.owners <= req.max_owners),
    }.items():
        wanted, satisfied = ok
        if label in hard and wanted is not None and not satisfied:
            return False
    return True


def _responsiveness(session: Session, dealer: Dealer, now: datetime) -> tuple[int, Optional[float]]:
    """0-10 points and the rate. A dealer with too little history gets a neutral 5, so new
    dealers are neither rewarded nor punished for having no record."""
    since = now - RESPONSIVENESS_WINDOW
    matches = session.exec(
        select(MatchRecord).where(MatchRecord.dealer_id == dealer.id, MatchRecord.created_at >= since)
    ).all()
    if len(matches) < RESPONSIVENESS_MIN_SAMPLE:
        return 5, None
    quoted = 0
    for m in matches:
        if session.exec(
            select(func.count()).select_from(DealerQuote).where(
                DealerQuote.dealer_id == dealer.id, DealerQuote.requirement_id == m.requirement_id
            )
        ).one():
            quoted += 1
    rate = quoted / len(matches)
    return round(10 * rate), rate


def _distance_points(distance: float, radius: int) -> int:
    if distance <= 0:
        return 10
    return max(0, round(10 * (1 - distance / radius)))


def _distance_reason(req: BuyRequirement, dealer: Dealer, distance: float) -> str:
    return f"In {req.city}" if dealer.city == req.city else f"{round(distance)} km away in {dealer.city}"


def score_vehicle(req: BuyRequirement, dealer: Dealer, car: Vehicle, distance: float, responsiveness: int) -> Candidate:
    exact = req.model is None or car.model == req.model
    tier = 1 if exact else 2
    reasons: list[str] = []

    points = 30 if exact else 15
    if exact:
        reasons.append(
            f"Exact match in stock: {car.year} {car.model}" if req.model is not None
            else f"{car.year} {car.model} in stock"
        )
    else:
        reasons.append(f"Similar car in stock: {car.year} {car.model}")

    if car.price <= req.budget_max:
        points += 20
        reasons.append(f"Priced {_lakh(car.price)}, within the {_lakh(req.budget_max)} budget")
    else:
        points += 10
        reasons.append(f"Priced {_lakh(car.price)}, slightly over the {_lakh(req.budget_max)} budget")

    points += 5  # registered in the requested years (a hard requirement, so always earned)
    if req.max_km is None or car.km <= req.max_km:
        points += 5
    else:
        points += 2

    points += _distance_points(distance, req.radius_km)
    reasons.append(_distance_reason(req, dealer, distance))

    prefs = _soft_preferences(req, car)
    if prefs:
        hits = [label for label, ok in prefs if ok]
        points += round(10 * len(hits) / len(prefs))
        if hits:
            reasons.append("Matches: " + ", ".join(hits))
        misses = [label for label, ok in prefs if not ok]
        if misses:
            reasons.append("Does not match: " + ", ".join(misses))
    else:
        points += 7  # nothing specific was asked for, so nothing was missed

    points += responsiveness
    points += 10  # the car is in stock right now

    return Candidate(dealer, tier, min(100, points), car, reasons)


def _sourcing_candidate(req: BuyRequirement, dealer: Dealer, distance: float, responsiveness: int) -> Candidate:
    points = 15 + 10 + _distance_points(distance, req.radius_km) + responsiveness
    return Candidate(
        dealer,
        3,
        min(100, points),
        None,
        [f"You source {req.make}", _distance_reason(req, dealer, distance), "Not in your stock: quote as a sourced car"],
    )


# ---------------------------------------------------------------- engine
def _is_live(req: BuyRequirement, now: datetime) -> bool:
    return req.status == RequirementStatus.OPEN and req.expires_at > now


def _leads_today(session: Session, dealer_id: uuid.UUID, now: datetime) -> int:
    start = datetime(now.year, now.month, now.day)
    return session.exec(
        select(func.count()).select_from(MatchRecord).where(
            MatchRecord.dealer_id == dealer_id, MatchRecord.created_at >= start
        )
    ).one()


def find_candidates(session: Session, req: BuyRequirement, now: Optional[datetime] = None) -> list[Candidate]:
    """Every dealer that could be shown this request right now (before caps), best first.
    Does not write anything."""
    now = now or datetime.utcnow()
    approved = session.exec(select(Dealer).where(Dealer.status == DealerStatus.APPROVED)).all()
    candidates: list[Candidate] = []
    for dealer in approved:
        distance = md.distance_km(dealer.city, req.city)
        if distance > req.radius_km:
            continue
        responsiveness, _ = _responsiveness(session, dealer, now)
        cars = session.exec(
            select(Vehicle).where(Vehicle.dealer_id == dealer.id, Vehicle.make == req.make)
        ).all()
        scored = [score_vehicle(req, dealer, car, distance, responsiveness) for car in cars if passes_hard_requirements(req, car)]
        if scored:
            candidates.append(min(scored, key=lambda c: (c.tier, -c.score)))
        elif req.make in dealer.sourcing_makes:
            candidates.append(_sourcing_candidate(req, dealer, distance, responsiveness))
    return sorted(candidates, key=lambda c: (c.tier, -c.score, c.dealer.business_name))


def _sourcing_released(session: Session, req: BuyRequirement, in_stock_exists: bool, now: datetime) -> bool:
    if not in_stock_exists:
        return True  # nobody has the car, so ask the dealers who can find it
    quotes = session.exec(
        select(func.count()).select_from(DealerQuote).where(DealerQuote.requirement_id == req.id)
    ).one()
    return now - req.created_at >= SOURCING_DELAY and quotes < MIN_QUOTES_BEFORE_SOURCING


def run_matching(session: Session, req: BuyRequirement, now: Optional[datetime] = None) -> list[MatchRecord]:
    """Create the missing matches for a request. Safe to call any number of times: a dealer is
    never matched twice and the caps count what already exists. Does not commit."""
    now = now or datetime.utcnow()
    if not _is_live(req, now):
        return []

    existing = session.exec(select(MatchRecord).where(MatchRecord.requirement_id == req.id)).all()
    matched_dealers = {m.dealer_id for m in existing}
    per_tier = {t: sum(1 for m in existing if m.tier == t) for t in TIER_CAPS}
    room = MAX_DEALERS_PER_REQUEST - len(existing)
    if room <= 0:
        return []

    candidates = [c for c in find_candidates(session, req, now) if c.dealer.id not in matched_dealers]
    in_stock_exists = any(m.tier in (1, 2) for m in existing) or any(c.tier in (1, 2) for c in candidates)
    allow_sourcing = _sourcing_released(session, req, in_stock_exists, now)

    created: list[MatchRecord] = []
    for cand in candidates:
        if room <= 0:
            break
        if cand.tier == 3 and not allow_sourcing:
            continue
        if per_tier[cand.tier] >= TIER_CAPS[cand.tier]:
            continue
        if _leads_today(session, cand.dealer.id, now) >= MAX_NEW_LEADS_PER_DEALER_PER_DAY:
            continue
        record = MatchRecord(
            requirement_id=req.id,
            dealer_id=cand.dealer.id,
            vehicle_id=cand.vehicle.id if cand.vehicle else None,
            tier=cand.tier,
            score=cand.score,
            reasons_csv="|".join(r.replace("|", "/") for r in cand.reasons),
            created_at=now,
        )
        session.add(record)
        session.flush()  # so the daily-cap count above sees it
        per_tier[cand.tier] += 1
        room -= 1
        created.append(record)

    if created:
        session.add(
            AuditEvent(
                actor_user_id=None,
                action="REQUIREMENT_MATCHED",
                entity_type="buy_requirement",
                entity_id=str(req.id),
                detail=f"{len(created)} new dealers (tiers: "
                + ", ".join(f"{t}={sum(1 for c in created if c.tier == t)}" for t in TIER_CAPS)
                + ")",
            )
        )
    return created


def live_requirements(session: Session, make: Optional[str] = None, now: Optional[datetime] = None) -> list[BuyRequirement]:
    now = now or datetime.utcnow()
    query = select(BuyRequirement).where(
        BuyRequirement.status == RequirementStatus.OPEN, BuyRequirement.expires_at > now
    )
    if make is not None:
        query = query.where(BuyRequirement.make == make)
    return list(session.exec(query).all())


def rematch_open_requests(session: Session, make: Optional[str] = None) -> int:
    """Re-run matching for open requests (optionally only one make). Used when stock or the set
    of approved dealers changes, and by the periodic job. Returns how many matches were created."""
    total = 0
    for req in live_requirements(session, make):
        total += len(run_matching(session, req))
    return total


def dealers_notified(session: Session, requirement_id: uuid.UUID) -> int:
    return session.exec(
        select(func.count()).select_from(MatchRecord).where(MatchRecord.requirement_id == requirement_id)
    ).one()


def liquidity(session: Session) -> list[dict]:
    """Where buyer demand outruns dealer supply, by city. For the admin."""
    now = datetime.utcnow()
    rows: dict[str, dict] = {}
    for req in live_requirements(session, now=now):
        row = rows.setdefault(req.city, {"city": req.city, "open_requests": 0, "unmatched_requests": 0, "approved_dealers": 0})
        row["open_requests"] += 1
        if dealers_notified(session, req.id) == 0:
            row["unmatched_requests"] += 1
    for dealer in session.exec(select(Dealer).where(Dealer.status == DealerStatus.APPROVED)).all():
        row = rows.setdefault(dealer.city, {"city": dealer.city, "open_requests": 0, "unmatched_requests": 0, "approved_dealers": 0})
        row["approved_dealers"] += 1
    return sorted(rows.values(), key=lambda r: (-r["unmatched_requests"], -r["open_requests"], r["city"]))
