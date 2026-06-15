# Offline / sync contract — rebuild

> The shop must keep working when the network is gone, and
> recover cleanly when it returns. This file defines, per
> action, whether offline is allowed, what the local UI state
> machine looks like, how conflicts resolve, what the retry
> policy is, and what the UI must show the user.

## Why this doc exists

[`data-placement.md`](./data-placement.md) says **where each
piece of data lives**. This file says **what each user action
is allowed to do when there is no network**, what state the row
goes through, and how the device and server reconcile. Without
this contract, every screen will quietly invent its own offline
behaviour and the business will silently lose money.

The principle is the same:

> Truth on the server. Speed in the app. Consistency in the
> shared domain.

Offline does not change the principle. It changes the timeline:
the truth-write to the server is **deferred**, not skipped.

## Per-action allowance table

The rule for every action staff or owner can take.

| Action | Offline allowed? | Why / Constraint |
|---|:---:|---|
| Create retail bill | ✅ | Must allocate a local bill id; queued via outbox; idempotency-key set at intent time |
| Create wholesale bill | ✅ | Same; outstanding update is local-fold until server-confirmed |
| Print bill | ✅ | Printer is local hardware; queue runs without network |
| Reprint bill | ✅ | Print queue can re-render from local bill state |
| Add purchase | ✅ | Allowed only if the item master is cached locally; if the item is new, blocked with `Needs network — new item` |
| Record expense (business) | ✅ | Pure event; cash projection updates locally |
| Record expense (personal) | ❌ | Owner-only; treat as settings change |
| Receive outstanding payment | ✅ | Shown as `Pending sync` until server confirms; over-settlement guarded by local fold + server re-check |
| Make outstanding payment | ❌ | Owner-only; defer until online |
| Stock adjustment (small) | ✅ | Allowed for staff if under `stock.adjustmentLargeKg`; flagged when large |
| Stock adjustment (large) | ❌ | Requires owner approval flow; needs network |
| Void today's bill | 🟡 | Allowed if cash session is still open AND idempotency key not yet server-acknowledged; shown as `Void pending review` |
| Void older bill | ❌ | Always owner-only and always online |
| Bill correction | 🟡 | Same as void today |
| Open cash session | ✅ | Local event; flagged if a server-acknowledged session is already open for this device's user |
| Close cash session | ✅ | Local event; bound to `closed_locally`; banner: `Cash close pending sync` |
| Edit item master | ❌ | Conflict risk too high; queue UI shows `Needs network` and parks the edit as a draft |
| Create new item | ❌ | Same |
| Archive item | ❌ | Same |
| Change roles / users | ❌ | Always online; security-critical |
| Change shop profile / settings | ❌ | Always online |
| Resolve review flag (low / medium) | ❌ | Brother / owner action; require network |
| Resolve review flag (high / `block` override) | ❌ | Owner-only and always online; flagged if attempted |
| Read all cached projections | ✅ | With explicit staleness badge per [`data-placement.md`](./data-placement.md) |
| Reports / Analytics | 🟡 | Allowed for the cached window only; older periods show `Older data requires network` |

✅ = allowed without restriction beyond cache requirements.
🟡 = allowed with **explicit pending-state surfacing**.
❌ = blocked with a clear UX message; no event ever appended
offline.

A row's value is enforced by **both** the UI (for UX) and the
storage adapter (for safety). The adapter is the truth: even a
direct SDK call from a hacked client must fail for ❌ rows.

## Local UI state vocabulary

Every write the user makes goes through a strict state machine.
The badge text the user sees is exactly one of:

| Badge | Meaning | When it changes |
|---|---|---|
| `Saved` | Appended to local event log. Visible in History from local fold. Not yet sent to server. | Set on local append. |
| `Sync pending` | Outbox has the event; reconnect not yet attempted or attempt in flight. | Set on outbox enqueue; set on `online` if not yet ack'd. |
| `Synced` | Server has accepted the event under its idempotency key. | Set on server ack. |
| `Sync failed (retrying)` | Server rejected for a transient reason (network, rate limit, 5xx); will retry. | Set on transient error. |
| `Needs review` | Server rejected for a permanent reason (`SCHEMA_INVALID`, `INVARIANT_VIOLATION`, `PERMISSION_DENIED`, `IDEMPOTENCY_CONFLICT`, `BLOCKED_BY_RULE`, `OUT_OF_ORDER`, `UNAUTHORIZED`); routed to Review Queue. | Set on permanent error. |
| `Printed` | Print queue confirmed delivery. | Independent of `Saved/Synced`. |
| `Print failed` | Printer reported failure or timed out. | Independent. |

