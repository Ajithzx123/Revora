"""A dealer's stock: vehicles and their photos."""
import uuid
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from fastapi.responses import FileResponse
from sqlmodel import Session, select

from backend.app.core import master_data as md
from backend.app.core.dependencies import current_user_id, get_dealer_profile, require_dealer
from backend.app.database.session import get_session
from backend.app.models.audit_model import AuditEvent
from backend.app.models.marketplace_models import (
    Dealer,
    DealerQuote,
    DealerStatus,
    Vehicle,
    VehicleMedia,
    VehicleStatus,
)
from backend.app.schemas.vehicle_schema import (
    MediaOrder,
    MediaResponse,
    VehicleCreate,
    VehicleResponse,
    VehicleUpdate,
)
from backend.app.services import matching_service, storage

router = APIRouter(tags=["Inventory"])

MAX_PHOTOS = 8
LIVE_QUOTE_STATUSES = ("PENDING", "REQUOTE_REQUESTED")


def media_url(media_id: uuid.UUID) -> str:
    return f"/api/media/{media_id}"


def _media(session: Session, vehicle_id: uuid.UUID) -> list[VehicleMedia]:
    return list(
        session.exec(
            select(VehicleMedia)
            .where(VehicleMedia.vehicle_id == vehicle_id)
            .order_by(VehicleMedia.position, VehicleMedia.created_at)
        ).all()
    )


def to_response(session: Session, vehicle: Vehicle) -> VehicleResponse:
    session.refresh(vehicle)  # a commit expires the instance; reload before serialising
    return VehicleResponse(
        **vehicle.model_dump(exclude={"updated_at"}),
        images=[
            MediaResponse(id=m.id, url=media_url(m.id), position=i)
            for i, m in enumerate(_media(session, vehicle.id))
        ],
    )


def _own_vehicle(session: Session, vehicle_id: uuid.UUID, dealer: Dealer) -> Vehicle:
    vehicle = session.get(Vehicle, vehicle_id)
    if vehicle is None or vehicle.dealer_id != dealer.id:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return vehicle


def _ensure_registration_free(session: Session, registration_no: str, ignore_id: Optional[uuid.UUID] = None):
    existing = session.exec(select(Vehicle).where(Vehicle.registration_no == registration_no)).first()
    if existing is not None and existing.id != ignore_id:
        raise HTTPException(
            status_code=409,
            detail="A vehicle with this registration number is already listed.",
        )


