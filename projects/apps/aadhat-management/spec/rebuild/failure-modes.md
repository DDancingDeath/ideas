# Failure modes — rebuild

> Expected system behaviour for real-world failures. Human runbooks live in
> [`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md).
> If a failure mode is missing, open a shaped spec TODO.

## Reading guide

Each entry defines **Trigger**, **Expected**, **Forbidden**, and **Test**. New entries need a scenario fixture; existing fixtures are in [`scenarios.md`](./scenarios.md).

## Failure catalogue

### F1. App crashes after save before print

- **Trigger**: bill appended to local event log; outbox may contain it; print job enqueued; app dies by OOM, crash, or force-close.
- **Expected**:
  - Relaunch replays local events; History shows the bill as `Saved` / `Sync pending` / `Synced`.
  - Print job recovers from IndexedDB as `queued`, `printing → queued` if no `print_succeeded` ack, or never started.
  - Bill reprints exactly once; print queue dedupes on `clientActionId`.
- **Forbidden**: duplicate sale event; non-dedupable duplicate print; disappearing bill.
- **Test**: `crash-after-save-before-print` scenario — kill between event append and print dispatch; relaunch asserts one sale event and one print delivery.

### F2. App crashes during print

- **Trigger**: bill is `Saved` / `Synced`; BT print transmission is in flight; process dies.
- **Expected**:
  - No `print_succeeded` event without printer confirmation.
  - Relaunch resets `printing` → `queued` and increments `attempts += 1`.
  - Queue retries up to [`print-queue.md`](./print-queue.md) budget.
  - Manual `Reprint` is allowed; queue dedupes on `clientActionId`.
- **Forbidden**: speculative `print_succeeded`; sale event from print path.
- **Test**: `crash-during-print` scenario.

### F3. Phone battery dies with unsynced bills

- **Trigger**: outbox holds N events; battery dies; phone relaunches hours later.
- **Expected**:
  - IndexedDB outbox is intact.
  - On `online`, drain follows [`offline-sync.md`](./offline-sync.md) retry policy.
  - Drained events keep original `idempotencyKey` and `clientAt`; server `at` is set on accept.
  - Reconciliation re-folds projections; bills show `Sync pending` until ack, then `Synced`.
- **Forbidden**: dropped outbox row; rewritten `clientAt`; silently moved bill date.
- **Test**: `battery-die-outbox-replay` scenario.

### F4. Firestore write succeeds but UI times out

- **Trigger**: server persists event; network drops before device receives ack.
- **Expected**: outbox keeps row; retry uses same `idempotencyKey`; server returns `OK (deduped)`; device marks `Synced`; exactly one server event and projection update.
- **Forbidden**: second server event; manual force-resend bypassing idempotency.
- **Test**: `ack-lost-on-wire` Firestore emulator integration test with network kill between persist and ack.

### F5. Print succeeds but `print_succeeded` event fails

- **Trigger**: printer confirms delivery; appending `print_succeeded` fails due to offline, server error, or crash.
- **Expected**:
  - Queue keeps an in-memory physically-printed marker keyed by `clientActionId`.
  - Retry that detects printer accepted this `clientActionId` (vendor echo or local no-resend guard within N seconds) does not reprint; it retries only the `print_succeeded` append.
  - If the marker is lost before persistence, the next attempt may reprint once.
- **Forbidden**: success without event; History counted as printed before `print_succeeded`.
- **Test**: `print-ack-event-fails`; `print-succeeded-marker-survives-restart`.

### F6. Duplicate tap during reconnect

- **Trigger**: staff taps Save offline, then taps again after reconnect before first ack.
- **Expected**:
  - UI disables Save on first tap; see [`bill-lifecycle.md`](./bill-lifecycle.md) B-rules.
  - Service reuses the same `clientActionId` only while editing the same draft.
  - Re-tap on same History row is a no-op shown as `Already saved`.
  - Server dedupes same `idempotencyKey` as `OK (deduped)`.
- **Forbidden**: two sale events; two drifting outbox rows; duplicate success toast.
- **Test**: `double-tap-during-reconnect` scenario.

### F7. Device date is wrong

- **Trigger**: phone date is last year or next year.
- **Expected**:
  - Every event carries `clientAt`; server stamps `at` on accept.
  - Server checks `|clientAt − at| < shopProfile.time.clockSkewMaxMin` per [`configuration.md`](./configuration.md); out-of-range accepts with `T1` clock-skew flag.
  - UI banner: `Your device clock looks wrong — fix in Settings` while skew persists.
  - Projections, reports, `Today`, and cash sessions use server `at`, never `clientAt`.
- **Forbidden**: projection/report from `clientAt`; dropped events; cash boundaries from device time.
- **Test**: `wrong-device-clock`; `T1` invariant test.

### F8. Staff uses old app version

- **Trigger**: old build writes earlier-schema events.
- **Expected**:
  - Server reads event `schemaVersion` and client `appVersion` on every write.
  - If `appVersion >= shopProfile.minSupportedAppVersion`, server validates historical schema, may up-migrate payload, and accepts.
  - Below supported window, server rejects with `UNAUTHORIZED`; device blocks on `Please update — version X.Y required`; no event accepted.
  - Support window and migration rules: [`versioning-compatibility.md`](./versioning-compatibility.md).
- **Forbidden**: silently dropped old fields; out-of-window client reading fresh data while writes are blocked.
- **Test**: `old-client-rejected`; `old-client-migrated`.

### F9. Local cache corrupts

- **Trigger**: IndexedDB read returns malformed JSON, schema mismatch, or failure.
- **Expected**:
  - Cache layer rejects bad row on Zod parse failure, marks cache poisoned, logs `cache.corrupted`, and refetches that projection input window from server.
  - UI shows `Refreshing local data…`; offline UI shows `Local data unreadable — connect to repair`.
  - Outbox has separate database and schema versioning; projection corruption cannot lose outbox.
- **Forbidden**: partially-parsed state; silent zero fallback; mixed repaired/unrepaired rows in one view.
- **Test**: `cache-corruption-quarantine` integration test.

### F10. Firebase is down

- **Trigger**: Firestore / Auth / Functions unavailable.
- **Expected**:
  - Valid session token: app continues offline read-write.
  - Expired token: offline sign-in screen uses cached last-known role; fresh auth required before any **owner-only** action.
  - Writes follow ✅/❌ matrix in [`offline-sync.md`](./offline-sync.md): ✅ continue, ❌ show `Needs network`.
  - Reads use cache with staleness badges.
  - On recovery: outbox drains, auth refreshes, offline banner clears.
- **Forbidden**: cached projections shown as fresh; role/settings writes in cached-auth mode; outbox corruption during retries.
- **Test**: `backend-outage-replay` integration test.

### F11. Printer disconnected

- **Trigger**: BT printer off, out of range, or paired elsewhere.
- **Expected**:
  - Queue marks job `failed` after BT timeout budget in [`print-queue.md`](./print-queue.md).
  - History row shows `Print failed` + `Retry`; sale event unchanged.
  - Retry uses same `clientActionId`.
- **Forbidden**: void bill because print failed; stalled queue blocking new bills or other jobs.
- **Test**: `printer-disconnected-during-bill` scenario.

### F12. Printer out of paper

- **Trigger**: printer accepts BT bytes but print is blank or partial.
- **Expected**:
  - ESC/POS status response, where supported, surfaces `out-of-paper`; queue marks `failed (paper)`.
  - Without status, user taps `Reprint`; queue dedupes; business state unchanged.
- **Forbidden**: `print_succeeded` on `out-of-paper`.
- **Test**: `printer-out-of-paper` mocked-driver scenario.

### F13. Android battery optimisation kills the app or print worker

- **Trigger**: OS suspends app while print job is in flight.
- **Expected**: resume follows F2; retry budget applies; app holds a foreground service / wake lock for the BT transmission window.
- **Forbidden**: assuming print succeeded because app restarted.
- **Test**: `battery-optimization-kills-print-worker`.

### F14. Phone is low on storage

- **Trigger**: IndexedDB writes fail with `QuotaExceededError`.
- **Expected**:
  - Outbox enters critical-only mode: domain events (sales, cash, settlements) still attempt enqueue; cached projections trim aggressively.
  - Blocking banner: `Storage almost full — clear space or contact owner` until storage frees.
  - If outbox enqueue fails, UI shows `Save failed — storage full`, never `Saved`.
- **Forbidden**: green check after refused outbox write; silent data loss.
- **Test**: `storage-quota-degradation` scenario.

### F15. Phone is low on RAM

- **Trigger**: large History / Reports page OOMs.
- **Expected**: read paths use bounded windows per [`data-placement.md`](./data-placement.md); Reports defer to server-materialized after M9; virtualise History, Stock, Outstanding, Audit, and Review Queue lists.
- **Forbidden**: full event log in memory for page render; loading beyond projection bounded window client-side.
- **Test**: `large-history-virtualization-perf` perf test.

### F16. App update during business hours

- **Trigger**: APK / PWA auto-updates mid-day.
- **Expected**:
  - PWA: new SW activates on next reload; current draft preserved; migrations run; outbox replays under new client.
  - APK: install completes; relaunch resumes persisted state.
  - Forced-upgrade write blocking: [`versioning-compatibility.md`](./versioning-compatibility.md) §Force-upgrade.
- **Forbidden**: lost active draft; mid-bill schema changes dropping fields.
- **Test**: `update-during-active-draft` Playwright test.

### F17. Two devices act at the same time

- **Trigger**: conflict described in [`offline-sync.md`](./offline-sync.md) §Conflict handling.
- **Expected / Forbidden / Test**: see that section.

### F18. Bill correction after cash close

- **Trigger**: cash session closed; sale in that session is later wrong.
- **Expected**: correction request appends a flag; closed totals stay unchanged until owner approval via Review Queue; approval appends correction event with `references.closedSessionId`; reports show re-stated session.
- **Forbidden**: silent closed-total mutation; correction without owner approval.
- **Test**: `correction-after-cash-close` scenario.

### F19. Sign-in attempt with stale or revoked token

- **Trigger**: owner revoked staff via Admin; staff device still has cached token.
- **Expected**: token refresh fails; device signs out; outbox stops draining for that user; pending events quarantined until owner intervention.
- **Forbidden**: writes under revoked identity; silently rebinding outbox to another user.
- **Test**: `revoked-token-quarantine` integration test.

### F20. Lost phone

- **Trigger**: staff phone is lost; owner must block future writes and handle unsynced events.
- **Expected**:
  - Owner revokes user in Admin; next online token refresh fails; F19 applies.
  - Events never reaching server are lost.
  - Next cash close detects mismatch and raises `reconciliation.cash-shortfall` for owner review.
  - Human runbook: [`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md) §Lost phone.
- **Forbidden**: pretending unsynced events can be recovered; counting them in reports.
- **Test**: `lost-phone-revoke-and-reconcile` integration test.

## Universal rules

- **No silent data loss.** If append fails, tell the user.
- **No silent duplication.** Every write requires idempotency keys.
- **Retries preserve intent.** Same `clientActionId`, same `idempotencyKey`.
- **Projections are reproducible.** Divergence means rebuild, never patch.
- **Every flag has a resolution path.** Review Queue is the landing pad; see [`review-queue.md`](./review-queue.md).

## Open items

- `TODO(spec, blocks: M0)` — Confirm `shopProfile.time.clockSkewMaxMin` and exact `T1` behaviour: accept-with-flag vs reject? **Default:** accept-with-flag.
- `TODO(spec, blocks: M10)` — Define exact ESC/POS status-byte handling per printer model? **Default:** user reprints; queue dedupes.
- `TODO(spec, blocks: M10)` — Decide foreground-service / wake-lock strategy for F13 on Android 14+? **Default:** foreground service for the BT transmission window only.
