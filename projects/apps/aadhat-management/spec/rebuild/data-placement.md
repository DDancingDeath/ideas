# Data placement — rebuild

> Where each piece of data lives, who owns the truth, what the
> phone keeps in cache, how staleness is shown, and what the
> read/write budget is. Lives in `spec/` because these are
> contracts every layer must honour — not opinions.

## Principle

> Truth on the server. Speed in the app. Consistency in the
> shared domain.

The staff device must feel **instant** during billing. Anything
slow, uncertain, remote, or hardware-dependent must move behind
a queue, cache, projection, or background worker.

This contradicts neither
[`event-ledger.md`](./event-ledger.md) ("events are truth") nor
[`projections.md`](./projections.md) ("projections are derived
folds"). It refines them: the **event log is authoritative on
the server**, but the **device keeps local projections it needs
for daily work** so no read on the hot path waits on the network.

## Three-layer model

```
┌────────────────────────────────────────────────────────────────┐
│  Shared domain (pure TS)                                        │
│  • event schemas (Zod)                                          │
│  • projection apply() folds                                     │
│  • invariants, suspicion rules                                  │
│  • total / cash / stock / outstanding math                      │
│  Runs in app, server, and tests — identical bytes.              │
└──────────────┬─────────────────────────────────┬───────────────┘
               │                                 │
               ▼                                 ▼
┌─────────────────────────────┐    ┌──────────────────────────────┐
│  App layer (device)         │    │  Server layer (Firestore)    │
│  • UI                       │    │  • events collection         │
│  • local projection cache   │    │  • security rules (A1–A5)    │
│  • bill-draft store         │    │  • idempotency key index     │
│  • outbox (pending writes)  │    │  • materialized reads (later)│
│  • print queue worker       │    │  • reconciliation job        │
│  • read budgets             │    │  • write budgets             │
└─────────────────────────────┘    └──────────────────────────────┘
```

Rules:

1. **Domain code is shared**: same `apply` runs in the app
   (build a local projection) and on the server (build a
   materialized projection or run reconciliation). They cannot
   disagree without a domain bug.
2. **App never owns truth**: it owns convenience. Any number
   shown by the app must be reproducible by the server from
   events alone.
3. **Server never owns UI behaviour**: hover states, draft
   text, focus, animations live only on the device.
4. **The line between them is `services.*`**: every read /
   write the UI does goes through a service that picks the
   right layer (cache vs network) and surfaces a single
   `Result<Value, AppError>` to the UI.

## Data placement table

For every data type the app touches, the **authoritative
location**, the **local cache rule**, the **sync rule**, the
**staleness tolerance** (how long a user-visible value may lag
truth before it is marked stale or refetched), and the
**offline behaviour**.

| Data | Authoritative | Local cache | Sync rule | Staleness tolerance | Offline behaviour |
|---|---|---|---|---|---|
| **Active bill draft** | App | App in memory + IndexedDB autosave | Local-only until `Save` appends event | n/a — user owns it | Fully usable; restores after reload |
| **Item master** | Server (`items` events) | Full mirror, IndexedDB | Subscribe; reconcile on app start | 60 s (UI badge `as of HH:MM:SS` if older) | Read-only OK; new items blocked offline |
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

Notes:

- "Subscribe" means a Firestore `onSnapshot` listener (or
  equivalent) keeps the local cache live.
- "Local fold" means the device runs the same `apply` from
  [`projections.md`](./projections.md) over the cached events to
  derive the projection — no separate code path.
- "Server-materialized" is a future optimization (post-M9) where
  reports are precomputed on the server; the app's interface
  does not change.

## Cache rules

1. **Cache the projection inputs, then fold.** Do not cache the
   projection output as the only truth. If folding is too slow,
   memoize the fold result keyed by the event count; invalidate
   on any new event in the projection's input set.
2. **Bounded by default.** Every cache has a bound: number of
   rows (autocomplete top N), days of events (sliding window),
   or megabytes (IndexedDB quota). On bound breach, evict by
   LRU.
3. **Versioned by schema.** Each cache key includes the
   projection's `apply` version. A domain-package bump
   invalidates every dependent cache automatically.
4. **No stale writes.** A queued write that was built against
   stale projection inputs (e.g. stock that has since gone
   negative on the server) must be revalidated by the server
   before commit; on rejection it surfaces in the Review Queue.
5. **No cross-shop cache.** Cache keys are
   `(shopId, projectionName, params)`; an app instance can
   never have two shops' caches active at once.

## Staleness display rules

The app must be honest about freshness. The rule for every
read-only view:

- If the projection's freshness is within its staleness
  tolerance (see table above): show normally.
- If older than tolerance but the network is up: refetch silently;
  show a small `Updating…` indicator if the refetch takes > 200 ms.
- If older than tolerance and the network is down: show the value
  with an explicit **As of HH:MM:SS** badge near the value, and
  an `Offline — cached` banner at the page level.
- If the cache cannot answer the query at all (data outside the
  cached window): show "Older data requires network" rather than
  guess.

No silent staleness. No spinners that hide cached values. No
fabricated zeros.

## Read path budgets

These are the per-data budgets the read path must honour on the
reference device profile in
[`performance-budgets.md`](./performance-budgets.md):

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

If a budget is not met, the responsible service either:
1. Adds an index / memoization, or
2. Moves the work to a Web Worker, or
3. Falls back to a server-materialized read.

It never silently degrades the user experience.

## Write path budgets

The write path is short by design — the UI hands the intent to a
service, the service appends an event, the projection updates
synchronously, and the row is visible.

| Write | Budget | Path |
|---|---|---|
| Save bill (online) | UI feedback ≤ 100 ms; bill visible locally ≤ 300 ms; server-confirmed ≤ 500 ms | UI → service → in-memory append → projection update → outbox flush → server ack |
| Save bill (offline) | UI feedback ≤ 100 ms; bill visible locally ≤ 300 ms; server confirmation deferred | UI → service → in-memory append → outbox |
| Request print | UI feedback ≤ 100 ms; queue accept ≤ 50 ms | UI → service → queue worker |
| Settle outstanding | UI feedback ≤ 100 ms; balances update ≤ 300 ms | Same as Save bill |
| Cash session open / close | UI feedback ≤ 100 ms; projection update ≤ 300 ms | Same as Save bill |
| Open review flag resolve | UI feedback ≤ 100 ms; queue removed ≤ 300 ms | Same |

Critical rule: **"Bill visible locally" is the user-perceived
success.** The server ack is recorded, surfaced in History
("sync: ok / pending / failed"), but does not gate the UI.

## Server vs app responsibilities

Mirrors the user's table; this is now the contract.

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

The shop must keep working when the network is gone. The
guarantees:

- **Read** all data that was in cache when the network was last
  up, with honest staleness badges.
- **Write** any event the staff can write online (sale,
  purchase, cash close, settlement, etc.), into the outbox.
- **Print** any bill, because the printer is local hardware.
- **Reject** any action that requires up-to-date server state
  (e.g. authoritative bill-number allocation — see Open items)
  with a clear message rather than guess.

When the network returns:

1. Outbox drains oldest-first.
2. Each event is reapplied on the server, idempotency-keyed.
3. Server-side rejections (schema, permission, idempotency
   conflict) raise a flag in the Review Queue per
   [`role-permission-matrix.md`](./role-permission-matrix.md).
4. The app reconciles its projections from the server's
   confirmed event ids; any divergence is itself a flag.

Outbox retention: **30 days**. Beyond that, surface a warning
("Your device hasn't synced in 30 days") and do not silently
drop. (See `decisions.md` row M11.)

## Open items

- `TODO(spec)` — **Bill number allocation offline.** Pre-allocate
  a small block per device on session open? Use a UUID locally
  and resolve to a human bill number on server reconcile? Pick
  before M5. Default: pre-allocate a small block on each session
  open; surface "offline-issued" badge on bills until reconciled.
- `TODO(spec)` — **Server-materialized reports threshold.** When
  does the app stop folding locally and start reading from a
  materialized view? Pick after measuring M9 perf. Default: 30
  days of events.
- `TODO(spec)` — **Background sync window after close-app.** Do
  we wake the app to flush outbox? In v2.0 keep it foreground-
  only; revisit after pilot.
- `TODO(spec)` — **Cross-device cache coherence.** Two devices on
  the same shop should not show conflicting Today summaries for
  more than the staleness tolerance. Document the protocol
  before M8.

## Tests this spec requires

- For every row in the placement table: a test that on the
  reference dataset, the read path meets its budget.
- For every read budget: a Playwright assertion at the phone
  viewport on the synthetic dataset.
- For every write budget: an integration test on the in-memory
  adapter plus a real-Firestore-emulator test.
- For staleness rules: a Playwright test that flips the network
  off mid-session and asserts that every page either shows fresh
  data, marks itself stale, or refuses to fabricate.
- For offline behaviour: the existing `offline-bill-replay`
  fixture in [`scenarios.md`](./scenarios.md) plus a new
  `offline-week-long` fixture that queues a week of activity
  and asserts no duplicate sales after reconnect.

## Recent changes

- _2026-06-15_ · file created. Three-layer model (shared domain
  · app layer · server layer); per-data placement table with
  staleness tolerance and offline behaviour; read- and
  write-path budgets per data type; server-vs-app
  responsibilities table; offline contract with outbox
  retention; cache versioning by domain version.
