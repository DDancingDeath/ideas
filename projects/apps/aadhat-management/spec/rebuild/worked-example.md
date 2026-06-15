# Worked example — one retail bill, end-to-end

> A single concrete trace of one retail bill through every layer of
> the v2 architecture. Read this once to make every other
> rebuild-spec document click into place. Every step below cites
> the spec doc it comes from.

The scenario: staff sells **2 kg of "Atta — Aashirvaad"** at
**₹50/kg** for **cash**. Net **₹100.00**. Bluetooth printer is
on; one staff device; brother is `owner`; `shopId = shop-1`.

## 0. Setup state

Before the user does anything:

- Active cash session `cs-001` is open with
  `openingCount = 200000` (₹2000 in paise).
- `item-atta-aashirvaad` exists in the items projection with
  `stockQty = 50000` mg (= 50 kg) and `movingAvgRate = 4500`
  paise/kg.
- Staff is signed in. UI shows the Billing page in retail mode.

References: [`event-ledger.md`](./event-ledger.md),
[`projections.md`](./projections.md), [`scenarios.md`](./scenarios.md)
fixture `simple-retail-day` setup template.

## 1. UI intent

Staff taps `+`, picks `Atta — Aashirvaad`, types qty `2 kg`,
confirms `₹50/kg`, taps **Save**.

The Billing component does **only** this:

1. Generates `clientActionId = "ui-bill:<uuid-v7>"` once when the
   form was opened. The same id is reused on retries (button-tap
   debounce) for the lifetime of this form instance.
2. Builds an in-memory `BillDraft` (a plain object, no event yet).
3. Calls `services.createRetailBill({ draft, clientActionId })`.
4. Disables the Save button until the service call resolves
   (B5 in [`invariants.md`](./invariants.md)).

The Billing component does **not** compute the grand total
authoritatively, does **not** subtract stock, does **not** mint
an event id, and does **not** call the printer. All of those
belong to layers below.

References: [`architecture.md`](./architecture.md) §"UI is never
the source of business truth", [`bill-lifecycle.md`](./bill-lifecycle.md),
[`idempotency.md`](./idempotency.md) §clientActionId.

## 2. Service input

`createRetailBill` receives:

```ts
{
  draft: {
    party: null,                          // walk-in
    lines: [
      { itemId: 'item-atta-aashirvaad',
        qtyMg: 2_000_000,                 // 2 kg as integer mg
        rateMilliPaisePerKg: 50_00_000 }, // ₹50/kg as paise×1000
    ],
    payment: { cash: 10_000, online: 0, due: 0 }, // ₹100 in paise
    notes: '',
  },
  clientActionId: 'ui-bill:01919c…f4',
}
```

The service:

1. Validates the draft with Zod against the
   [`event-schemas.md`](./event-schemas.md) `retail_sale_created`
   payload schema. Fail-fast on any schema error.
2. Computes the grand total in the **domain**, not in itself:
   `domain.bill.computeRetailTotal(draft) → 10_000` paise.
3. Verifies `cash + online + due == grandTotal` (M3 invariant).
4. Looks up the next bill number (transactional allocator).
5. Builds the event envelope and assigns
   `idempotencyKey = 'retail_sale_created:ui-bill:01919c…f4'`
   per [`idempotency.md`](./idempotency.md).
6. Calls `storage.appendEvent(event)`.

## 3. The event

```jsonc
{
  "id":             "01919c…f5",                 // UUID v7
  "type":           "retail_sale_created",
  "at":             "2026-06-15T14:30:11.842Z",  // server-assigned
  "clientAt":       "2026-06-15T14:30:11.198Z",
  "by":             "user-staff-01",
  "shopId":         "shop-1",
  "idempotencyKey": "retail_sale_created:ui-bill:01919c…f4",
  "schemaVersion":  1,
  "payload": {
    "billId":   "bill-2026-06-15-0042",
    "party":    null,
    "lines": [
      { "itemId": "item-atta-aashirvaad",
        "qtyMg": 2000000,
        "rateMilliPaisePerKg": 5000000,
        "lineTotal": 10000 }
    ],
    "payment":    { "cash": 10000, "online": 0, "due": 0 },
    "grandTotal": 10000,
    "notes":      ""
  },
  "references": { "cashSessionId": "cs-001" }
}
```

