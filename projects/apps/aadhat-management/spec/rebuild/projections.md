# Projections — rebuild

> Contract for values derived from the event ledger. Stock, cash, outstanding, history, reports, audit, and Review Queue are folds over events, not authoritative stores.

## Projection rules (apply to all)

1. **Fold only.** `projection = events.reduce(apply, emptyState)`; `apply` is pure and lives in `domain`.
2. **Replay wins.** Cached/materialized mismatch means rebuild from events.
3. **No event writes.** Projections consume events only.
4. **Deterministic.** Same input events produce same projection; property tests enforce.
5. **Commutative where safe.** Disjoint-key operations may reorder; same-key corrections are ordered by `references`.

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

Stale-detection: none; recompute on every read in v2.0.

### Rate history per item

Tracks configured sell-rate set-points and transacted buy/sell rates. Replaces v1 Analytics Rate Trends; see [`../page-specs/11-analytics.md`](../page-specs/11-analytics.md) §Rate Trends.

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

Reads: item-detail screen shows master-set step chart with reason on hover, plus optional transacted buy/sell points over 7 / 30 / 90-day window. Margin compression is read from this series. Series is append-only; corrections append `item_rate_changed`.

Stale-detection: none; recompute on read in v2.0.

- `TODO(spec, blocks: M2)` — Should rate history use one merged projection instead of separate master-rate/transacted-rate views, which retention/windowing applies for high-volume items, and should purchase-implied buy rate also raise `master-set`? **Default:** none agreed.

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

Rebuild: full replay from genesis. Daily reconciliation compares replay with cache and raises `recon.projection-mismatch` (high) on drift.

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

Invariant: `byParty[p].balance == Σ byBill[b for b's party == p]` always; property-based test enforces.

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

Invariant C1: `expectedClosing == opening + activity`; close event payload must satisfy it or schema rejects.

### History (bills)

Ordered `BillRow` list from sale events joined to void/correction chains and print status. Sort most recent first by `at`. Pagination cursor: event `id` (UUID v7 sortable).

### Today summary

Filter money events to `[today-start, today-end]` in shop timezone. Use the Period reports reducer with `range = today` and output documented shape.

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

Cross-page invariant R4: Today / Finance / Reports / Analytics render identical numbers for any shared range; invariant test runs one reducer and compares callers.

### Analytics

`Array<{ bucket: IsoDate; ...periodReportFields }>`; buckets are day / week / month. Each bucket is the period report for that range.

Forward-looking/comparative insights and event inputs are in [`analytics.md`](./analytics.md). Analytics reads projections only and never owns an authoritative total (`M5`, `R4`).

### Audit log

Every event, oldest to newest within configured retention window. Read-only for every role (A4). Rows expose `id, type, at, by, summary` and raw-payload link.

### Review Queue (unresolved)

```
unresolvedFlags = flag_raised.filter(f => !flag_resolved.exists(r => r.references contains f.id))
```

Sort: severity desc, then `raisedAt` desc.

### Print status per bill

For each `billId`:

- `latestAttempt = max(print_attempt by attemptNo)` for jobKind `first-print`
- `state` = `printed` if any `print_succeeded` for this billId exists else `failed` if latest attempt outcome is `failed` else `pending`
- Reprints are tracked separately under jobKind `reprint`, each with its own state.

### Reconciliation status

Worker picks window (yesterday, today, last 7 days), computes canonical projection from events, compares against cached/materialized projection, emits `flag_raised(rule: 'recon.projection-mismatch', severity: 'high')` per drift, and updates `reconciliationStatus`: `lastRunAt`, `windowsChecked`, `driftsFound`.

Diagnostics page surfaces this row; see [`review-queue.md`](./review-queue.md).

## Materialization strategy

v2.0 default: client-side projections with optional caching. Client computes projections from streamed events. Small per-projection caches, e.g. Today summary, live in memory and invalidate on any input event. Tests assert cache equals replay for every fixture.

Later server-side materialization may be added without changing `getProjection<T>(name, params)`.

## Stale-detection

Stale means the projection misses present events or reflects absent events.

| Mechanism | Rule |
|---|---|
| Subscription invalidation | Each projection declares input event types; new event synchronously invalidates dependent projections |
| Periodic reconciliation | Worker runs every N minutes, configurable in [`configuration.md`](./configuration.md), and compares cache to replay |
| On-demand verification | UI page may request fresh replay for its visible section |

On stale detection, rebuild cache from events and raise `recon.projection-mismatch`.

## Rebuild process

Read every shop event in `[genesis, now]`, fold through `apply`, and write state. Source events are read-only. For large inputs, `projectionSnapshot` is allowed; snapshots store latest included event id, and replay starts strictly after it.

## Tests this spec requires

| Test area | Requirement |
|---|---|
| Projection × scenario fixture | Replay matches documented expected values |
| Projection commutativity | Random shuffle of commutative subset preserves final state |
| Projection invalidation | Rebuilds after every affecting event type |
| Snapshot replay | Snapshot + replay-from-snapshot equals full replay |
| Cross-projection invariants | R1–R4 hold for every fixture |
| Rate history | `item_rate_changed` + purchase + sale sequence yields chronological `RatePoint[]` with correct `master-set` / `buy` / `sell`; later rate change appends and does not alter earlier points or historical bill re-fold |
| Performance | Full rebuild for expected 2-year volume meets [`performance-budgets.md`](./performance-budgets.md) |
