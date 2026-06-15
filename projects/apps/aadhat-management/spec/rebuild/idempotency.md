# Idempotency — rebuild

> Mechanical, line-by-line spec for the "one user intent = one
> bill, forever" guarantee in [`bill-lifecycle.md`](./bill-lifecycle.md).
> This file is what the storage adapter, application services, and
> outbox replay all code against.

## Key generation

### When the key is generated

| Action | When the `clientActionId` is created | Where it lives |
|---|---|---|
| Open a bill form | First render of the form for this draft | In the form's local state and in IndexedDB draft row |
| Open the items page → "new item" | First render of the new-item form | Form local state |
| Start cash session open / close | First render of the cash sheet | Form local state |
| Adjust stock | First render of the adjustment form | Form local state |
| Settle outstanding | First render of the settlement form | Form local state |
| Resolve a flag | First render of the resolution dialog | Dialog local state |
| Print request | At enqueue time on the queue, derived from `(billId, jobKind, ordinal)` | Print queue table |

### How `clientActionId` becomes `idempotencyKey`

```
idempotencyKey = `${eventTypeNamespace}:${stableKeyMaterial}`
```

Stable key material per event type is defined in
[`event-schemas.md`](./event-schemas.md). Most of them are
`${typeNamespace}:${clientActionId}`. A few (cash close,
correction, void) include a stable domain identifier instead.

Examples:

| Event type | `idempotencyKey` |
|---|---|
| `retail_sale_created` | `bill.create:${clientActionId}` |
| `wholesale_sale_created` | `bill.create:${clientActionId}` |
| `purchase_recorded` | `bill.create:${clientActionId}` |
| `bill_voided` | `bill.void:${originalBillId}` |
| `bill_correction_recorded` | `bill.correct:${originalBillId}:${correctionHash}` |
| `cash_session_opened` | `cash.open:${clientActionId}` |
| `cash_session_closed` | `cash.close:${sessionId}` |
| `stock_adjustment_recorded` | `stock.adjust:${itemId}:${clientActionId}` |
| `outstanding_payment_received` | `settle.in:${clientActionId}` |
| `flag_resolved` | `flag.resolve:${flagId}` |
| `print_attempt` | `print.attempt:${jobId}:${attemptNo}` |

### Uniqueness scope

A key is unique within `(shopId, eventTypeNamespace)`. The
storage adapter rejects an append whose `(shopId, type, idempotencyKey)`
already exists with a different payload (see
**Conflict-on-different-payload** below).

## Lifetime of the key

