# Concurrency — rebuild

> Multi-device contract. Even with one staff phone today, the
> shop will grow into "owner has a phone too", "second counter
> on a tablet", "brother reviews on his laptop". This file says
> what happens when two devices act at the same time on the same
> data, what is rejected, what is reconciled, and what is left
> for human review.

## Why this doc exists

[`offline-sync.md`](./offline-sync.md) §Conflict handling
already has the matrix for **the most common races** (duplicate
idempotency key, two devices editing an item, two devices
settling the same outstanding, two devices opening cash
sessions). [`idempotency.md`](./idempotency.md) covers the
key shape. [`invariants.md`](./invariants.md) C3 says "one
active cash session per shop".

This file consolidates the **rules that those docs assume but
don't state in one place**:

1. What "active" means for a cash session — per shop, per
   device, per user.
2. How bill numbers are allocated so two devices never collide.
3. What rate an item bill uses when the rate is edited
   mid-billing.
4. What happens when a concurrent wholesale sale would push
   stock negative.
5. The default reconciliation rule when no specific row above
   applies.

The principle:

> One source of truth (server). One winner per write. No silent
> overwrites. Every loss surfaces in the Review Queue.

## Active cash session — one per shop

Per [`invariants.md`](./invariants.md) C3, **a shop has at most
one open cash session at any time**. Not per device, not per
user — **per shop**.

- The "open" check is on `(shopId, sessionState = open)` on
  the server.
- A device tries to open a session: server checks the
  invariant; if another is open, the open is rejected with
  `BLOCKED_BY_RULE`, the device's UI shows "A session is
  already open from {deviceName} ({userName})", and a
  `session-open-conflict` low-severity flag is raised so the
  brother sees the attempt.
- A session can be **closed from any device**, regardless of
  which device opened it. The close event records the closing
  user; that may differ from the opening user (e.g. owner
  closes a session staff opened and walked away from).
- An offline open is allowed (per
  [`offline-sync.md`](./offline-sync.md)) but is reconciled at
  sync: if the server already has an open session, the
  offline-opened one is rejected with `BLOCKED_BY_RULE` and the
  device is asked to fold its offline events into the
  already-open session if the cash-on-hand math allows.

A consequence: cash on hand is **shop-wide**, not device-local.
Two devices reading "cash on hand" see the same number because
both read the same projection.

## Bill number allocation — server-side counter

