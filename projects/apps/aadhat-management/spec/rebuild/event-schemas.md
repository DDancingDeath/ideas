# Event schemas — rebuild

> The wire-and-storage shape of every event in the ledger. This file
> is the contract validated by the storage adapter and every service
> that constructs an event. If an event does not match its schema,
> the adapter rejects the append.

## Validation library

All payloads validated with a runtime schema (Zod recommended; see
[`../../plan/rebuild/tech-candidates.md`](../../plan/rebuild/tech-candidates.md)).
Schema definitions live in the shared `domain` package so client,
server (if any), and tests share one source.

## Common envelope

Every event, regardless of type, carries the same envelope:

```ts
interface EventEnvelope {
  id: string;              // UUID v7 — server-assigned, sortable by time
  type: EventType;         // discriminant; one of the names in §Types below
  at: string;              // ISO-8601 UTC, server-assigned for money/stock events
  clientAt?: string;       // ISO-8601 UTC, client-claimed (audit only)
  by: string;              // userId of the authenticated principal
  shopId: string;          // tenant key; required even for v2.0 single-shop
  idempotencyKey: string;  // see ./idempotency.md
  payload: unknown;        // type-discriminated; per-type schemas below
  references?: EventRef[]; // causal links (corrections, voids, settlements, flags)
  schemaVersion: number;   // integer; bumped on any breaking payload change
}

interface EventRef {
  type: 'corrects' | 'voids' | 'settles' | 'flags' | 'resolves' | 'caused-by';
  eventId: string;
}
```

### Envelope rules (apply to every type)

- `id`, `at`, `shopId`, `by` are set by the storage adapter, not the
  client. A client-supplied value is ignored.
- `idempotencyKey` is mandatory and unique per `(shopId, type)`. See
  [`idempotency.md`](./idempotency.md) for shape.
- `schemaVersion` starts at `1` and is bumped only when a payload
  field is removed or its meaning changes. Adding optional fields
  does not bump it.
- `references[].eventId` must exist in the same `shopId` and must
  satisfy the type-specific rule (e.g. a `voids` reference must
  point to a sale event in a non-voided state).

## Money representation

All amounts are integer paise (₹ × 100). Floating point is
forbidden. Schema enforces `z.number().int().nonnegative()` unless
the field documents a signed delta (e.g. `stock_adjustment_recorded.delta`).

## Common payload primitives

```ts
type Paise = number;                   // integer, >= 0 unless noted
type Quantity = number;                // shown as kg (2dp) in this file's examples for readability; canonical STORAGE unit is integer milligrams (decisions row 8 / money-units-rounding.md)
type IsoDate = string;                 // 'YYYY-MM-DD' shop-local date
type IsoTimestamp = string;            // ISO-8601 UTC
type ItemId = string;                  // UUID
type PartyId = string;                 // UUID
type BillId = string;                  // UUID
type UserId = string;                  // UUID matching auth principal

interface Payment {
  online: Paise;
  cash: Paise;
  due: Paise;
}                                      // invariant: online + cash + due == grandTotal

interface BillLine {
  itemId: ItemId;
  weights: Quantity[];                 // bag-by-bag weights, sum = qty
  rate: Paise;                         // ₹/kg in paise
  itemTotal: Paise;                    // = round(Σweights × rate)
  isHeavy?: boolean;                   // snapshot from item master at write time
  unit?: 'kg' | 'packet' | 'piece';    // defaults 'kg'; per item's allowed list
  discountPaise?: Paise;               // applied at line level; capped by role
}
```

## Types

### `item_created`

```ts
payload: {
  itemId: ItemId;
  names: { en: string; hi: string };
  defaultRates: { retail: Paise; wholesale: Paise; purchase: Paise };
  unit: 'kg' | 'packet' | 'piece';
  allowedUnits?: Array<'kg' | 'packet' | 'piece'>;
  isHeavy?: boolean;
  laborRatePaise?: Paise;              // per heavy packet
}
```

Validation: `names.en` and `names.hi` non-empty. `defaultRates.*`
non-negative integers. `unit` ∈ `allowedUnits` if both present.

Invariants applied: M4 (paise), X3 (schema-clean).

Idempotency key shape: `item.create:{names.en | slug}`.

Example (valid):

```json
{
  "type": "item_created",
  "payload": {
    "itemId": "01HZ...",
    "names": { "en": "Aloo", "hi": "आलू" },
    "defaultRates": { "retail": 3500, "wholesale": 3000, "purchase": 2800 },
    "unit": "kg",
    "allowedUnits": ["kg", "packet"],
    "isHeavy": false
  }
}
```

