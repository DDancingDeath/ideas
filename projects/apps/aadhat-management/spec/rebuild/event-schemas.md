# Event schemas — rebuild

> Wire/storage contract for ledger events. The storage adapter rejects any event that fails its schema.

## Validation library

Runtime schemas (Zod recommended; see [`../../plan/rebuild/tech-candidates.md`](../../plan/rebuild/tech-candidates.md)) live in the shared `domain` package.

## Common envelope

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

| Field | Rule |
|---|---|
| `id`, `at`, `shopId`, `by` | Set by storage adapter; client values ignored. |
| `idempotencyKey` | Mandatory; unique per `(shopId, type)`. Shape: [`idempotency.md`](./idempotency.md). |
| `schemaVersion` | Starts at `1`; bump only when a payload field is removed or its meaning changes. Optional additions do not bump. |
| `references[].eventId` | Must exist in the same `shopId` and satisfy type-specific state rules. |

## Money representation

All amounts are integer paise (₹ × 100). Floating point is forbidden. Default schema: `z.number().int().nonnegative()` unless a field documents a signed delta (e.g. `stock_adjustment_recorded.delta`).

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
Validation: `names.en` and `names.hi` non-empty; `defaultRates.*` non-negative integers; `unit` ∈ `allowedUnits` if both present. Invariants: M4, X3. Idempotency key: `item.create:{names.en | slug}`. Invalid examples: missing `names.hi`; negative rate; unit not in `allowedUnits`.

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


### `item_updated`
```ts
payload: {
  itemId: ItemId;
  changes: Partial<Omit<ItemCreatedPayload, 'itemId'>>;
}
```
Validation: at least one field in `changes`; storage adapter rejects `itemId` mutation. Invariants: M4, X3. Idempotency key: `item.update:{itemId}:{changeHash}`.


### `item_archived`
```ts
payload: { itemId: ItemId; reason: string }
```
Validation: `reason` non-empty (≥ 5 chars); reject if item is referenced by any non-voided open draft. Idempotency key: `item.archive:{itemId}`.


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
Validation: `lines.length >= 1`; each `BillLine.weights.length >= 1`; `grandTotal == Σlines.itemTotal − laborCharges` (M3); `payment.online + payment.cash + payment.due == grandTotal` (M1); `billNumber` positive and counter-produced. Invariants: M1, M3, M4, B1, B5, S4 (rate update), T1, T2 (if backdated). Idempotency key: `bill.create:{idempotencyKey supplied by client form}`.


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
Validation: `grandTotal == Σlines.itemTotal − Σlines.discountPaise` (M2 + line discounts); `payment.online + payment.cash + payment.due == grandTotal` (M1); discounts within role limit (else `price.discount.*`). Invariants: M1, M2, M4, B1, B5. Retail does **not** touch stock (S3). Idempotency key: `bill.create:{clientActionId}`.


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
Validation: same money rules as retail; `party.partyId` required. Invariants: M1, M2, M4, B1, B5, S1, S2 (if pushes < 0). Idempotency key: `bill.create:{clientActionId}`.


### `bill_voided`
```ts
payload: { originalBillId: BillId; reason: string }
references: [{ type: 'voids', eventId: <original sale event id> }]
```
Validation: original sale exists, is not already voided, and has no outstanding correction chain that is itself voided; `reason` non-empty (≥ 5 chars). Invariants / permission: B2; role matrix (`outstanding-day` voids may need owner approval). Idempotency key: `bill.void:{originalBillId}`.


### `bill_correction_recorded`
```ts
payload: {
  originalBillId: BillId;
  correctedPayload: RetailSalePayload | WholesaleSalePayload | PurchasePayload;
  reason: string;
}
references: [{ type: 'corrects', eventId: <latest non-voided version of bill> }]
```
Validation: original exists and is not voided; `correctedPayload` passes its schema and money invariants; `originalBillId` in corrected payload equals `payload.originalBillId`. Invariants / permission: B3; role matrix. Idempotency key: `bill.correct:{originalBillId}:{correctionHash}`.


### `stock_adjustment_recorded`
```ts
payload: {
  itemId: ItemId;
  delta: number;                       // signed kg; allowed negative
  reason: string;
  context?: 'physical-count' | 'damage' | 'theft' | 'transfer' | 'other';
}
```
Validation: `delta != 0`; `reason` non-empty (≥ 5 chars). Invariants: S1, S2. Flag: if `|delta|` exceeds `shopProfile.stock.adjustmentLargeMg` → `stock.adjustment.large`. Idempotency key: `stock.adjust:{itemId}:{clientActionId}`.


