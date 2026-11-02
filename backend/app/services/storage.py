"""File storage for dealer documents (private) and vehicle photos (public by unguessable id).
Local disk for now.

Files are saved under random names; clients never see or choose a path.
Swap this module for object storage (Supabase Storage) without touching callers.
"""
import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status

from backend.app.core.config import settings

# (magic bytes, extension, content type)
_SIGNATURES = (
    (b"%PDF-", ".pdf", "application/pdf"),
    (b"\xff\xd8\xff", ".jpg", "image/jpeg"),
    (b"\x89PNG\r\n\x1a\n", ".png", "image/png"),
)


def _root() -> Path:
    settings.UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    return settings.UPLOAD_DIR


async def _save(file: UploadFile, detect, accepted_message: str) -> tuple[str, str, int]:
    data = await file.read(settings.MAX_UPLOAD_BYTES + 1)
    if not data:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "The file is empty")
    if len(data) > settings.MAX_UPLOAD_BYTES:
        raise HTTPException(
            status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            f"File is larger than {settings.MAX_UPLOAD_BYTES // (1024 * 1024)} MB",
        )
    # Trust the bytes, not the client-supplied name or content type.
    found = detect(data)
    if found is None:
        raise HTTPException(status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, accepted_message)
    ext, content_type = found
    key = f"{uuid.uuid4().hex}{ext}"
    (_root() / key).write_bytes(data)
    return key, content_type, len(data)


def _detect_document(data: bytes):
    for magic, ext, content_type in _SIGNATURES:
        if data.startswith(magic):
            return ext, content_type
    return None


def _detect_image(data: bytes):
    if data.startswith(b"\xff\xd8\xff"):
        return ".jpg", "image/jpeg"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png", "image/png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return ".webp", "image/webp"
    return None


async def save_document(file: UploadFile) -> tuple[str, str, int]:
    """Validate and store a KYC document. Returns (storage_key, content_type, size_bytes)."""
    return await _save(file, _detect_document, "Only PDF, JPEG and PNG files are accepted")


async def save_image(file: UploadFile) -> tuple[str, str, int]:
    """Validate and store a vehicle photo."""
    return await _save(file, _detect_image, "Only JPEG, PNG and WebP photos are accepted")


def path_for(storage_key: str) -> Path:
    path = (_root() / storage_key).resolve()
    if path.parent != _root().resolve():  # defence in depth against path tricks
        raise HTTPException(status.HTTP_404_NOT_FOUND, "File not found")
    return path


def delete_document(storage_key: str) -> None:
    try:
        path_for(storage_key).unlink(missing_ok=True)
    except HTTPException:
        pass