This is the **only** authoritative record of the sale. Stock,
cash, history, audit, Today, Reports all derive from this event
plus the rest of the log.

References: [`event-ledger.md`](./event-ledger.md),
[`event-schemas.md`](./event-schemas.md) §`retail_sale_created`.

## 4. Storage adapter

`storage.appendEvent` returns one of the codes in
[`idempotency.md`](./idempotency.md) §Adapter contract:

- `OK` — event appended.
- `IDEMPOTENCY_CONFLICT` — same `idempotencyKey` already exists
  with a different payload. Service surfaces an error, UI shows
  a flag.
- `SCHEMA_INVALID` / `INVARIANT_VIOLATION` / `PERMISSION_DENIED`
  / `OUT_OF_ORDER` — typed failure, no event written.
- Idempotent repeat (same key, same payload) → returns `OK` with
  the existing event id.

For our happy path: `OK`. The service returns the bill summary
to the UI.

## 5. Projections update

The same event flows to every projection that subscribes to its
type:

| Projection | Reaction |
|---|---|
| Live stock | `item-atta-aashirvaad.qty -= 2_000_000` mg → `48_000_000` |
| Cash on hand | `+= 10_000` → ₹2100 in `cs-001`'s active session |
| History | new `BillRow` prepended; `state = created`, `printState = pending` |
| Today summary | `totalSales += 10_000`; `paymentSplit.cash += 10_000`; bill count `+= 1` |
| Audit log | one row: `retail_sale_created — bill-2026-06-15-0042 — by user-staff-01 — ₹100` |
| Review Queue | no flag raised (within all thresholds) |

Invariants asserted after this event (any failure → block + flag):

- M1 grandTotal is integer paise.
- M3 payment sum equals grand total.
- S1 stock did not go negative.
- C1/C2 cash session activity matches the cash leg.
- A4 audit row was written, not editable.

References: [`projections.md`](./projections.md),
[`invariants.md`](./invariants.md).

## 6. UI feedback

The Billing component, on `services.createRetailBill` resolution:

1. Re-enables Save.
2. Shows toast "Bill saved" with the assigned bill number.
3. Resets the draft form.
4. Renders the Print button (initial state).

The bill row is **already visible** in History because the
History page is subscribed to the projection; the projection
updated synchronously when the event was appended.

Perf budgets for these steps come from
[`performance-budgets.md`](./performance-budgets.md):

- Tap Save → UI re-paint ≤ **100 ms**.
- New row visible in History ≤ **500 ms** online.

## 7. Print path — separate concern

Staff taps **Print**. This is a new user intent, with its own
`clientActionId`:

1. The Print button captures
   `clientActionIdForPrint = "ui-print:<uuid-v7>"`.
2. `services.requestPrint({ billId, jobKind: 'first-print', clientActionId })`
   enqueues a print job. Idempotency key:
   `print_attempt:ui-print:<uuid-v7>`.
3. The job lives in the **print queue worker** (a separate
   process / task), not the UI.
4. Button immediately transitions to `Printing…`.
5. Worker pulls the job, opens the BT socket to the paired
   ESC/POS printer, sends the rendered ticket.

If staff taps Print **again** while the worker is still talking
to the printer (slow Bluetooth):

- The Billing component sees the button is in `Printing…` state.
- The repeat tap is **rejected at the UI** with toast "Already
  printing…".
- Even if a stale `requestPrint` somehow reached the service, the
  same `clientActionIdForPrint` resolves to the same idempotency
  key — second call returns `OK` with the existing
  `print_attempt` event. **No duplicate event. No duplicate
  printout.**

Worker outcomes (each appends a `queue worker`-principal event;
see [`role-permission-matrix.md`](./role-permission-matrix.md)):