@router.post("/inventory", response_model=VehicleResponse, status_code=201)
def add_vehicle(
    data: VehicleCreate,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    _ensure_registration_free(session, data.registration_no)
    vehicle = Vehicle(dealer_id=dealer.id, **data.model_dump())
    session.add(vehicle)
    session.flush()
    session.add(
        AuditEvent(
            actor_user_id=dealer.user_id,
            action="VEHICLE_ADDED",
            entity_type="vehicle",
            entity_id=str(vehicle.id),
        )
    )
    if dealer.status == DealerStatus.APPROVED:
        matching_service.rematch_open_requests(session, vehicle.make)  # new stock may suit waiting buyers
    session.commit()
    session.refresh(vehicle)
    return to_response(session, vehicle)


@router.get("/inventory", response_model=List[VehicleResponse])
def list_my_vehicles(
    status: Optional[VehicleStatus] = Query(default=None),
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    query = select(Vehicle).where(Vehicle.dealer_id == dealer.id).order_by(Vehicle.created_at.desc())
    if status is not None:
        query = query.where(Vehicle.status == status)
    return [to_response(session, v) for v in session.exec(query).all()]


@router.get("/inventory/{vehicle_id}", response_model=VehicleResponse)
def get_vehicle(
    vehicle_id: uuid.UUID,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    return to_response(session, _own_vehicle(session, vehicle_id, dealer))


@router.patch("/inventory/{vehicle_id}", response_model=VehicleResponse)
def update_vehicle(
    vehicle_id: uuid.UUID,
    data: VehicleUpdate,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    vehicle = _own_vehicle(session, vehicle_id, dealer)
    changes = data.model_dump(exclude_unset=True)

    for required in ("registration_no", "make", "model", "year", "fuel", "transmission", "km", "price", "owners"):
        if required in changes and changes[required] is None:
            raise HTTPException(status_code=422, detail=f"{required} cannot be empty")
    if "registration_no" in changes:
        _ensure_registration_free(session, changes["registration_no"], ignore_id=vehicle.id)

    merged_make = changes.get("make", vehicle.make)
    merged_model = changes.get("model", vehicle.model)
    if merged_model not in md.MAKES_AND_MODELS.get(merged_make, []):
        raise HTTPException(status_code=422, detail=f"{merged_model} is not a known {merged_make} model")
    merged_price = changes.get("price", vehicle.price)
    merged_min = changes.get("min_price", vehicle.min_price)
    if merged_min is not None and merged_min > merged_price:
        raise HTTPException(status_code=422, detail="min_price cannot be above the asking price")

    old_status = vehicle.status
    for key, value in changes.items():
        setattr(vehicle, key, value)
    vehicle.updated_at = datetime.utcnow()
    session.add(vehicle)

    if vehicle.status == VehicleStatus.SOLD and old_status != VehicleStatus.SOLD:
        # Sold elsewhere: every live quote on this car is now wrong, so buyers must not accept it.
        for quote in session.exec(select(DealerQuote).where(DealerQuote.vehicle_id == vehicle.id)).all():
            if quote.status in LIVE_QUOTE_STATUSES:
                quote.status = "UNAVAILABLE"
                session.add(quote)
        session.add(
            AuditEvent(
                actor_user_id=dealer.user_id,
                action="VEHICLE_SOLD",
                entity_type="vehicle",
                entity_id=str(vehicle.id),
            )
        )
    if dealer.status == DealerStatus.APPROVED and vehicle.status == VehicleStatus.AVAILABLE:
        matching_service.rematch_open_requests(session, vehicle.make)
    session.commit()
    session.refresh(vehicle)
    return to_response(session, vehicle)


@router.delete("/inventory/{vehicle_id}", status_code=204)
def delete_vehicle(
    vehicle_id: uuid.UUID,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    vehicle = _own_vehicle(session, vehicle_id, dealer)
    if session.exec(select(DealerQuote).where(DealerQuote.vehicle_id == vehicle.id)).first() is not None:
        raise HTTPException(
            status_code=409,
            detail="This vehicle is attached to quotes. Mark it as sold instead of deleting it.",
        )
    for media in _media(session, vehicle.id):
        storage.delete_document(media.storage_key)
        session.delete(media)
    session.delete(vehicle)
    session.add(
        AuditEvent(
            actor_user_id=dealer.user_id,
            action="VEHICLE_DELETED",
            entity_type="vehicle",
            entity_id=str(vehicle_id),
        )
    )
    session.commit()


# ---------- photos ----------
@router.post("/inventory/{vehicle_id}/media", response_model=VehicleResponse, status_code=201)
async def add_photo(
    vehicle_id: uuid.UUID,
    file: UploadFile = File(...),
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    vehicle = _own_vehicle(session, vehicle_id, dealer)
    existing = _media(session, vehicle.id)
    if len(existing) >= MAX_PHOTOS:
        raise HTTPException(status_code=409, detail=f"A vehicle can have at most {MAX_PHOTOS} photos")
    key, content_type, size = await storage.save_image(file)
    session.add(
        VehicleMedia(
            vehicle_id=vehicle.id,
            storage_key=key,
            content_type=content_type,
            size_bytes=size,
            position=len(existing),
        )
    )
    session.commit()
    return to_response(session, vehicle)


@router.delete("/inventory/{vehicle_id}/media/{media_id}", response_model=VehicleResponse)
def remove_photo(
    vehicle_id: uuid.UUID,
    media_id: uuid.UUID,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    vehicle = _own_vehicle(session, vehicle_id, dealer)
    media = session.get(VehicleMedia, media_id)
    if media is None or media.vehicle_id != vehicle.id:
        raise HTTPException(status_code=404, detail="Photo not found")
    storage.delete_document(media.storage_key)
    session.delete(media)
    session.flush()
    for position, remaining in enumerate(_media(session, vehicle.id)):
        remaining.position = position
        session.add(remaining)
    session.commit()
    return to_response(session, vehicle)


@router.put("/inventory/{vehicle_id}/media/order", response_model=VehicleResponse)
def reorder_photos(
    vehicle_id: uuid.UUID,
    order: MediaOrder,
    dealer: Dealer = Depends(get_dealer_profile),
    session: Session = Depends(get_session),
):
    vehicle = _own_vehicle(session, vehicle_id, dealer)
    current = {m.id: m for m in _media(session, vehicle.id)}
    if set(order.ids) != set(current) or len(order.ids) != len(current):
        raise HTTPException(status_code=422, detail="The list must contain every photo of this vehicle exactly once")
    for position, media_id in enumerate(order.ids):
        current[media_id].position = position  # the first id becomes the cover
        session.add(current[media_id])
    session.commit()
    return to_response(session, vehicle)


@router.get("/media/{media_id}", include_in_schema=True)
def serve_photo(media_id: uuid.UUID, session: Session = Depends(get_session)):
    """Vehicle photos are public (they are shown to buyers) but only reachable by their random id."""
    media = session.get(VehicleMedia, media_id)
    if media is None:
        raise HTTPException(status_code=404, detail="Photo not found")
    path = storage.path_for(media.storage_key)
    if not path.exists():
        raise HTTPException(status_code=404, detail="Photo not found")
    return FileResponse(
        path,
        media_type=media.content_type,
        headers={"Cache-Control": "public, max-age=86400, immutable"},
    )
