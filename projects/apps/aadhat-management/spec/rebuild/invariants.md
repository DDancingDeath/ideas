# Invariants — rebuild

> **These are business laws.** They must hold at all times across the
> system. Any violation in test, in CI, or in production is a `Sev-1`
> defect. Many of these are enforced by automated invariant tests
> (see `quality-bar.md`); some are runtime assertions that raise a
> `flag_raised` event when violated.

## Constitution — the "no false data" rules

Eight plain-language rules every screen, service, and event-
write must obey. Each is restated formally in one of the
labelled invariant tables below. Together they are the
**accuracy contract** of the app — there is no other source.

| # | Rule | Where it is enforced (labels in this file unless noted) |
|---|---|---|
| AC1 | No screen may show authoritative totals from UI math. | `M5` (no per-screen period math); `C5` (no per-screen cash math); `R4` (Today == Finance == Reports) |
| AC2 | Every bill total equals the domain calculation. | `M1`–`M3` (formula); [`money-units-rounding.md`](./money-units-rounding.md) (canonical formula and rounding) |
| AC3 | Every stock value is event-derived. | `S1` (replay formula); `S3` (retail does not move stock); architectural rule in [`architecture.md`](./architecture.md) — no UI stock guesses |
| AC4 | Every report total reconciles with the ledger. | `R1`–`R3` (replay equality); `R4` (cross-screen agreement) |
| AC5 | Every payment balances: `cash + online + due == grandTotal`. | `M1` |
| AC6 | Every correction or void references the original event. | `B2` (void → existing sale); `B3` (correction → most recent non-voided version) |
| AC7 | Every mismatch creates a Review Queue flag. | `C2` (cash mismatch); `S2` (stock-negative); `R4` (cross-screen divergence in dev); §"What to do when an invariant fails" below; [`review-queue.md`](./review-queue.md) |
| AC8 | Projection cache may be stale, but must be labelled stale. | [`data-placement.md`](./data-placement.md) (staleness tolerance per data type); [`offline-sync.md`](./offline-sync.md) (UI state vocabulary); no row may render without its badge |

The constitution is the **summary**. The labelled invariants
below are the **enforcement** — they are the rows CI tests,
storage adapters reject against, and the suspicion engine
flags from. A change to AC1–AC8 means a change to one of the
M / S / O / C / B / R / A / X / T rows; the constitution does
not drift independently.

## Money

| # | Invariant | How checked |
|---|---|---|
| M1 | For every sale (retail / wholesale) and purchase: `online + cash + due == grandTotal` | Domain assertion at event construction; rejected at append |
| M2 | For retail bills, `grandTotal == Σ items.itemTotal` (no labor field) | Domain assertion |
| M3 | For purchase bills, `grandTotal == Σ items.itemTotal − laborCharges` | Domain assertion |
| M4 | All money values stored as integer paise (or whichever atomic unit is chosen at M0). No floating-point money. | Schema validation |
| M5 | Period revenue, period expenses, period profit computed via the single period-math helper. No screen calculates a period total locally. | Lint rule / code review; runtime sanity check between two callers must always agree |

## Stock

| # | Invariant | How checked |
|---|---|---|
| S1 | Computed stock for any item at any time = Σ(purchases) − Σ(wholesale-sales) + Σ(adjustments), accounting for voids and corrections | Replay test on every scenario fixture |
| S2 | Stock can be negative only with an explicit `stock_adjustment_recorded` event saying so, or by raising a `flag_raised` from the suspicion engine. A wholesale sale that would push stock below zero is allowed but **must raise a flag**. | Domain check + suspicion engine |
| S3 | Retail sales do not affect stock (matches v1; see `02-billing.md`). | Domain rule |
| S4 | Item rate after a purchase = moving average weighted by quantity (matches v1). Tests assert the exact formula. | Unit + scenario tests |

## Outstanding (udhaar)

| # | Invariant | How checked |
|---|---|---|
| O1 | Per-party outstanding = Σ(bills with due > 0 against party) − Σ(payments received/made against party). | Replay test |
| O2 | `payment.due` on a bill and the outstanding projection must agree. v1's split between `dueAmount` and `payment.due` is removed; there is one source. | Domain rule + schema |
| O3 | Settling outstanding always references the bill(s) it pays against; partial payments are allowed and tracked per bill. | Service contract |

## Cash

