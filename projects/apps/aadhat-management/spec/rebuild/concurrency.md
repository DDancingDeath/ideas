# Concurrency — rebuild

> Multi-device write contract: one server winner, no silent overwrites, every loss visible in Review Queue.

## Scope

Common race matrix: [`offline-sync.md`](./offline-sync.md) §Conflict handling. Idempotency key shape: [`idempotency.md`](./idempotency.md). One active cash session: [`invariants.md`](./invariants.md) C3.

This file adds rules for cash-session scope, bill numbers, rate snapshots, stock races, and default reconciliation.

## Active cash session — one per shop

Per C3, a shop has at most one open cash session: per shop, not per device or user.

| Case | Rule |
|---|---|
| Open check | Server checks `(shopId, sessionState = open)`. |
| Second online open | Reject with `BLOCKED_BY_RULE`; UI: `A session is already open from {deviceName} ({userName})`; raise `session-open-conflict` low-severity flag. |
| Close | Any device may close; close event records closing user, even if different from opener. |
| Offline open | Allowed per [`offline-sync.md`](./offline-sync.md); on sync, reject with `BLOCKED_BY_RULE` if server already has an open session, then ask device to fold offline events into the open session if cash math allows. |
| Cash on hand | Shop-wide projection shared by all devices. |

## Bill number allocation — server-side counter

