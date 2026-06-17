# Architecture — rebuild

## Principle

> **The UI is never the source of business truth.**
>
> A bill total, a stock level, an outstanding balance, or a cash
> reconciliation must be computable from the event ledger by code
> that knows nothing about React, Svelte, Capacitor, Firestore, or
> Bluetooth. If a component renders a number, it asks the domain for
> it; it does not calculate it.

This is the single most important architectural rule. v1 mixed
business math into modules that also touched the DOM and Firebase,
which is why the same number can disagree between Finance, Reports,
and Analytics if any caller bypasses `PeriodMath`. v2 fixes this by
splitting layers and not letting them leak.

## Layers

```
┌──────────────────────────────────────────────────────────────┐
│ 5. Device integrations                                       │
│    Bluetooth printer driver, mic / SpeechRecognition,        │
│    camera / barcode (later), Capacitor bridges.              │
│    Replaceable in tests with mocks.                          │
├──────────────────────────────────────────────────────────────┤
│ 4. UI (mobile-first web app)                                 │
│    Pages, components, routing, input forms, screen state.    │
│    Knows about layout, gestures, focus, accessibility.       │
│    Calls application services. Never calculates totals.      │
├──────────────────────────────────────────────────────────────┤
│ 3. Application services (use cases)                          │
│    createRetailBill, recordPurchase, settleOutstanding,      │
│    openCashSession, closeCashSession, adjustStock,           │
│    voidBill, requestPrint, retryPrint.                       │
│    Orchestrate domain + storage + queue. No UI imports.      │
├──────────────────────────────────────────────────────────────┤
│ 2. Storage adapters                                          │
│    Firestore / Postgres / SQLite client, outbox queue,       │
│    print queue, audit log writer, scenario fixtures loader.  │
│    Implements interfaces defined by the domain.              │
├──────────────────────────────────────────────────────────────┤
│ 1. Domain core (pure)                                        │
│    Bill math, stock math, cash reconciliation, udhaar        │
│    ledger, period aggregations, payment-split rules,         │
│    permission rules, invariant checks, event types.          │
│    No I/O. No framework. No async I/O. Runs in Node + browser│
│    + tests with no shims.                                    │
└──────────────────────────────────────────────────────────────┘
```

## What lives where

### Domain core (layer 1)

- All money math: per-item total, bill total, labor calculation
  (purchase deducts; retail has none), payment split invariant,
  rounding rules, discount limits.
- All stock math: derived quantity from `purchase`, `wholesale_sale`,
  `stock_adjustment` events.
- All cash math: opening + activity = expected closing; mismatch
  detection; tolerance comparison.
- All outstanding math: per-party ledger from sale/payment events.
- All period aggregations (the v2 successor to `PeriodMath`).
- Permission rules as pure functions: `canUserPerform(action, user,
  context) → allow | deny | needs-approval`.
- Event type definitions and the `apply(state, event) → state` fold.
- Invariant checks (see `invariants.md`).

### Application services (layer 3)

Each use case is one function. Signature shape:

```
createRetailBill(input, ctx) → { billId, events[], flags[] }
```

Rules:

- Generates the `billId` (idempotency key) once.
- Validates input via shared schema (e.g. Zod).
- Runs domain calculations.
- Produces the list of events to append (never mutates existing
  events).
- Runs the suspicion engine; attaches resulting `flags[]`.
- Writes events through the storage adapter.
- Enqueues print job through the print queue (does not print
  itself).
- Returns the result. Idempotent on repeated calls with the same
  `idempotencyKey`.

Services may call other services only via their public function
boundaries — no shared mutable state.

### Storage adapters (layer 2)

- One adapter per backend choice; the rest of the app codes against
  interfaces.
- The event store is **append-only** at the adapter level. There is
  no `update` or `delete` API on events. Corrections are new events
  that reference the original (see `event-ledger.md`).
- Read models (current stock, current cash, current outstanding,
  per-day reports) are derived projections. v2 may cache them, but
  the cache is always rebuildable from events.
- The outbox queue persists pending writes when offline; replay is
  idempotent (see `bill-lifecycle.md`).
- The print queue persists pending print jobs; retries are tracked
  as `print_attempt` events, never as new bills.

### UI (layer 4)

- Mobile-first. Phone-sized viewport is the design target; tablet
  and PWA-on-desktop are secondary.
- Forms submit through application services and immediately reflect
  optimistic UI from the service's return value.
- No component owns money math. If a number is on screen, its source
  is either:
  - a value returned by a service call, or
  - a value read from a domain-provided selector that takes events.
- Long-running operations (print, sync, report generation, audit
  export) must not block the UI thread. They return a job handle and
  the UI subscribes to its status.

### Device integrations (layer 5)

- Each integration has a documented interface and a mock used in
  tests.