Example (invalid → reason): missing `names.hi` (required); negative
rate; unit not in allowedUnits.

---

### `item_updated`

```ts
payload: {
  itemId: ItemId;
  changes: Partial<Omit<ItemCreatedPayload, 'itemId'>>;
}
```

Validation: at least one field in `changes`. Storage adapter
rejects mutation of the `itemId`.

Invariants: M4, X3.

Idempotency key: `item.update:{itemId}:{changeHash}`.

---

### `item_archived`

```ts
payload: { itemId: ItemId; reason: string }
```

Validation: `reason` non-empty (≥ 5 chars). The adapter rejects if
the item is referenced by any non-voided open draft.

Idempotency key: `item.archive:{itemId}`.

---

### `purchase_recorded`

```ts
payload: {
  billId: BillId;
  billNumber: number;                  // assigned by counter, see B5
  billDate: IsoDate;                   // user-claimed bill date; backdating raises T2
  party: { partyId?: PartyId; name: string };
  lines: BillLine[];                   // ≥ 1
  laborCharges: Paise;                 // see M3 — deducted from grandTotal
  payment: Payment;
  grandTotal: Paise;                   // = Σlines.itemTotal − laborCharges
}
```

Validation:
- `lines.length >= 1`
- each `BillLine.weights.length >= 1`
- `grandTotal == Σlines.itemTotal − laborCharges` (M3)
- `payment.online + payment.cash + payment.due == grandTotal` (M1)
- `billNumber` is positive and matches what the counter produced

Invariants: M1, M3, M4, B1, B5, S4 (rate update), T1, T2 (if backdated).

Idempotency key: `bill.create:{idempotencyKey supplied by client form}`.

---

### `retail_sale_created`

```ts
payload: {
  billId: BillId;
  billNumber: number;
  billDate: IsoDate;
  party?: { partyId?: PartyId; name?: string };  // walk-in often empty
  lines: BillLine[];
  payment: Payment;
  grandTotal: Paise;                   // = Σlines.itemTotal (M2, no labor)
  totalDiscountPaise?: Paise;
}
```

Validation:
- `grandTotal == Σlines.itemTotal − Σlines.discountPaise` (M2 + line discounts)
- `payment.online + payment.cash + payment.due == grandTotal` (M1)
- discounts within role limit (else `price.discount.*` rule)

Invariants: M1, M2, M4, B1, B5. Note: retail does **not** touch
stock (S3).

Idempotency key: `bill.create:{clientActionId}`.

---

### `wholesale_sale_created`

```ts
payload: {
  billId: BillId;
  billNumber: number;
  billDate: IsoDate;
  party: { partyId: PartyId; name: string };  // ledger-aware; partyId required
  lines: BillLine[];
  payment: Payment;
  grandTotal: Paise;
}
```

Validation: same money rules as retail; `party.partyId` required.

Invariants: M1, M2, M4, B1, B5, S1, S2 (if pushes < 0).

Idempotency key: `bill.create:{clientActionId}`.

---

### `bill_voided`

```ts
payload: { originalBillId: BillId; reason: string }
references: [{ type: 'voids', eventId: <original sale event id> }]
```

Validation: original sale event must exist, must not already be
voided, must not have an outstanding correction chain that is
itself voided. `reason` non-empty (≥ 5 chars).

Invariants: B2. Permission: see role matrix (`outstanding-day`
voids may need owner approval).

Idempotency key: `bill.void:{originalBillId}`.

---

### `bill_correction_recorded`

```ts
payload: {
  originalBillId: BillId;
  correctedPayload: RetailSalePayload | WholesaleSalePayload | PurchasePayload;
  reason: string;
}
references: [{ type: 'corrects', eventId: <latest non-voided version of bill> }]
```

Validation: original must exist and not be voided. `correctedPayload`
must itself pass the schema for its type and the money invariants.
`originalBillId` in the corrected payload equals `payload.originalBillId`.

Invariants: B3. Permission per role matrix.

Idempotency key: `bill.correct:{originalBillId}:{correctionHash}`.

---

### `stock_adjustment_recorded`

```ts
payload: {
  itemId: ItemId;
  delta: number;                       // signed kg; allowed negative
  reason: string;
  context?: 'physical-count' | 'damage' | 'theft' | 'transfer' | 'other';
}
```

Validation: `delta != 0`. `reason` non-empty (≥ 5 chars).