| State | Retention |
|---|---|
| In the form's local state | Until form is closed (committed or abandoned) |
| In an IndexedDB draft row | Until the bill is committed or the draft is explicitly discarded |
| In the outbox | Until the server confirms the write |
| In the event ledger (as the appended event's `idempotencyKey`) | Forever |

The key is never reused for a different intent.

## What happens when…

### …the user double-taps Save

1. Tap 1 fires `createBill({ ..., clientActionId: K1 })`. UI
   disables Save and shows `Saving…`.
2. Tap 2 (≤ 200 ms later) is blocked by the disabled state. **Spec
   level guarantee:** the disabled state is not the only line of
   defense. If tap 2 somehow fires (browser race, programmatic
   click, restored from history), the service still de-dupes
   because the key is the same.
3. Adapter sees the in-flight write or the just-completed one;
   returns the same `eventId`. No second sale event is appended.

### …the user is offline and creates a bill

1. Service writes to the outbox under key `bill.create:K1`.
2. Service returns `{ billId, status: 'pending', flags: [] }` to
   the UI. Optimistic UI shows the bill in the form as saved.
3. On reconnect, the outbox replay sends the same payload with the
   same key. Adapter appends one event.
4. If reconnect happens after the user thinks they re-tried (e.g.
   they reopened the app and the form was restored from draft and
   they tapped Save again), the outbox dedupes on `(shopId, type,
   key)` before sending. Worst case the server sees two requests
   with the same key — it returns the same `eventId` both times.

### …the user closes the tab mid-request

1. The HTTP request may or may not reach the server.
2. The outbox is updated with the pending write before the request
   fires, so even after a kill the outbox replay will retry on
   next launch with the same key.
3. If the server did receive the first request, the second is a
   no-op.
4. If the server did not, the second appends one event.
5. The bill is in History exactly once.

### …the same key arrives with a **different** payload

This is a **conflict** and signals a bug or tampering. Adapter
behaviour:

1. The append is rejected with `IDEMPOTENCY_CONFLICT`.
2. A `flag_raised(rule = 'bill.idempotency-mismatch', severity =
   'block')` is appended by the engine.
3. The UI shows the user: "This action was already submitted with
   different details. Refresh and try again."
4. Storage adapter records the rejected payload in a quarantine
   collection for forensic review (not in the main ledger).

### …the app is killed mid-print and restarted

1. Print queue is persistent; jobs are not lost on restart.
2. Worker resumes from the oldest non-terminal job.
3. The `(billId, jobKind, ordinal)` key prevents enqueuing a
   duplicate of the still-running job.
4. The printer side cannot be made strictly idempotent (ESC/POS
   has no echo). The worker tracks `payloadHash` per attempt and
   raises `print.repeated-failures` and `print.many-reprints`
   flags so the brother sees if a customer might have received two
   copies.

### …print succeeds but server sync of the `print_succeeded` event
fails

1. The print queue records the success locally and queues the
   event for sync.
2. On reconnect, the event syncs with the same key as if it had
   gone first time.
3. The History row shows `printed` once locally, then again once
   confirmed remotely; no UI flicker because the projection
   prefers the most recent local value.

### …two devices try to write the same intent at the same time

Not supported in v2.0 (`TODO(spec)`: confirm). If it happens
anyway:

1. Whichever request reaches the adapter first wins.
2. The other gets `IDEMPOTENCY_CONFLICT` and the user is told the
   write already happened on another device.
3. A `flag_raised(rule = 'bill.duplicate.window', severity =
   'medium')` is added as belt-and-braces if the second payload
   was identical (then it's safe; just a sync race).

### …a correction is filed twice with the same intent

1. The first correction succeeds with key
   `bill.correct:B1:hash1`.
2. A second attempt with the same diff produces the same `hash1`,
   the same key, and is deduped — no second correction event.
3. A second attempt with a different diff produces `hash2` and is
   a new, valid correction event referencing the latest version.

### …a void is filed twice

1. The first succeeds with key `bill.void:B1`.
2. The second is deduped — same key, same payload. No second event.
3. If the second carries a different `reason`, that is treated as
   `IDEMPOTENCY_CONFLICT` because the payload differs and the user
   is told to refresh.

## Storage adapter contract

```ts
interface AppendResult {
  status: 'appended' | 'duplicate' | 'conflict' | 'rejected';
  eventId: string;        // present when status is 'appended' or 'duplicate'
  errorCode?: AdapterErrorCode;
  errorMessage?: string;
}

function append(
  envelope: EventEnvelope
): Promise<AppendResult>;
```

Behaviour:

- `appended` — first time this `(shopId, type, idempotencyKey)`
  was seen. Returns the new `eventId`.
- `duplicate` — same key and **identical payload** as a prior
  event. Returns the existing `eventId`. This is a success from
  the caller's perspective.
- `conflict` — same key but **different payload**. Rejects.
  Returns `errorCode = 'IDEMPOTENCY_CONFLICT'`.
- `rejected` — any other validation / permission / invariant
  failure. Returns the appropriate `errorCode`.

## Payload-equality rule

"Identical payload" means after schema normalization:

- ordering of object keys is irrelevant
- whitespace inside free-text fields is normalized
- `at` is the only envelope field that may differ between the
  duplicate and the original (it's server-assigned at first
  append; never overwritten on subsequent dedup)
- floating-point comparison is irrelevant because money is integer
  paise; weights as decimal kg are compared after rounding to 3
  d.p.

Anything else differing → conflict.

## Tests this spec requires

- Adapter unit test: append, dedupe identical, conflict on
  different, conflict on different `reason`, conflict on different
  `lines`, normalization of key ordering.
- Service test: rapid double-call resolves to one event, returns
  same eventId.
- Outbox test: offline write + online replay = one event.
- E2E (Playwright): double-tap Save under throttled network = one
  bill in History.
- E2E: kill tab mid-request, reopen, one bill in History.
- E2E: same form opened in two tabs, both Save → conflict surfaced
  to the second tab.
- Property-based: arbitrary sequence of duplicate/non-duplicate
  appends, asserted unique by key.

## What never happens

- A `bill.create` key is reused for a different `eventTypeNamespace`.
- An idempotency key is constructed from server-only data (e.g.
  server timestamps) — that would defeat client-driven dedup.
- The dedup window expires. Keys live as long as the events do.
- A service "decides" the key on retry by hashing the current
  payload — the key is whatever the original form generated, not
  whatever the retry sees.