### `expense_recorded`
```ts
payload: {
  category: string;                    // free text, recommend enum per shop
  amount: Paise;
  kind: 'business' | 'personal';
  payment: Payment;                    // due is normally 0 for expenses
  payee?: string;                      // optional: who was paid (v1 04-expenses "payee/person")
  note?: string;                       // optional: reason / memo for the spend
  occurredAt: IsoDate;
}
```
Validation: `amount > 0`; `payment.online + payment.cash + payment.due == amount`. Idempotency key: `expense.create:{clientActionId}`.


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
Validation: `amount > 0`; `payment.online + payment.cash == amount`; `payment.due == 0`. Idempotency key: `withdrawal.create:{clientActionId}`.


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
Validation: `amount > 0`; `payment.due == 0`; if `againstBills` present, `Σallocate == amount` and each `allocate <= bill outstanding` at write time, else `outstanding.settlement-overpayment`. Invariants: O1, O3. Idempotency key: `settle.in:{clientActionId}`.


### `outstanding_payment_made`

Symmetric to `outstanding_payment_received` (we pay a supplier). Same schema; opposite per-party outstanding effect.

Idempotency key: `settle.out:{clientActionId}`.


### `cash_session_opened`
```ts
payload: { sessionId: string; openingCount: Paise; openedAt: IsoTimestamp }
```
Validation: `openingCount >= 0`; reject if a session is already open for the same shop (C3). Idempotency key: `cash.open:{clientActionId}`.


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
Validation: `closingCount >= 0`; `expectedClosing` matches domain computation (C1); `mismatch == closingCount − expectedClosing`; if `|mismatch| > shopProfile.cash.mismatchTolerance`, raise `cash.mismatch.above-tolerance` or `.large` with mandatory `mismatchReason` (configurable). Invariants: C1, C2, C4. Idempotency key: `cash.close:{sessionId}`.


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
Validation: `attemptNo >= 1`; `errorCode` required when `outcome == 'failed'`; audit-only; never modifies a sale (B4). Idempotency key: `print.attempt:{jobId}:{attemptNo}`.


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
Validation: a `print_attempt` with same `jobId, attemptNo` and `outcome != 'failed'` exists. Idempotency key: `print.success:{jobId}:{attemptNo}`.


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
Validation: `ruleId` in registered rule set; `severity` matches the rule's configured severity in `shopProfile`. Idempotency key: `flag.raise:{ruleId}:{targetEventId | recon-window}`; prevents same rule re-fire for same event.


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
Validation: target flag exists and is unresolved; `correct` requires a `bill_correction_recorded` or `stock_adjustment_recorded` in the same shop at or before `resolvedAt`. Idempotency key: `flag.resolve:{flagId}`.


### `user_role_changed`
```ts
payload: {
  targetUserId: UserId;
  fromRole: 'staff' | 'manager' | 'owner' | 'reviewer';
  toRole: 'staff' | 'manager' | 'owner' | 'reviewer';
  reason?: string;
}
```
Validation: owner principal only (A1, A3); `fromRole != toRole`; `fromRole` equals current role at write time. Idempotency key: `user.role:{targetUserId}:{toRole}:{clientActionId}`.


### `user_status_changed`
```ts
payload: {
  targetUserId: UserId;
  fromStatus: 'pending' | 'active' | 'rejected' | 'suspended';
  toStatus: 'pending' | 'active' | 'rejected' | 'suspended';
  reason?: string;
}
```
Validation: owner principal only; transitions in `role-permission-matrix.md`. Idempotency key: `user.status:{targetUserId}:{toStatus}:{clientActionId}`.


### `shop_profile_updated`
```ts
payload: {
  changes: Partial<ShopProfile>;       // shop profile shape lives in domain
  changedBy: UserId;
}
```
Validation: owner principal only; `changes` non-empty; cannot disable a `block`-severity rule (`suspicion-engine.md` §Configurability). Role config: validate `changes.roleConfig` against **hard floors** in `role-permission-matrix.md` §Owner-configurable role visibility & capabilities; clamp grants beyond matrix ceiling; reject floor violations (escalation, owner key, visibility ⊇ action, lock-out-billing) with `SCHEMA_INVALID`. Idempotency key: `shop.profile:{changeHash}`.

---

## Referenced events not yet specified here

