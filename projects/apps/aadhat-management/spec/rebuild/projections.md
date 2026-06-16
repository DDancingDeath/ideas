# Projections — rebuild

> The contract for everything that is **derived** from the event
> ledger. Stock, cash, outstanding, history, reports, audit,
> Review Queue — none of these are an authoritative store. They are
> functions of events. This file defines the function for each.

## Projection rules (apply to all)

1. **A projection is a fold.** `projection = events.reduce(apply,
   emptyState)`. The `apply` function is pure and lives in
   `domain`.
2. **Replay always wins.** If a cached or materialized projection
   disagrees with `reduce(apply, events)`, the cache is wrong and
   gets rebuilt from events.
3. **No projection writes to the event log.** Projections are
   consumers, never producers.
4. **Same events, same projection.** For a fixed input, the
   `apply` fold is deterministic. Property-based tests enforce
   this on random event sequences.
5. **Commutativity where safe.** Operations on disjoint keys
   (e.g. purchases on different items) must produce the same
   final projection regardless of order. Operations on the same
   key (e.g. two corrections of the same bill) are causally
   ordered by `references`.

## Catalog

| Projection | Inputs (event types) | Output shape | Layer |
|---|---|---|---|
| Items master | `item_*` | `Map<itemId, Item>` | domain |
| Rate history per item | `item_rate_changed`, `purchase_recorded`, `retail_sale_created`, `wholesale_sale_created` | `Map<itemId, RatePoint[]>` (chronological) | domain |
| Live stock | `purchase_recorded`, `wholesale_sale_created`, `stock_adjustment_recorded`, `bill_voided`, `bill_correction_recorded` | `Map<itemId, { qty: Quantity; movingAvgRate: Paise }>` | domain |
| Outstanding per party | sale events, `outstanding_payment_*`, `bill_voided`, `bill_correction_recorded` | `Map<partyId, { balance: Paise; perBill: Map<billId, Paise> }>` | domain |
| Cash on hand | sale events (cash portion), `expense_recorded` (cash), `withdrawal_recorded` (cash), `outstanding_payment_*` (cash), `cash_session_*` | `Paise` (live), plus `Map<sessionId, CashSession>` | domain |
| History (bills) | sale events, `bill_voided`, `bill_correction_recorded`, `print_*` | `OrderedList<BillRow>` | domain |
| Today summary | money-affecting events filtered to shop-local today | `{ totalSales, totalPurchases, totalCash, totalOnline, totalDue, bills, ...flagsCount }` | domain |
| Period reports | money-affecting events filtered to chosen range | `{ totalSales, totalPurchases, totalExpenses, cashFlowProfit, wholesaleRealizedProfit, withdrawals, paymentSplit }` | domain |
| Analytics | period reports + temporal binning | `Array<{ bucket: IsoDate; ... }>` | domain |
| Audit log | every event | `OrderedList<AuditRow>` | domain |
| Review Queue (unresolved) | `flag_raised` and `flag_resolved` | `OrderedList<FlagRow>` | domain |
| Print status per bill | `print_attempt`, `print_succeeded` filtered by `billId` | `{ state, lastAttemptNo, lastError? }` | domain |
| Reconciliation status | reconciliation job runs (see below) | `{ lastRunAt, drifts: FlagRow[] }` | domain + worker |

## Per-projection contract

### Items master

```
empty = { items: new Map() }

apply(state, event):
  switch event.type:
    case 'item_created':   state.items.set(itemId, snapshot from payload)
    case 'item_updated':   merge payload.changes into state.items.get(itemId)
    case 'item_archived':  mark state.items.get(itemId).archived = true
```

Stale-detection: not applicable; the projection is small enough to
recompute on every read in v2.0.

### Rate history per item

Tracks how an item's price moves **over time** — both the owner's
**configured sell rate** (set-points, each with a reason) and the
**actually transacted** buy / sell rates. This is the v2 home for
what v1 surfaced as the Analytics "Rate Trends" subtab (see
[`../page-specs/11-analytics.md`](../page-specs/11-analytics.md)
§Rate Trends), now event-sourced from the ledger instead of
re-derived ad hoc from bill rows.

```
type RatePoint = {
  at: IsoTimestamp;
  kind: 'master-set' | 'buy' | 'sell';   // master-set = owner changed the item's rate
  rate: Paise;                            // ₹/kg in paise
  fromRate?: Paise;                       // master-set only: the previous rate
  reason?: string;                        // master-set only: mandatory reason
  sourceEventId: string;
};

empty = { history: new Map<ItemId, RatePoint[]>() }

apply(state, event):
  case 'item_rate_changed':
    push { at, kind: 'master-set', rate: payload.newRate,
           fromRate: payload.oldRate, reason: payload.reason }
  case 'purchase_recorded':
    for each line: push { at, kind: 'buy',  rate: line.rate }
  case 'retail_sale_created' | 'wholesale_sale_created':
    for each line: push { at, kind: 'sell', rate: line.rate }
```

