# Revora Design System

Source of truth for UI. Tokens below mirror the **current code** in `frontend/lib/core/theme/` (not the older palette in `plans/implementation_plan.md`). Change code and this file together.

## 1. Principles
1. **Price-first, never ambiguous.** Every number says what it is (Vehicle price, On-road total, Offer).
2. **Trust by evidence.** Badges and "Verified" appear only when backed by an admin/third-party check; claims carry a source label.
3. **Calm competition.** Show progress (quotes arriving, countdowns) without pressure tactics.
4. **One primary action per screen.**
5. **Inclusive by default.** Large text, high contrast, plain language, works on low-end phones and slow networks.

## 2. Tokens (current)
**Colour** (`AppColors`)
| Token | Value | Use |
|---|---|---|
| primary | #0F172A | App bars, primary buttons, headings |
| primaryLight | #1E293B | Hover/pressed, dark surfaces |
| accent | #FF6B00 | Price highlights, key CTAs (use sparingly, one per view) |
| accentLight | #FFECE0 | Accent backgrounds |
| background / surface | #F5F7FA / #FFFFFF | Page / cards |
| textPrimary / textSecondary / textMuted | #1F2937 / #4B5563 / #9CA3AF | Text (muted only for non-essential) |
| border / borderLight | #E5E7EB / #F3F4F6 | Dividers |
| success / warning / error / info | #2E7D32 / #ED6C02 / #D32F2F / #0288D1 | Status, each with a `*Bg` tint |
| dark: background/surface/text/border | #121212 / #1E1E1E / #F9FAFB / #374151 | Dark theme |

Contrast notes to verify in S0: `textMuted` (#9CA3AF) on white is ~2.5:1 — decorative/placeholder only. White on accent #FF6B00 is ~2.9:1 — **use primary text on accent, or darken accent to ≥ #C2410C for white text.**

**Spacing** (`AppSpacing`): 2, 4, 8, 12, 16, 20, 24, 32, 48. Page gutter 16 (mobile) / 24 (tablet) / 32 (desktop). Radius: 4, 8, 12, 16, 20, pill.

**Typography** (`AppTextStyles`, Outfit): display 32/bold, headline 28 & 24, title 20/600, body 16 / 14 / 12, label 14/600 & 13/500. Prices use tabular figures and `titleLarge`+ weight 700.

**Elevation**: 0 (flat, borders) default; 1 for cards on tinted background; 3 for sheets/menus. Prefer borders over shadows.

**Motion**: 150–250ms ease-out; page transitions fade+slide 12px; quote arrival = subtle slide-in + count badge pulse. Respect reduced motion.

**Breakpoints**: compact < 600 (bottom nav), medium 600–1024 (rail), expanded > 1024 (sidebar). Existing `adaptive_shell.dart` implements this; keep it.

## 3. Navigation
- Customer bottom bar (4): Home · Activity · Alerts · Profile. Buy/Sell are the two primary actions on Home and a persistent "+" entry.
- Dealer bottom bar (5): Dashboard · Leads · Inventory · Deals · More.
- Admin: sidebar (web).
- Back always returns to the previous logical screen; deep links from notifications open the exact quote/offer/deal.

## 4. Components (shared widgets; ✓ = exists in `lib/shared/widgets`)
✓ custom_button, custom_text_field, custom_card, custom_app_bar, custom_loader, empty_state_widget, error_widget, car_card, offer_card, quote_comparison_card, dealer_match_card, match_badge, status_chip, spec_chip, kpi_tile, section_header, responsive_data_table, activity_tile, image_container.
To add (as needed): `PriceTag`, `Stepper form shell`, `CountdownChip`, `SkeletonList`, `OfflineBanner`, `SourceLabel` (Owner declared / Dealer claim / Verified), `DealScoreBreakdown`, `TimelineTile`, `BottomSheetScaffold`, `ConfirmDialog`, `RatingStars`, `FilterBar`.

Component rules
- **Button**: primary (filled navy), secondary (outlined), destructive (error), text. Min height 48. Loading state replaces label with spinner and disables.
- **Input**: label above, helper text, inline error; prefix ₹ for money; numeric keyboard; clear button.
- **Quote card**: dealer (name, verified, reliability), vehicle line, **total price** large, availability tag (In stock / Sourced / Alternative), validity countdown, primary "View", secondary "Shortlist".
- **Status chip**: colour + icon + text (never colour alone). Maps in §6.
- **Skeletons** for lists/cards; spinners only for button-level waits.

## 5. Screen patterns
- **Stepper forms**: max 3–4 steps, progress at top, Back/Continue sticky bottom, optional section collapsed, autosave draft, review step before submit.
- **List + filter**: sticky filter bar, pull-to-refresh, pagination, empty state with action.
- **Detail**: hero media, key facts row, sections, sticky action bar.
- **Comparison**: sticky first column, highlight best value per row (lowest total, longest warranty), max 4 items.
- **Dashboard**: top = "needs your action" list; KPIs secondary.
- **Confirmation**: summarise what will happen + consequences before irreversible actions (accept, withdraw, cancel).

## 6. Status vocabulary
| Entity | State → label / colour |
|---|---|
| Request | OPEN info · PAUSED muted · QUOTE_ACCEPTED success · IN_TRANSACTION info · COMPLETED success · EXPIRED warning · CANCELLED muted |
| Quote | SUBMITTED info · REVISED info · ACCEPTED success · NOT_SELECTED muted · WITHDRAWN muted · EXPIRED warning · UNAVAILABLE error |
| Offer | INITIAL info · INSPECTION_SCHEDULED info · FINAL info · ACCEPTED success · REJECTED error · EXPIRED warning |
| Dealer | PENDING warning · APPROVED success · REJECTED error · SUSPENDED error · RESTRICTED warning |
| Deal | DOCUMENTS_PENDING warning · PAYMENT_PENDING warning · TRANSFER_PENDING info · COMPLETED success · DISPUTED error |

## 7. Content & tone
Plain, calm, specific. Say what happened and what to do next. Prices with ₹ and Indian grouping (₹7.25 Lakh; ₹12,34,000 in detail). Dates relative for recent, absolute for deadlines ("Expires today, 6:30 PM"). Never blame the user in errors. Avoid jargon ("hypothecation" → "loan on the car (hypothecation)").
Examples: Empty quotes → "No quotes yet. 12 dealers have been notified — most reply within a few hours." Expiring → "This quote expires in 3 hours."

## 8. States checklist (every screen)
Loading skeleton · Empty with action · Error with retry · Offline banner · Partial data · Success confirmation · Permission denied · Expired/closed (read-only) · Long text/large font · Slow image placeholder.

## 9. Accessibility
Semantics labels on icons/images, focus order, 48dp targets, 4.5:1 text contrast (3:1 large text/UI), text scale to 200%, no colour-only meaning, screen-reader announcements for new quotes, captions for videos, reduce-motion support, keyboard navigation for web/desktop.

## 10. Imagery
Vehicle photos 4:3 with placeholder + blurhash/low-res, tap to zoom gallery, min 5 photos for sell listing with guided shots (front, rear, sides, interior, dashboard/odometer, engine). Strip EXIF location. Brand logos from a local asset set.

## 11. Review workflow
Design brief → implement with tokens → run `revora-ui-check` → `design:design-critique` → `design:accessibility-review` → fixes → screenshot evidence in PR.
