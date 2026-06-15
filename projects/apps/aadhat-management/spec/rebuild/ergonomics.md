# Ergonomics — rebuild

> The shop-floor reality the app must work in: phone in one
> hand, customer at the counter, printer beeping, sunlight on
> the screen, Hindi labels under the thumb. Performance
> budgets in [`performance-budgets.md`](./performance-budgets.md)
> answer "how fast"; this file answers "how usable".

## The constraints

The reference shop-floor moment is:

- Staff is standing.
- Phone is held in **one hand**.
- The other hand is touching items / cash / printer / the
  customer's bag.
- The shop is loud (vehicle horns, fans, other customers).
- The light is harsh (open shutter, mid-day).
- The phone is a mid-range Android in the ₹15–20k range (per
  [`decisions.md`](../../plan/rebuild/decisions.md) row 6).
- Hindi is the staff's primary language; English is read on
  signage.

Every UI decision must respect these constraints. "Pretty on
desktop" is not a target.

## Tap targets and one-handed reach

- **Minimum tap target: 48 × 48 dp** for any interactive
  element on the billing path.
- **Recommended target: 56 × 56 dp** for primary actions (Save,
  Print, Add line, item picker).
- **Bottom-aligned primary actions.** Save and Print sit
  inside the thumb's natural arc on a 6-inch device held in
  the right hand. Owner mode may show a left/right toggle for
  left-handed staff.
- **Top bar is for context, not action.** The status bar,
  shop name, and sync indicator live at the top; no buttons
  the staff needs during a bill.
- **Side gestures are forbidden** for primary actions —
  swipe-from-edge conflicts with Android system gestures.

### Why these numbers

- 48 dp matches Android Material accessibility guidance and is
  the floor below which mis-taps become measurable on noisy
  hands.
- 56 dp matches the Save / Print habit from the v1 app and
  works one-handed on a mid-range phone.

## Sunlight readability

- Minimum text contrast: **WCAG AA (4.5:1)** for body text;
  **3:1** for large text and UI controls.
- The billing page is **light-theme-first**. A dark theme is
  optional in Settings but the default must be readable in
  bright sunlight.
- Status colours are **paired with shape or icon**, never
  colour alone:
  - Saved: green check
  - Sync pending: amber dot + clock icon
  - Sync failed / Needs review: red triangle + word
  - Printed: blue printer icon
  - Print failed: red printer icon + word
- Maximum readable text size respects the OS font-scale
  setting up to 130 % without breaking the billing layout.
  Beyond that, billing rows reflow rather than truncate.

## Hindi labels fit

- Every label has both `hi` and `en` text in the same
  component; the layout is sized for the longer of the two.
- Hindi labels often run **15–25 % wider** than the English
  equivalent; line wrapping is allowed for non-primary labels
  and forbidden for primary buttons (Save / Print) — the
  button widens instead.
- A long Hindi word in the item name **truncates with ellipsis**
  in the picker; the full name shows in the tooltip / row
  expand.
- Devanagari rendering must use the system font; the app does
  not ship a custom font (latency + storage cost).

## Noisy environment

- All confirmations are **visual**, not audio-only.
- Optional audio cue for `Saved` and `Print succeeded` is
  short, distinctive, and configurable per shop.
- Haptic feedback is mandatory for: Save, Print, Add line,
  Remove line, picker selection. (Per
  [`spec/mobile-enhancements.md`](../mobile-enhancements.md).)

## Accidental tap prevention

- Destructive actions (Void, Delete draft, Close session)
  require a **two-step confirm**: tap → confirmation sheet →
  hold to confirm (300 ms hold).
- Save and Print are **single-tap** because they are the
  primary actions; the idempotency contract makes a double-tap
  safe (see [`bill-lifecycle.md`](./bill-lifecycle.md) B-rules
  and [`offline-sync.md`](./offline-sync.md) F6).
- The picker uses **tap-to-select with explicit Done**, not
  swipe-to-dismiss, on the billing path.
- Long-press gestures are reserved for diagnostics and copy-id
  actions; never for primary write actions.

## Confirmations only where they matter