Invariants: S1, S2. If `|delta|` exceeds `shopProfile.stock.adjustmentLargeKg`
→ `stock.adjustment.large` flag.

Idempotency key: `stock.adjust:{itemId}:{clientActionId}`.

---

### `expense_recorded`

```ts
payload: {
  category: string;                    // free text, recommend enum per shop
  amount: Paise;
  kind: 'business' | 'personal';
  payment: Payment;                    // due is normally 0 for expenses
  note?: string;
  occurredAt: IsoDate;
}
```

Validation: `amount > 0`. `payment.online + payment.cash + payment.due == amount`.

Idempotency key: `expense.create:{clientActionId}`.

---

### `withdrawal_recorded`

```ts
payload: {
  amount: Paise;
  payee: string;
  payment: Payment;
  note?: string;
  occurredAt: IsoDate;
}
```

Validation: `amount > 0`. `payment.online + payment.cash == amount`,
`payment.due == 0` (withdrawals are not credit).

Idempotency key: `withdrawal.create:{clientActionId}`.

---

### `outstanding_payment_received`

```ts
payload: {
  partyId: PartyId;
  amount: Paise;
  againstBills?: Array<{ billId: BillId; allocate: Paise }>;
  payment: Payment;                    // due must be 0
  occurredAt: IsoDate;
  note?: string;
}
references: againstBills.map(b => ({ type: 'settles', eventId: b.billId }))
```

Validation: `amount > 0`. `payment.due == 0`. If `againstBills`
present, `Σallocate == amount` and each `allocate <= bill outstanding`
at time of write (else `outstanding.settlement-overpayment` flag).

Invariants: O1, O3.

Idempotency key: `settle.in:{clientActionId}`.

---

### `outstanding_payment_made`

Symmetric to `outstanding_payment_received` (we pay a supplier).
Same schema; differs only in direction of effect on per-party
outstanding.

Idempotency key: `settle.out:{clientActionId}`.

---

### `cash_session_opened`

```ts
payload: { sessionId: string; openingCount: Paise; openedAt: IsoTimestamp }
```

Validation: `openingCount >= 0`. Rejected if a session is already
open for the same shop (C3).

Idempotency key: `cash.open:{clientActionId}`.

---

### `cash_session_closed`

```ts
payload: {
  sessionId: string;
  closingCount: Paise;
  expectedClosing: Paise;
  mismatch: number;                    // closingCount − expectedClosing (signed)
  mismatchReason?: string;
  closedAt: IsoTimestamp;
}
references: [{ type: 'caused-by', eventId: <cash_session_opened event> }]
```

Validation: `closingCount >= 0`. `expectedClosing` matches the
domain's computation (C1). `mismatch == closingCount − expectedClosing`.
If `|mismatch| > shopProfile.cash.mismatchTolerance` →
`cash.mismatch.above-tolerance` (or `.large`) flag with mandatory
`mismatchReason` (configurable).

Invariants: C1, C2, C4.

Idempotency key: `cash.close:{sessionId}`.

---

### `print_attempt`

```ts
payload: {
  billId: BillId;
  jobId: string;
  attemptNo: number;                   // 1-based
  outcome: 'queued' | 'connecting' | 'sending' | 'failed';
  errorCode?: string;
  errorMessage?: string;
  printerInfo?: { name: string; mac?: string };
  startedAt: IsoTimestamp;
  finishedAt?: IsoTimestamp;
}
references: [{ type: 'caused-by', eventId: <sale event id> }]
```

Validation: `attemptNo >= 1`. `errorCode` required when
`outcome == 'failed'`. Audit-only; never modifies a sale (B4).

Idempotency key: `print.attempt:{jobId}:{attemptNo}`.

---

### `print_succeeded`

```ts
payload: {
  billId: BillId;
  jobId: string;
  attemptNo: number;
  printerInfo?: { name: string; mac?: string };
  payloadHash: string;                 // hash of the ESC/POS bytes sent
  finishedAt: IsoTimestamp;
}
references: [{ type: 'caused-by', eventId: <sale event id> }]
```

Validation: a `print_attempt` with the same `jobId, attemptNo` and
`outcome != 'failed'` exists.

Idempotency key: `print.success:{jobId}:{attemptNo}`.

---

### `flag_raised`

```ts
payload: {
  flagId: string;
  ruleId: string;                      // matches a rule in suspicion-engine.md
  severity: 'low' | 'medium' | 'high' | 'block';
  summary: string;                     // one line, human-readable
  context: Record<string, unknown>;    // rule-specific structured data
  raisedAt: IsoTimestamp;
  raisedBy: 'engine' | UserId;
}
references: [{ type: 'flags', eventId: <target event id, optional for background flags> }]?
```

