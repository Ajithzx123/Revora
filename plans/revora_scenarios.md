# Revora — Complete Scenario Book

Everything that can happen to a **customer (buyer)**, **customer (seller)**, **dealer** and **admin**, what each sees, and which notification fires. Companion to `revora_plan_2_flows_and_rules.md` (state machines and rules).

Notation: 📱 push · 🔔 in-app · ✉️ email · 💬 SMS · (WA) WhatsApp (opt-in only). **Bold** = state change.
Timings are defaults and configurable by admin.

---

## PART A — The buyer (customer buying a car)

### A1. Account and first use
| # | Scenario | What happens | Notifications |
|---|---|---|---|
| A1.1 | New user installs app | Splash → 3 onboarding cards → choose Buy/Sell → phone OTP → name, city | 💬 OTP |
| A1.2 | OTP not received | Resend after 30s (max 5/hour), fallback to email OTP | 💬/✉️ |
| A1.3 | Wrong OTP 5 times | Locked 15 min | 🔔 "Too many attempts" |
| A1.4 | Existing email account | Login by email+password or OTP | – |
| A1.5 | Different city later | Change preferred city; requests keep their own city | – |
| A1.6 | Delete account | Warns about active requests/deals; blocked while a deal is in progress; otherwise anonymises data after retention rules | ✉️ confirmation |

### A2. Posting a buy request (what the buyer enters)
Step 1 Car: make, model (or "flexible"), variant, year range, body type. Step 2 Money & place: budget min/max, fuel, transmission, city, radius, urgency (Now / 1–2 weeks / 30–60 days), finance needed?, exchange old car? Step 3 Preferences (optional, each Must/Nice): max km, owners, colour, first-owner, certified, service history, accident-free, features.
Review shows "~N dealers likely to respond".

| # | Scenario | System behaviour |
|---|---|---|
| A2.1 | Knows exact car (Hyundai i20 2021+ automatic < ₹7L, Bengaluru) | Strict make/model/transmission/budget; matched to dealers with such stock first |
| A2.2 | Only brand + budget | Model "any"; dealers with any matching model qualify; alternatives labelled |
| A2.3 | Wants an SUV in budget | Body type match; shown as many models; quotes grouped by model |
| A2.4 | Flexible on models | Chooses 2–5 models or "any in body type"; match score lower on non-preferred |
| A2.5 | Needs car immediately | Urgency=Now: in-stock only, 24h response deadline, dealers notified together 📱 |
| A2.6 | Plans in 30–60 days | Sourced quotes welcome; 72h deadline; weekly reminder |
| A2.7 | Wants EMI | Finance flag: quotes show EMI estimate if dealer supports; finance partner (later) |
| A2.8 | Certified used only | Hard filter on certified inventory |
| A2.9 | Compare many dealers | Default behaviour; up to 15 matched |
| A2.10 | Buy from another city | Radius/"anywhere in state"; quotes must include delivery charge and ETA |
| A2.11 | Exchange old car | Option "Also sell my car" → creates linked sell listing (ExchangeMatch, later phase); until then two independent journeys |
| A2.12 | Duplicate request | Warns "You already have an open request for i20"; allow or edit existing |
| A2.13 | Drops out mid-form | Draft saved; reminder after 24h 📱 |
| A2.14 | Invalid input (budget below minimum, year > this year) | Inline error, can't continue |

### A3. After posting
1. **Request OPEN**, matcher runs (seconds). Buyer sees "12 dealers notified". 🔔
2. Dealers receive 📱; buyer sees countdown to the response window.
3. Quotes arrive; each triggers 📱 "Dealer X sent a quote" (batched if > 3 in 10 min: "3 new quotes").
4. At 24h: if < 3 quotes → 🔔 "Want more quotes? Widen radius to 100 km" (one-tap rematch).
5. At day 10: 📱 "Your request expires in 4 days — extend?" Day 14: **EXPIRED** → "Repost" copies everything.