- Confirm dialogs are a **tax** on the staff. They must exist
  only where idempotency does not save us:
  - Void / delete (data-shape change)
  - Close cash session (boundary event)
  - Owner-only settings changes
  - Forced upgrade
- For everything else (Save, Print, Add line) the UI shows the
  result instead of asking permission.

## Low-end phone performance

- The reference profile in
  [`performance-budgets.md`](./performance-budgets.md) is the
  contract: every primary action meets its budget on a Pixel 6a
  / Redmi Note class device.
- A lower-end profile (Snapdragon 4-series, 4 GB RAM) is
  allowed to miss budgets by ≤ 50 %; the UI must still
  function (no missed taps, no dropped events).
- Animations are subtle and short (≤ 150 ms) and use opacity /
  transform only; no layout animations on the billing path.
- Heavy images, fonts, and analytics chrome are excluded from
  the billing path.

## Empty and error states

Every screen has explicit empty and error states with concrete
copy:

- **Empty**: explains why ("No bills yet today") and offers the
  one obvious next step ("Tap + to create a bill").
- **Loading**: skeletons, never spinners, for any wait > 200 ms.
  Spinners only for indeterminate background work, not blocking
  content.
- **Offline**: banner per [`offline-sync.md`](./offline-sync.md)
  §What the UI must show.
- **Error**: bold one-line summary + an action ("Retry",
  "Open Review Queue", "Contact owner"). Never a stack trace.

## Picker design

The item picker is the single biggest UX element on the
billing path.

- Opens within 150 ms (per perf budget).
- Default selection: most-recent item by the same staff in the
  current cash session.
- Search matches across Hindi name, English name, and barcode
  / sku.
- Results are sorted: exact prefix → fuzzy → recent → favourites.
- Each row shows: name, current stock, last sale rate.
- Selecting a row closes the picker and focuses the qty input.

## History row design

- One row per bill; multi-line layout.
- Primary line: bill number, party name, total in ₹.
- Secondary line: time, badges (`Saved`, `Sync pending`,
  `Synced`, `Printed`, etc.).
- Tap → bill detail; long-press → copy trace id.
- Voids and corrections are visible inline ("Voided",
  "Corrected from ₹500 → ₹450") — not hidden behind a tab.

## Reports for trust

- Every report header says "Last reconciled at HH:MM" so the
  owner knows whether numbers are fresh.
- Every aggregate has an "Open audit" tap to show the
  underlying event list.
- Numbers are **never** silently zero. If a number is unknown
  (cache miss, error), the cell shows "—" with a tooltip
  explaining.

## Required tests

- `tap-target-min-48dp` — Playwright + axe scan on each
  primary screen.
- `contrast-aa` — automated WCAG contrast check.
- `hindi-label-no-overflow` — visual regression on the billing
  page with the longest Hindi labels.
- `font-scale-130-billing-usable` — Playwright with
  font-scale 130 % asserts no clipped controls.
- `confirm-required-on-void-only` — Save / Print do not show a
  confirm; Void does.
- `picker-open-under-150ms` — perf budget assertion.
- `loading-skeleton-not-spinner` — visual regression on slow
  network.
- `error-state-shows-action` — every error has at least one
  actionable button.
- `colour-not-only-status` — status indicators have icon /
  shape, not colour alone.

## Open items

- `TODO(spec)` — exact audio cue files (and licence) for Save
  / Print succeeded. Default v2.0: ship silent, owner enables
  per shop.
- `TODO(spec)` — left-handed layout toggle. Default v2.0:
  right-handed only; revisit after pilot.
- `TODO(spec)` — minimum supported Android version. Default:
  Android 9 (consistent with the v1 production app).

## Recent changes

- _2026-06-15_ · file created. Shop-floor constraints
  (one-handed, sunlight, noisy, Hindi-first, ₹15–20k phone);
  tap-target floors (48 / 56 dp); WCAG AA contrast with
  icon-not-colour status; Hindi label sizing rules;
  two-step confirm only for destructive actions;
  single-tap Save / Print backed by idempotency; picker
  design; history row design; required tests.
