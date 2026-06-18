# Scope boundaries — rebuild

> Every feature lives in exactly one bucket. Disputed items go to
> `TODO(spec)` and back to the owner, not silently into Core.

The rebuild starts as a custom app for one family shop with one
regular staff member and the brother as monitor. It is designed so
that productization for other small Indian wholesale/retail shops is
possible later without a second rewrite — but **shop-1 stays the
reference customer** until at least one other shop is piloted.

## The four buckets

| Bucket | Meaning | Rebuild treatment |
|---|---|---|
| **Core** | Behaviour every shop will need; cannot be turned off | Pure domain logic, fully tested, no config switch |
| **Configurable** | Same behaviour, different parameters per shop | Driven by `shopProfile` config, defaults captured for shop-1 |
| **Shop-custom** | Specific to this family shop; no other shop is expected to use it | Lives behind a feature flag or in a shop-1-only module |
| **Not doing (v2.0)** | Out of scope for the rebuild's first production cut | Explicitly listed so agents stop asking |

## Core (always on)

- Item master with English + Hindi names and per-item rates.
- Purchase entry (we buy stock from suppliers).
- Retail sale entry (over-the-counter sale to walk-in customer).
- Wholesale sale entry (from tracked stock, with party ledger impact).
- Derived stock (purchases − sales ± adjustments; never stored as
  authoritative).
- Outstanding ledger per party (receivable + payable in one view).
- Cash session: open with opening count → activity → close with
  closing count and mismatch reconciliation.
- Immutable event ledger + audit trail (see `event-ledger.md`).
- Suspicion engine + Review Queue (see `suspicion-engine.md`,
  `review-queue.md`).
- Bill lifecycle with idempotency and separation from printing (see
  `bill-lifecycle.md`).
- Background print queue (see `print-queue.md`).
- Role-based authorization enforced server-side (not only in UI).
- Period math: every "total for a period" goes through one helper.
  v1 calls this `PeriodMath`; the rebuild keeps the single-source-of-
  truth rule but may rename or split it.
- **Full Hindi/English UI localization with a single app-wide toggle**
  (instant, no reload, Hindi-first) — see `localization.md`. All chrome
  comes from a message catalog; item/party names remain bilingual data.
  (This supersedes the earlier "inline bilingual, not a locale toggle"
  scope; the owner asked for a real language switch.)
- **Production-grade UI quality** — the v1 app is the *floor*, not the
  ceiling. Design tokens, reusable components, mobile bottom-nav,
  every-state coverage, accessibility. See `ui-standards.md`.

## Configurable (per-shop profile)

- Shop name, address, GSTIN if any, contact for printed bills.
- Default labor rate, heavy-weight default, packet/bag conventions.
- Bill format: header text, footer text, line width (32 / 48 / 58
  column), Hindi/English column labels, paper width.
- Cash mismatch tolerance threshold (₹).
- Discount limit per role (staff / manager / owner).
- Item units allowed (kg, packet, piece, …).
- Wholesale vs retail availability per role.
- Per-role page visibility and optional capabilities, owner-editable
  at runtime from Admin → Roles & Visibility (see
  `role-permission-matrix.md` §Owner-configurable role visibility &
  capabilities). The fixed matrix is the ceiling; this config only
  narrows it, never widens it.
- Printer model / connection profile.
- Currency / locale (defaults to `en-IN`, `₹`).
- Audit log retention window (v1 = 90 days; configurable in v2).
- Suspicion-engine thresholds (see `suspicion-engine.md`).

## Shop-custom (this family shop only, for now)

- Item categories specific to shop-1's catalog (e.g. local crop
  names, regional vegetable Hindi spellings).
- The specific wording of party autocompletes (parties built up over
  years of bills).
- Any printed-bill phrasing the family uses (greeting line, festival
  note, etc.).
- The exact set of expense categories shop-1 books against.
- Brother's monitoring preferences (which Review Queue rules he
  wants always-on vs digest).

> Anything in this bucket must live behind a `shopId === 'shop-1'`
> guard or in a separate module that the productization path can
> swap out without touching Core.

## Not doing (v2.0)

- GST e-invoicing / e-way bill integration.
- Multi-branch / multi-warehouse stock per shop.
- iOS native build (Android + PWA only, per v1).
- Desktop-first / large-screen-first UX (mobile-first stays).
- Full ERP-style accounting (P&L, balance sheet, journal entries).
  v2 stops at cash-flow-style finance + reports.
- Real-time multi-device collaborative editing of the same bill.
- Customer-facing app (loyalty, ordering, online catalog).
- Payment gateway integration (UPI deep-link is acceptable; full
  PSP integration is not).
- Generic plugin / extension system. Productization happens via
  configuration, not third-party plugins.

## Disputed / unresolved

- `TODO(spec)`: Voice billing v2 (see `../voice-billing-v2.md`) —
  Core or Configurable? Default assumption: Configurable, off by
  default for shops without a Hindi-capable mic environment.
  Zero-touch / hands-free **activation** (no-touch app launch + full
  bill by voice) is a v2.1 sub-goal recorded in
  `../voice-billing-v2.md` §9; mechanism `TODO(spec)` (OS-assistant
  launch recommended over an always-listening in-app wake-word).
