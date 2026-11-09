# Revora Design System

Source of truth for UI. Tokens below mirror the **current code** in `frontend/lib/core/theme/` (not the older palette in `plans/implementation_plan.md`). Change code and this file together.

## 1. Principles
1. **Price-first, never ambiguous.** Every number says what it is (Vehicle price, On-road total, Offer).
2. **Trust by evidence.** Badges and "Verified" appear only when backed by an admin/third-party check; claims carry a source label.
3. **Calm competition.** Show progress (quotes arriving, countdowns) without pressure tactics.
4. **One primary action per screen.**
5. **Inclusive by default.** Large text, high contrast, plain language, works on low-end phones and slow networks.

## 2. Tokens ("Showroom" system)
Warm canvas + deep ink, one ignition-orange accent, signal green for savings. Two fonts: **Sora** (headlines, prices) and **DM Sans** (everything you read). Source: `frontend/lib/core/theme/`.

**Colour** (`AppColors`, named by role)
| Token | Value | Use |
|---|---|---|
| primary | #0B1324 | Ink: primary buttons, hero surfaces, nav bar, headings |
| accent | #F2650C | Ignition orange: selected nav, key CTA on dark, highlights. **Text/icons on it use `onAccent` (ink)** |
| accentDeep | #B9480A | Orange for small text on light backgrounds (links, "View all") |
| background / surface | #F5F3EE / #FFFFFF | Warm canvas / cards |
| primarySubtle | #EEEBE4 | Quiet fills: chips, spec pills, disabled |
| border / borderLight | #E4E0D7 / #EFECE5 | Hairlines |
| textPrimary / textSecondary / textMuted | #0B1324 / #475060 / #7B8494 | Muted only for non-essential text |
| success / warning / error / info (+ `*Bg`) | #0B7A55 / #B45309 / #C62F2F / #1D5FD1 | Status. Green also means "best price / savings" |

Contrast rules: white on accent is only 3.6:1, so never put small white text on orange. Muted text is not for anything the user must read.

**Typography** (`AppTextStyles`, mirrored in `ThemeData.textTheme`): display 34 · headline 28/22 · title 18 · body 16/15 · small 13 · label 15/13/11.5 · `price` (Sora 22, tabular figures) · `overline`. Weights 400/600/700.

**Spacing** `AppSpacing`: 2, 4, 8, 12, 16, 20, 24, 32, 48. Page gutter 16. Bottom padding 96 where a FAB or floating nav overlaps.
**Radius hierarchy**: 6 badges · 10 chips · 14 buttons/inputs · 20 cards · 28 hero cards/sheets · pill.
**Elevation**: flat with hairline borders by default; layered shadow (tight + ambient) for the floating nav, hovered cards and the bid stack.
**Motion**: 120-250ms ease-out; press scale 0.985 on cards; staggered slide-in for the bid stack; reduced-motion respected. Page transitions use the Cupertino slide.
**Breakpoints**: compact < 600 (floating nav), medium 600-1199 (rail), expanded >= 1200 (sidebar). Cards use `ResponsiveCardGrid` (1 / 2 / 3 columns at <640 / 640+ / 1000+).

## 3. Navigation
- Phone: **FloatingNavBar**, an ink pill. The selected destination expands to an orange chip with its label; others are icons with count badges.
- Tablet: navigation rail. Desktop: sidebar. Both ink with an orange selected state.
- Customer destinations: Home · Buy · Sell · Activity · Profile. Dealer: Home · Leads · Inventory · Activity · Dealership. Admin: drawer/sidebar.
- Primary "create" actions are an extended FAB (New request, Sell a car, Add vehicle). Back returns to the previous logical screen.

## 4. Components (shared widgets; ✓ = exists in `lib/shared/widgets`)
✓ custom_button, custom_text_field, custom_card, custom_app_bar, custom_loader, empty_state_widget, error_widget, car_card, offer_card, quote_comparison_card, dealer_match_card, match_badge, status_chip, spec_chip, kpi_tile, section_header, responsive_data_table, activity_tile, image_container.
Built for the redesign: `FloatingNavBar`, `BidStack` (signature visual), `ResponsiveCardGrid`, `CarCard` (photo-first, fills bounded height or sizes to content), `BuyLeadCard`, `AuthScaffold`. To add (as needed): `PriceTag`, `Stepper form shell`, `CountdownChip`, `SkeletonList`, `OfflineBanner`, `SourceLabel` (Owner declared / Dealer claim / Verified), `DealScoreBreakdown`, `TimelineTile`, `RatingStars`, `FilterBar`.

Component rules
- **Button**: primary (filled ink), accent (orange fill, ink text, hero/dark surfaces only), outlined, text (accentDeep). Height 52 on pages, 44 inside cards. Loading state replaces label with spinner and disables.
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

## 12. Known gaps (tracked)
- Dark theme exists but is not shipped: many screens still hard-code `AppColors` constants. The app is light-only until those move to theme colours.
- Fonts load from Google at runtime (a brief fallback flash on first load). Bundle Sora and DM Sans as assets for instant, offline-safe text.
- Not yet restyled (they inherit the theme but have not been designed): post-requirement / post-listing forms, listing and requirement detail, quote comparison, chat, add-vehicle, send-quote, make-offer, dealer activity/profile, admin requirements/vehicles. These are rebuilt as their slices (S2+) land.
