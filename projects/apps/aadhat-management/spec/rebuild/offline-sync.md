# Offline / sync contract — rebuild

> Offline allowance, local state machine, conflict handling, retry policy, and required UI copy.

## Principle

Truth stays on the server; offline only defers the server write. Data ownership is in [`data-placement.md`](./data-placement.md).

## Per-action allowance table

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
| Stock adjustment (small) | ✅ | Allowed for staff if under `stock.adjustmentLargeMg`; flagged when large |
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

✅ = allowed offline. 🟡 = allowed with explicit pending-state surfacing. ❌ = blocked with clear UX; no offline event appended. UI and adapter both enforce rows; adapter is authoritative against direct SDK calls.

## Local UI state vocabulary

| Badge | Meaning | When it changes |
|---|---|---|
| `Saved` | Appended to local event log. Visible in History from local fold. Not yet sent to server. | Set on local append. |
| `Sync pending` | Outbox has the event; reconnect not yet attempted or attempt in flight. | Set on outbox enqueue; set on `online` if not yet ack'd. |
| `Synced` | Server has accepted the event under its idempotency key. | Set on server ack. |
| `Sync failed (retrying)` | Server rejected for a transient reason (network, rate limit, 5xx); will retry. | Set on transient error. |
| `Needs review` | Server rejected for a permanent reason (`SCHEMA_INVALID`, `INVARIANT_VIOLATION`, `PERMISSION_DENIED`, `IDEMPOTENCY_CONFLICT`, `BLOCKED_BY_RULE`, `OUT_OF_ORDER`, `UNAUTHORIZED`); routed to Review Queue. | Set on permanent error. |
| `Printed` | Print queue confirmed delivery. | Independent of `Saved/Synced`. |
| `Print failed` | Printer reported failure or timed out. | Independent. |

A History row may show both sale sync and print badges. Forbidden: hiding local/server status behind spinners, transient toasts, or green checks while outbox rows remain.

## Sync retry policy

| Policy | Value |
|---|---|
| Trigger | `online`, app foregrounded, periodic 60 s tick while online, or user `Retry`. |
| Order | Oldest-first within a shop; bounded retry window before parking and advancing. |
| Backoff | Exponential with jitter: start 1 s, cap 60 s, reset to 1 s after success or `online`. |
| Per-event budget | 5 transient attempts; sixth transient failure parks as `Needs review`. |
| Permanent failures | No retry; park immediately and raise `sync.permanent-rejection`. |
| Idempotency | Retry with same `idempotencyKey`; accepted duplicate returns `OK` and marks `Synced`. |
| Bandwidth | Batch at most 25 events per request. |
| Outbox retention | 30 days; then banner `Your device hasn't synced in 30 days — contact owner` and refuse new writes until drain. See `decisions.md`, M11. |

The outbox worker is shared by every event type.

## Conflict handling

| Conflict | Resolution |
|---|---|
| Same `idempotencyKey`, **identical** payload | Server treats as duplicate; returns `OK (deduped)`. UI marks `Synced`. |
| Same `idempotencyKey`, **different** payload | Server rejects with `IDEMPOTENCY_CONFLICT`. UI marks `Needs review`. A `dedup.conflict` flag is raised with both payloads attached. Owner decides which wins; the other is voided. |
| Two devices edit the same item master row | Last-write-wins is **forbidden**. Server rejects the second with `OUT_OF_ORDER` (the event's `references.itemVersion` is stale). UI marks `Needs review`. Owner resolves. |
| Two devices receive the same outstanding payment | First wins. The second is rejected with `INVARIANT_VIOLATION` (`O1` — outstanding cannot go negative). UI marks `Needs review`; flagged. |
| Two devices open cash sessions for the same shop / user | First wins. The second is rejected with `BLOCKED_BY_RULE`. UI marks `Needs review`; the staff is shown `A session is already open elsewhere`. |
| Bill correction after cash close | Always requires owner review even if device is online. Service appends only the **request**; the corrective event lands only after a `flag_resolved(approve)`. |
| Out-of-order replay (offline burst) | Server orders events by their server-side `seq`. The shared `apply` is **order-independent** for projection state where possible; where order matters (cash session open/close), the event carries `references.sessionId` and is rejected if `seq` shows it would re-order a session boundary. |

No silent loss, overwrite, or automatic merge; conflicts surface in Review Queue with both candidates where applicable.

## Reconnect sequence

1. Device detects `online`.
2. Outbox worker posts up to 25 oldest events with idempotency keys.
3. Server validates: accept → emit server-ordered events and mark `Synced`; transient reject → backoff up to budget; permanent reject → `Needs review` + flag.
4. After each successful batch, device pulls new shop events from any device, re-folds projections, and stays within the staleness tolerance in [`data-placement.md`](./data-placement.md).
5. Projection divergence raises `reconciliation.mismatch` and forces rebuild from server events.

There is no cross-device cache coherence protocol in v2.0 beyond pull, re-fold, and the staleness badges defined in [`data-placement.md`](./data-placement.md).

## UI requirements

| Surface | Required copy/behaviour |
|---|---|
| App banner, offline | `Offline — your work is saved locally and will sync when you reconnect.` |
| App banner, draining | `Syncing N items…` |
| App banner, stuck | `N items need review — open Review Queue.` |
| Per-row badge | One of the exact state vocabulary badges above in History / Today / Outstanding. |
| Failed row | One obvious `Retry` button; retry reuses the same idempotency key. |

Forbidden: hiding `Sync pending`, toast-only signals, treating `Saved locally` as terminal success in Reports/Cash close/Outstanding, cash close ignoring pending events, or voiding a `Sync pending` bill without the matching idempotency-key handling.

## Required tests

- `offline-bill-replay` (already listed) — single offline bill, reconnect, single server bill.
- `offline-burst-then-reconnect` — staff creates 20 bills offline; reconnect; exactly 20 server bills with stable order; no duplicates.
- `offline-week-long` — week of activity offline including cash open / close, settlements, voids; replay produces identical projections.
- `dedup-conflict-same-key-different-payload` — same `idempotencyKey` arrives twice with different totals; server raises `dedup.conflict`; UI parks both as `Needs review`.
- `concurrent-item-edit` — two devices edit the same item; one succeeds; the other lands as `OUT_OF_ORDER`.
- `concurrent-outstanding-settlement` — two devices receive the same payment; first wins; second is `INVARIANT_VIOLATION`.
- `cash-close-with-pending-sync` — staff closes cash while three sale events are still `Sync pending`; cash close is itself appended; on reconnect, the cash session totals match exactly.
- `retry-budget-exhausted` — permanent rejection on the 6th attempt parks as `Needs review` and the next item drains.
- `reconciliation-mismatch-rebuild` — local stock projection diverges from server's; flag raised; device rebuilds and resolves.
- `outbox-quota-30d` — simulate 30 days without sync; banner appears; new writes are refused until drain.

Each scenario specifies setup, sequence, expected projections, expected flags, and expected UI badges in [`scenarios.md`](./scenarios.md).

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

- Bill number allocation offline: pre-allocate a small block per device per [`data-placement.md`](./data-placement.md); surface `offline-issued` badge until reconciled.
- `TODO(spec, blocks: M11)` — Stale `references.itemVersion` window: how old can an offline item reference be before server forces refetch? **Default:** 24 h.
- `TODO(spec, blocks: M11)` — Background sync after app close? **Default:** foreground-only in v2.0; revisit after pilot.

