# Failure modes — rebuild

> Every scary real-world failure, the **expected behaviour** of
> the rebuild when it happens, and the **test** that proves the
> behaviour. If a failure mode is not in this list, treat that as
> a spec gap and open a `TODO(spec)`.

This file is the catalogue. The runbook for **what a human
does** about each failure lives in
[`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md).
This file says what the **system** does so the human has
something stable to operate on.

## Reading guide

For each failure:

- **Trigger** — the concrete situation.
- **Expected system behaviour** — events appended, projections
  updated, flags raised, UI state, recovery path.
- **Forbidden behaviour** — what must never happen.
- **Test** — the scenario fixture or integration test that pins
  this. New entries here must come with a fixture; existing
  fixtures are in [`scenarios.md`](./scenarios.md).

## Failure catalogue

### F1. App crashes after save before print

- **Trigger**: bill is appended to the local event log, outbox
  has it (or not, depending on online state), print job has been
  enqueued, then the app process dies (OOM, crash, force-close).
- **Expected**:
  - On relaunch, the local event log replays into projections;
    the bill is visible in History with `Saved` /
    `Sync pending` / `Synced` as appropriate.
  - The print job recovers from its IndexedDB queue. State on
    relaunch is one of `queued` / `printing → reset to queued`
    (because no `print_succeeded` ack was recorded) / never
    started. Bill is reprinted exactly once because the print
    queue is idempotent on `clientActionId`.
- **Forbidden**: a duplicate sale event, a duplicate print that
  cannot be deduped, or the bill disappearing.
- **Test**: `crash-after-save-before-print` scenario — kills the
  process between event-append and print dispatch; relaunch
  asserts exactly one sale event and exactly one print delivery.

### F2. App crashes during print

- **Trigger**: bill is `Saved` / `Synced`, the BT print
  transmission is in flight, process dies.
- **Expected**:
  - No `print_succeeded` event is appended (the printer never
    confirmed).
  - On relaunch the queue state is `printing` → it is reset to
    `queued` with `attempts += 1`.
  - The queue retries up to its budget (see
    [`print-queue.md`](./print-queue.md)).
  - The user can manually `Reprint` and the queue dedupes on
    `clientActionId`.
- **Forbidden**: appending `print_succeeded` speculatively;
  creating any sale event from the print path.
- **Test**: `crash-during-print` scenario.

### F3. Phone battery dies with unsynced bills

- **Trigger**: outbox holds N events; battery dies; phone
  recharges and launches the app possibly hours later.
- **Expected**:
  - Outbox is persisted in IndexedDB and is intact on relaunch.
  - On `online`, drain proceeds per the retry policy in
    [`offline-sync.md`](./offline-sync.md).
  - Every drained event keeps its original `idempotencyKey` and
    its original `clientAt` timestamp; server `at` is set on
    server-side accept.
  - Reconciliation re-folds projections; user sees the unsynced
    bills as `Sync pending` until ack, then `Synced`.
- **Forbidden**: dropping any outbox row; rewriting `clientAt`;
  silently moving the bill's recorded date.
- **Test**: `battery-die-outbox-replay` scenario.

### F4. Firestore write succeeds but UI times out

- **Trigger**: server accepts and persists the event, but the
  network drops before the ack reaches the device — the device
  thinks the write failed.
- **Expected**:
  - Outbox keeps the row and retries with the same
    `idempotencyKey`.
  - Server returns `OK (deduped)` because the key already
    exists; device marks `Synced`.
  - Exactly one server event; exactly one projection update.
- **Forbidden**: a second server-side event, a manual "force
  resend" path that bypasses idempotency.
- **Test**: `ack-lost-on-wire` integration test against the
  Firestore emulator with a network kill between persist and ack.

### F5. Print succeeds but `print_succeeded` event fails

- **Trigger**: printer confirms delivery, the queue tries to
  append `print_succeeded`, that append fails (offline, server
  error, app crash).
- **Expected**:
  - The print queue retains an in-memory "physically printed"
    marker keyed by `clientActionId`. On any retry that
    discovers the printer already accepted this `clientActionId`
    (vendor-specific echo, or a local "do not resend within N
    seconds" guard), it does **not** reprint; it only retries
    the `print_succeeded` event append.
  - If the marker is lost (e.g. process crash before marker
    persistence), the next attempt may reprint once; this is a
    documented and acceptable corner because the alternative
    (silently believing the print succeeded) is worse.
- **Forbidden**: assuming success without an event; counting the
  bill as "printed" in History before `print_succeeded` is
  recorded.
- **Test**: `print-ack-event-fails` scenario; also
  `print-succeeded-marker-survives-restart`.

### F6. Duplicate tap during reconnect

- **Trigger**: staff taps Save once while offline, then taps
  Save a second time after the device just came online but the
  first event hasn't acknowledged yet.
- **Expected**:
  - UI: Save button disables on the first tap (see
    [`bill-lifecycle.md`](./bill-lifecycle.md) B-rules).
  - Service: the second tap reuses the same `clientActionId`
    only if the user is still editing the same draft; if it's a
    re-tap on the same row in History, it's a no-op surfaced as
    `Already saved`.
  - Server: same `idempotencyKey` → `OK (deduped)`.
- **Forbidden**: two sale events; two outbox rows that drift
  apart; "Save successful" toast firing twice for one intent.
- **Test**: `double-tap-during-reconnect` scenario.

### F7. Device date is wrong

- **Trigger**: phone date is set to last year (or next year).
- **Expected**:
  - Every event carries `clientAt` (device time) and the
    server stamps `at` (server time) on accept.
  - On accept the server checks `|clientAt − at| <
    shopProfile.time.clockSkewMaxMin` (default `15 min`). If
    out of range, the server raises a `T1` (clock skew) flag
    and tags the event but still accepts (it would be worse to
    refuse the sale).
  - The UI shows a banner `Your device clock looks wrong — fix
    in Settings` while the skew persists.
  - All projections, reports, and "today" boundaries use
    server `at`, never `clientAt`. The shop's `Today` and cash
    session window are server-truth.
- **Forbidden**: trusting `clientAt` for any projection or
  report; silently dropping events; deriving cash session
  boundaries from device time.
- **Test**: `wrong-device-clock` scenario; `T1` invariant test.

### F8. Staff uses old app version

- **Trigger**: staff phone is running an older build than the
  current schema. Old build attempts to write events with an
  earlier schema version.
- **Expected**:
  - Server reads the event's `schemaVersion` and the client's
    self-reported `appVersion` (on every write).
  - Within the supported window (`appVersion >=
    shopProfile.minSupportedAppVersion`): server validates
    against the historical schema, optionally up-migrates the
    payload, accepts.
  - Below the supported window: server rejects with
    `UNAUTHORIZED` and the device shows a blocking screen
    `Please update — version X.Y required`. No event is
    accepted from a below-minimum client.
  - See [`versioning-compatibility.md`](./versioning-compatibility.md)
    for the support window and migration rules.
- **Forbidden**: silently dropping fields from old payloads;
  letting an out-of-window client read fresh data while writes
  are blocked.
- **Test**: `old-client-rejected` and `old-client-migrated`
  scenarios.

### F9. Local cache corrupts

- **Trigger**: IndexedDB read returns malformed JSON, schema
  mismatch, or fails entirely.
- **Expected**:
  - The cache layer detects (Zod parse fails) and **does not**
    use the bad row. It marks the cache as poisoned, logs a
    `cache.corrupted` flag, and triggers a refetch from the
    server for that projection's input window.
  - User sees `Refreshing local data…` briefly. If offline,
    user sees `Local data unreadable — connect to repair`.
  - The outbox is in its own database with its own schema
    versioning; corrupting projections cannot lose the outbox.
- **Forbidden**: trusting partially-parsed projection state;
  silent fallback to "zero" values; mixing repaired and
  unrepaired rows in the same view.
- **Test**: `cache-corruption-quarantine` integration test.

### F10. Firebase is down

- **Trigger**: the backend (Firestore / Auth / Functions) is
  unavailable.
- **Expected**:
  - Auth: if session token is still valid the app continues in
    offline-read-write mode. If expired, app shows the offline
    sign-in screen using cached credentials' last-known role and
    prompts to reconnect for fresh auth before any **owner-only**
    action.
  - Writes: all ✅-rows in
    [`offline-sync.md`](./offline-sync.md) continue. All ❌-rows
    are blocked with `Needs network`.
  - Reads: served from cache with explicit staleness badges.
  - When Firebase returns, outbox drains; auth refreshes; UI
    transitions out of the offline banner.
- **Forbidden**: silently treating cached projections as fresh;
  allowing role-change or settings writes while auth is in
  cached mode; corrupting outbox during repeated retries.
- **Test**: `backend-outage-replay` integration test.

### F11. Printer disconnected

- **Trigger**: BT printer powered off, out of range, paired
  with another device.
- **Expected**:
  - Print queue marks the job `failed` after the BT timeout
    budget (see [`print-queue.md`](./print-queue.md)).
  - Bill row in History shows `Print failed` with a `Retry`
    button; the sale event itself is untouched.
  - User can retry; the queue re-tries with the same
    `clientActionId`.
- **Forbidden**: voiding the bill because the print failed;
  blocking new bills because the queue is stalled (the queue
  must continue draining other jobs).
- **Test**: `printer-disconnected-during-bill` scenario.

### F12. Printer out of paper

- **Trigger**: printer accepts the BT bytes but the physical
  print is blank / partial.
- **Expected**:
  - The printer's ESC/POS status response (where supported)
    surfaces `out-of-paper`; queue marks `failed (paper)`.
  - Where status is not available, the user sees the bill is
    blank and taps `Reprint`. Queue dedupes; nothing changes
    business-wise.
- **Forbidden**: appending `print_succeeded` on `out-of-paper`.
- **Test**: `printer-out-of-paper` scenario (mocked driver).

### F13. Android battery optimisation kills the app or print worker

- **Trigger**: OS aggressively suspends the app while a print
  job is in flight.
- **Expected**:
  - Queue state on resume matches F2 (treat as crash-during-
    print); retry budget applies.
  - The app holds a foreground service / wake lock for the BT
    transmission window so the kill is rare in practice.
- **Forbidden**: assuming the print succeeded because the app
  re-started.
- **Test**: `battery-optimization-kills-print-worker`.

### F14. Phone is low on storage

- **Trigger**: IndexedDB writes start failing with `QuotaExceededError`.
- **Expected**:
  - Outbox writes degrade to a "critical-only" mode: domain
    events (sales, cash, settlements) still attempt to enqueue;
    cached projections trim aggressively to free space.
  - User sees a blocking banner `Storage almost full — clear
    space or contact owner`. Once storage is freed, the device
    self-recovers.
  - If outbox enqueue itself fails: the UI **must** show `Save
    failed — storage full`, never a misleading `Saved`.
- **Forbidden**: a green check when the outbox write was
  refused; silent data loss.
- **Test**: `storage-quota-degradation` scenario.

### F15. Phone is low on RAM

- **Trigger**: large History / Reports causes the page to OOM.
- **Expected**:
  - Read paths use the local fold with bounded windows per
    [`data-placement.md`](./data-placement.md). Reports
    threshold defers to server-materialized after M9.
  - List virtualisation everywhere (History, Stock,
    Outstanding, Audit, Review Queue).
- **Forbidden**: holding the full event log in memory to render
  a page; loading more than the projection's bounded window
  client-side.
- **Test**: `large-history-virtualization-perf` perf test.

### F16. App update during business hours

- **Trigger**: APK / PWA auto-updates mid-day.
- **Expected**:
  - PWA: new SW activates only on next reload; current draft is
    preserved. After reload, schema migrations run; outbox
    replays under the new client.
  - APK: install completes; relaunch resumes from the persisted
    state.
  - See [`versioning-compatibility.md`](./versioning-compatibility.md)
    §Force-upgrade for the rules around blocking writes during
    a forced upgrade.
- **Forbidden**: losing the active draft; mid-bill schema
  changes that drop fields.
- **Test**: `update-during-active-draft` Playwright test.

### F17. Two devices act at the same time

- **Trigger**: covered as a conflict in
  [`offline-sync.md`](./offline-sync.md) §Conflict handling.
- **Expected / Forbidden / Test**: see that section. Cross-
  referenced here so failure-mode reviewers do not miss it.

### F18. Bill correction after cash close

- **Trigger**: cash session was closed; a sale in that session
  is later discovered to be wrong.
- **Expected**: correction request appends a flag; nothing
  changes on the closed session's totals until owner approves
  via the Review Queue. After approval, the correction event is
  appended with a `references.closedSessionId` so reports show
  a re-stated session.
- **Forbidden**: silently mutating the closed session's totals;
  appending the correction without owner approval.
- **Test**: `correction-after-cash-close` scenario.

### F19. Sign-in attempt with stale or revoked token

- **Trigger**: owner revoked staff via Admin; staff device
  still has a cached token.
- **Expected**: token refresh fails; device transitions to
  signed-out state; outbox stops draining for that user; pending
  events are quarantined until owner intervention.
- **Forbidden**: continuing to write under a revoked identity;
  silently re-binding the outbox to another user.
- **Test**: `revoked-token-quarantine` integration test.

### F20. Lost phone

- **Trigger**: staff phone is lost. Owner needs to (a) prevent
  further writes from that device, (b) recover any unsynced
  events the phone held.
- **Expected**:
  - (a) Owner revokes the user in Admin → token refresh fails
    on the lost device (next time it ever comes online); the
    revoked-token flow from F19 applies.
  - (b) Any events that never reached the server are lost. The
    next cash close after the loss will detect a mismatch and
    raise a `reconciliation.cash-shortfall` flag for owner
    review.
  - The runbook for the human side is in
    [`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md)
    §Lost phone.