| # | Scenario | Result |
|---|---|---|
| A3.1 | No dealer responds | Auto-rematch once (wider radius, next-tier dealers); then options: edit budget, widen, concierge help (human) |
| A3.2 | Only one quote | Shown with "1 of 12 responded"; tips to widen |
| A3.3 | Irrelevant quote | "Not relevant" + reason → hidden; dealer gets aggregate quality signal only |
| A3.4 | Quote for alternative model | Tag ALTERNATIVE, shown below exact matches |
| A3.5 | Quote for car not in stock | Tag SOURCED + ETA; never ranked above in-stock by default |
| A3.6 | Identical car from 2 dealers | Compare view highlights price, warranty, distance, DealScore |
| A3.7 | Buyer changes budget/model | Material change → existing quotes **REQUOTE_REQUESTED**, dealers notified 📱; minor change keeps quotes |
| A3.8 | Pause | **PAUSED**: no new matches, quotes stay; auto-resume option |
| A3.9 | Cancel | **CANCELLED**; open quotes closed; dealers told "Request closed" 🔔 |

### A4. Reading and comparing quotes
Each quote shows: dealer (verified badge, reliability, distance), exact vs alternative vs sourced, vehicle (photos, year, km, owners, source labels), **price breakup** (vehicle, registration, insurance, delivery, extras → on-road total), negotiable?, warranty, free services, finance/EMI, delivery days, test-drive availability, **valid until** (countdown), terms.
Compare (up to 4): rows highlight lowest total, longest warranty, nearest dealer. Three tags: **Lowest price · Best value · Highest trust**, each with a "why" breakdown (DealScore).
| # | Scenario | Behaviour |
|---|---|---|
| A4.1 | Quote about to expire | 📱 4h and 1h before |
| A4.2 | Quote expired | Greyed out, "Ask for a new quote" button → dealer notified |
| A4.3 | Dealer revised price down | 📱 "Price dropped ₹20,000" |
| A4.4 | Dealer revised price up | Needs buyer re-confirmation; old price shown struck-through; 📱 |
| A4.5 | Dealer withdrew quote | 🔔 "Dealer withdrew"; removed from comparison, history kept |
| A4.6 | Vehicle sold before buyer decides | Quote → **UNAVAILABLE**; 📱 "This car is no longer available" + similar quotes |

### A5. Negotiation
Buyer taps **Counter** → price + note + validity → dealer 📱. Dealer can accept, counter, or decline. Max 5 rounds. History visible to both. Other dealers never see it.
| # | Scenario | Result |
|---|---|---|
| A5.1 | Dealer accepts counter | Quote revised to agreed price, status SUBMITTED at new price; buyer can accept |
| A5.2 | Dealer ignores counter | Expires after 24h: 🔔 both |
| A5.3 | 5 rounds exhausted | Must accept or decline last offer |
| A5.4 | Counter far below (<50%) | Blocked client-side with explanation |

### A6. Test drive and inspection
Buyer requests slot (home/dealer location) → dealer confirms → reminders 📱💬 at 24h and 2h → completed / no-show.
| # | Scenario | Result |
|---|---|---|
| A6.1 | Dealer cannot do slot | Proposes alternates 📱 |
| A6.2 | Buyer no-show | Marked; 2 no-shows → soft warning, dealers see "missed 2 test drives" |
| A6.3 | Dealer no-show | Buyer reports; dealer cancellation count++; 📱 apology + alternate dealers |
| A6.4 | Independent inspection | Booked via partner (later) or dealer inspection; report with photos, odometer, checklist |
| A6.5 | Inspection reveals damage | Buyer: renegotiate / cancel free / dispute; evidence kept |

### A7. Accepting
Buyer taps **Accept** → confirmation screen (locked total, validity, what happens next, consent) → atomic accept.
- Winner: **ACCEPTED**, Price Lock starts (7 days) 📱💬; Booking draft created.
- Others: **NOT_SELECTED** 🔔 "Customer chose another offer" (no winner info).
- Request: **QUOTE_ACCEPTED**. Buyer contact released to winner only.
| # | Scenario | Result |
|---|---|---|
| A7.1 | Tries to accept two | Second blocked: "You've already accepted a quote. Cancel it first." |
| A7.2 | Double tap / network retry | Idempotency key → single acceptance |
| A7.3 | Dealer sold car in the same second | Accept fails 409 → UNAVAILABLE flow |
| A7.4 | Quote expires during confirmation | Blocked with clear message |
| A7.5 | Changes mind within 30 min | Free "undo" if dealer hasn't started booking |

