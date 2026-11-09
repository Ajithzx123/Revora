"""Dealer application workflow: details -> documents -> submit -> admin decision."""
from sqlmodel import Session, select

from backend.app.database.connection import engine
from backend.app.models.audit_model import AuditEvent
from backend.tests.conftest import JPEG, PDF, REQUIREMENT

REQUIRED = ["OWNER_ID", "BUSINESS_PROOF", "ADDRESS_PROOF"]


def upload(client, h, doc_type, content=PDF, name="doc.pdf"):
    return client.post(
        "/api/dealers/me/documents",
        headers=h,
        data={"doc_type": doc_type},
        files={"file": (name, content, "application/octet-stream")},
    )


def fill_application(client, h, *, with_docs=True):
    r = client.patch("/api/dealers/me", headers=h, json={"address": "12 MG Road", "gstin": "29ABCDE1234F1Z5"})
    assert r.status_code == 200, r.text
    if with_docs:
        for t in REQUIRED:
            assert upload(client, h, t).status_code == 201


def submitted_dealer(client, actors):
    h = actors.dealer()
    fill_application(client, h)
    r = client.post("/api/dealers/me/submit", headers=h)
    assert r.status_code == 200, r.text
    return h


def audit_actions():
    with Session(engine) as s:
        return [e.action for e in s.exec(select(AuditEvent).order_by(AuditEvent.created_at)).all()]


# ---------- dealer side ----------
def test_new_application_shows_missing_documents(client, actors):
    h = actors.dealer()
    d = client.get("/api/dealers/me", headers=h).json()
    assert d["status"] == "DRAFT" and d["editable"] is True
    assert sorted(d["missing_documents"]) == sorted(REQUIRED)
    assert d["can_submit"] is False


def test_cannot_submit_without_documents_or_address(client, actors):
    h = actors.dealer()
    r = client.post("/api/dealers/me/submit", headers=h)
    assert r.status_code == 422 and "Missing required documents" in r.json()["detail"]
    for t in REQUIRED:
        upload(client, h, t)
    r = client.post("/api/dealers/me/submit", headers=h)
    assert r.status_code == 422 and "address" in r.json()["detail"].lower()


def test_full_application_can_be_submitted(client, actors):
    h = submitted_dealer(client, actors)
    d = client.get("/api/dealers/me", headers=h).json()
    assert d["status"] == "PENDING" and d["editable"] is False and d["submitted_at"]


def test_submitted_application_is_locked(client, actors):
    h = submitted_dealer(client, actors)
    assert client.patch("/api/dealers/me", headers=h, json={"city": "Pune"}).status_code == 409
    assert upload(client, h, "GST_CERTIFICATE").status_code == 409
    assert client.post("/api/dealers/me/submit", headers=h).status_code == 409


def test_newer_upload_supersedes_older(client, actors):
    h = actors.dealer()
    first = upload(client, h, "OWNER_ID").json()
    second = upload(client, h, "OWNER_ID", content=JPEG, name="id.jpg").json()
    docs = client.get("/api/dealers/me", headers=h).json()["documents"]
    assert [d["id"] for d in docs] == [second["id"]] and first["id"] != second["id"]


def test_upload_validation(client, actors):
    h = actors.dealer()
    assert upload(client, h, "OWNER_ID", content=b"MZ\x90\x00 not a document", name="evil.pdf").status_code == 415
    assert upload(client, h, "OWNER_ID", content=b"", name="empty.pdf").status_code == 422
    assert upload(client, h, "NOT_A_TYPE").status_code == 422
    assert upload(client, h, "OWNER_ID", content=PDF + b"0" * (5 * 1024 * 1024)).status_code == 413


def test_dealer_can_delete_own_document_only_while_editable(client, actors):
    h = actors.dealer()
    doc = upload(client, h, "OWNER_ID").json()
    other = actors.dealer()
    assert client.delete(f"/api/dealers/me/documents/{doc['id']}", headers=other).status_code == 404
    assert client.delete(f"/api/dealers/me/documents/{doc['id']}", headers=h).status_code == 204
    assert "OWNER_ID" in client.get("/api/dealers/me", headers=h).json()["missing_documents"]


# ---------- admin side ----------
def test_admin_queue_filters_by_status(client, actors):
    submitted_dealer(client, actors)
    actors.dealer()  # stays DRAFT
    admin = actors.admin()
    pending = client.get("/api/admin/dealers?status=PENDING", headers=admin).json()
    assert len(pending) == 1 and pending[0]["status"] == "PENDING"
    assert len(client.get("/api/admin/dealers", headers=admin).json()) == 2


def test_cannot_approve_until_documents_are_accepted(client, actors):
    h = submitted_dealer(client, actors)
    admin = actors.admin()
    r = client.post(f"/api/admin/dealers/{h.dealer_id}/approve", headers=admin)
    assert r.status_code == 409 and "Accept these documents" in r.json()["detail"]