Reads: the item-detail screen shows the master-set series as a step
chart (reason on hover) and, optionally, the transacted buy / sell
points over a 7 / 30 / 90-day window. Margin compression (sell rate
flat while buy rate climbs) is read directly off this series. The
series is **append-only** and never edited — a rate correction is a
new `item_rate_changed` event, never a rewrite, so the history is a
faithful audit of every change.

Stale-detection: not applicable; recompute on read in v2.0.

`TODO(spec)` — confirm: (a) one merged projection vs separate
master-rate and transacted-rate views; (b) retention / windowing for
high-volume items; (c) whether a purchase that implies a new buy
rate should also raise a `master-set` point or stay purely
transactional. Depends on finalizing the `item_rate_changed` schema
(still in [`event-schemas.md`](./event-schemas.md) §Referenced
events not yet specified here).

### Live stock

```
empty = { stock: new Map() }

apply(state, event):
  case 'purchase_recorded':
    for each line: update qty += Σweights;
                   movingAvgRate = (oldQty * oldRate + Σweights * line.rate)
                                   / (oldQty + Σweights)
  case 'wholesale_sale_created':
    for each line: qty -= Σweights
  case 'stock_adjustment_recorded':
    qty += delta
  case 'bill_voided':
    inverse of the referenced sale event
  case 'bill_correction_recorded':
    inverse of the latest non-voided version, then apply the corrected payload
```

Rebuild process: full replay from genesis. Acceptable for the
shop's data volume in v2.0.

Stale-detection: a daily reconciliation job recomputes from
events and compares to the cached projection. Drift fires
`recon.projection-mismatch` (high).

### Outstanding per party

```
empty = { byParty: new Map(), byBill: new Map() }

apply(state, event):
  case sale (any):
    if payment.due > 0:
      byParty[partyId].balance += payment.due
      byBill[billId] = payment.due
  case 'outstanding_payment_received':
    if againstBills present:
      for each allocation: byBill[billId] -= allocate
    byParty[partyId].balance -= amount
  (symmetric for 'made')
  case 'bill_voided':
    reverse the original's outstanding effect
  case 'bill_correction_recorded':
    reverse the latest, apply the corrected
```

Invariant: `byParty[p].balance == Σ byBill[b for b's party == p]`
at all times. Property-based test enforces.

### Cash on hand

```
empty = { onHand: 0, sessions: new Map(), activeSessionId: null }

apply(state, event):
  case 'cash_session_opened':
    activeSessionId = sessionId
    sessions[sessionId] = { opening: openingCount, activity: 0 }
    onHand += openingCount
  case sale (any):
    onHand += payment.cash
    sessions[active].activity += payment.cash
  case 'expense_recorded':
    onHand -= payment.cash
    sessions[active].activity -= payment.cash
  case 'withdrawal_recorded':
    onHand -= payment.cash
    sessions[active].activity -= payment.cash
  case 'outstanding_payment_received':
    onHand += payment.cash
  case 'outstanding_payment_made':
    onHand -= payment.cash
  case 'cash_session_closed':
    sessions[sessionId].closingCount = payload.closingCount
    sessions[sessionId].mismatch = payload.mismatch
    onHand -= sessions[sessionId].opening + sessions[sessionId].activity
              // drawer is reconciled to baseline; net effect = the close amount
    activeSessionId = null
```

Invariant C1: `expectedClosing == opening + activity`. The close
event's payload must satisfy this; if not, schema rejects.

### History (bills)

A simple ordered list of `BillRow` constructed from sale events,
joined to their void / correction chains and to their print
status. Sort: most recent first by `at`. Pagination cursor: event
`id` (UUID v7 is sortable).

### Today summary

Filter all money events to `[today-start, today-end]` in the
shop's configured timezone. Reduce to the documented shape.
Identical reducer to **Period reports** with `range = today`.

### Period reports

```
input = (events filtered to [from, to])

output = {
  totalSales:       Σ sale grandTotals - Σ correction reversals - Σ void reversals
  totalPurchases:   Σ purchase grandTotals (corrected/voided handled identically)
  totalExpenses:    Σ expenses where kind == 'business'
  cashFlowProfit:   totalSales - totalPurchases - totalExpenses - withdrawals + paymentsReceived - paymentsMade
                    // exact formula carried over from v1 PeriodMath; tests assert byte equality
  wholesaleRealizedProfit: Σ over wholesale sales of (grandTotal - cogs at moving-average rate at sale time)
  withdrawals:      Σ withdrawal amounts
  paymentSplit:     { cash, online, due } summed over all sales
}
```