### A8. Booking, payment, delivery
Booking → token amount (payment recorded; MVP = outside platform with receipt upload) → documents checklist (ID, address proof, insurance, finance docs) → delivery/handover → ownership-transfer tracking → **COMPLETED** → rating prompt 📱 after 2 days.
| # | Scenario | Result |
|---|---|---|
| A8.1 | Loan rejected | Reason "finance rejected" → booking cancelled, no-fault, token refund per terms |
| A8.2 | Dealer changes price after acceptance | Needs reason + evidence + buyer approval; else keep locked price; if disputed → dispute |
| A8.3 | Payment fails | Retry; no state change; 📱 |
| A8.4 | Duplicate payment callback | Ignored (idempotent) |
| A8.5 | Dealer refuses delivery | Buyer files dispute; transaction **DISPUTED**; admin 🔔 |
| A8.6 | Ownership transfer delayed | Reminders to dealer; escalation after N days |
| A8.7 | Delivery to other city | Milestones: dispatched, in transit, delivered |
| A8.8 | Buyer cancels after acceptance | Reason code; may forfeit token per terms; counts on buyer's profile only as soft signal |

---

## PART B — The seller (customer selling a car)

### B1. Creating a sell listing
Steps: ① car (registration no., make/model/variant, reg year, manufacture year, fuel, transmission, colour) ② condition (km + odometer photo, owners, accident history, service history, insurance validity, loan/hypothecation, RC status, modifications, known issues) ③ photos/video (guided shots, min 5) ④ price (expected, negotiable?) + urgency + inspection preference (home inspection OK?).
Contact details never shown to dealers until acceptance.

| # | Scenario | System behaviour |
|---|---|---|
| B1.1 | Normal sale | Standard flow below |
| B1.2 | Urgent sale | "Sell in 48h": offers window 12h, dealers with pickup capability prioritised, lower price expectations shown |
| B1.3 | Wants max price | "Take 72h": longer window (up to 5 days), offers collected before comparison |
| B1.4 | Accident-damaged | Must disclose; damage photos required; routed to dealers who buy damaged cars |
| B1.5 | Mechanical issue | Disclose issue type; dealers factor in repair cost |
| B1.6 | Luxury car | Routed to premium-segment dealers; manual admin check optional |
| B1.7 | EV | Battery health fields; EV-capable dealers only |
| B1.8 | Loan outstanding | Declares bank + approx outstanding; offers show "settlement required"; checklist adds NOC/foreclosure |
| B1.9 | Insurance expired | Allowed; flagged; offer deducts/renews cost |
| B1.10 | Registered in another state | Flagged; dealers decide; checklist adds NOC/re-registration |
| B1.11 | Not the registered owner | Relationship + owner consent required; listing held for admin review |
| B1.12 | Selling several cars | Separate listings; dashboard groups them; "bulk offer" possible for dealers later |
| B1.13 | Wrong km entered | Odometer photo required; inspection verifies; mismatch → re-offer with reason |
| B1.14 | Duplicate registration number | Blocked: "This car is already listed"; if different owner → admin review |
| B1.15 | Photo upload fails | Resume/retry; draft kept |
| B1.16 | Suspected stolen/blacklisted | Admin freeze; evidence retained; legal review |

### B2. Offers
**OPEN** → matched dealers (≤10) 📱 → dealers review photos/docs, use procurement calculator → **INITIAL offers** (valid 48h). Seller 📱 per offer (batched) and sees: dealer, price, conditions (inspection required, loan settlement, pickup date), validity.
| # | Scenario | Result |
|---|---|---|
| B2.1 | No offers in 24h | Auto-rematch wider; tips (add photos, lower price); optional price guidance |
| B2.2 | Many offers | Sorted by price/trust/speed; compare view |
| B2.3 | Seller counters | Same negotiation as buyer |
| B2.4 | Highest dealer withdraws | Offer removed; 📱 seller; next best promoted |
| B2.5 | Seller changes expected price | Allowed; dealers with open offers notified; offers stay valid |
| B2.6 | Seller rejects all | Listing stays open or closes; dealers 🔔 "Not selected" |
| B2.7 | Seller takes external offer | One tap "Sold elsewhere"; closes offers; optional sale price for pricing data |
| B2.8 | Seller pauses/closes | Dealers notified listing closed |