A bill row in History can show two badges: one for the sale
event (e.g. `Synced`) and one for the print (e.g. `Print
failed`). They are different concerns by design.

Forbidden:

- A spinner that hides whether the value is local-only or
  server-confirmed.
- A toast that disappears before the user can read whether it
  said `Saved` or `Synced`.
- A "looks fine" green check while the outbox has the row.

## Sync retry policy

Driver for the outbox worker.

1. **Trigger**: `online` event, app foregrounded, periodic 60 s
   tick while online, or explicit user `Retry`.
2. **Order**: oldest-first within a shop. A failed item does
   not block the queue beyond a small bounded retry window —
   after that, it parks in `Needs review` and the worker
   advances.
3. **Backoff**: exponential with jitter. Start at 1 s, cap at
   60 s. Reset to 1 s after any success or after `online`.
4. **Per-event budget**: 5 transient attempts. The sixth
   transient failure parks the item as `Needs review` for the
   brother / owner to triage.
5. **Permanent failures** never retry. They park immediately
   and raise a `sync.permanent-rejection` flag.
6. **Idempotency**: every retry uses the same
   `idempotencyKey`. If the server has already accepted the
   event under that key (e.g. ack lost on the wire) it returns
   `OK` (idempotent) and the worker marks `Synced`.
7. **Bandwidth**: batch at most 25 events per request to avoid
   long blocking writes.
8. **Outbox retention**: 30 days. Beyond that the device
   surfaces a banner (`Your device hasn't synced in 30 days —
   contact owner`) and refuses new writes until a successful
   drain. (See `decisions.md`, M11.)

The retry policy is one piece of code, not per-feature. Every
event type uses the same outbox.

## Conflict handling

Two devices can act at once even when there is only one staff
device today (e.g. staff phone + owner phone). The rules:

| Conflict | Resolution |
|---|---|
| Same `idempotencyKey`, **identical** payload | Server treats as duplicate; returns `OK (deduped)`. UI marks `Synced`. |
| Same `idempotencyKey`, **different** payload | Server rejects with `IDEMPOTENCY_CONFLICT`. UI marks `Needs review`. A `dedup.conflict` flag is raised with both payloads attached. Owner decides which wins; the other is voided. |
| Two devices edit the same item master row | Last-write-wins is **forbidden**. Server rejects the second with `OUT_OF_ORDER` (the event's `references.itemVersion` is stale). UI marks `Needs review`. Owner resolves. |
| Two devices receive the same outstanding payment | First wins. The second is rejected with `INVARIANT_VIOLATION` (`O1` — outstanding cannot go negative). UI marks `Needs review`; flagged. |
| Two devices open cash sessions for the same shop / user | First wins. The second is rejected with `BLOCKED_BY_RULE`. UI marks `Needs review`; the staff is shown `A session is already open elsewhere`. |
| Bill correction after cash close | Always requires owner review even if device is online. Service appends only the **request**; the corrective event lands only after a `flag_resolved(approve)`. |
| Out-of-order replay (offline burst) | Server orders events by their server-side `seq`. The shared `apply` is **order-independent** for projection state where possible; where order matters (cash session open/close), the event carries `references.sessionId` and is rejected if `seq` shows it would re-order a session boundary. |

The general rule: **no silent loss, no silent overwrite**. Any
real conflict surfaces in the Review Queue with both candidates
visible.

## What happens on reconnect

1. Device detects `online`.
2. Outbox worker batches up to 25 oldest events and `POST`s
   with idempotency keys.
3. Server validates and either:
   - Accepts → emits server-ordered events back; device marks
     `Synced`.
   - Rejects (transient) → device backs off and retries up to
     the per-event budget.
   - Rejects (permanent) → device marks `Needs review` and
     raises a flag.
4. After every successful batch, the device pulls any
   newly-server-recorded events for the shop (from any device)
   into its event cache, then re-folds projections. The user
   sees the most recent projection within the **staleness
   tolerance** in [`data-placement.md`](./data-placement.md).
5. If reconciliation detects divergence (a local projection
   that does not match the server's after re-fold) a
   `reconciliation.mismatch` flag is raised and the device
   force-rebuilds the affected projection from the server's
   events.

## What the UI must show

For every page, the offline / sync state surfaces in three
places:

1. **App-level banner** when offline:
   `Offline — your work is saved locally and will sync when
   you reconnect.`
   When draining: `Syncing N items…`.
   When stuck: `N items need review — open Review Queue.`
2. **Per-row badge** in History / Today / Outstanding using the
   state vocabulary above. Always visible; never collapsed
   into "everything is fine".
3. **One obvious `Retry` button** on any failed row. Tapping
   it enqueues a fresh attempt that reuses the same
   idempotency key.

Forbidden UI patterns:

- Hiding `Sync pending` once the page re-renders.
- A toast-only signal that auto-dismisses.
- Treating `Saved locally` as terminal success in any business
  view (Reports, Cash close, Outstanding).
- Cash close that ignores `Sync pending` events.
- Allowing a "void" of a `Sync pending` bill without the
  matching idempotency-key surgery (see Conflict handling row
  above).

## Required tests

Add to [`scenarios.md`](./scenarios.md) (or extend existing
fixtures):

- `offline-bill-replay` (already listed) — single offline bill,
  reconnect, single server bill.
- `offline-burst-then-reconnect` — staff creates 20 bills
  offline; reconnect; exactly 20 server bills with stable order;
  no duplicates.
- `offline-week-long` — week of activity offline including cash
  open / close, settlements, voids; replay produces identical
  projections.
- `dedup-conflict-same-key-different-payload` — same
  `idempotencyKey` arrives twice with different totals; server
  raises `dedup.conflict`; UI parks both as `Needs review`.
- `concurrent-item-edit` — two devices edit the same item; one
  succeeds; the other lands as `OUT_OF_ORDER`.
- `concurrent-outstanding-settlement` — two devices receive the
  same payment; first wins; second is `INVARIANT_VIOLATION`.
- `cash-close-with-pending-sync` — staff closes cash while
  three sale events are still `Sync pending`; cash close is
  itself appended; on reconnect, the cash session totals match
  exactly.
- `retry-budget-exhausted` — permanent rejection on the 6th
  attempt parks as `Needs review` and the next item drains.
- `reconciliation-mismatch-rebuild` — local stock projection
  diverges from server's; flag raised; device rebuilds and
  resolves.
- `outbox-quota-30d` — simulate 30 days without sync; banner
  appears; new writes are refused until drain.

Each of these has the standard scenario contract: setup,
sequence, expected projections, expected flags, expected UI
badges.

## Test layers

| Layer | What it asserts |
|---|---|
| Unit | Retry / backoff policy, conflict-classification function, state-machine transitions. |
| Scenario | The offline fixtures above against the in-memory adapter. |
| Integration | The same fixtures against the Firestore emulator. |
| Security | Server enforces ❌ rows under direct-SDK access. |
| Playwright | The badge text in the state vocabulary appears exactly when expected; `Retry` button works; banner copy is correct. |
| Perf | Outbox throughput ≥ 10 events/sec; first-item attempt ≤ 1 s of `online`; no UI long-task during drain. |

## Open items

- `TODO(spec)` — **Bill number allocation offline.** Pick before
  M5. Default in [`data-placement.md`](./data-placement.md):
  pre-allocate a small block per session; surface
  `offline-issued` badge until reconciled.
- `TODO(spec)` — **Stale `references.itemVersion` window.** How
  old can an offline item reference be before the server forces
  a refetch? Default: 24 h.
- `TODO(spec)` — **Background sync after app close.** v2.0
  keeps sync foreground-only; revisit after pilot.
- `TODO(spec)` — **Cross-device cache coherence protocol.**
  Document before M8 (also flagged in `data-placement.md`).

## Recent changes

- _2026-06-15_ · file created. Per-action allow / block matrix
  with offline rules; local UI state vocabulary
  (`Saved` / `Sync pending` / `Synced` / `Sync failed
  (retrying)` / `Needs review` / `Printed` / `Print failed`);
  exponential-backoff retry policy with 6-attempt budget;
  conflict handling matrix; reconnect protocol; required UI
  surfaces; ten required test fixtures.
