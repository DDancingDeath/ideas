# Localization (Hindi / English) — rebuild

> **The entire app must switch between English and Hindi (Devanagari)
> from a single toggle, at runtime, with no reload.** Hindi is the
> shop staff's primary language (`ergonomics.md`); English is read by
> the owner/brother and on some printed output. This is a first-class
> product requirement, not a nice-to-have.

This **updates a prior decision.** `scope-boundaries.md` originally
said "inline bilingual, **not** a locale toggle — matches v1." The
owner has since asked for a real, full-app language switch ("let's
have an option to convert the whole app in Hindi, localization
support"). This doc is the authority; the bilingual-data behaviour and
the UI locale toggle are reconciled in §"Data vs UI chrome" below. It
also aligns with `quality-bar.md`, which already tests "Hindi-leading
and English-leading label modes".

## What "localized" means here

1. **Every user-facing string** in the app chrome — tab labels,
   buttons, field labels, placeholders, validation messages, status
   text, empty states, suggestions — comes from a **message catalog**,
   never hardcoded in a component.
2. **One toggle flips the whole UI.** A single setting (English ↔
   हिंदी) re-renders all chrome instantly. No screen keeps a
   half-translated state.
3. **Hindi-first.** The catalog is authored so Hindi is complete and
   natural (not machine-literal), and the layout (`ui-standards.md`)
   never assumes English text widths — Hindi labels can be 20–40%
   wider and may wrap.

## The message catalog

- A single source of truth maps a **stable key** → `{ en, hi }`.
  Components reference keys (`t('action.saveBill')`), never literals.
- Keys are **language-independent**; they double as the basis for
  `data-testid`s so tests pass unchanged in both modes
  (`quality-bar.md` §7).
- Missing-translation policy: a key with no `hi` falls back to `en`
  **and** is flagged in dev/CI (a Hindi gap is a tracked defect, not a
  silent English leak).
- Pluralization and interpolation are supported (e.g. "{n} bills",
  "₹{amount} over 90 days") with Hindi-correct forms.

## Canonical terminology (adopt v1's names)

The catalog's English column uses the **v1 app's established terms**
— the owner prefers them and the staff already know them — not
invented words. The rebuild must not introduce ad-hoc names (e.g.
"udhaar") where v1 used a specific term. Confirmed verbatim from the v1
app's navigation (`DDancingDeath/AadhatManagementApp`,
`www/templates/navigation.html`):

| Concept | English (v1 nav label) | Hindi (catalog) |
|---|---|---|
| Daily home | Today | आज |
| Retail billing | Billing | बिलिंग |
| Wholesale sale | **Sales** (v1 calls wholesale "Sales") | बिक्री |
| Purchase | Purchase | खरीद |
| Live stock | **Stocks** (plural in v1 nav) | स्टॉक |
| Money owed/owing | **Outstanding** (not "Udhaar"/"Due") | बकाया |
| Item catalogue | Items | सामान |
| Cash session | Cash | नकद |
| Reports/analytics | Reports | रिपोर्ट |

> Note: in v1, retail "Sale" lives inside the Billing tab as a mode
> switch, while the **Sales** nav tab is wholesale-only — the rebuild
> keeps wholesale under "Sales". These names are implemented in
> `apps/web/src/lib/messages.ts` and asserted by `apps/web/test/i18n.test.ts`.

## Data vs UI chrome (reconciling the old decision)

- **UI chrome** (labels, buttons, messages) → fully **localized** via
  the catalog and flipped by the toggle. This is the new behaviour.
- **Master data** (item names, party names, categories) is **bilingual
  data**, stored per record (`nameEn` + `nameHi`, per
  `scope-boundaries.md` Core). It is **not** translated by the toggle;
  instead the current language decides which name leads, with the
  other shown inline where helpful (e.g. dropdowns, receipts). An
  item with no Hindi name still shows its English name in Hindi mode.

## Numbers, currency, dates

- **Currency**: always `₹`, Indian digit grouping (`₹1,24,500.00`),
  `tabular-nums`. `TODO(spec)`: decide whether money uses **Latin
  numerals even in Hindi mode** (recommended for unambiguous money) or
  Devanagari numerals — default recommendation: Latin numerals for all
  amounts/quantities, Hindi for words.
- **Dates / relative time**: localized ("2 days ago" / "2 दिन पहले"),
  shop-timezone aware (`time-clock.md`).
- **Units**: kg / किलो, packet / पैकेट, etc., come from the catalog.

## The toggle

- A clear control in Settings/Admin (and ideally a quick switch), per
  the owner-configurable model. Setting is **per device** at minimum
  (it is a display preference), persisted, and applied on next render.
- `TODO(spec)`: default language for a fresh install — Hindi or
  English? Recommendation: **Hindi** (staff-primary), owner can flip.
- Switching language must **never** change any stored data or any
  money value — it is presentation only (asserted in tests).

## Typography & layout

Devanagari rendering and width-tolerant layout are specified in
[`ui-standards.md`](./ui-standards.md) (font stack includes a
high-quality Devanagari family; no fixed-width assumptions). Printed
output (`printer-compatibility.md`) keeps its own Hindi/English column
handling.

## Tests this requires

- **Toggle completeness**: in Hindi mode, no screen shows an
  untranslated English chrome string (catalog-coverage test); a
  missing key fails CI.
- **Same flow, both modes**: every Playwright flow passes unchanged in
  English and Hindi by keying on `data-testid` (`quality-bar.md` §7).
- **Presentation-only**: flipping language does not alter any
  projection number or stored event (property/integration test).
- **Visual regression** in both Hindi-leading and English-leading
  modes (`quality-bar.md` §8).
- **Layout-fit**: Hindi labels do not overflow/clip on a 360 dp phone
  width.

## Recent changes

- _2026-06-18_ · File created. Makes a **full-app Hindi/English
  language toggle** a first-class requirement (the owner's
  "localization support" ask), superseding the earlier "inline
  bilingual, not a locale toggle" line in `scope-boundaries.md`.
  Specifies a key-based message catalog (single source, `{en, hi}`,
  CI-checked coverage), Hindi-first authoring, the rule to **adopt the
  v1 app's terminology** (no invented names like "udhaar"; a
  `TODO(spec)` table to fill verbatim from v1), the data-vs-chrome
  reconciliation (item names stay bilingual data; chrome is
  localized), number/currency/date handling, the toggle's behaviour
  and default, and the required tests. Cross-references
  `ui-standards.md`, `quality-bar.md`, `ergonomics.md`.
- _2026-06-18_ (later) · Filled the canonical terminology table verbatim
  from the v1 app's `navigation.html` (Today, Billing, **Sales** =
  wholesale, Purchase, **Stocks**, **Outstanding**, Items, Cash,
  Reports) — the `TODO(spec)` is closed. These names + the EN↔HI toggle
  are implemented in the `bahi` web app (`apps/web/src/lib/messages.ts`,
  `i18n.svelte.ts`) and locked by `apps/web/test/i18n.test.ts`.