### B3. Accept → inspection → final offer
1. Seller accepts best **initial** offer → **OFFER_ACCEPTED**; others NOT_SELECTED. Contact released to that dealer.
2. Dealer schedules inspection (home/showroom) 📱💬 reminders.
3. Inspection result recorded (photos, odometer, checks). 
4. Dealer submits **FINAL offer**: same price → straight to documents; lower → reason code + evidence required.
5. Seller: accept / counter / decline free. If > 5% drop, 📱 highlights "Final offer is ₹X lower — reason: …".
6. If declined: listing reopens; the next-best initial offer (if still valid) is offered 24h.

| # | Scenario | Result |
|---|---|---|
| B3.1 | Dealer no-show at inspection | Seller reports; reschedule or switch dealer; dealer cancellation++ |
| B3.2 | Seller no-show | Dealer may reschedule once, then release |
| B3.3 | Inspection finds undisclosed accident | Re-offer allowed with evidence; seller may decline |
| B3.4 | Dealer silent after inspection | 48h reminder → 72h auto-escalate; seller may restart |
| B3.5 | Challans pending | Deducted as seller liability in final offer; itemised |

### B4. Documents, payment, transfer
Checklist: RC, insurance, PUC, Form 29/30 (and others as applicable), ID, address, loan NOC/foreclosure, service book, keys. Each item: owner, status (Pending/Uploaded/Verified). Payment recorded by dealer, confirmed by seller (UTR/receipt). Pickup scheduled. Transfer milestones: Docs collected → Submitted → Completed (or Blocked with reason).
| # | Scenario | Result |
|---|---|---|
| B4.1 | Seller delays documents | Reminders 📱 at 2/5/7 days; then dealer may cancel no-fault |
| B4.2 | Payment disputed ("not received") | Dispute; evidence upload; admin mediates |
| B4.3 | Transfer not done by dealer | Seller reminder → escalate; sanction ladder |
| B4.4 | Seller fails to hand over | Dealer reports; dispute |
| B4.5 | Finance NOC delayed | Transaction waits in DOCUMENTS_PENDING with visible reason |

---

## PART C — The dealer

### C1. Onboarding and verification
| # | Scenario | What happens | Notifications |
|---|---|---|---|
| C1.1 | Register | Business name, owner, phone OTP, address, city, brands handled | ✉️ received |
| C1.2 | Upload documents | GST, trade/dealer certificate, ID, address proof, brand authorisation (if claimed), photos of showroom | – |
| C1.3 | Submit | **PENDING**; can browse but not quote | 🔔 admin queue |
| C1.4 | Approved | **APPROVED**; Verified badge; full access | 📱✉️ |
| C1.5 | Needs more documents | **NEEDS_CHANGES** with reasons; resubmit | 📱✉️ |
| C1.6 | Rejected | **REJECTED** with reason; may reapply after 30 days | ✉️ |
| C1.7 | Document expiring | 30/14/7 days warnings; expiry → **RESTRICTED** (finish accepted deals, no new quotes) | 📱✉️ |
| C1.8 | Suspended | **SUSPENDED**: active quotes voided, accepted deals continue under watch; reason + appeal path | 📱✉️ |
| C1.9 | Reactivation | Admin reactivates with note; quotes not auto-restored if expired | 📱 |
| C1.10 | Staff added | Owner invites by phone; role = manager / sales / purchase / inventory / accounts / read-only | 📱 invitee |
| C1.11 | Branch added | Separate address, stock, staff; leads routed by branch city | – |

### C2. Inventory
| # | Scenario | Behaviour |
|---|---|---|
| C2.1 | Add car | Reg no./VIN, make/model/variant, year, km, owners, colour, price, **min price (private)**, photos (≥5), docs, status |
| C2.2 | Duplicate reg/VIN | Blocked; if another dealer holds it → flag both, admin review |
| C2.3 | Mark Reserved | Auto when a quote on it is ACCEPTED; manual by staff |
| C2.4 | Sold offline | Mark SOLD → all open quotes on that car **UNAVAILABLE**, buyers notified |
| C2.5 | Price change | Open quotes keep their price until expiry; dealer revises quotes deliberately |
| C2.6 | Aging stock | Days-in-stock badge; 60/90 day suggestions |
| C2.7 | Bulk import (later) | CSV mapping, validation report |
| C2.8 | Upload fails | Retry, partial save |