The 22 types above have frozen payload schemas. Names below are referenced by other rebuild docs but are not accepted by the storage adapter until they get a `###` schema block and the count is updated.

| Event | Referenced in | Purpose | Payload hints already stated | Status |
|---|---|---|---|---|
| `item_rate_changed` | [`data-governance.md`](./data-governance.md) §Rate change history | Record an item rate change as an event, never a silent edit; feeds the **Rate history per item** projection ([`projections.md`](./projections.md#rate-history-per-item)) | Mandatory non-empty `reason`; generic reason → `rate-reason-generic` flag; must carry old + new rate so bills re-fold to the rate-as-of-T | `TODO(spec, blocks: M<N>)` — Confirm whether this is its own type or a constrained `item_updated`? **Default:** none agreed. |
| `party_updated` | [`data-governance.md`](./data-governance.md) §Typo correction | Record a party (customer / supplier) field change | Carries old and new value in payload | `TODO(spec, blocks: M<N>)` — What is the full schema for `party_updated`? **Default:** none agreed. |
| `item_merged` | [`data-governance.md`](./data-governance.md) §Duplicate item merge | Merge a duplicate item into a survivor; rerouting happens at projection time, never by rewriting history | Exactly one event per merge; references both ids; no shadow updates of historical bills | `TODO(spec, blocks: M<N>)` — What is the full schema for `item_merged`? **Default:** none agreed. |
| `party_merged` | [`data-governance.md`](./data-governance.md) §Duplicate party merge | Same as `item_merged` for parties; survivor outstanding = pre-merge sum-of-outstanding | Same shape as `item_merged` | `TODO(spec, blocks: M<N>)` — What is the full schema for `party_merged`? **Default:** none agreed. |
| `print_manual_recorded` | [`printer-compatibility.md`](./printer-compatibility.md) §Manual print fallback | Owner marks a bill "printed manually"; audit-only, does **not** modify the sale | Audit-only; low-severity flag if manual marks spike | `TODO(spec, blocks: M<N>)` — What is the full schema for `print_manual_recorded`? **Default:** none agreed. |
| `shop_timezone_changed` | [`time-clock.md`](./time-clock.md) §Reports use shop timezone | Audit the owner changing the shop timezone; triggers a report-projection re-render | Old + new IANA tz; owner-only | `TODO(spec, blocks: M<N>)` — What is the full schema for `shop_timezone_changed`? **Default:** none agreed. |
| `overpayment_recorded` | [`concurrency.md`](./concurrency.md) §Open items | Explicit owner-recorded overpayment, distinct from a failed settlement | Owner-only; out of scope for v2.0 unless requested | **Proposed** — deferred, not in v2.0 |

Not ledger events:

- `screen_view`, `action_started`, `action_succeeded`, `action_failed` — analytics / telemetry events in [`observability.md`](./observability.md) §Analytics.
- `print_failed` — bill print-state in [`bill-lifecycle.md`](./bill-lifecycle.md); failed print is `print_attempt` outcome plus `flag_raised`.

`TODO(spec, blocks: M<N>)` — How does a party first enter the ledger: explicit `party_created`, or implicitly on first sale that names it? **Default:** none agreed.

---

## Versioning

- `schemaVersion` starts at `1` for every type.
- Additive optional fields do not bump it.
- Removing, renaming, retyping, or changing meaning bumps it.
- Storage adapter keeps readers for every previous version forever.
- Tests replay every fixture in `scenarios.md` through current readers and assert documented projections, including old schema versions.

## Append-time errors

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

Every error includes stable `code`, human `message`, and, in dev / staging, a test-useful `context` blob.

## Open questions

- `TODO(spec, blocks: M0)` — What remains after the frozen integer-milligram decision? **Default:** migrate `BillLine` / `Quantity` schemas and examples in **this** file from decimal kg to integer mg using `itemTotal = round(Σweights_mg × paisePerKg / 1_000_000)`; this is representation work only. See decisions row 8 and [`money-units-rounding.md`](./money-units-rounding.md).
- `TODO(spec, blocks: M<N>)` — What is the canonical case / locale for free-text fields (`category`, `reason`): store as-typed, normalized client-side, or normalized on append? **Default:** store-as-typed with normalization only for matching/search.
- `TODO(spec, blocks: M<N>)` — Do `print_attempt` events live in the main ledger or a sibling `audit` stream? **Default:** main ledger, partitioned by `type` in queries.