- **Forbidden**: pretending the unsynced events can be
  recovered; counting them in any report.
- **Test**: `lost-phone-revoke-and-reconcile` integration test.

## Universal rules

These rules apply to every failure above:

- **No silent data loss.** If an event cannot be appended, the
  user is told.
- **No silent duplication.** Idempotency keys are mandatory on
  every write.
- **Every retry is the same intent.** Same `clientActionId`,
  same `idempotencyKey`.
- **Every projection is reproducible from events.** If a
  projection diverges, throw it away and rebuild — never patch
  it in place.
- **Every flag has a resolution path.** The Review Queue is
  the universal landing pad; see
  [`review-queue.md`](./review-queue.md).

## Open items

- `TODO(spec)` — confirm `shopProfile.time.clockSkewMaxMin`
  (default 15 min) and the exact `T1` behaviour: accept-with-
  flag vs reject. Default in this file is accept-with-flag.
- `TODO(spec)` — define exact ESC/POS status-byte handling per
  printer model the shop uses. Until known, F12 falls back to
  "user reprints; queue dedupes."
- `TODO(spec)` — decide on the foreground-service / wake-lock
  strategy for F13 on Android 14+. Default: foreground service
  for the BT transmission window only.

## Recent changes

- _2026-06-15_ · file created. 20 failure modes with expected
  behaviour, forbidden behaviour, and pinned test fixture;
  universal rules; cross-links to print-queue, offline-sync,
  data-placement, versioning-compatibility, review-queue, and
  the operations runbook.