Per [`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md) row M5, bill numbers are per-shop, monotonic, and transactionally allocated server-side.

| Case | Rule |
|---|---|
| Online | Allocate next bill number in the same transaction as sale append; device receives it in the append response. |
| Offline | Device uses a provisional number from `shopProfile.billNumber.offlineBlock`; default in [`configuration.md`](./configuration.md). Bill shows `offline-issued` until reconciled. |
| Reconnect accept | Server accepts provisional number only if inside that device's block and unused. |
| Reconnect collision | Reject later arrival with `BLOCKED_BY_RULE`; losing device re-issues under fresh server number; user sees `Bill number changed — confirm reprint`. |
| Block binding | Pre-issued blocks are bound to `(shopId, deviceId)` and non-overlapping, e.g. 100–149 vs 150–199. |
| Void | Voided numbers are never reused per [`invariants.md`](./invariants.md) B5. |

Blocks are per device, not per session: two devices sharing one cash session would otherwise allocate colliding numbers, breaking B5. Device-bound blocks cannot collide.

`billId` is a device UUID allocated at intent time; bill number is the printed human identifier.

## Idempotency keys under concurrency

Per [`idempotency.md`](./idempotency.md): identical payload + same key returns `OK (deduped)` with no second event. Different payload + same key returns `IDEMPOTENCY_CONFLICT`; both payloads surface under `dedup.conflict`; owner chooses winner and loser is voided in the same resolution transaction.

A retry after lost ack reuses the same key. A second device rebuilding the same sale gets a different key because `clientActionId` is device-local.

## Two devices settle the same outstanding

Covered by [`offline-sync.md`](./offline-sync.md) §Conflict handling and [`invariants.md`](./invariants.md) O1.

| Step | Rule |
|---|---|
| Intent | Settle event carries `references.outstandingBalanceAtIntent`. |
| Apply | Server applies settle and checks projection. |
| Negative result | Reject second settle with `INVARIANT_VIOLATION`. UI: `This outstanding was already settled. Open the party detail to see the latest payment.` |
| Overpayment | Only explicit `overpayment_recorded` can record overpayment; failed settlement is never converted silently. |

## Item master edit while billing

Covered by [`offline-sync.md`](./offline-sync.md) §Conflict handling; billing adds rate snapshot rules.

| Case | Rule |
|---|---|
| Line added/refreshed | Capture item rate at intent time into the bill line. |
| Another device edits rate | In-progress bill commits with captured rate, not latest server rate. |
| Next bill | Item picker re-fetches when item is added and reads the new rate. |
| Replay | Bill history replays to same total because rate is in event payload per [`data-governance.md`](./data-governance.md) §Rate change history. |
| Explicit refresh | If captured rate changed, confirm: `Rate changed from ₹X to ₹Y. Use new rate?`. |

Forbidden: silently repricing an in-progress bill when server rate changes.

## Concurrent wholesale sale that would push stock negative

| Condition | Result |
|---|---|
| Sale carries `references.itemStockAtIntent` | Server applies sale and checks projection. |
| Post-apply stock < 0 AND `references.itemStockAtIntent ≥ qty` | Accept sale per [`invariants.md`](./invariants.md) S2 and raise `stock-race-negative`. |
| UI wants pre-flight block | UI may check before commit; advisory only. Server remains arbiter. |
| Acknowledge/correct | Use `stock_adjustment_recorded`. |

## Default reconciliation rule

For cases not listed here or in [`offline-sync.md`](./offline-sync.md) §Conflict handling:

1. First server commit wins; last-write-wins is forbidden.
2. Losing write rejects with `OUT_OF_ORDER`, `INVARIANT_VIOLATION`, or `BLOCKED_BY_RULE`.
3. Losing device row becomes `Needs review` per [`offline-sync.md`](./offline-sync.md).
4. A flag is raised for owner/brother visibility.
5. Resolution is human in Review Queue or retry-with-current-state on next user action; no silent merge.

## Storage adapter enforcement

In addition to [`time-clock.md`](./time-clock.md) §What the storage adapter enforces:

- C3 one-open-session check and open append are transactional.
- Bill number allocation and sale append are one transaction.
- Idempotency-key uniqueness is enforced by a storage unique index; second appends never partially succeed.
- Provisional bill numbers are checked against the issued block; out-of-block rejects.
- O1 outstanding non-negativity is checked in the settle transaction.
- Adapter reject codes are limited to `OK, SCHEMA_INVALID, INVARIANT_VIOLATION, PERMISSION_DENIED, REFERENCE_INVALID, IDEMPOTENCY_CONFLICT, BLOCKED_BY_RULE, OUT_OF_ORDER, UNAUTHORIZED`.

## Tests this spec requires

- `cash-session-second-open-blocked` — Device A opens, Device B tries to open, rejected with `BLOCKED_BY_RULE`; flag raised.
- `cash-session-close-from-different-device` — Device B closes the session Device A opened; close event records both users.
- `bill-number-server-allocated-online` — two devices send near-simultaneous sales; both receive distinct sequential numbers; no collision.
- `bill-number-offline-block-no-collision` — devices A and B pre-issued non-overlapping blocks; both create 50 offline bills; reconcile; no collision.
- `bill-number-offline-block-collision-handled` — collision is contrived (test harness re-uses a number); loser is rejected; user is asked to reprint with new number.
- `idempotency-conflict-different-payload-surfaces` — same key, different payload from two devices; both visible in Review Queue.
- `settle-race-second-rejected` — two devices settle the same outstanding; first wins; second `INVARIANT_VIOLATION`.
- `item-rate-edit-during-billing-bill-uses-snapshot` — Device B edits rate while Device A's bill is composing; Device A's bill commits with the snapshotted rate; replay matches.
- `stock-race-negative-accepted-flagged` — two wholesale sales race so the second pushes stock to −1; both accepted; `stock-race-negative` flag present.
- `losing-write-shows-needs-review-badge` — every rejection routes through the offline-sync state machine to `Needs review`.

## Open items

- `TODO(spec, blocks: M5)` — Exact pre-issued offline block size per device? **Default:** 50 numbers; revisit after pilot.
- `TODO(spec, blocks: M8)` — Should C3 (one open session per shop) relax for a multi-counter shop in v2.1? **Default:** no; keep one session = one shop in v2.0.
- `TODO(spec, blocks: M7)` — Overpayment event semantics? **Default:** explicit `overpayment_recorded` event with owner-only permission; out of scope for v2.0 unless the brother asks.