- The printer interface exposes: `connect()`, `print(payload)`,
  `getStatus()`. It does not know about bills.
- The mic / SpeechRecognition interface exposes a stream of
  transcripts; parsing lives in domain.

## Data flow for a typical retail bill

1. UI collects form fields and calls
   `createRetailBill({ items, payment, ... }, ctx)`.
2. Service generates `billId` (UUID v7 or equivalent), constructs
   `retail_sale_created` event, runs domain math, validates
   invariants, runs suspicion engine.
3. Service appends event(s) to the store. Either the write succeeds
   immediately or it is queued in the outbox.
4. Service enqueues a print job referencing `billId`.
5. Service returns `{ billId, status: 'created', flags }` to the UI.
6. UI shows the bill in History (read from the derived projection,
   which already reflects the new event) and shows the print job
   status next to it.
7. Print queue worker, on its own schedule, picks up the job, sends
   to the printer, records `print_attempt` events. UI updates the
   row's print status from the queue.

The UI is never waiting for the printer to decide whether the bill
exists. The bill exists the moment step 3 succeeds.

## Why this matters for testability

- Domain core has zero I/O, so its tests run in milliseconds.
- Services can be tested against an in-memory storage adapter and a
  mock printer; full scenario tests run without Firebase or Android.
- UI tests (Playwright) can swap real services for fakes that drive
  the screen through any state in two API calls.
- Security tests run against the storage adapter's authorization
  layer directly, with no need to spin up a real backend.

## Engineering conventions

Cross-cutting rules every layer and every agent follows. They are
not business invariants (those live in [`invariants.md`](./invariants.md));
they are how the code is built so the invariants are cheap to keep.

### Entity identity — reference by stable id, never by name

- Every entity (item, party, bill, cash session, user, flag) has a
  **stable, opaque, immutable id** (`itemId`, `partyId`, `billId`,
  `sessionId`, `userId`, `flagId`) assigned once at creation. That id
  is the only key.
- **A name is display data, never a key.** Names are mutable, can
  repeat, exist in Hindi *and* English, and are corrected over time.
  Keying by name is the v1 mistake that produced ghost stock rows
  under `itemName` while the canonical key was `itemId`
  ([`../../plan/review-issues.md`](../../plan/review-issues.md)
  WALK-27) and forced `05-items.md` to call the English name the
  "canonical key". v2 does not repeat it.
- Projections key by id (`Map<itemId, …>`); event payloads carry ids;
  the UI resolves a name → id **once** at pick time and then carries
  the id. A rename is an `item_updated` / `party_updated` event — the
  id is unchanged, so history and stock stay intact.
- Ids are opaque: do not encode meaning in them, do not parse them,
  and do not use them for business ordering (use `at` / `seq`).

### Robust data structures and algorithms

- **Pick the structure that makes the wrong state unrepresentable and
  the invariant cheap.** Keyed maps (by id) for O(1) lookup; never an
  array scan by name on a hot path.
- **No super-linear work on the hot paths** (bill create, projection
  fold, append). Folds are O(events); lookups are O(1)/O(log n);
  avoid nested scans of the log. If a path needs more, memoize a
  projection — never recompute per render.
- **Exact integer arithmetic** for money/weight (paise/mg), with
  BigInt wherever a product can exceed 2^53 (e.g. crore-scale line
  totals). No floating-point money, ever (`M4`).
- **Algorithms are deterministic and total** — defined for empty,
  single, duplicate, and very large inputs; no `NaN` / `undefined`
  leaks (v1's divide-by-zero chart bug, WALK-38). Any randomness in a
  test runs under a fixed seed (`ci-contract.md` §invariant).
- **Append-only, immutable data wins.** Corrections and voids are new
  events; never mutate history in place.
- **Bound everything** — outbox retention, list sizes, retry counts.
  No unbounded growth, no unbounded loops.


  (offline-first with sync) or splits a small server component for
  authoritative event ordering. Default assumption: client-only with
  Firestore / backend-as-a-service, matching v1.
- `TODO(spec)`: Decide if event projections are materialized in the
  database (server-side) or computed in the client on subscription.
  Default assumption: client-side projections in v2.0, with the
  option to move to server-side later.

## Recent changes

- _2026-06-17_ · Added `## Engineering conventions` — two cross-cutting
  guidelines the agents and code follow: (1) **entity identity** —
  reference every entity by a stable opaque id (`itemId`, `partyId`,
  `billId`, …), never by name (names are mutable display data; keying
  by name caused the v1 WALK-27 ghost-stock bug); (2) **robust data
  structures and algorithms** — keyed maps over name scans, no
  super-linear work on hot paths, exact integer money math with
  BigInt, deterministic/total algorithms (no NaN leaks), append-only
  immutable data, bound everything.