Validation: `ruleId` must be in the registered rule set. `severity`
matches the rule's configured severity in `shopProfile`.

Idempotency key: `flag.raise:{ruleId}:{targetEventId | recon-window}`.
Prevents the engine re-firing the same rule for the same event.

---

### `flag_resolved`

```ts
payload: {
  flagId: string;
  resolution: 'approve' | 'dismiss' | 'correct';
  note?: string;
  resolvedAt: IsoTimestamp;
  resolvedBy: UserId;
}
references:
  [{ type: 'resolves', eventId: <flag_raised event id> }]
  + (resolution === 'correct'
      ? [{ type: 'caused-by', eventId: <correction event id> }]
      : [])
```

Validation: target flag exists and is unresolved. `correct`
resolution requires a `bill_correction_recorded` or
`stock_adjustment_recorded` event in the same shop at or before
`resolvedAt`.

Idempotency key: `flag.resolve:{flagId}`.

---

### `user_role_changed`

```ts
payload: {
  targetUserId: UserId;
  fromRole: 'staff' | 'manager' | 'owner' | 'reviewer';
  toRole: 'staff' | 'manager' | 'owner' | 'reviewer';
  reason?: string;
}
```

Validation: only the owner principal can append this (A1, A3).
`fromRole != toRole`. `fromRole` must equal the current role at
write time.

Idempotency key: `user.role:{targetUserId}:{toRole}:{clientActionId}`.

---

### `user_status_changed`

```ts
payload: {
  targetUserId: UserId;
  fromStatus: 'pending' | 'active' | 'rejected' | 'suspended';
  toStatus: 'pending' | 'active' | 'rejected' | 'suspended';
  reason?: string;
}
```

Validation: only owner principal. Status transitions documented in
`role-permission-matrix.md`.

Idempotency key: `user.status:{targetUserId}:{toStatus}:{clientActionId}`.

---

### `shop_profile_updated`

```ts
payload: {
  changes: Partial<ShopProfile>;       // shop profile shape lives in domain
  changedBy: UserId;
}
```

Validation: only owner principal. `changes` non-empty. Disabling a
`block`-severity rule is rejected (`suspicion-engine.md` §Configurability).

Idempotency key: `shop.profile:{changeHash}`.

---

## Referenced events not yet specified here

The 22 types above are the ones with a frozen payload schema. The
following event names are **referenced by other rebuild docs** but
do not yet have a full schema in this file. Each must get one (a
`###` block above, and a bump of the count) **before** the
milestone that first emits it. Until then the storage adapter does
not accept them. This table is the single reconciliation point so
the registry and the prose docs do not silently drift.

