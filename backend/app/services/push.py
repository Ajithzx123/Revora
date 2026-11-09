"""Push channel adapters. The notification service only knows the `PushSender` interface."""
import logging
from typing import Optional, Protocol

from backend.app.core.config import settings

log = logging.getLogger("revora.push")


class PushSender(Protocol):
    def send(self, token: str, title: str, body: str, data: dict[str, str]) -> None:
        """Send one push. Raise on failure so the caller can retry."""


class LogPushSender:
    """Dev/test sender: records that a push would go out. Never logs the full device token."""

    def send(self, token: str, title: str, body: str, data: dict[str, str]) -> None:
        log.info("push (not sent, no FCM credentials) to ...%s: %s", token[-6:], title)


class FcmPushSender:
    """Firebase Cloud Messaging through the optional `firebase-admin` package."""

    def __init__(self, credentials_file: str):
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            firebase_admin.initialize_app(credentials.Certificate(credentials_file))

    def send(self, token: str, title: str, body: str, data: dict[str, str]) -> None:
        from firebase_admin import messaging

        messaging.send(
            messaging.Message(
                token=token,
                notification=messaging.Notification(title=title, body=body),
                data=data,
            )
        )


_sender: Optional[PushSender] = None


def get_sender() -> PushSender:
    global _sender
    if _sender is None:
        if settings.FCM_CREDENTIALS_FILE:
            _sender = FcmPushSender(settings.FCM_CREDENTIALS_FILE)
        else:
            _sender = LogPushSender()
    return _sender


def set_sender(sender: Optional[PushSender]) -> None:
    """Tests install a fake sender here; passing None restores the default."""
    global _sender
    _sender = sender
