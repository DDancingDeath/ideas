# Print queue — rebuild

## Principle

> **The printer is the slowest, flakiest thing in the system. The UI
> must never wait on it.**
>
> A print job is a durable, persistent piece of work owned by a
> background worker. The UI subscribes to its status; it does not
> drive it. A bill exists the moment the sale event is in the
> ledger, regardless of whether the printer has acknowledged
> anything.

## Job shape

Each job has:

- `jobId` (UUID)
- `billId` (foreign key into the event log)
- `jobKey` (deduplication key — see below)
- `state`: `queued` | `connecting` | `sending` | `printed` |
  `failed` | `cancelled`
- `attempts[]`: each with `attemptNo`, `startedAt`, `finishedAt`,
  `outcome`, `printerInfo`, `errorCode?`, `errorMessage?`
- `createdAt`, `updatedAt`, `createdBy`
- `payload`: the ESC/POS bytes (or a recipe to regenerate them) and
  a content hash so we can detect drift if the bill is corrected

## Dedup keys

| Intent | Job key |
|---|---|
| Print this bill for the first time | `('first-print', billId)` |
| Retry the failed first print | reuses the existing job; increments `attemptNo` |
| Explicit reprint requested by user | `('reprint', billId, ordinal)` where `ordinal` is the n-th reprint |
| Reprint of a corrected bill | `('reprint', billId, ordinal)` with the corrected payload hash |

The queue rejects an enqueue that would create a duplicate of an
existing non-terminal job under the same key. It returns the
existing `jobId` instead. This is what makes double-tap on Print
safe.

## Worker behaviour

- Single worker per device. Multiple devices are not supported for
  the same printer in v2.0 (`TODO(spec)`: confirm).
- The worker drains the queue serially. While a job is in
  `connecting` or `sending`, no other job advances.
- Retry policy: bounded exponential backoff with a maximum retry
  count (`shopProfile.printer.maxRetries`, default `TODO(spec)`).
  After exhaustion, the job becomes `failed` and a
  `flag_raised(rule: 'print-exhausted', severity: 'medium')` event
  is appended.
- The worker writes a `print_attempt` event for every connect /
  send / fail boundary, and a `print_succeeded` event for the
  successful attempt. These are audit-only and never modify a sale.

## UI contract

- The bill row in History exposes its current print status by
  reading the job for `('first-print', billId)` and its reprints.
- The Print button on a bill cycles through:
  - `Print` — no job exists or all prior jobs are terminal and
    successful.
  - `Printing…` — current job is in `queued` / `connecting` /
    `sending`. Button is disabled.
  - `Retry print` — current job is `failed`. Tapping it does not
    create a new job; it asks the worker to retry the existing one.
  - `Reprint` — only after a previous job has succeeded. Tapping it
    creates a new `('reprint', billId, n+1)` job.
- The button never directly calls into the Bluetooth driver. It
  always goes through the queue.
- A small Diagnostics view shows the queue: current job, recent
  attempts, last error, printer connection status.

## Connection management

- The printer driver exposes `connect()`, `disconnect()`,
  `getStatus()`, `send(bytes)`.
- The worker tries to keep the connection warm during active hours
  (configurable) and reconnects with backoff on disconnect.
- Connect failures, send failures, and acknowledge timeouts all
  count as one failed attempt against the job, not as the job being
  done.
- The driver is mocked in all tests below the device-integration
  layer; only manual hardware smoke tests touch real hardware.

## Offline behaviour

- The queue persists across app restarts (IndexedDB / SQLite /
  equivalent).
- If the device is offline but the printer is on, the worker still
  prints — the queue is local.
- If the device is online but the printer is unreachable, the bill
  is still in the ledger and visible everywhere; the print just
  stays `queued` until the printer comes back.
- `TODO(spec)`: Decide whether `print_attempt` events sync to the
  server in real time or batch. Default: real time, with the same
  outbox path as other events.

## Tests this spec requires

(see `quality-bar.md` for the full plan)

- Slow Bluetooth: connecting takes 5 s; user taps Print 3 times.
  Exactly one job exists; one printout; three taps logged as UI
  attempts, one `print_attempt` event.
- Printer off: tap Print, wait for fail, tap Retry. Single job,
  two `print_attempt` events, one `print_succeeded` after retry.
- Reprint after success: two job rows, two `print_succeeded`, no
  duplicate sale events.
- App killed mid-print: queue persists, worker resumes on next
  launch, idempotent on the printer side as far as ESC/POS can be
  made so (best-effort; `TODO(spec)` how we mark a possible
  duplicate-print scenario for review).
- Bill corrected after print succeeded: new reprint job uses the
  corrected payload; old printout's hash is in audit.
- Voided bill: the queue cancels any non-terminal job for that
  `billId` and records the cancellation in audit.

## What must not happen

- A new sale created because the print failed. Ever.
- A new sale created because the user pressed Print twice. Ever.
- The UI thread blocking on `connect()` or `send()`.
- A job silently disappearing. Every terminal state has an event.
- A reprint of a corrected bill using the pre-correction payload.