| # | Invariant | How checked |
|---|---|---|
| C1 | Expected closing cash = opening count + Σ(cash inflows in session) − Σ(cash outflows in session). | Domain rule |
| C2 | Mismatch = closing count − expected closing. Any non-zero mismatch above `shopProfile.cash.mismatchTolerance` raises a flag. | Suspicion engine |
| C3 | A new session cannot be opened while another is open for the same shop. | Service contract |
| C4 | A session cannot be closed without a closing count (no implicit zero). | Service contract |
| C5 | Cash on hand displayed anywhere matches the projection from cash events. No screen calculates it locally. | Invariant test |

## Bill lifecycle

| # | Invariant | How checked |
|---|---|---|
| B1 | One `idempotencyKey` → at most one sale event in the log. | Storage adapter check + tests for double-tap, retry, replay |
| B2 | A `bill_voided` event must reference an existing sale event with state ≠ voided. | Schema + domain rule |
| B3 | A `bill_correction_recorded` event must reference the most recent non-voided version of the bill. | Domain rule |
| B4 | Print attempts and successes never create or modify sale events. | Architectural rule; type system enforces (services that print do not have access to the sale-write API) |
| B5 | Bill numbers are strictly increasing per `(shopId, date, type)` and never reused, even after void. | Counter contract |

## Authorization

| # | Invariant | How checked |
|---|---|---|
| A1 | Every event's `by` field matches the authenticated principal at the time of write. | Storage adapter rejects mismatches |
| A2 | Server-side rules (e.g. Firestore rules) enforce role-based access. UI checks are advisory only — they exist for UX, never for security. | Security-rule test suite |
| A3 | Staff cannot append events of types restricted to manager / owner (defined in the permission rules in `architecture.md` layer 1). | Domain rule + storage check |
| A4 | The audit log surface is read-only for every role; events cannot be edited or deleted via any API. | Storage check + security-rule test |
| A5 | Cross-shop reads are impossible: every read filters by `shopId`, and the storage adapter rejects queries that do not. | Storage check |

## Reconciliation

| # | Invariant | How checked |
|---|---|---|
| R1 | Reports' "total sales for period X" == sum over sale events in period X. Tests assert the exact equality on every scenario. | Replay test |
| R2 | Reports' "cash on hand at end of period X" == projection from cash events at end of X. | Replay test |
| R3 | Reports' "outstanding at end of period X" == projection from outstanding events at end of X. | Replay test |
| R4 | Today page numbers == Finance page numbers == Reports page numbers, for any period that all three render. (v1 mitigates this by routing through `PeriodMath`; v2 hardens it by making per-screen calculation literally impossible.) | Runtime assertion in dev; invariant test in CI |

## XSS / data hygiene

| # | Invariant | How checked |
|---|---|---|
| X1 | User-controlled strings are never injected into HTML as raw markup. Framework-level escaping is the only allowed render path. | Linter / framework choice; targeted test for every user-facing string field |
| X2 | Print payloads escape control characters that the printer driver could misinterpret. | Driver-level test |
| X3 | All event payloads are validated by schema (Zod or equivalent) on append. Unknown / extra fields are rejected. | Schema test |

## Time

| # | Invariant | How checked |
|---|---|---|
| T1 | All event timestamps that affect money or stock are server-assigned. Client times are recorded for the audit but not authoritative. | Storage adapter |
| T2 | Backdating an event by more than `shopProfile.backdateToleranceDays` raises a `flag_raised`. | Suspicion engine |

## What to do when an invariant fails

1. In **tests**: the test fails. The implementation is the bug, not
   the test. Fixing by weakening the assertion is forbidden (see
   the quality bar).
2. In **dev / staging**: the invariant assertion throws; the
   service rejects the event with a clear error. The UI surfaces a
   "this would create inconsistent data — refused" message.
3. In **production**: the storage adapter rejects the write and the
   suspicion engine raises a `flag_raised` with severity `high` for
   the Review Queue. The user is told to retry or escalate.
4. If a projection ever disagrees with a replay (R1–R4): the
   projection is wrong. Rebuild it from events.

## Recent changes

- _2026-06-16_ · added `## Constitution — the "no false data"
  rules` section at the top. Eight AC rules (AC1–AC8) restate
  the accuracy contract in plain language and map each to the
  M / S / C / B / R label that enforces it. The constitution is
  a summary, not an independent source of truth — changes flow
  from M/S/C/B/R rows into the AC summary, never the other way.

