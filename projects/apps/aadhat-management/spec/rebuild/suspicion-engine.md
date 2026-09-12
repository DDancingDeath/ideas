# Suspicion engine — rebuild

> Pure rule engine that flags suspicious writes. `block` rules refuse save; all other severities append Review Queue flags.

## How it runs

- Pure function: `(currentState, candidateEvent, shopProfile) -> flag_raised[]`.
- Application service runs it after domain validation and before append; flags append in the same transaction as the target event.
- Server-only / cross-window rules run in the storage adapter or reconciliation job and append asynchronously.
- Non-`block` flags let the write through with Review Queue visibility.

## Severities

| Severity | At billing time (inline) | After the bill | In the daily report |
|---|---|---|---|
| `low` | info note on the line | logged | listed |
| `medium` | **inline confirm before save** | Review Queue entry + Today "Needs review" widget | listed, grouped by rule |
| `high` | **inline confirm before save** | prominent Review Queue entry; brother notified (mechanism: `TODO(spec, blocks: M10)` — **Default:** in-app badge + the Today digest; push and WhatsApp deferred to v2.1) | listed at the top, highlighted |
| `block` | **save refused inline**; owner-approval override path | the override attempt shows in the Review Queue | listed |

The only severity vocabulary is `block` / `high` / `medium` / `low`. Do not use any other scale.

## Surfacing