| Event | Referenced in | Purpose | Payload hints already stated | Status |
|---|---|---|---|---|
| `item_rate_changed` | [`data-governance.md`](./data-governance.md) §Rate change history | Record an item rate change as an event, never a silent edit; feeds the **Rate history per item** projection ([`projections.md`](./projections.md#rate-history-per-item)) | Mandatory non-empty `reason`; generic reason → `rate-reason-generic` flag; must carry old + new rate so bills re-fold to the rate-as-of-T | `TODO(spec)` — confirm whether this is its own type or a constrained `item_updated` |
| `party_updated` | [`data-governance.md`](./data-governance.md) §Typo correction | Record a party (customer / supplier) field change | Carries old and new value in payload | `TODO(spec)` |
| `item_merged` | [`data-governance.md`](./data-governance.md) §Duplicate item merge | Merge a duplicate item into a survivor; rerouting happens at projection time, never by rewriting history | Exactly one event per merge; references both ids; no shadow updates of historical bills | `TODO(spec)` |
| `party_merged` | [`data-governance.md`](./data-governance.md) §Duplicate party merge | Same as `item_merged` for parties; survivor outstanding = pre-merge sum-of-outstanding | Same shape as `item_merged` | `TODO(spec)` |
| `print_manual_recorded` | [`printer-compatibility.md`](./printer-compatibility.md) §Manual print fallback | Owner marks a bill "printed manually"; audit-only, does **not** modify the sale | Audit-only; low-severity flag if manual marks spike | `TODO(spec)` |
| `shop_timezone_changed` | [`time-clock.md`](./time-clock.md) §Reports use shop timezone | Audit the owner changing the shop timezone; triggers a report-projection re-render | Old + new IANA tz; owner-only | `TODO(spec)` |
| `overpayment_recorded` | [`concurrency.md`](./concurrency.md) §Open items | Explicit owner-recorded overpayment, distinct from a failed settlement | Owner-only; out of scope for v2.0 unless requested | **Proposed** — deferred, not in v2.0 |

Also referenced but deliberately **not** ledger events (do not add
them here):

- `screen_view`, `action_started`, `action_succeeded`,
  `action_failed` — analytics / telemetry events defined in
  [`observability.md`](./observability.md) §Analytics, not ledger
  appends.
- `print_failed` — a **bill print-state** in
  [`bill-lifecycle.md`](./bill-lifecycle.md), not an event type. A
  failed print is a `print_attempt` outcome plus a `flag_raised`.

`TODO(spec)`: parties are updated and merged above but there is no
`party_created` event anywhere in the spec. Decide how a party
first enters the ledger (explicit `party_created`, or implicitly on
first sale that names it) before the party-management milestone.

---

## Versioning

- `schemaVersion` starts at `1` for every type.
- Additive changes (new optional field) do not bump it.
- Removing a field, renaming a field, changing a field's type, or
  changing the meaning of a field bumps it. The storage adapter
  must keep a reader for every previous version forever.
- Test suite asserts: every fixture in `scenarios.md` replayed
  through the current readers produces the documented projections,
  including fixtures recorded under old schema versions.

## Append-time errors

The storage adapter returns one of:

| Code | Meaning |
|---|---|
| `OK` | Appended (or duplicate idempotency key, returning existing eventId) |
| `SCHEMA_INVALID` | Payload failed Zod validation; client bug |
| `INVARIANT_VIOLATION` | Money/stock/cash invariant failed; client bug or tampering |
| `PERMISSION_DENIED` | Principal cannot append this event type |
| `REFERENCE_INVALID` | A `references[]` entry is missing or wrong state |
| `IDEMPOTENCY_CONFLICT` | Same key, different payload (see `idempotency.md`) |
| `BLOCKED_BY_RULE` | A `block`-severity suspicion rule rejected the write |
| `OUT_OF_ORDER` | Causally impossible sequencing (e.g. close before open) |
| `UNAUTHORIZED` | No authenticated principal |

Every error includes a stable `code`, a human `message`, and (in
dev / staging) a `context` blob useful for tests.

## Open questions

- `TODO(spec)`: weight-unit **decision is frozen** — integer
  milligrams (decisions row 8; formulas in
  [`money-units-rounding.md`](./money-units-rounding.md)). What
  remains is mechanical: the `BillLine` / `Quantity` schemas and
  examples in **this** file still express weights as decimal kg
  with `itemTotal = round(Σweights × rate)` (rate as ₹/kg). Migrate
  these literal schemas and example values to the integer-mg model
  (`itemTotal = round(Σweights_mg × paisePerKg / 1_000_000)`)
  during M0. This is a representation change, not an open decision.
- `TODO(spec)`: Decide the canonical case / locale for free-text
  fields (`category`, `reason`) — store as-typed, normalized
  client-side, or normalized on append? Recommend store-as-typed
  with normalization only for matching/search.
- `TODO(spec)`: Decide whether `print_attempt` events live in the
  main ledger or a sibling `audit` stream. Default: main ledger,
  partitioned by `type` in queries.

## Recent changes

- _2026-06-16_ (later) · Reframed the stale weight-unit `TODO(spec)`
  in §Open questions from "decide kg vs mg before M0" to "decision is
  frozen (decisions row 8 = integer mg); migrate this file's kg
  schemas/examples to the mg model during M0". The decision was
  already frozen in `decisions.md` row 8 and
  [`money-units-rounding.md`](./money-units-rounding.md); only the
  literal schemas here still used kg. Annotated the `Quantity`
  primitive comment accordingly. No schema values changed.
- _2026-06-16_ · Added the `## Referenced events not yet specified
  here` reconciliation table. It names every event referenced by
  other rebuild docs that does not yet have a frozen schema here
  (`item_rate_changed`, `party_updated`, `item_merged`,
  `party_merged`, `print_manual_recorded`, `shop_timezone_changed`,
  and the proposed `overpayment_recorded`), so the canonical
  registry and the prose docs stop drifting. Also documented which
  referenced names are deliberately **not** ledger events
  (telemetry `screen_view` / `action_*`; the `print_failed` bill
  state) and flagged the missing `party_created` event as a
  `TODO(spec)`. No payloads were invented; all entries are
  `TODO(spec)` / Proposed.
