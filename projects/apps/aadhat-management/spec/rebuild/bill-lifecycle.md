# Bill lifecycle — rebuild

## The invariant

> **One user intent = one bill. Forever.**
>
> A bill creation action — no matter how many times the user taps,
> how slow the Bluetooth printer is, how many retries the offline
> queue performs, or how many tabs are open — must result in exactly
> one sale event with one bill number. Printing is a separate
> concern and can happen zero or many times against the same bill
> without ever creating another sale.

This is the single biggest correctness bug in the v1 app and the
owner has called it out explicitly. The rebuild enforces it by
construction.

## States

```
                      ┌────────────┐
                      │   draft    │  (autosave while user is editing)
                      └─────┬──────┘
                            │  user taps "Save / Create"
                            ▼
                      ┌────────────┐
                      │  created   │  (event in ledger, bill number assigned)
                      └─────┬──────┘
                            │  print requested (auto or manual)
                            ▼
                ┌─────────────────────────┐
                │     print_pending       │ ◀──────┐
                └─────────┬───────────────┘        │
                          │                        │
              ┌───────────┴──────────┐             │
              ▼                      ▼             │
        ┌──────────┐           ┌──────────┐        │
        │ printed  │           │print_fail│ ───────┘
        └────┬─────┘           └────┬─────┘   user taps "Retry print"
             │ user taps "Reprint"  │
             ▼                      │
        ┌──────────┐                │
        │reprint_  │ ───────────────┘
        │pending   │
        └──────────┘

   (anywhere)                       (anywhere except draft)
        │                                  │
        │ user taps "Void"                 │ user records correction
        ▼                                  ▼
   ┌──────────┐                       ┌───────────────────┐
   │  voided  │                       │ corrected         │
   │ (event)  │                       │ (correction event │
   └──────────┘                       │  references this) │
                                      └───────────────────┘
```

States `printed`, `print_pending`, `print_failed`, `reprint_pending`
are all read off the print queue's view of the bill. The bill itself
remains `created` (or `voided` / `corrected`) at the ledger level —
print state is not a property of the sale.

### The `draft → created` transition runs the suspicion pre-check

On **Save / Create**, before the sale event is appended, the
cashier-facing suspicion rules run as a client-side **advisory
pre-check** (rate sanity, discount, zero-rate, stock-negative). If a
line trips one, an inline confirm appears — *"…rate is unusually low;
Fix or Save anyway?"* — and **Save anyway proceeds and records the
flag**, never skips it (a `block` rule refuses the save, with an
owner-approval override). The server re-runs the engine and appends
the authoritative `flag_raised` in the same transaction. The full
contract is in [`suspicion-engine.md`](./suspicion-engine.md) §When
and where a flag surfaces.

## Idempotency

### When the idempotency key is generated

- The UI generates a `clientActionId` (UUID) the instant the user
  opens the bill form and stores it with the draft. Every save
  attempt from this form instance carries the same `clientActionId`.
- The application service translates `clientActionId` into the
  event's `idempotencyKey`.

### What "double tap on Save" must do

1. First tap fires `createBill({ ..., clientActionId: X })`.
2. While the request is in flight, the Save button enters a
   disabled `Saving…` state. The form does not accept another tap.
3. If the user somehow fires a second call (network retry, second
   tab, restored from background) with the same `clientActionId`,
   the service detects the existing event and returns the same
   result. **No second sale event is appended.**
4. The History list shows one bill, with the bill number assigned
   at first append.

### What "double tap on Print" must do

1. First tap enqueues a `print_job` with key
   `(billId, jobKind: 'first-print')`.
2. The Print button becomes `Printing…` while the job is in any
   state other than `printed` or `print_failed`.
3. A second tap before the job completes is a no-op (queue dedupes
   on the key).
4. After failure, the button becomes `Retry print`. Tapping it
   enqueues a new attempt under the same job key, incrementing
   `attemptNo`. A `print_attempt` event is recorded for the audit.
   **No sale event is created or modified.**
5. Explicit reprint (long-press, or "Reprint" menu item) creates a
   new job under key `(billId, jobKind: 'reprint', n)` for the n-th
   reprint. Each is its own audit row, none is a sale.

## Bill numbering

- Bill numbers are assigned by the storage adapter via a
  transactional counter on append of the sale event, keyed by
  `(shopId, billDate, billType)`. This is the v1 contract and it
  carries over.
- If the same `idempotencyKey` is appended twice, the counter
  advances zero times — the existing number is returned.
- Voided bills do not roll back the counter. The number stays
  assigned to the voided event; the audit trail makes it visible.
- `TODO(spec)`: Confirm whether corrections reuse the original bill
  number (recommended) or get a new one. Default assumption:
  reuse, with a `rev` suffix shown in print.

## Draft autosave

- The form autosaves locally (IndexedDB or equivalent) on a debounce
  and on every focus-out. The draft carries the same `clientActionId`
  as the eventual save.
- Drafts are local-device only by default. They are not synced to
  the server, so closing the tab on one device does not leave a
  draft visible on another.
- `TODO(spec)`: Decide whether drafts should sync per user for
  resume-on-another-device. Off by default in v2.0.

## Voiding

- A void appends a `bill_voided` event referencing the original
  `billId` with a mandatory `reason`.
- Projections that depend on the bill (stock, outstanding, cash,
  reports) recompute as if the original were not present, but the
  event log still shows both.
- Permission: staff cannot void without owner approval. The action
  either requires the owner role at the time of execution, or
  enqueues an approval request that the brother/owner clears from
  the Review Queue. `TODO(spec)`: pick one before M0; default
  assumption is approval-required.

## Correction (instead of edit)

- An edit to a saved bill is forbidden as a direct mutation. It is
  expressed as a `bill_correction_recorded` event whose payload is
  the corrected bill, referencing the original `billId`.
- Projections always use the latest correction in the chain.
- The print queue treats a correction as a new printable artifact;
  the previous print remains in the audit trail.

## What the UI must never do

- Must not call the storage adapter directly to append a sale event
  without going through the application service that owns
  idempotency.
- Must not enable the Save button after the first tap until the
  service call resolves (success or failure).
- Must not generate the bill number client-side.
- Must not treat a print failure as a reason to roll back the sale.
- Must not let any UI state machine count print attempts as bills.
- Must not show the bill in History before the service call returns
  success. Optimistic UI is allowed within the bill form itself,
  but the History row appears only once the event is in the ledger.

## What the print queue must never do

- Must not append a sale event under any circumstance.
- Must not retry a job in a way that creates a second job under the
  same job key.
- Must not silently drop a job. A job that exhausts retries
  transitions to `print_failed` and raises a `flag_raised` to the
  Review Queue.

## Tests this spec requires

(see `quality-bar.md` for the full test plan; these are the must-
exists)

- Rapid-double-tap on Save creates exactly one sale event.
- Tap Save → kill network mid-request → reconnect → outbox replay
  creates exactly one sale event.
- Tap Save → close tab before response → reopen app: bill exists
  iff the server saw the write; client draft reflects unsaved iff
  it did not.
- Tap Print while printer disconnected; tap Print again; reconnect:
  exactly one printout, two `print_attempt` audit rows.
- Tap Print, wait for failure, tap Retry: exactly one printout
  total, all attempts in audit.
- Long-press / Reprint after success: two printouts total, no
  second sale.
- Void after print: sale gone from projections, original event and
  void event both in log, print history preserved.
- Correction after print: latest values in projections, full chain
  in log, print history shows both originals and corrections.
