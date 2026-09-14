# Data placement — rebuild

> Where data lives, who owns truth, cache/staleness rules, and read/write budgets.

## Principle

Truth is server events. Speed is device cache. Consistency is shared domain code. This refines [`event-ledger.md`](./event-ledger.md) and [`projections.md`](./projections.md): devices keep local projections for daily work; the server event log remains authoritative.

## Three-layer model

| Layer | Owns |
|---|---|
| Shared domain (pure TS) | Zod event schemas, `apply()` folds, invariants, suspicion rules, total/cash/stock/outstanding math. Runs identical bytes in app, server, tests. |
| App layer (device) | UI, local projection cache, bill-draft store, outbox, print queue worker, read budgets. |
| Server layer (Firestore) | `events` collection, security rules (A1–A5), idempotency index, materialized reads later, reconciliation job, write budgets. |

Rules: domain code is shared; app owns convenience, not truth; server does not own UI behaviour; UI reads/writes only through `services.*` returning `Result<Value, AppError>`.

## Data placement table

| Data | Authoritative | Local cache | Sync rule | Staleness tolerance | Offline behaviour |
|---|---|---|---|---|---|
| **Active bill draft** | App | App in memory + IndexedDB autosave | Local-only until `Save` appends event | n/a — user owns it | Fully usable; restores after reload |
| **Item master** | Server (`items` events) | Full mirror, IndexedDB | Subscribe; reconcile on app start | 60 s (UI badge `as of HH:MM` if older) | Read-only OK; new items blocked offline |
| **Recent parties (autocomplete)** | Server (`party_*` events) | Top N most-recent in IndexedDB | Subscribe; LRU evict beyond N | 60 s | Read-only OK |
| **Event ledger (recent)** | Server (`events` collection) | Sliding window: last 30 days + opening snapshot | Subscribe over window; older fetched on demand | 5 s for "today's" window; 1 min for older | Reads served from cache; writes queued |
| **Pending writes (outbox)** | App | IndexedDB | Drain on `online`, with idempotency keys | n/a | This is the offline surface — drains on reconnect |
| **Print queue** | App (printer is local hardware) | IndexedDB queue + worker | Print events also synced to server | n/a | Fully usable; bills queued for print survive reboot |
| **Stock projection** | Server (event-derived) | Local fold over cached events | Recompute on any `stock_*` / sale / purchase / void / correction event | 1 s during active use; 5 s otherwise | Local fold against cached events |
| **Cash session projection** | Server (event-derived) | Local fold over active session events | Recompute on any cash-affecting event | 1 s | Local fold against cached events |
| **Outstanding projection** | Server (event-derived) | Local fold over outstanding-affecting events | Recompute on settlement / sale-on-credit / correction | 5 s during settlement flow; 30 s otherwise | Local fold against cached events |
| **Today summary** | Server (event-derived) | Local fold over today's events | Recompute on any money-affecting event today | 1 s | Local fold; "offline" banner shown |
| **Period reports (≤ 1 month)** | Server preferred; app can fall back | Local fold if events in cache | Server-materialized after M9 (see Open items) | 1 min | Local fold over cached window only; older shows "data older than your cache window — go online to load" |
| **Analytics (charts)** | Server preferred | Cached summaries per bucket | Materialized at the server after M9 | 5 min | Show cached buckets; mark unloaded ones explicitly |
| **Audit log** | Server (read-only) | Recent N rows; older on demand | Subscribe over recent window | 5 s | Read from cache; "older entries require network" |
| **Review flags (unresolved)** | Server (event-derived) | Subscribe to `flag_*` events | Push from server in real time | 5 s | Show cached set; "may be incomplete offline" |
| **Shop profile / settings** | Server | Full mirror in IndexedDB | Subscribe; refetch on app start | 60 s | Read-only OK |
| **User session / role** | Server (Firebase Auth) | Token in memory + secure storage | Refresh per Firebase rules | n/a — auth is real-time | Read-only mode; new writes queued **only if** identity still valid; no privilege escalation possible offline |

`Subscribe` = Firestore `onSnapshot` or equivalent. `Local fold` = same `apply` from [`projections.md`](./projections.md). `Server-materialized` = post-M9 optimization with unchanged app interface.

## Cache rules

| Rule | Contract |
|---|---|
| Cache inputs, then fold | Do not cache projection output as truth. Memoize by event count only if needed; invalidate on new input event. |
| Bounded by default | Bound by rows, days, or MB. Evict by LRU. |
| Versioned by schema | Cache key includes projection `apply` version; domain bump invalidates dependent caches. |
| No stale writes | Server revalidates queued writes built against stale projection inputs; rejection surfaces in Review Queue. |
| No cross-shop cache | Cache keys are `(shopId, projectionName, params)`; one active shop per app instance. |

## Staleness display rules

| State | UI behaviour |
|---|---|
| Within tolerance | Show normally. |
| Older than tolerance, network up | Refetch silently; show `Updating…` if refetch takes > 200 ms. |
| Older than tolerance, network down | Show value with **As of HH:MM** badge and page banner `Offline — cached`. |
| Cache cannot answer | Show `Older data requires network`. |