Cross-page invariant (R4): Today / Finance / Reports / Analytics
for any range they all render must produce identical numbers.
Enforced by an invariant test that runs the same reducer once and
compares the three callers' outputs.

### Analytics

`Array<{ bucket: IsoDate; ...periodReportFields }>`. Buckets are
day / week / month depending on UI selection. Each bucket is just
the period report applied to that bucket's range.

### Audit log

Every event, oldest to newest within the configured retention
window. Read-only for every role (A4). Rows expose `id, type, at,
by, summary` and a link to the raw event payload.

### Review Queue (unresolved)

```
unresolvedFlags = flag_raised.filter(f => !flag_resolved.exists(r => r.references contains f.id))
```

Sort: severity desc, then `raisedAt` desc.

### Print status per bill

For each `billId`:

- `latestAttempt = max(print_attempt by attemptNo)` for jobKind `first-print`
- `state` = `printed` if any `print_succeeded` for this billId
  exists else `failed` if latest attempt outcome is `failed` else
  `pending`
- Reprints are tracked separately under jobKind `reprint`, each
  with its own state.

### Reconciliation status

The reconciliation worker periodically:

1. Picks a window (default: yesterday, today, last 7 days).
2. Computes the canonical projection from events.
3. Compares to the cached / materialized projection.
4. For each drift, emits `flag_raised(rule: 'recon.projection-mismatch', severity: 'high')`.
5. Updates a small `reconciliationStatus` row: `lastRunAt`,
   `windowsChecked`, `driftsFound`.

This row is surfaced on the Diagnostics page (see
[`review-queue.md`](./review-queue.md)).

## Materialization strategy

For v2.0, the default is **client-side projections** with optional
caching:

- Projections are computed in the client from streamed events.
- A small per-projection cache (e.g. Today summary) lives in
  memory and is invalidated by any event that touches its inputs.
- The cache is verifiable by replaying; tests assert the cache
  equals the replay for every fixture.

Server-side materialization is an option for later if read load
demands it. The interface (`getProjection<T>(name, params)`) does
not change.

## Stale-detection

A projection is "stale" when:

- The events that should have produced it are present but the
  projection does not reflect them.
- The projection reflects events that are not present (cache
  corruption, replay bug).

Detection mechanisms, in order of preference:

1. **Subscription invalidation.** Each projection declares the
   event types it depends on. When a new event arrives, every
   dependent projection is invalidated synchronously.
2. **Periodic reconciliation.** The worker runs every N minutes
   (configurable; default `TODO(spec)`) and compares cache to
   replay.
3. **On-demand verification.** Any UI page can request a fresh
   replay for the section it shows; useful for the brother's
   "double-check" flow.

When stale is detected, the cache is rebuilt from events without
user action. A `recon.projection-mismatch` flag is raised so the
brother sees it happened.

## Rebuild process

A rebuild reads every event in `[genesis, now]` for the shop,
folds through `apply`, and writes the resulting state. This is
the safest operation in the system because it cannot corrupt
events (read-only over the source). It is the recovery path for
any cache or materialized-view corruption.

For projections with very large input event counts, snapshotting
is allowed (`projectionSnapshot` row + replay from snapshot
onward). Snapshots are tagged with the latest event id they
include; replay starts strictly after.

## Tests this spec requires

- For each projection × each scenario fixture: replay produces
  exactly the documented expected values.
- For each projection: random shuffle of commutative event subset
  produces identical final state.
- For each projection: invalidation correctly rebuilds after every
  affecting event type.
- For each projection: snapshot + replay-from-snapshot equals
  full replay.
- Across projections: R1–R4 invariants hold for every fixture.
- Rate history: a sequence of `item_rate_changed` + purchase + sale
  events for one item yields a chronological `RatePoint[]` with the
  correct `master-set` / `buy` / `sell` kinds; a later rate change
  appends a new point and does **not** alter earlier points or any
  historical bill's re-fold (rate-as-of-T holds).
- Performance: full rebuild for the shop's expected 2-year volume
  completes within the budget in
  [`performance-budgets.md`](./performance-budgets.md).

## Recent changes

- _2026-06-16_ · Added the **Rate history per item** projection
  (sources: `item_rate_changed` master set-points plus transacted
  `buy` / `sell` rates from purchase and sale lines), giving v2 an
  event-sourced home for tracking an item's price over time and
  carrying forward v1's Analytics "Rate Trends" — which the
  projection catalogue previously lacked. Added a required test. The
  exact view shape depends on finalizing the `item_rate_changed`
  schema (`TODO(spec)` in `event-schemas.md`).