Per [`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md)
row 5's open question M5: bill numbers are per-shop, monotonic,
transactionally allocated server-side.

The contract:

- The storage adapter allocates the next bill number in the
  same transaction that appends the sale event. There is no
  "reserve then commit" — the number lives only after the
  event commits.
- Online: the device asks the server for the number and
  receives it in the same round trip as the sale append.
- Offline: the device allocates a **provisional** number from
  a pre-issued block in `shopProfile.billNumber.offlineBlock`
  (default 50 numbers per device). The bill carries an
  `offline-issued` badge until reconciled.
- On reconnect, the device sends the sale event with the
  provisional number; the server **accepts the provisional
  number** if it is still inside the device's pre-issued block
  AND no other bill has the same number. If a collision is
  found (two devices issued the same offline number), the
  server rejects the later arrival with `BLOCKED_BY_RULE`; the
  losing device re-issues under a fresh server-assigned number
  and the user sees "Bill number changed — confirm reprint".
- A pre-issued block is bound to `(shopId, deviceId)`. Blocks
  are non-overlapping by construction (allocator gives device A
  numbers 100–149 and device B numbers 150–199).
- Voided bill numbers are **never** reused (per
  [`invariants.md`](./invariants.md) B5).

The number is part of the printed bill and the human-readable
identifier; the `billId` (UUID) is the machine identifier and
is allocated by the device at intent time.

## Idempotency keys under concurrency

Per [`idempotency.md`](./idempotency.md):

- Same key, identical payload → server returns `OK (deduped)`;
  no second event in the log.
- Same key, different payload → server returns
  `IDEMPOTENCY_CONFLICT`; **both** payloads are surfaced in
  the Review Queue under a `dedup.conflict` flag; the owner
  picks which one wins, and the loser is voided in the same
  transaction the resolution happens.

Why this matters under concurrency: a device that loses
connection between send and ack, then retries, will use the
same key. The server's idempotent ack closes the gap. A
**different** device building the same intent (e.g. staff
re-bills the customer on another phone after the first phone
froze) generates a **different** key by construction (the key
includes `clientActionId` which is a device-local UUID per
intent). So the "different payload, same key" path is rare and
indicates a bug — that is why it surfaces for human review
rather than auto-resolving.

## Two devices settle the same outstanding

Already covered by [`offline-sync.md`](./offline-sync.md)
§Conflict handling row "Two devices receive the same outstanding
payment" and [`invariants.md`](./invariants.md) O1.

The expanded rule:

- The settle event carries `references.outstandingBalanceAtIntent`
  (the balance the device thought it was settling against).
- Server applies the settle and checks the projection: if the
  resulting balance would be negative (O1 violation), the
  second device's settle is rejected with `INVARIANT_VIOLATION`.
- The rejected device sees: "This outstanding was already
  settled. Open the party detail to see the latest payment."
- If the owner **wants** to record an overpayment, that is a
  separate event type (`overpayment_recorded`) with explicit
  intent; the system does not silently convert a failed
  settlement into one.

## Item master edit while billing

Already covered by [`offline-sync.md`](./offline-sync.md)
§Conflict handling row "Two devices edit the same item master
row". The expanded rule for the **billing-while-editing** case:

- A bill that is in progress on Device A captures the item's
  rate at **intent time** (when the line was added or rate
  refreshed). The rate is snapshotted into the line.
- If Device B edits the item's rate while Device A is still
  composing the bill, Device A's bill **commits with the rate
  it captured**, not the latest server rate. The committed
  sale event's payload carries the resolved rate.
- The next bill on Device A reads the new rate (because the
  item picker re-fetches when an item is added).
- The history of a bill always replays to the same total
  because the rate is in the event payload (per
  [`data-governance.md`](./data-governance.md) §Rate change
  history).
- If Device B's edit is to an item Device A has already added
  to the bill and Device A explicitly refreshes the line, the
  refresh raises a confirm: "Rate changed from ₹X to ₹Y. Use
  new rate?".

The forbidden behaviour: silently re-pricing an in-progress
bill when the server rate changes. The staff agreed to ₹X with
the customer; ₹X is what the bill records.

## Concurrent wholesale sale that would push stock negative

- Each wholesale sale event carries
  `references.itemStockAtIntent` — the stock the device read
  when adding the line.
- Server applies the sale and checks the projection.
- If the post-apply stock would be negative AND
  `references.itemStockAtIntent ≥ qty`, this means another
  sale slipped in between Device A's read and Device A's
  commit. The sale is **accepted** (per
  [`invariants.md`](./invariants.md) S2: stock can go negative
  with an explicit flag) AND a `stock-race-negative` flag is
  raised so the brother sees the contention.
- If the device wants to **block** the negative path (e.g. for
  a customer who needs to know whether to wait or not), the UI
  can pre-flight a check before commit; the pre-flight is
  advisory only. The server is still the arbiter.
- A `stock_adjustment_recorded` event is the explicit path for
  the brother to acknowledge or correct.

This is intentionally permissive: the shop doesn't want a sale
blocked because of a millisecond race when the stock is in
fact present (the brother might just need to reconcile a
mis-counted item). Flagging instead of blocking keeps the bill
flowing.

## Default reconciliation rule

For every concurrency case not listed in this file or in
[`offline-sync.md`](./offline-sync.md) §Conflict handling:

1. First-server-commit wins. No "last-write-wins" is permitted
   anywhere.
2. The losing write is rejected with the appropriate adapter
   code (`OUT_OF_ORDER`, `INVARIANT_VIOLATION`,
   `BLOCKED_BY_RULE`).
3. The losing device's row goes to `Needs review` (per
   [`offline-sync.md`](./offline-sync.md) state vocabulary).
4. A flag is raised so the owner / brother sees the conflict
   without having to find it.
5. Resolution is human (owner via Review Queue) or automatic
   (the device retries with current state on its next user
   action). Silent automatic merging is forbidden.

## What the storage adapter enforces

In addition to what [`time-clock.md`](./time-clock.md) §What
the storage adapter enforces lists:

- The C3 invariant (one open cash session per shop) is
  transactional. The check and the open append in the same
  transaction.
- Bill number allocation is in the same transaction as the
  sale append.
- Idempotency-key uniqueness is enforced by a unique index in
  the storage layer; second appends never partially succeed.
- Provisional bill numbers are validated against the
  device's issued block on append; out-of-block numbers are
  rejected.
- Outstanding balance non-negativity (O1) is checked in the
  same transaction as the settle.
- All adapter rejects produce one of the documented codes
  (`OK, SCHEMA_INVALID, INVARIANT_VIOLATION, PERMISSION_DENIED,
  REFERENCE_INVALID, IDEMPOTENCY_CONFLICT, BLOCKED_BY_RULE,
  OUT_OF_ORDER, UNAUTHORIZED`).

## Tests this spec requires

- `cash-session-second-open-blocked` — Device A opens, Device
  B tries to open, rejected with `BLOCKED_BY_RULE`; flag raised.
- `cash-session-close-from-different-device` — Device B
  closes the session Device A opened; close event records both
  users.
- `bill-number-server-allocated-online` — two devices send
  near-simultaneous sales; both receive distinct sequential
  numbers; no collision.
- `bill-number-offline-block-no-collision` — devices A and B
  pre-issued non-overlapping blocks; both create 50 offline
  bills; reconcile; no collision.
- `bill-number-offline-block-collision-handled` — collision
  is contrived (test harness re-uses a number); loser is
  rejected; user is asked to reprint with new number.
- `idempotency-conflict-different-payload-surfaces` — same
  key, different payload from two devices; both visible in
  Review Queue.
- `settle-race-second-rejected` — two devices settle the same
  outstanding; first wins; second `INVARIANT_VIOLATION`.
- `item-rate-edit-during-billing-bill-uses-snapshot` — Device
  B edits rate while Device A's bill is composing; Device A's
  bill commits with the snapshotted rate; replay matches.
- `stock-race-negative-accepted-flagged` — two wholesale
  sales race so the second pushes stock to −1; both accepted;
  `stock-race-negative` flag present.
- `losing-write-shows-needs-review-badge` — every rejection
  routes through the offline-sync state machine to `Needs
  review`.

## Open items

- `TODO(spec)` — exact pre-issued offline block size per
  device. Default: 50 numbers; revisit after pilot.
- `TODO(spec)` — should the C3 invariant (one open session per
  shop) be relaxed for a "multi-counter" shop in v2.1?
  Default: no, keep one session = one shop in v2.0; multi-
  counter is a v2.1 design item.
- `TODO(spec)` — overpayment event semantics. Default: explicit
  `overpayment_recorded` event with owner-only permission;
  out of scope for v2.0 unless the brother asks.

## Recent changes

- _2026-06-16_ · file created. Cash session is shop-wide (C3);
  bill numbers server-side allocated with device-bound offline
  blocks; rate-snapshot-at-intent for in-progress bills;
  concurrent-sale-into-negative-stock accepted-and-flagged
  per S2; default rule "first server commit wins, losing
  write surfaces in Review Queue"; storage-adapter contract
  consolidated; cross-references offline-sync.md conflict
  matrix and idempotency.md.