- `TODO(spec)`: AI Assistant chat tab (see `../chat-design.md`) —
  Core or Not-doing for v2.0? Default assumption: defer to v2.1,
  ship the rest first.
- `TODO(spec)`: WhatsApp share of bill PDF — Core or Configurable?
  Default assumption: Core (every shop wants it).

## v1 parity gaps (2026-06-17 audit)

A full feature-parity audit (v1 repo `AadhatManagementApp`, ~248
features, vs the rebuild spec) confirmed the rebuild covers every
core domain — auth, purchase / retail / wholesale billing, drafts +
auto-save, derived stock + adjustments, item master, cash sessions,
outstanding, expenses + withdrawals, reports, finance, analytics,
today, Bluetooth printing, admin / settings, diagnostics + audit,
offline / PWA, the notification contract, WhatsApp share, and data
export (see `data-governance.md` §Export). Four v1 features were
present in the v1 inventory (`../capabilities.md`) but had **no
bucket here**. They are recorded below with a recommended bucket;
each is `TODO(spec)` until the owner confirms.

- `TODO(spec)`: **Frequency-sorted item dropdown / "most-used"
  badges** (v1 `itemFrequency`, 90-day half-life decay). The
  `itemFrequency` collection already survives in v2
  (`firestore-rules-design.md` §4.8), but the dropdown-sort /
  most-used behaviour is unspecified. Recommended bucket: **Core**
  (a billing-speed feature; the data plumbing is already kept). Needs
  the sort/score behaviour written into the billing/items rebuild
  contract.
- `TODO(spec)`: **Bulk item import + item-master export (Excel /
  CSV)** (v1 SheetJS `xlsx`: export the catalog, import to replace
  it). v2 `data-governance.md` §Export covers bills / stock /
  outstanding / reports / audit / ledger export but **not** an
  item-master export row, and there is no ongoing bulk-import tool
  (the one-time v1→v2 item import lives in `migration-cutover.md`,
  not a reusable feature). Recommended bucket: **Configurable** —
  add an "Item master (CSV)" export row to §Export and an owner-only
  bulk-import tool that runs every row through the normal
  `item_created` / `item_updated` validation gates.
- `TODO(spec)`: **Custom finance accounts** (v1
  `customFinanceAccounts`: owner-defined asset / liability accounts
  that feed the Assets / net-worth view). Not modelled in the
  rebuild Finance / analytics spec. Recommended bucket:
  **Configurable**, off by default (owner-only manual net-worth
  adjustment line items, audited like any other config).
- `TODO(spec)`: **Native contact picker** (v1 Capacitor Contacts API
  to fill the customer / supplier name on billing forms). Not in
  `platform-compatibility.md` (which lists WhatsApp share and file
  export as native capabilities, but not Contacts). Recommended
  bucket: **Configurable**, Android-only, off by default (a typing
  shortcut, not a data-integrity feature).

Deliberate v2 simplifications that look like gaps but are **not** —
do not re-add them:

- Orphan / "unmatched" stock buckets (v1 keyed stock by item *name*)
  are designed out by the entity-by-id rule (`architecture.md`
  §Engineering conventions); there is no name-keyed bucket to orphan.
- Full v1-event-history replay is deferred to v2.1 (decision D3); the
  v2.0 cutover is a snapshot import of opening balances.
- Voice billing, barcode scan, and an LLM chat were **not** in v1
  (v1's chat is local rule-based); they are new-or-deferred, tracked
  in `roadmap.md` §v2.1, not parity gaps.

## Recent changes

- _2026-06-18_ · Replaced the "inline bilingual, not a locale toggle"
  Core line with **full Hindi/English localization via a single
  app-wide toggle** (new `localization.md`) and added a
  **production-grade UI quality** Core line (new `ui-standards.md`),
  both driven by the owner's "make it production, not POC" +
  "localization support" asks. Item/party names stay bilingual data;
  app chrome is now catalog-driven and toggle-switched.

- _2026-06-17_ (later) · Noted under the Voice-billing disputed item
  that **zero-touch / hands-free activation** (no-touch app launch +
  full bill by voice) is now a recorded v2.1 sub-goal — full spec in
  `../voice-billing-v2.md` §9, mechanism `TODO(spec)`.
- _2026-06-17_ · Added §v1 parity gaps — a full v1↔v2 feature audit
  (~248 v1 features) confirmed the rebuild covers every core domain
  and recorded the four v1 features that had no bucket
  (frequency-sorted dropdown, Excel item import/export, custom
  finance accounts, native contact picker) with a recommended bucket
  and `TODO(spec)` for owner sign-off. Also pinned three deliberate
  simplifications (orphan stock buckets, full-history replay, voice /
  barcode / LLM-chat) so they are not mistaken for gaps.
- _2026-06-17_ · Added "Per-role page visibility and optional
  capabilities" to the **Configurable** bucket — owner-editable at
  runtime from Admin → Roles & Visibility, narrowing (never widening)
  the fixed role × permission ceiling. Generalises the existing
  "Wholesale vs retail availability per role" and "Discount limit per
  role" lines. Full contract in `role-permission-matrix.md`
  §Owner-configurable role visibility & capabilities.