### C3. Buyer leads and quoting
Lead card: requirement summary, **match score & why**, Exact/Alternative, distance, budget, urgency, response deadline, "N dealers also notified" (not who). Contact hidden.
Flow: open lead → choose **in-stock car** (auto-fills) / **alternative** / **sourced** → price breakup → warranty, delivery, validity, extras, test-drive availability → preview "customer will see" → submit.
| # | Scenario | Behaviour |
|---|---|---|
| C3.1 | Lead arrives | 📱 (hourly digest if many); lead feed sorted by score + urgency |
| C3.2 | No stock | "Quote a sourced car": ETA required, flagged SOURCED |
| C3.3 | Lead not interested | Dismiss with reason (budget too low, not my segment) → improves future matching; counts neutral |
| C3.4 | Deadline approaching | 📱 at 75% of window |
| C3.5 | Lead assigned to staff | Assign/reassign; reminders to assignee; history |
| C3.6 | Two staff quote same lead | Blocked: one active quote per dealer per request; second becomes revision |
| C3.7 | Edit quote | Revision stored; if price rises after buyer shortlisted → buyer must reconfirm |
| C3.8 | Withdraw | Reason required; allowed until accepted |
| C3.9 | Quote below min price | Warning (private); allowed if owner role |
| C3.10 | Car sold while quote open | Auto-UNAVAILABLE; warning to staff; repeated cases lower reliability |
| C3.11 | Buyer counters | 📱; accept/counter/decline within 24h |
| C3.12 | Buyer accepts | 📱💬 "You won!"; buyer contact revealed; car auto-Reserved; booking tasks start |
| C3.13 | Buyer chose another | 🔔 "Not selected" (+ optional anonymous feedback: price rank band) |
| C3.14 | Request edited by buyer | 📱 "Requirement changed — review your quote" |
| C3.15 | Request cancelled/expired | 🔔 quote closed |
| C3.16 | Dealer account suspended mid-quote | Quotes voided; buyers notified neutrally |
| C3.17 | Dealer wants to transfer lead to another branch | Reassign with note; original quote withdrawn or kept per choice |

### C4. Seller leads (purchase offers)
Lead card: car summary, photos, condition/disclosures, seller's expected price (and urgency), listing documents (view-only), location. 
Procurement calculator: offer price + refurbishment + transfer/RTO + loan settlement + challans + holding cost → **expected resale** and **gross margin**.
| # | Scenario | Behaviour |
|---|---|---|
| C4.1 | Submit initial offer | Valid 48h; conditions subject to inspection |
| C4.2 | Seller accepts | 📱💬; contact revealed; schedule inspection |
| C4.3 | Seller not selected | 🔔 |
| C4.4 | Inspection and final offer | Same/lower; lower > 5% needs reason + evidence |
| C4.5 | Seller declines revised price | Offer closes no-penalty; if repeated large drops across many sellers → flagged to admin (bait-and-switch pattern) |
| C4.6 | Withdraw offer | Allowed before acceptance; after → cancellation with reason |
| C4.7 | Pickup & payment | Dealer records payment; seller confirms; transfer milestones |
| C4.8 | Seller cancels | Dealer notified 📱; reason recorded |

### C5. Dealer dashboard (first screen order)
1. **Needs action**: leads expiring soon, counters to answer, inspections today, accepted deals awaiting booking.
2. New leads (sorted).
3. Active quotes/offers & statuses.
4. KPI strip: response time, win rate, conversion, cancellations.
5. Inventory ageing, margin, employee performance (owner/manager only).

### C6. Dealer-side failures
| Scenario | Behaviour |
|---|---|
| Doesn't respond to leads | Response rate drops; fewer leads (not a punishment: matching weights recent responsiveness) |
| Repeated cancellations | Reliability score falls; warning → restriction ladder |
| Violates quote terms (price changed after acceptance) | Dispute; sanction |
| Suspicious bidding (colluding accounts, withdraw-resubmit games) | Auto-flag; admin review |
| Staff leaves | Owner deactivates; their leads reassigned |
| Notification delivery fails | Retry → in-app badge → email for critical |

---

## PART D — Admin