No silent staleness, no spinners hiding cached values, no fabricated zeros.

There is no cross-device cache coherence protocol in v2.0. Drift within the staleness tolerance is accepted and labelled: the `As of HH:MM` badge required by AC8 tells the user the number's age. The shop runs one or two devices, and a coherence protocol is real complexity for a rare confusion. Revisit this only if the pilot shows it actually bites.

## Read path budgets

Reference device profile: [`performance-budgets.md`](./performance-budgets.md).

| Read | Budget | Source |
|---|---|---|
| Item picker open + first matches | ≤ 150 ms open; ≤ 50 ms per keystroke | Local cache |
| Party autocomplete | ≤ 50 ms per keystroke | Local cache |
| History first page | ≤ 500 ms | Local cache + projection fold |
| Today summary | ≤ 500 ms | Local fold |
| Stock page first 50 items | ≤ 500 ms | Local fold |
| Stock search / filter | ≤ 100 ms per keystroke | Local fold + memoized index |
| Outstanding first 50 parties | ≤ 500 ms | Local fold |
| Cash close current session | ≤ 300 ms | Local fold |
| Reports last month — first chart | ≤ 1500 ms local; ≤ 800 ms server-materialized | Local fold or server |
| Reports last year — first chart | ≤ 3000 ms local; ≤ 1200 ms server-materialized | Local fold or server |
| Audit log first 50 rows | ≤ 500 ms | Local cache |
| Review Queue first page | ≤ 500 ms | Local cache |
| Recent events full text | n/a (out of scope for v2.0) | — |

If a budget fails, the service adds indexing/memoization, moves work to a Web Worker, or falls back to server-materialized reads. It never silently degrades UX.

## Write path budgets

| Write | Budget | Path |
|---|---|---|
| Save bill (online) | UI feedback ≤ 100 ms; bill visible locally ≤ 300 ms; server-confirmed ≤ 500 ms | UI → service → in-memory append → projection update → outbox flush → server ack |
| Save bill (offline) | UI feedback ≤ 100 ms; bill visible locally ≤ 300 ms; server confirmation deferred | UI → service → in-memory append → outbox |
| Request print | UI feedback ≤ 100 ms; queue accept ≤ 50 ms | UI → service → queue worker |
| Settle outstanding | UI feedback ≤ 100 ms; balances update ≤ 300 ms | Same as Save bill |
| Cash session open / close | UI feedback ≤ 100 ms; projection update ≤ 300 ms | Same as Save bill |
| Open review flag resolve | UI feedback ≤ 100 ms; queue removed ≤ 300 ms | Same |

User-perceived success is `bill visible locally`; server ack appears in History as `sync: ok / pending / failed`.

## Server vs app responsibilities

| Concern | Lives on |
|---|---|
| Bill total math | Domain (shared) |
| Validation schemas (Zod) | Domain (shared) |
| Permission enforcement | Server rules (mandatory); app for UX only |
| Idempotency check | Server / storage adapter (mandatory); app pre-check for UX |
| Suspicion rules — fast, deterministic | Domain (shared); fire on every event |
| Suspicion rules — slow / cross-window | Server background job |
| UI formatting (₹, dates, Hindi/English labels) | App |
| Print rendering (ESC/POS bytes) | App / local printer queue |
| Heavy reports | Local fold up to threshold; server-materialized beyond (post-M9) |
| Offline queue replay | App, idempotency-verified on server |
| Projection rebuild (full) | Server tooling |
| Projection rebuild (window) | App can do, server-verified |
| Audit log writes | Implicit from any event; app cannot author audit rows directly |
| Audit log reads | Server (paginated); app caches recent window |
| Reconciliation (R1–R4) | Server job; app can spot-check on demand |
| Backup / disaster recovery | Server (Firestore export schedule) |

## Offline behaviour contract

- Read cached data with staleness badges.
- Write online-allowed staff events into the outbox.
- Print locally.
- Reject actions needing current server state with a clear message.

Reconnect: drain oldest-first; server reapplies by idempotency key; permanent rejections raise Review Queue flags per [`role-permission-matrix.md`](./role-permission-matrix.md); app re-folds from confirmed server event ids; divergence raises a flag.

Outbox retention: **30 days**. After that, warn `Your device hasn't synced in 30 days`; do not silently drop. See `decisions.md` row M11.

## Open items

- Bill number allocation offline: pre-allocate a small block per device and surface `offline-issued` badge until reconciled.
- `TODO(spec, blocks: M9)` — Server-materialized reports threshold: when does the app stop folding locally and start reading from a materialized view? **Default:** 30 days of events.
- `TODO(spec, blocks: M11)` — Background sync window after close-app: wake the app to flush outbox? **Default:** foreground-only in v2.0; revisit after pilot.

## Tests this spec requires

- Placement table rows meet budgets on the reference dataset.
- Read budgets have Playwright phone-viewport assertions on the synthetic dataset.
- Write budgets have in-memory adapter and Firestore-emulator integration tests.
- Staleness tests flip network off mid-session and assert fresh/stale/refuse states.
- Offline tests cover [`scenarios.md`](./scenarios.md) `offline-bill-replay` plus `offline-week-long`, with no duplicate sales after reconnect.