| Outcome | Event appended | UI transition |
|---|---|---|
| Printed | `print_succeeded` referencing `print_attempt` | Button → `Printed ✓` |
| Failed | `print_attempt` with `outcome: 'failed'` | Button → `Retry print` |
| Timeout (≥ 5 s) | `print_attempt` with `outcome: 'failed'`, reason `'timeout'` | Button → `Retry print`; flag `printing.timeout` (low) |

Crucial guarantee: **no print event can produce a sale event.**
The print queue is forbidden from appending sale-event types
(see [`role-permission-matrix.md`](./role-permission-matrix.md)).

References: [`print-queue.md`](./print-queue.md),
[`bill-lifecycle.md`](./bill-lifecycle.md),
[`idempotency.md`](./idempotency.md) §case 4 "print killed mid-flight".

## 8. Audit log

The audit log already shows two rows (and would show three after
print succeeds):

```
14:30:11  user-staff-01  retail_sale_created  bill-2026-06-15-0042  ₹100  (cash)
14:30:14  queue-worker   print_attempt        bill-2026-06-15-0042  first-print  attempt 1
14:30:16  queue-worker   print_succeeded      bill-2026-06-15-0042  first-print  attempt 1
```

The brother (acting as `owner`) sees these in
**Audit log** and in **Today** without any extra action.

References: [`invariants.md`](./invariants.md) §A1–A5,
[`role-permission-matrix.md`](./role-permission-matrix.md)
§"engine and queue worker principals".

## 9. Tests that prove every step

Every layer above is pinned by a test in the rebuild repo:

| Test layer | What it asserts for this flow |
|---|---|
| `unit` | `domain.bill.computeRetailTotal({lines:[…]}) === 10_000`; M1/M3 enforced |
| `scenario` | `simple-retail-day` fixture (one of the 15 in [`scenarios.md`](./scenarios.md)) replays to: stock = 48 kg, cash = ₹2100, bill in History, audit log = 3 rows, no flags |
| `invariant` | All M/S/C/B/A/R labels green on this fixture and on the property-based suite |
| `security` | Staff is **allowed** to append `retail_sale_created`; staff is **forbidden** from appending `print_succeeded` (worker-only); cross-shop variant of this event from `shop-2` is invisible to `shop-1` |
| `integration` | Same `clientActionId` called twice produces exactly one event; same `clientActionIdForPrint` called twice produces exactly one `print_attempt` |
| `playwright` | Mobile viewport: pick item, qty, rate, Save, Print; assert bill in History, mock printer received exactly one payload, button transitions hit the documented states |
| `visual` | Phone-viewport snapshots of Billing draft, Saved state, Printing state, Printed state |
| `perf` | Save-to-UI < 100 ms; row-in-History < 500 ms; Print-button transition < 100 ms |

References: [`quality-bar.md`](./quality-bar.md),
[`feature-acceptance.md`](./feature-acceptance.md),
[`ci-contract.md`](./ci-contract.md).

## 10. What this trace pins as architectural law

Re-read this list whenever a design decision is unclear:

1. **One user intent = one `clientActionId` = one event.** The UI
   never mints event ids.
2. **Money math lives in domain.** UI displays it; services
   compute it; storage records it.
3. **Stock, cash, history, audit, Today, Reports are derived.**
   Never stored as authoritative duplicates of the event log.
4. **Billing and printing are different services with different
   `clientActionId`s.** A retry on either path is idempotent.
5. **The print queue worker can append `print_*` events and
   nothing else.** Sales cannot leak in through the printer.
6. **Every event creates an audit row, automatically.** No code
   path opts out.
7. **Every projection has an `apply` fold a test can call
   directly.** If the cache disagrees with the fold, the cache
   is wrong.
8. **No feature is done without all eight test layers green for
   its scope** (see [`feature-acceptance.md`](./feature-acceptance.md)).

## Recent changes

- _2026-06-15_ · file created. One worked example end-to-end —
  UI intent → service → event → projection → print job → audit →
  tests — pinning every layer in the architecture.
