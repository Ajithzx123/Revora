# Revora — Product Plan, Part 2: Journeys, State Machines, Matching, Business Rules, Notifications

Planning only. Nothing here exists in code yet unless Part 1 says so.

---

## Deliverable 4 — User journeys

### A. Customer buying (happy path)
1. Sign up (phone OTP / email) → pick city.
2. "Buy a car" → 3-step form (see Deliverable 5) → review → post.
3. System matches dealers (capped) → customer sees "12 dealers notified".
4. Quotes arrive (sealed: competitors can't see each other). Customer sees count + timer.
5. Compare: total on-road cost, availability type (in stock / sourced), validity, DealScore.
6. Shortlist 2–3 → chat/counteroffer → book test drive → accept one quote.
7. Accepting locks the price (Price Lock), closes other quotes as "Not selected", notifies dealers.
8. Booking → inspection (optional) → payment record → delivery → completed → rate dealer.

### B. Customer selling
1. "Sell my car" → registration no., details, condition, disclosures, photos → post.
2. Matched dealers see a seller card (contact hidden).
3. Dealers send initial offers (valid N hours). Seller compares.
4. Seller accepts an offer for inspection → dealer inspects → final offer (same or revised, reason required).
5. Seller accepts final → documents checklist → payment → ownership transfer tracking → completed.
6. If final offer is lower than initial by more than a threshold, seller may decline with no penalty and the next best initial offer is re-opened for 24h.

### C. Dealer
1. Apply → upload documents → pending → approved (or rejected with reasons, resubmit).
2. Add inventory (photos, price, min price).
3. Dashboard shows new matches sorted by match score and urgency, with response deadline.
4. Buy lead: pick inventory car (exact/alternative) or "sourced" → quote builder → submit.
5. Sell lead: procurement calculator → offer → schedule inspection → final offer.
6. Track accepted deals through test drive, booking, delivery, transfer.

### D. Admin
Review dealer applications; monitor funnel and liquidity; moderate listings; handle flagged activity; run disputes; every intervention writes an audit event; admins never edit a quote/offer price (they can only void with a reason).

---

## Edge-case catalogue (condensed)
Format: Condition → Action → System behaviour → State change → Notify → Admin → Acceptance.

### Buying
| # | Scenario | Behaviour | State | Notify | Acceptance |
|---|---|---|---|---|---|
| B1 | No dealer responds in 48h | Widen radius once, rematch next-tier dealers, then offer "extend / edit budget / concierge" | Request stays OPEN, `rematch_count++` | Customer: tips; dealers: new matches | Rematch runs once; customer sees reason and options |
| B2 | Only one quote | Show it, label "1 of N notified responded", suggest widening | none | Customer | Banner shown; comparison view works with one quote |
| B3 | Dealer submits alternative model | Quote flagged `ALTERNATIVE`; shown separately from exact matches | Quote SUBMITTED | Customer | Exact and alternative are visually separate |
| B4 | Dealer has no stock | May submit `SOURCED` quote with delivery ETA; clearly labelled | Quote SUBMITTED | Customer | Label visible; sourced quotes never rank above in-stock by default |
| B5 | Dealer withdraws quote | Allowed before acceptance; reason required | Quote WITHDRAWN | Customer | Withdraw after ACCEPTED is refused (must use cancel/dispute) |
| B6 | Car sold before customer accepts | Inventory reserve check on submit and on accept | Quote → UNAVAILABLE | Customer + dealer | Accept fails with clear message; dealer warned for repeated cases |
| B7 | Customer accepts two quotes at once | Accept is a single transaction; only one request-level acceptance allowed | second call returns 409 | Customer | Concurrency test passes |
| B8 | Two staff submit conflicting quotes | One active quote per dealer per request; others become revisions | Revision n+1 | Dealer | Unique constraint (dealer_id, requirement_id) |
| B9 | Customer changes budget/model | Material change (make/model/budget ±20%) → existing quotes marked `REQUOTE_REQUESTED`; minor change keeps quotes | Request EDITED | Dealers with quotes | Audit entry with before/after |
| B10 | Customer cancels | Open quotes → CLOSED_BY_CUSTOMER | Request CANCELLED | Dealers | No new quotes accepted |
| B11 | Loan rejected after acceptance | Customer marks reason; deal → CANCELLED (no-fault category) | Booking CANCELLED | Dealer | Reliability not penalised |
| B12 | Inspection shows damage | Customer can renegotiate or cancel; dealer must document | Inspection FAILED/DISPUTED | both | Evidence photos required |
| B13 | Dealer refuses delivery | Customer files dispute | Transaction DISPUTED | Admin | Dealer cancellation count++ |
| B14 | Irrelevant quotes | "Not relevant" button, reason; feeds dealer quality metric | Quote HIDDEN | Dealer (aggregate only) | Hidden quotes don't count in comparison |
| B15 | Request expires | Default 14 days; reminder at day 10; "Repost" copies fields | EXPIRED | Customer | Repost creates new request linked to old |

### Selling
| # | Scenario | Behaviour | Acceptance |
|---|---|---|---|
| S1 | Seller enters wrong km | Mandatory odometer photo; inspection records actual km; large mismatch → re-offer allowed with reason | Re-offer shows both values |
| S2 | Seller not registered owner | Ask relationship + owner consent; flag; admin review before dealers see contact | Listing gated until resolved |
| S3 | Pending loan | Declared at listing; offer shows "loan settlement required"; checklist step added | Checklist contains NOC/foreclosure |
| S4 | Challans outstanding | Declared or detected; deducted in procurement calc as seller liability | Final offer line item |
| S5 | No offers | Rematch wider; suggest price band (FairPrice later) | Seller sees guidance |
| S6 | Top dealer withdraws | Next best active offer promoted; seller notified | Withdrawn offer never shows as active |
| S7 | Price drop after inspection | Needs reason + evidence; seller may decline free | Audit event; decline returns listing to OPEN |
| S8 | Seller rejects all | Listing stays open or closes; dealers told "not selected" | No personal data leaked |
| S9 | Seller sells externally | One-tap "sold elsewhere"; asks (optional) price for FairPrice data | Offers closed |
| S10 | Seller fails to transfer | Reminders → dispute path; dealer protected after N days | Timeline visible |
| S11 | Vehicle blacklisted/stolen | Admin freeze, evidence kept, dealer alert, legal review | Listing FROZEN |

### Dealer / platform
- Verification expires → status `RESTRICTED`: can finish accepted deals, cannot quote; 7-day warning notifications.
- Suspended dealer → active quotes `VOID_ADMIN`, accepted deals continue under admin watch, reason shown to dealer.
- Duplicate inventory → block on registration number or VIN match; warn on near-duplicate.
- Suspicious bidding (identical prices across "different" dealers, repeated withdraw-and-resubmit, quoting far below cost then revising up) → flag, not auto-ban.
- Notification failure → retry with backoff (3 attempts), fall back to next channel, always keep in-app record.
- Upload failure → resumable, client-side compression, retry; draft saved.
- Duplicate payment callback → idempotency key; second callback ignored and logged.
- Admin suspends wrongly → reactivation restores quotes only if still valid; audit shows who/why.
- Unresolved dispute → SLA timers (48h first response, 7d resolution target), escalation to senior admin.

---

## Deliverable 6 (part) — State machines
Each entity has its **own** status column and transition table. Sensitive transitions write an `audit_event`.

**Buy request**: DRAFT → OPEN → (PAUSED ⇄ OPEN) → QUOTE_ACCEPTED → IN_TRANSACTION → COMPLETED. Also OPEN → EXPIRED, OPEN/PAUSED → CANCELLED. Disallowed: COMPLETED/CANCELLED/EXPIRED → anything except "repost" (creates new row).

**Sell listing**: DRAFT → UNDER_REVIEW (only if admin-gated) → OPEN → OFFER_ACCEPTED → INSPECTION → FINAL_ACCEPTED → TRANSFER_PENDING → SOLD. OPEN → EXPIRED/CLOSED/FROZEN.

**Quote**: DRAFT → SUBMITTED → (REVISED → SUBMITTED) → ACCEPTED | REJECTED | NOT_SELECTED | WITHDRAWN | EXPIRED | UNAVAILABLE | VOID_ADMIN. Terminal: all except SUBMITTED/REVISED. Only one non-terminal quote per (dealer, request).

**Purchase offer**: DRAFT → INITIAL_SUBMITTED → INSPECTION_SCHEDULED → INSPECTED → FINAL_SUBMITTED → ACCEPTED → COMPLETED. Side exits: WITHDRAWN, REJECTED, EXPIRED, NOT_SELECTED, VOID_ADMIN.

**Negotiation (thread on a quote/offer)**: OPEN → COUNTER_BY_CUSTOMER ⇄ COUNTER_BY_DEALER → AGREED | DECLINED | EXPIRED. Max 5 rounds (configurable). Each round has price, note, `valid_until`.

**Inspection**: REQUESTED → SCHEDULED → (RESCHEDULED) → IN_PROGRESS → COMPLETED(passed/issues) | NO_SHOW | CANCELLED.

**Test drive**: REQUESTED → CONFIRMED → COMPLETED | NO_SHOW_CUSTOMER | NO_SHOW_DEALER | CANCELLED | RESCHEDULED.

**Booking**: PENDING → CONFIRMED → CANCELLED | CONVERTED_TO_TRANSACTION.

**Transaction**: CREATED → DOCUMENTS_PENDING → PAYMENT_PENDING → PAYMENT_CONFIRMED → DELIVERY/HANDOVER → TRANSFER_PENDING → COMPLETED. Exits: CANCELLED, DISPUTED (can return to previous state when resolved).

**Payment** (record-only in MVP; gateway later): INITIATED → PENDING → SUCCEEDED | FAILED | REFUNDED(partial/full). Idempotency key on every callback.

**Ownership transfer**: NOT_STARTED → DOCS_COLLECTED → SUBMITTED → COMPLETED | BLOCKED(reason).

**Dispute**: OPEN → UNDER_REVIEW → AWAITING_PARTY → RESOLVED(outcome) → CLOSED; REOPENED once.

**Concurrency rules**
- `accept` runs in one DB transaction with `SELECT … FOR UPDATE` on the request/listing row and checks `status = OPEN` and `quote.status = SUBMITTED`.
- Expiry job and accept must not race: accept re-checks `valid_until > now()`.
- Idempotent endpoints use a client `Idempotency-Key`.

---

## Deliverable 13 — Matching logic

### Hard requirements (must pass, else dealer not eligible)
Make and model (or any model within chosen body type if "flexible"); budget (inventory price ≤ budget × 1.05 tolerance); transmission if marked strict; fuel if strict; min year; max km if set; dealer verified and ACTIVE; dealer city within radius (or in "delivers to" list); dealer not RESTRICTED.

### Soft preferences (score only)
Variant, colour, owners, service history, insurance validity, certification, features.

### Score (0–100, transparent)
| Factor | Weight |
|---|---|
| Exact make/model/variant | 30 |
| Price vs budget (closer to ≤ budget scores higher; under-budget gets full) | 20 |
| Year / km fit | 10 |
| Distance | 10 |
| Soft preference hits | 10 |
| Dealer responsiveness (median response, min sample 5 else neutral) | 10 |
| Inventory freshness (in stock now) | 10 |

### Distribution rules
- Tier 1: in-stock exact matches, top 8 by score. Tier 2: in-stock alternatives, up to 4. Tier 3 ("sourcing"): specialists in that make who opted in, up to 3, released after 12h if fewer than 3 quotes.
- Cap: **max 15 dealers per request**; a dealer receives max N new leads/day (configurable) to avoid fatigue.
- Skip dealers inactive 14+ days, or whose response rate < 10% (with min sample).
- Never rematch the same dealer for the same request (unique `(request_id, dealer_id)` in `match_record`).
- Urgent requests (≤ 7 days) get Tier 1+2 at once and a shorter response deadline (24h vs 72h).
- Out-of-city dealers participate if they enable "deliver to city" and a delivery charge is stated in the quote.
- No match → request stays open, admin liquidity dashboard flags city+segment, customer offered widen/edit options.
- Fairness: new dealers get a neutral responsiveness score and a small exploration boost for their first 20 matches; subscriptions never change the score.
- **Phase 1 is pure SQL filtering + the scoring function above. No ML.**

Sell-side matching: verified dealers who buy that make (declared preference), within radius, within vehicle age/km bands, max 10 per listing.

---

## Deliverable 6 — Business rules catalogue

**Quotations**
- Requires: vehicle (inventory id or sourced description), vehicle price, itemised charges (registration, insurance, delivery, other), warranty text, delivery days, validity (default 72h, max 7d), availability type (IN_STOCK, SOURCED, ALTERNATIVE).
- Price revision allowed only while SUBMITTED, creates a revision row; a price **increase** after the customer has shortlisted requires customer re-confirmation.
- One active quote per dealer per request.
- Inventory car must be AVAILABLE and not RESERVED by another accepted deal at submit time.
- Dealer cannot quote below the inventory `min_price` without a warning (internal only).

**Purchase offers**: initial offer valid 48h; final offer after inspection must cite a reason code and evidence if lower than initial by > 5%; seller may decline free after a downward revision.

**Negotiation**: max 5 rounds; each counter needs price + validity; all rounds immutable and visible to both parties.

**Bidding**: default **sealed** for both buy and sell. Dealers never see competitors' prices or count of quotes (only "Quotes received: n" after submitting their own is optional, off by default). Negotiation mode starts only after the customer shortlists a dealer, and is one-to-one. Anti-manipulation: rate-limit revisions (3 per quote), flag same-device/same-IP dealer accounts, flag quote-then-withdraw patterns.

**Acceptance**: atomic; sets other quotes to NOT_SELECTED; creates a Booking draft; starts Price Lock (default 7 days); notifies all parties.

**Expiry**: quotes at `valid_until`; requests at 14 days; offers at 48h; test drive requests unanswered after 24h; unpaid booking after configured window. A scheduled job runs every 5 minutes; user-facing countdowns come from server time.

**Cancellation**: before acceptance — free. After acceptance — reason code required; counts toward reliability unless reason is no-fault (loan rejected, inspection failed with evidence, vehicle sold elsewhere proven).

**Inspection**: independent partner or dealer inspection; report includes photos, odometer reading, checklist; mismatch beyond tolerance (km ±2%, undisclosed accident) allows re-offer or free cancel.

**Booking/transaction/payment**: booking amount capped (e.g. ≤ 2% or fixed), refundable rules defined per reason code; MVP records payments made outside the platform (UTR/receipt upload) — no money held by Revora until legal review.

**Disputes**: categories (price change, condition mismatch, misleading info, cancellation, refund, fraud, unauthorised payment request); evidence uploads; assignee; SLA; outcomes recorded; dealer sanction ladder (warning → restriction → suspension).

**Admin conduct**: admins can freeze, void with reason, suspend; they cannot edit prices or messages. Every action writes `audit_event(actor, action, entity, before, after, reason, ts)`.

---

## Deliverable 8 (part) — Notification system

**Architecture**: domain event → `notification_event` row → fan-out worker → channel adapters (in-app always; push; email; SMS/WhatsApp only for critical or opted-in) → `notification_delivery` log with status, attempts, dedupe key.

**Rules**
- Dedupe key = (event type, entity id, recipient, window).
- Retry: 3 attempts with exponential backoff; fall back push → in-app badge → email for critical.
- Quiet hours (22:00–08:00) for non-critical; digest for dealers (hourly lead summary).
- Preferences per category (leads, quotes, deals, marketing); critical events cannot be disabled.
- Notify only relevant parties; competitors are never told who won or at what price.
- WhatsApp/SMS require explicit consent and approved templates (compliance review).

| Event | Recipient | Channels |
|---|---|---|
| Requirement posted / matches found | Customer; matched dealers | in-app; push (dealers) |
| Quote / offer received | Customer | push + in-app |
| Counteroffer | Other party | push + in-app |
| Offer expiring (4h) | Both | push |
| Accepted | Winner (push+SMS), others "not selected" (in-app) | |
| Withdrawn | Customer | push |
| Test drive / inspection scheduled, reminder (24h, 2h) | Both | push + SMS reminder |
| Booking confirmed, payment recorded | Both | push + email receipt |
| Document pending / transfer action | Responsible party | push |
| Dispute updates | Parties + assignee | in-app + email |
| Verification approved / rejected / expiring | Dealer | email + push |
