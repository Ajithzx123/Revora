---
name: revora-ui-check
description: Review or verify any Revora Flutter screen or widget for design-system compliance, states, responsiveness, accessibility and UX copy. Use after every UI change, before marking a UI task done, or when asked to "check the UI".
---

# Revora UI check

Run this on every UI change. Read `design/DESIGN.md` and `CLAUDE.md` first.

## 1. Static review (read the code)
For each changed file under `frontend/lib/**/presentation` or `shared/widgets`:
- **Tokens**: no hard-coded `Color(0x…)`, `fontSize`, or magic spacing numbers; uses `AppColors`, `AppSpacing`, `AppTextStyles`.
- **Reuse**: an existing shared widget isn't re-implemented.
- **States**: loading (skeleton), empty (message + action), error (retry), offline, success are all handled for async data.
- **Forms**: validation messages, disabled-while-submitting, keyboard type, draft saved, no double submit.
- **Money/dates**: via formatters; label says what the price is.
- **Strings**: no new hard-coded user-facing text if localisation is set up.
- **Perf**: `const` constructors, `ListView.builder`, narrow provider `select`, `CachedNetworkImage`.
- **Architecture**: screen → provider → repository (no Dio in widgets).
- **Trust rules**: no "Verified" visuals without verified data; competitor prices never shown to dealers; customer contact hidden before acceptance.

## 2. Visual check (run the app)
Use the built-in browser pane for Flutter web (`flutter run -d chrome --web-port 5000`, then preview that URL) or the iOS simulator tool for mobile.
Check at **375×812, 768×1024, 1280×800**, in **light and dark**:
1. No overflow (yellow/black stripes), clipping, or horizontal scroll.
2. Primary action is obvious and reachable with one thumb on mobile.
3. Hierarchy: price/key facts are the most prominent; secondary info muted.
4. Spacing rhythm follows the 4/8 scale; alignment consistent.
5. Long names, 200% text scale, empty list, 100+ items, slow network, error response.
6. Keyboard open on forms doesn't hide the submit button.
Capture a screenshot per width and note defects.

## 3. Accessibility
Contrast ≥ 4.5:1 (flag `textMuted` on white, white on `accent`), 48dp targets, semantic labels on icon buttons/images, focus order, colour-not-only status, reduce-motion.

## 4. UX copy
Plain language, says what happened and what to do next, no blame, consistent terms (Quote vs Offer: dealers send **quotes** to buyers and **offers** to sellers).

## 5. Report format
```
Screen: <name>   Widths checked: 375/768/1280   Themes: light/dark
Pass: …
Issues (severity · file:line · fix):
  1. High · … 
Not verified: …
```
Fix High/Medium issues, re-run, and only then report the UI as done. If something can't be run (no simulator, no backend), say so rather than claiming a pass.

## Companion skills
`design:design-critique` for heuristic feedback · `design:accessibility-review` for WCAG audit · `design:ux-copy` for wording · `design:design-handoff` for specs · Flutter skills (Dart and Flutter, Flutter Skills) for implementation patterns.