| Surface | Required behaviour |
|---|---|
| Billing time | Client advisory pre-check for cashier-facing rules (`price.*`, discount, zero-rate, stock-negative, unit, archived-item). Inline warning while typed; Save confirm names issue and expected range. `block` offers only Fix plus owner-approval override. |
| Authoritative append | Application service re-runs engine and appends `flag_raised` in the same transaction. Offline/tampered clients cannot suppress flags. `Save anyway` records the flag. |
| Review Queue | Every `medium` / `high` flag persists for brother/owner resolution in [`review-queue.md`](./review-queue.md). |
| Daily report | Today digest and [`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md) §Daily list every flag raised that day, grouped by severity, unresolved highlighted. |

Example confirm: `Aloo: rate ₹6/kg is unusually low (typical ≈ ₹60). Fix the rate, or save and flag for review?`

## Rules (v2.0, initial set)

Config defaults live in [`configuration.md`](./configuration.md); this file names keys only.

### Stock rules

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `stock.negative` | A sale would push computed stock below zero | `medium` | Flag; allow save. |
| `stock.negative.large` | A sale would push computed stock below `−(shopProfile.stock.negativeBlockMg)` | `block` | Refuse save unless owner override. |
| `stock.zero-after-recent-purchase` | An item went from positive to zero within an hour of a purchase being recorded — possible duplicate sale | `medium` | Flag; allow save. |
| `stock.adjustment.large` | An adjustment of magnitude greater than `shopProfile.stock.adjustmentLargeMg` | `medium` | Flag; allow save/request per permissions. |

### Pricing rules

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `price.below-cost` | Sale rate < latest moving-average purchase rate for that item | `medium` | Confirm; flag if saved. |
| `price.discount.large` | Discount exceeds `shopProfile.pricing.maxDiscountPctByRole[staff]` for the user's role | `medium` | Confirm; flag if saved. |
| `price.discount.exceeds-limit` | Discount exceeds the absolute discount limit for the user's role | `block` | Refuse save unless owner override. |
| `price.zero-rate` | Sale rate == 0 with non-zero quantity | `medium` | Confirm; flag if saved. |
| `price.unusually-high` | Sale rate > `shopProfile.pricing.maxRateMultiple` × moving-average for that item | `medium` | Confirm; flag if saved. |
| `price.unusually-low` | Sale rate is above cost but below `(1 / shopProfile.pricing.maxRateMultiple)` × the item's typical sell rate | `medium` | Confirm; flag if saved. |
| `price.purchase-rate-unusual` | Manual purchase rate deviates from recent purchase rate by more than `shopProfile.pricing.maxRateMultiple`× in either direction | `medium` | Confirm; flag if saved. |

Sale high/low anchors on item master rate, else recent median from [`projections.md`](./projections.md#rate-history-per-item). Cost rules anchor on moving-average purchase rate. First-ever transactions use item `rateCeilingPaise` from [`data-governance.md`](./data-governance.md) §Validation gates plus `price.zero-rate`.

- `TODO(spec, blocks: M4)` — Add `shopProfile.items.rateFloorPaise`, or require owner-confirm on first sale of a never-sold item? **Default:** `shopProfile.items.rateFloorPaise`.

### Duplicate / replay rules

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `bill.duplicate.window` | Same `(party, billTotal, lineItems[])` saved within `shopProfile.bills.duplicateWindowSec` | `medium` | Confirm; flag if saved. |
| `bill.idempotency-mismatch` | Same `idempotencyKey` arrived with a different payload (client bug or tampering) | `block` | Reject; flag conflict. |
| `bill.client-clock-skew` | Client-claimed timestamp differs from server arrival time by more than `shopProfile.time.clockSkewMaxMin` | `low` | Flag; allow save. |

### Cash rules

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `cash.mismatch.above-tolerance` | `|closing − expected| > shopProfile.cash.mismatchTolerance` | `medium` | Confirm; flag if saved. |
| `cash.mismatch.large` | `|closing − expected| > shopProfile.cash.mismatchLarge` | `high` | Confirm; prominent flag. |
| `cash.session.long-open` | A session has been open for more than `shopProfile.cash.maxSessionHours` | `low` | Flag. |
| `cash.session.opened-without-close` | A new session opens while a previous one is still open | `block` | Reject unless allowed reconciliation path applies. |
| `cash.paid-but-no-entry` | A bill is marked paid (cash / online) but no matching cash inflow / online-entry event exists | `medium` | Flag. |

### Outstanding rules

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `outstanding.changed-without-bill` | A party's outstanding moves without a linked transaction (manual adjustment) | `medium` | Flag. |
| `outstanding.settlement-overpayment` | A settlement event pays more than the outstanding for the referenced bill(s) | `medium` | Confirm; flag if saved. |
| `outstanding.long-overdue` | A bill has been outstanding for more than `shopProfile.outstanding.longOverdueDays` | `low` | Flag. |

### Timing rules

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `time.backdated` | Event's claimed bill date is more than `shopProfile.time.backdateToleranceDays` before today | `medium` | Confirm; flag if saved. |
| `time.future-dated` | Event's claimed bill date is in the future | `medium` | Confirm; flag if saved. |

### Authorization rules

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `auth.staff-edits-old-bill` | Staff submits a correction or void against a bill from before today | `medium` (requires owner approval) | Queue approval request; no direct append. |
| `auth.role-escalation-attempt` | A request was rejected because the principal lacked permission; multiple within `shopProfile.auth.escalationWindowMin` triggers this | `high` | Flag; notify brother/owner path. |
| `auth.session-anomaly` | Sign-in from a new device, country, or after a long absence (`TODO(spec, blocks: M3)` — **Default:** none agreed.) | `low` | Flag. |

### Item / unit rules

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `unit.mismatch` | Bill line uses a unit not in the item's allowed unit list | `medium` | Confirm; flag if saved. |
| `item.archived` | Bill line references an archived item | `medium` | Confirm; flag if saved. |

### Printing rules

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `print.repeated-failures` | A print job's `attemptNo` exceeds `shopProfile.printer.attemptsBeforeFlag` | `low` | Flag. |
| `print.exhausted` | A job has exhausted retries (terminal `failed`) | `medium` | Flag. |
| `print.many-reprints` | A bill has been reprinted more than `shopProfile.printer.reprintsBeforeFlag` times (possible duplicate-handout) | `low` | Flag. |

### Reconciliation rules (background)

| Rule id | Triggers when | Severity | Action |
|---|---|---|---|
| `recon.report-vs-ledger` | A daily report total disagrees with the replay-from-events total for that day | `high` | Flag; require review. |
| `recon.projection-mismatch` | A live projection disagrees with a fresh replay on the same time window | `high` | Flag; rebuild affected projection. |
| `recon.audit-gap` | A money-affecting event has no corresponding audit row (should be impossible by construction; if it ever fires, it is a system bug) | `high` | Flag system bug. |

## Stored events

`flag_raised`: `targetEventId` (`null` for background flags), `ruleId`, `severity`, `summary`, `context`, `raisedAt`, `raisedBy: 'engine'`.

`flag_resolved`: `flagId`, `resolution` (`approve` | `dismiss` | `correct`), optional `note`, `resolvedAt`, `resolvedBy`.

## Engine limits

- Does not modify candidate events; only emits flags.
- Does not raise unactionable flags; each rule supports `approve`, `dismiss`, or `correct`.
- Every flag has a human-readable `summary`.
- `block` rules are also enforced by domain/storage adapter so tampered clients cannot bypass them.

## Configurability

Each rule is on by default. Owner may disable, re-threshold, promote, or demote via `shopProfile`; each change writes `shop_profile_updated`. Disabled high-severity rules show a Diagnostics banner. `block` rules cannot be disabled; only thresholds can change.

## Tests this spec requires

- Each rule has one triggering fixture and one non-triggering fixture.
- Each `block` rule rejects at storage adapter even if engine is bypassed.
- Background reconciliation runs on every scenario fixture and expected flags are asserted.
- Property-based sequences of sale/purchase/payment/void/correction never violate invariants without `flag_raised` or `block` rejection.
- Billing-time surfacing: `price.unusually-low` shows inline confirm; **Save anyway** appends sale and flag in the same transaction; bypassed client still gets server flag.
- Daily report surfacing: every flag raised that day appears grouped by severity with unresolved highlighted.