| # | Scenario | Flow |
|---|---|---|
| D1 | Dealer application | Queue → review docs (checklist) → approve / request changes / reject with reason → audit event; dealer notified |
| D2 | Document expiry | Daily job lists expiring; auto notices; restrict on expiry |
| D3 | Suspend dealer | Reason + evidence; quotes voided; affected buyers notified neutrally; audit; appeal route |
| D4 | Wrongly suspended | Reactivate with note; dealer notified; audit shows who/why |
| D5 | Listing moderation | Flags: duplicate, suspicious details, misleading photos, inappropriate content → freeze/unfreeze; owner notified |
| D6 | Monitor quotes/offers | Read-only view; unusual pricing, repeated withdrawals; admin can **void with reason** only (never edit) |
| D7 | Dispute handling | Intake (category, evidence) → assign → request info from both parties → decide (outcomes: dealer corrects, partial refund, cancel no-fault, sanction dealer, dismiss) → close; SLA 48h first response / 7d resolution |
| D8 | Fraud reports | Quick freeze of account/listing; evidence preserved; legal escalation path |
| D9 | Liquidity watch | Cities/segments where open requests > active dealers → recruit dealers; unmatched list |
| D10 | Customer support | Search user/request/deal, view timeline, add notes (internal), cannot view documents without reason logged |
| D11 | Master data | Add makes/models/variants/cities; deprecations safe for existing requests |
| D12 | Broadcasts | Targeted announcements (city/role) with approval |
| D13 | Reports | Funnel, conversion, response times, revenue, dispute rate, city view; export CSV |
| D14 | Settings | Windows, caps (15 dealers), thresholds (5% re-offer), feature flags |
| D15 | Admin permissions | Roles: support, verifier, moderator, finance, super-admin; every action logged |

---

## PART E — Platform behaviour

| # | Scenario | Behaviour |
|---|---|---|
| E1 | Two users act at once (accept vs withdraw) | DB row lock; first committed wins; loser gets clear message |
| E2 | Expiry job vs action | Action re-checks `valid_until` |
| E3 | Image upload fails | Chunked/resumable, compression, retry, draft saved |
| E4 | Payment gateway fails (later) | State stays PENDING/FAILED; retry; reconciliation job |
| E5 | Duplicate payment callback | Idempotency key; ignored |
| E6 | Notification provider down | Queue retry (3x backoff) → alternate channel; in-app always stored |
| E7 | User offline | Offline banner; drafts local; actions queued only for safe ones (drafts), never accept/pay |
| E8 | App update required | Min-version check, soft/hard prompt |
| E9 | Abuse (spam requests, fake quotes) | Rate limits, device signals, report button, shadow-limit |
| E10 | Data request/deletion | Export/delete flow with legal holds on disputes/transactions |
| E11 | Time zones | Server time in UTC, shown in IST |
| E12 | Language | English first; Hindi/regional via ARB |

---

## PART F — Notification master table

Who gets what, when. Default channels; user prefs can mute non-critical. Critical = cannot be disabled.

### Customer (buyer)
| Event | Trigger | Channels | Critical |
|---|---|---|---|
| Request posted | submit | 🔔 | |
| Dealers matched | matcher done | 🔔 | |
| Quote received | dealer submits | 📱🔔 (batched) | |
| Quote revised / price dropped | dealer revises | 📱🔔 | |
| Price increase needs reconfirm | revision up | 📱🔔 | ✔ |
| Quote expiring | −4h, −1h | 📱 | |
| Quote withdrawn / unavailable | dealer action | 📱🔔 | |
| Counter response | dealer replies | 📱🔔 | |
| Test drive confirmed / reminder | 24h, 2h | 📱💬 | ✔ |
| Inspection scheduled/completed | | 📱🔔 | |
| Accept confirmed | acceptance | 📱💬✉️ | ✔ |
| Booking/payment recorded | | 📱✉️ | ✔ |
| Document pending | checklist item due | 📱 | |
| Delivery/transfer milestones | | 📱🔔 | |
| Request expiring / expired | day 10 / 14 | 📱🔔 | |
| Rate dealer | +2 days after completion | 📱 | |
| Dispute update | | 🔔✉️ | ✔ |
| Chat message | | 📱 | |