def test_full_approval_flow_unlocks_marketplace(client, actors):
    h = submitted_dealer(client, actors)
    admin = actors.admin()
    detail = client.get(f"/api/admin/dealers/{h.dealer_id}", headers=admin).json()
    for doc in detail["documents"]:
        r = client.post(
            f"/api/admin/dealers/{h.dealer_id}/documents/{doc['id']}/review",
            headers=admin, json={"status": "ACCEPTED"},
        )
        assert r.status_code == 200
    r = client.post(f"/api/admin/dealers/{h.dealer_id}/approve", headers=admin)
    assert r.status_code == 200 and r.json()["status"] == "APPROVED"
    assert client.get("/api/leads/buy", headers=h).status_code == 200
    assert client.get("/api/me", headers=h).json()["dealer_status"] == "APPROVED"


def test_request_changes_then_resubmit(client, actors):
    h = submitted_dealer(client, actors)
    admin = actors.admin()
    assert client.post(f"/api/admin/dealers/{h.dealer_id}/request-changes", headers=admin, json={"reason": "x"}).status_code == 422  # too short
    r = client.post(f"/api/admin/dealers/{h.dealer_id}/request-changes", headers=admin, json={"reason": "Address proof is blurry"})
    assert r.status_code == 200 and r.json()["status"] == "NEEDS_CHANGES"
    d = client.get("/api/dealers/me", headers=h).json()
    assert d["status_reason"] == "Address proof is blurry" and d["editable"] is True
    assert upload(client, h, "ADDRESS_PROOF", content=JPEG, name="addr.jpg").status_code == 201
    assert client.post("/api/dealers/me/submit", headers=h).json()["status"] == "PENDING"


def test_reject_requires_reason_and_is_final(client, actors):
    h = submitted_dealer(client, actors)
    admin = actors.admin()
    assert client.post(f"/api/admin/dealers/{h.dealer_id}/reject", headers=admin, json={}).status_code == 422
    r = client.post(f"/api/admin/dealers/{h.dealer_id}/reject", headers=admin, json={"reason": "Documents look forged"})
    assert r.json()["status"] == "REJECTED"
    assert client.post(f"/api/admin/dealers/{h.dealer_id}/approve", headers=admin).status_code == 409
    assert client.post("/api/dealers/me/submit", headers=h).status_code == 409
    assert client.get("/api/leads/buy", headers=h).status_code == 403


def test_suspend_and_reactivate(client, actors):
    h = actors.dealer(approved=True)
    admin = actors.admin()
    assert client.post(f"/api/admin/dealers/{h.dealer_id}/suspend", headers=admin, json={"reason": "Customer fraud report"}).json()["status"] == "SUSPENDED"
    assert client.get("/api/leads/buy", headers=h).status_code == 403
    assert client.post(f"/api/admin/dealers/{h.dealer_id}/reactivate", headers=admin).json()["status"] == "APPROVED"
    assert client.get("/api/leads/buy", headers=h).status_code == 200


def test_invalid_transitions_are_rejected(client, actors):
    h = actors.dealer()  # DRAFT
    admin = actors.admin()
    assert client.post(f"/api/admin/dealers/{h.dealer_id}/approve", headers=admin).status_code == 409
    assert client.post(f"/api/admin/dealers/{h.dealer_id}/suspend", headers=admin, json={"reason": "no reason"}).status_code == 409
    assert client.post(f"/api/admin/dealers/{h.dealer_id}/reactivate", headers=admin).status_code == 409


def test_document_download_is_admin_only_and_audited(client, actors):
    h = submitted_dealer(client, actors)
    admin = actors.admin()
    doc = client.get(f"/api/dealers/me", headers=h).json()["documents"][0]
    url = f"/api/admin/dealers/{h.dealer_id}/documents/{doc['id']}/file"
    assert client.get(url, headers=h).status_code == 403
    assert client.get(url, headers=actors.customer()).status_code == 403
    r = client.get(url, headers=admin)
    assert r.status_code == 200 and r.content.startswith(b"%PDF")
    assert "DOCUMENT_VIEWED" in audit_actions()


def test_every_decision_is_audited(client, actors):
    h = submitted_dealer(client, actors)
    admin = actors.admin()
    client.post(f"/api/admin/dealers/{h.dealer_id}/request-changes", headers=admin, json={"reason": "Need clearer ID"})
    assert audit_actions() == [
        "DEALER_APPLICATION_STARTED", "DEALER_PENDING", "DEALER_NEEDS_CHANGES",
    ]


def test_document_review_rules(client, actors):
    h = submitted_dealer(client, actors)
    admin = actors.admin()
    doc = client.get(f"/api/admin/dealers/{h.dealer_id}", headers=admin).json()["documents"][0]
    url = f"/api/admin/dealers/{h.dealer_id}/documents/{doc['id']}/review"
    assert client.post(url, headers=admin, json={"status": "REJECTED"}).status_code == 422  # note required
    assert client.post(url, headers=admin, json={"status": "PENDING"}).status_code == 422
    assert client.post(url, headers=h, json={"status": "ACCEPTED"}).status_code == 403
    assert client.post(url, headers=admin, json={"status": "REJECTED", "note": "Unreadable"}).status_code == 200


def test_dealer_cannot_see_another_dealers_documents(client, actors):
    a = submitted_dealer(client, actors)
    b = actors.dealer()
    assert client.get("/api/dealers/me", headers=b).json()["documents"] == []
    doc = client.get("/api/dealers/me", headers=a).json()["documents"][0]
    assert client.delete(f"/api/dealers/me/documents/{doc['id']}", headers=b).status_code == 404
