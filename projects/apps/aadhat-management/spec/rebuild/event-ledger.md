# Event ledger — rebuild

## Principle

> **Store what happened, derive what is.**
>
> Stock, cash, outstanding, reports, and audit trails are all
> projections of a single append-only event log. Numbers on the
> screen come from replaying events, not from rows that were edited
> in place.

This replaces v1's pattern of writing both the source row (a
purchase) and the affected aggregate (the stock row) and hoping they
stay in sync. In v2, the aggregate is computed; if it ever disagrees
with the events that produced it, the projection is wrong and gets
rebuilt — the events stay correct.

## Event types (v2.0, initial set)

Each event has: `id` (UUID v7), `type`, `at` (server timestamp),
`by` (userId), `shopId`, `idempotencyKey`, `payload`, and zero or
more `references` to prior events.

| Type | Payload (summary) | Affects |
|---|---|---|
| `item_created` | itemId, names, defaultRates, unit, isHeavy | item master |
| `item_updated` | itemId, changedFields | item master |
| `item_archived` | itemId, reason | item master |
| `purchase_recorded` | billId, party, lines[{itemId, weights[], rate}], labor, payment, billNumber, billDate | stock, outstanding, cash |
| `retail_sale_created` | billId, lines, payment, billNumber, billDate | outstanding, cash |
| `wholesale_sale_created` | billId, party, lines, payment, billNumber, billDate | stock, outstanding, cash |
| `bill_voided` | originalBillId, reason | reverses original |
| `bill_correction_recorded` | originalBillId, correctedPayload | replaces original |
| `stock_adjustment_recorded` | itemId, delta, reason | stock |
| `expense_recorded` | category, amount, kind (business/personal), payment | cash |
| `withdrawal_recorded` | amount, payee, payment | cash |
| `outstanding_payment_received` | party, amount, againstBillId?, payment | outstanding, cash |
| `outstanding_payment_made` | party, amount, againstBillId?, payment | outstanding, cash |
| `cash_session_opened` | sessionId, openingCount | cash |
| `cash_session_closed` | sessionId, closingCount, mismatch, mismatchReason? | cash |
| `print_attempt` | billId, attemptNo, outcome (queued / sent / failed), printerInfo | print queue (audit only) |
| `print_succeeded` | billId, attemptNo, printerInfo | print queue (audit only) |
| `flag_raised` | targetEventId, ruleId, severity, summary | Review Queue |
| `flag_resolved` | flagId, resolution (approve / dismiss / correct), by | Review Queue |
| `user_role_changed` | targetUserId, fromRole, toRole, by | auth / audit |
| `user_status_changed` | targetUserId, fromStatus, toStatus, by | auth / audit |
| `shop_profile_updated` | changedFields | config |

> `TODO(spec)`: Confirm the final event list before M0. The list
> above covers every v1 workflow; new event types may be added but
> must be justified in this file before implementation.

## Hard rules

1. **Append-only.** The store API exposes `append(event)` and
   `read(filter)`. There is no `update(event)` or `delete(event)`.
2. **No silent edits.** "Editing" an old transaction means appending
   a `bill_correction_recorded` event that references the original.
   The original event stays in the log.
3. **No silent deletes.** "Deleting" means appending a `bill_voided`
   event with a reason. The original event stays in the log.
4. **Idempotency key per logical action.** Each event carries an
   `idempotencyKey`. Re-issuing the same logical action with the
   same key is a no-op (returns the existing event). This is the
   guarantee that prevents duplicate sales from double-taps, retry
   sync, or replayed outbox queues.
5. **Server-assigned timestamps.** `at` is set by the storage
   adapter, not by the client clock, for any event that affects
   money or stock. Where the device is offline, the adapter records
   both client-claimed time and server-arrival time, and any gap
   beyond the configured tolerance raises a `flag_raised` via the
   suspicion engine.
6. **Causal references.** Correction, void, payment-against-bill,
   and flag-resolution events must reference the event(s) they
   relate to. Projections use these references to reconstruct
   chains.
7. **Authorization is recorded.** Every event carries the `by`
   userId at the time of write. The storage adapter rejects writes
   whose `by` does not match the authenticated principal.

## Read models / projections

The following are computed by folding events; they are never the
authoritative store of the number.

| Projection | Built from |
|---|---|
| Current item master | `item_*` events |
| Current stock per item | `purchase_recorded`, `wholesale_sale_created`, `stock_adjustment_recorded`, `bill_voided`, `bill_correction_recorded` |
| Current outstanding per party | sale + payment events that reference that party |
| Current cash on hand | open session + activity events − close events |
| Period reports (day / week / month) | filtered fold over money-affecting events |
| Bill history | sale + correction + void events, grouped by `billId` |
| Print status per bill | latest `print_attempt` / `print_succeeded` for `billId` |
| Audit log | every event, surfaced read-only |
| Review Queue | unresolved `flag_raised` events |

A projection rebuild from events is part of the test suite (see
`quality-bar.md`): for any scenario fixture, replaying events must
produce the expected projection values exactly.

## Retention

- Events are retained for the lifetime of the shop's account by
  default. The audit log surface filters to a configurable window
  (v1 default: 90 days; v2 default: same, configurable per shop).
- No event is ever expunged by app code without explicit owner
  action and an `event_retention_purged` event recording what was
  removed and why. `TODO(spec)`: agree retention model with owner
  before implementing purge.

## Migration from v1 data

`TODO(spec)`: Decide whether v1 production data is imported into
the v2 event log on cutover. Two candidates:

- **Snapshot import.** v1's final state becomes a synthetic
  `migration_snapshot` event at t=cutover. History before that is
  not queryable inside v2.
- **Replay import.** v1's purchases, sales, expenses, etc. are
  translated into v2 events in chronological order. Higher fidelity
  but more work; only worth it if the owner needs historical
  drill-down inside the new app.