### Customer (seller)
| Event | Channels |
|---|---|
| Listing live / under review | 🔔 |
| Offer received (batched) | 📱🔔 |
| Offer withdrawn | 📱🔔 |
| Offer expiring | 📱 |
| Inspection scheduled / reminder (24h, 2h) | 📱💬 |
| Final offer lower (with reason) | 📱🔔 ✔ |
| Documents pending | 📱 |
| Payment recorded — please confirm | 📱✉️ ✔ |
| Transfer milestone / blocked | 📱🔔 |
| Listing expiring | 📱 |

### Dealer
| Event | Channels | Critical |
|---|---|---|
| New matched buyer lead / seller lead | 📱 (digest if many) 🔔 | |
| Lead deadline near | 📱 | |
| Requirement changed / cancelled | 📱🔔 | |
| Counteroffer | 📱🔔 | ✔ |
| Quote/offer accepted | 📱💬 | ✔ |
| Not selected | 🔔 | |
| Test drive / inspection request & reminders | 📱💬 | ✔ |
| Inventory car marked unavailable (affects quotes) | 🔔 | |
| Verification approved / rejected / needs changes | 📱✉️ | ✔ |
| Document expiry (30/14/7 days) | 📱✉️ | ✔ |
| Suspended / reactivated | 📱✉️ | ✔ |
| Dispute opened/updated | 📱✉️ | ✔ |
| Staff assigned a lead | 📱 (assignee) | |
| Weekly performance summary | ✉️ | |

### Admin
New dealer application · document expiry batch · flagged listing/dealer · dispute SLA breach · liquidity alert · payment anomalies → 🔔 + ✉️ (daily digest + urgent push for SLA/fraud).

### Delivery rules
Dedupe by (event, entity, recipient, window); quiet hours 22:00–08:00 for non-critical; retry 3× (1m, 5m, 30m); fallback push→in-app→email; SMS/WhatsApp only with consent and approved templates; notification tap deep-links to the exact quote/offer/deal; all deliveries logged for support.

---

## PART G — End-to-end timelines

### G1. Buying (typical)
| Time | Buyer sees | Dealers see |
|---|---|---|
| T+0 | Posts request, "12 dealers notified" | 📱 new lead (matched) |
| T+30m | First quote 📱 | Other dealers' leads still open (no prices) |
| T+3h | 4 quotes; compare; shortlists 2 | Counter requests 📱 |
| T+1d | Counter agreed; books test drive | Confirms slot |
| T+2d | Test drive done; accepts quote; Price Lock 7 days | Winner 📱💬; others "Not selected" |
| T+3d | Pays token (recorded), uploads docs | Booking confirmed, car Reserved |
| T+7d | Delivery | Delivery + transfer tasks |
| T+9d | Rates dealer; COMPLETED | Metrics updated |

### G2. Selling (typical)
| Time | Seller sees | Dealers see |
|---|---|---|
| T+0 | Lists car (photos, disclosures) | 📱 matched sell lead |
| T+6h | 5 initial offers; counters best | Procurement calculator, offers placed |
| T+1d | Accepts best; inspection booked | Winner 📱💬 |
| T+2d | Inspection; final offer (same) | Final offer submitted |
| T+3d | Accepts; uploads documents | Collects docs, pickup |
| T+4d | Payment received (confirms) | Records payment |
| T+10d | Transfer completed; COMPLETED | Transfer done |

### G3. Failure path (price drop after inspection)
Inspection finds issue → dealer final offer −₹30,000 + evidence → seller 📱 → seller **declines free** → listing reopens, next-best initial offer offered 24h → dealer's "price-drop rate" metric increases → if pattern persists, admin flag.

---

## PART H — Who can see what (privacy matrix)
| Data | Buyer | Matched dealer | Winning dealer | Admin |
|---|---|---|---|---|
| Buyer name/phone | self | hidden (first name only) | revealed after acceptance | with reason logged |
| Buyer requirements | self | yes | yes | yes |
| Other dealers' quotes | yes (own requests) | **no** | no | yes (read-only) |
| Seller documents | self | view-only watermarked after offer stage | full after acceptance | with reason logged |
| Dealer min price / purchase cost | no | own only (owner roles) | own | no |
| Dealer reliability score | yes | own detail | – | yes |
| Dispute evidence | parties | parties | parties | assigned staff |
