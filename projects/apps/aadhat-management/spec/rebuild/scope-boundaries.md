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
- Hindi + English UI labels in the same render (inline bilingual,
  not a locale toggle — matches v1).

## Configurable (per-shop profile)

- Shop name, address, GSTIN if any, contact for printed bills.
- Default labor rate, heavy-weight default, packet/bag conventions.
- Bill format: header text, footer text, line width (32 / 48 / 58
  column), Hindi/English column labels, paper width.
- Cash mismatch tolerance threshold (₹).
- Discount limit per role (staff / manager / owner).
- Item units allowed (kg, packet, piece, …).
- Wholesale vs retail availability per role.
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
- `TODO(spec)`: AI Assistant chat tab (see `../chat-design.md`) —
  Core or Not-doing for v2.0? Default assumption: defer to v2.1,
  ship the rest first.
- `TODO(spec)`: WhatsApp share of bill PDF — Core or Configurable?
  Default assumption: Core (every shop wants it).
