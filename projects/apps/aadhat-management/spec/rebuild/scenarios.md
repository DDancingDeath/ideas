# Scenarios — rebuild

> Shop-day fixtures for scenario tests (`quality-bar.md` §2). Each fixture specifies setup, ordered events, expected projections, and flags.

## Conventions

- Money is paise (₹ × 100). Weights display as kg (2 dp); storage is integer milligrams (decisions row 8 / [`money-units-rounding.md`](./money-units-rounding.md)).
- `idempotencyKey` values are stable across replays.
- Scenario-specific `shopProfile` settings appear under **Profile**.
- `t+Nh` means N hours after session open, shop-local time.
- Payload bill numbers are expected counter outputs; tests assert exact match.

## Catalog

| Fixture | Covers | Layer |
|---|---|---|
| `simple-retail-day` | normal retail day | scenario |
| `wholesale-credit-sale` | credit + stock | scenario |
| `purchase-then-sale` | rate moving-average + stock | scenario |
| `cash-shortage-day-close` | mismatch flag + approval | scenario |
| `customer-udhaar-settlement` | partial multi-bill settlement | scenario |
| `staff-billing-owner-review` | discount limit + review flow | scenario |
| `bill-void-after-print` | void after success print | scenario |
| `bill-correction-after-print` | correction after success print | scenario |
| `offline-bill-replay` | outbox replay idempotency | scenario + integration |
| `double-tap-create` | client double-tap | scenario + UI |
| `double-tap-print-slow-bt` | print queue dedup | scenario + UI |
| `negative-stock-attempt` | stock flag below zero | scenario |
| `negative-stock-block` | block threshold | scenario + storage |
| `backdated-entry` | T2 flag | scenario |
| `cross-shop-isolation` | multi-shop read isolation | security |


## `simple-retail-day`

**Intent:** Walk-in retail sales paid cash + UPI; zero-mismatch close.

**Profile:** defaults; `cash.mismatchTolerance = 0`.

**Setup state:** items `Aloo`, `Pyaaz`, `Tamatar`; retail rates 35 / 30 / 40 ₹/kg; cash on hand `0`; no open session.

**Sequence:**

| # | t | Event | Key payload |
|---|---|---|---|
| 1 | t0 | `cash_session_opened` | openingCount = 50000 paise (₹500 float) |
| 2 | t+1h | `retail_sale_created` | 2 kg Aloo @ 35 → 7000; cash = 7000, online = 0, due = 0 |
| 3 | t+2h | `retail_sale_created` | 5 kg Pyaaz @ 30 → 15000; online = 15000 |
| 4 | t+3h | `retail_sale_created` | 1 kg Tamatar @ 40 → 4000; cash = 4000 |
| 5 | t+8h | `cash_session_closed` | expectedClosing = 50000 + 7000 + 4000 = 61000; closingCount = 61000; mismatch = 0 |

**Expected projections after replay:** `stock.Aloo` unchanged (S3); `cashOnHand = 61000` during session, returns to baseline after close; `outstanding` unchanged; `history` has 3 retail bills numbered `1, 2, 3`; `audit` has 5 events plus optional 2–3 print attempts (fixture skips print).

**Expected flags:** none.

**Test asserts:** projection equality on stock / cash / outstanding / history; counter numbers exactly `1, 2, 3`; no flag events.


## `wholesale-credit-sale`

**Intent:** Wholesale credit sale decrements stock and increases outstanding.

**Profile:** defaults.

**Setup state:** `Aloo` stock = 100 kg @ moving-average rate 2800 paise/kg. Party `Ramesh Traders` opening outstanding 0. Cash session open from `simple-retail-day` or independently.

**Sequence:**

| # | t | Event | Key payload |
|---|---|---|---|
| 1 | t0 | `wholesale_sale_created` | 30 kg Aloo @ 3200 → 96000; party = Ramesh Traders; payment = {online: 30000, cash: 16000, due: 50000} |

**Expected projections:** `stock.Aloo = 70 kg` (S1); `outstanding.Ramesh Traders = 50000`; `cashOnHand += 16000`; online ledger += 30000; `history` has 1 wholesale bill numbered `1`.

**Expected flags:** none (price 3200 > cost 2800).


## `purchase-then-sale`

**Intent:** Purchase updates moving-average; later wholesale sale uses the new stock.

**Profile:** defaults.

**Setup state:** `Aloo` stock = 100 kg @ moving-average 2800.

**Sequence:**

| # | t | Event | Key payload |
|---|---|---|---|
| 1 | t0 | `purchase_recorded` | 50 kg Aloo @ 3000 (line); labor = 200; grandTotal = 50×3000−200 = 149800; payment = {online: 149800, cash: 0, due: 0} |
| 2 | t+1h | `wholesale_sale_created` | 40 kg Aloo @ 3500 → 140000; party = Suresh; payment = {online: 0, cash: 0, due: 140000} |

**Expected projections:** after event 1, `stock.Aloo = 150 kg`, moving-average rate = `(100×2800 + 50×3000) / 150 = 2867 paise/kg` (S4; exact integer); after event 2, `stock.Aloo = 110 kg`, moving-average unchanged; `outstanding.Suresh = 140000`; `cashOnHand` unchanged on both events.

**Expected flags:** none (price 3500 > cost 2867).


## `cash-shortage-day-close`

**Intent:** ₹500 shortage above tolerance; flag raised; owner approves.

**Profile:** `cash.mismatchTolerance = 10000` (₹100); `cash.mismatchLarge = 100000`.

**Setup state:** session open with `openingCount = 50000`; one retail sale `cash = 30000`; expected closing = 80000.

**Sequence:**

| # | t | Event | Key payload |
|---|---|---|---|
| 1 | t0 | `cash_session_opened` | openingCount = 50000 |
| 2 | t+1h | `retail_sale_created` | cash = 30000 |
| 3 | t+8h | `cash_session_closed` | closingCount = 30000; expectedClosing = 80000; mismatch = −50000; mismatchReason = "missing" |
| 4 | t+9h | `flag_raised` | ruleId = `cash.mismatch.above-tolerance`; severity = `medium`; context = {expected: 80000, got: 30000, tolerance: 10000} |
| 5 | t+10h | `flag_resolved` | resolution = `approve`; resolvedBy = owner; note = "investigated; tip jar removed" |

**Expected projections:** `cashOnHand` reflects close; `reviewQueue.unresolved = 0` after event 5; `audit` has full chain; Today page "Needs review" shows the flag between events 4 and 5.

**Test asserts:** engine fires exactly one flag; retry does not re-fire due to idempotency; one `flag_resolved`.


## `customer-udhaar-settlement`

**Intent:** Customer pays ₹40,000 against three credit bills with partial allocation.

**Profile:** defaults.

**Setup state:** Party `Mohan` has three wholesale bills outstanding `15000, 20000, 10000`, total `45000`.

**Sequence:**

| # | t | Event | Key payload |
|---|---|---|---|
| 1 | t0 | `outstanding_payment_received` | partyId = Mohan; amount = 40000; payment = {online: 40000, cash: 0, due: 0}; againstBills = [{billId: B1, allocate: 15000}, {billId: B2, allocate: 20000}, {billId: B3, allocate: 5000}] |

**Expected projections:** `outstanding.Mohan = 5000`; per-bill B1 = 0, B2 = 0, B3 = 5000; `cashOnHand` unchanged; `audit` has one settlement referencing three bills.

**Expected flags:** none.

**Variant** (overpayment): `amount = 50000` with allocations totaling 45000 → `outstanding.settlement-overpayment`; settlement recorded with explicit prepaid balance `5000`. `TODO(spec, blocks: M<N>)` — Should overpayment be recorded with credit or rejected? **Default:** raise the flag, record the settlement, treat excess as a credit on the party.


## `staff-billing-owner-review`

**Intent:** Staff creates a retail bill with 25% discount; 10% role limit raises a flag; owner approves.

**Profile:** `pricing.maxDiscountPctByRole.staff = 10`; `.manager = 20`; `.owner = 100`.

**Setup state:** staff user `S1` active; owner user `O1` active.

**Sequence:**

| # | t | Event | Actor | Key payload |
|---|---|---|---|---|
| 1 | t0 | `retail_sale_created` | S1 | 10 kg Aloo @ 35 → 35000; discountPaise = 8750 (25%); grandTotal = 26250; payment cash = 26250 |
| 2 | t0 | `flag_raised` | engine | ruleId = `price.discount.large`; severity = `medium`; context = {pct: 25, limit: 10} |
| 3 | t+5m | `flag_resolved` | O1 | resolution = `approve` |

**Expected projections:** bill exists in History; `reviewQueue.unresolved = 0` after event 3; `audit` shows discount, flag, resolution.

**Variant** (block): with `pricing.discount.exceeds-limit` threshold 30%, event 1 appends with the flag; if the limit is `block` for staff at this magnitude, event 1 is rejected with `BLOCKED_BY_RULE` and user sees owner-approval override.


## `bill-void-after-print`

**Intent:** Sale is created, printed successfully, then voided; projections exclude sale; audit keeps events and prints.

**Profile:** defaults.

**Setup state:** none required.

**Sequence:**

| # | t | Event | Key payload |
|---|---|---|---|
| 1 | t0 | `retail_sale_created` | 2 kg Aloo → 7000; cash = 7000 |
| 2 | t+10s | `print_attempt` | jobId = J1; attemptNo = 1; outcome = `sending` |
| 3 | t+12s | `print_succeeded` | jobId = J1; attemptNo = 1; payloadHash = H1 |
| 4 | t+1h | `bill_voided` | originalBillId = B1; reason = "customer returned all items" |

**Expected projections:** bill 1 absent from sales projection; `cashOnHand` net = 0 from this bill; `history` shows state `voided` (`TODO(spec, blocks: M<N>)` — Should voided bills show in history or be filtered out? **Default:** shown with strikethrough.); print queue cancels non-terminal jobs for B1; J1 remains audit-succeeded; `audit` has all 4 events.

**Expected flags:** if staff voids a bill older than today and void needs owner approval, raise `auth.staff-edits-old-bill`; default approver gated.


## `bill-correction-after-print`

**Intent:** Printed sale is corrected; reprint uses corrected payload.

**Profile:** defaults.

**Sequence:**

| # | t | Event | Key payload |
|---|---|---|---|
| 1 | t0 | `retail_sale_created` | 2 kg Aloo @ 35 → 7000 |
| 2 | t+10s | `print_succeeded` | jobId = J1; payloadHash = H1 |
| 3 | t+5m | `bill_correction_recorded` | originalBillId = B1; corrected: 2 kg Aloo @ 30 → 6000; reason = "wrong rate" |
| 4 | t+5m | `print_attempt` (reprint) | jobId = J2; payloadHash = H2 (≠ H1) |
| 5 | t+5m | `print_succeeded` | jobId = J2 |

**Expected projections:** `history` shows B1 at corrected total 6000 with revision marker; `cashOnHand` reflects 6000; `audit` has full chain; print history shows H1 and H2.

**Expected flags:** none unless staff corrects prior-day retail bill; then `auth.staff-edits-old-bill`.


## `offline-bill-replay`

**Intent:** Offline bill outbox replay produces exactly one sale.

**Profile:** defaults.

**Sequence:**

| # | t | Event | Note |
|---|---|---|---|
| 1 | t0 | (network off) | — |
| 2 | t+30s | UI calls `createRetailBill({...}, clientActionId = K1)` | service writes to outbox; returns `pending` |
| 3 | t+5m | (network on) | outbox replays |
| 4 | t+5m | `retail_sale_created` | idempotencyKey = `bill.create:K1`; server `at` set on append |
| 5 | t+5m+1s | UI sends same `createRetailBill({...}, clientActionId = K1)` accidentally (background re-sync) | adapter returns existing event id; no second event |

**Expected projections:** exactly one `retail_sale_created` in audit; `history` shows one bill; `outbox` empty after replay.

**Test asserts:** exact event count; adapter idempotency-key dedup; bill number assigned once.


## `double-tap-create`

**Intent:** Two `createRetailBill` calls within 200 ms with same `clientActionId`; one bill exists.

**Setup state:** form opened, `clientActionId = K1`.

**Sequence:**

| # | t | Action | Expected |
|---|---|---|---|
| 1 | t0 | First `createRetailBill(..., K1)` | service in flight; UI Save button → `Saving…` disabled |
| 2 | t+150ms | Second call sneaks through (rapid resubmit / background) | adapter returns existing in-flight or completed event id |
| 3 | t+250ms | First call resolves | UI shows success |

**Expected projections:** exactly one `retail_sale_created`; UI History list shows exactly one row.

**Test asserts:** service + storage adapter; Playwright with real button.


## `double-tap-print-slow-bt`

**Intent:** Bluetooth connect takes 5 s; three Print taps produce one printout, multiple `print_attempt` events, no extra sale.

**Sequence:**

| # | t | Action | Expected |
|---|---|---|---|
| 0 | t-1m | bill B1 created and printed never before | — |
| 1 | t0 | User taps Print → enqueues job (`first-print`, B1) | queue accepts |
| 2 | t+1s | User taps Print again | queue rejects (same key, non-terminal); UI `Printing…` |
| 3 | t+3s | User taps Print again | queue rejects again |
| 4 | t+5s | Bluetooth connects | `print_attempt(connecting → sending)` events recorded |
| 5 | t+6s | `print_succeeded` | UI button → `Reprint` |

**Expected projections:** one `print_succeeded` for B1; multiple `print_attempt` rows; no second sale event.


## `negative-stock-attempt`

**Intent:** Wholesale sale pushes `Aloo` stock to −5 kg; below 0 but above block threshold. Sale stored; flag raised.

**Profile:** `stock.negative` is `medium`; `stock.negativeBlockMg = 100_000_000` (100 kg).

**Setup state:** `stock.Aloo = 10 kg`.

**Sequence:**

| # | t | Event |
|---|---|---|
| 1 | t0 | `wholesale_sale_created` 15 kg Aloo |
| 2 | t0 | `flag_raised` ruleId = `stock.negative`; context = {item: Aloo, computed: −5} |

**Expected projections:** `stock.Aloo = −5`; bill exists; flag in Review Queue.


## `negative-stock-block`

**Intent:** Wholesale sale would push stock below block threshold; adapter rejects write.

**Profile:** `stock.negativeBlockMg = 100_000_000` (100 kg).

**Setup state:** `stock.Aloo = 10 kg`.

**Sequence:**

| # | t | Action | Expected |
|---|---|---|---|
| 1 | t0 | submit `wholesale_sale_created` 200 kg Aloo | adapter returns `BLOCKED_BY_RULE`; UI offers owner override path |
| 2 | t+1m | owner overrides | owner approval appends an owner-approval event, and the new attempt references it. The override is not a rule short-circuit; it remains visible in the audit trail. |

**Expected projections:** no sale appended unless override flow completes.


## `backdated-entry`

**Intent:** Staff records purchase `billDate` 10 days ago; tolerance is 3 days; T2 flag raised.

**Profile:** `time.backdateToleranceDays = 3`.

**Setup state:** today = `2026-06-15`.

**Sequence:**

| # | t | Event |
|---|---|---|
| 1 | t0 | `purchase_recorded` billDate = `2026-06-05` |
| 2 | t0 | `flag_raised` ruleId = `time.backdated`; context = {claimedDate: '2026-06-05', toleranceDays: 3} |


## `cross-shop-isolation`

**Intent:** Reads scoped to `shopId = shop-A` exclude `shopId = shop-B`.

**Setup state:** events appended for both shops.

**Sequence:** none beyond setup.

**Test asserts:** `read({ shopId: 'shop-A' })` returns only shop-A events; `read({ shopId: 'shop-B' })` returns only shop-B events; query without `shopId` is rejected by adapter.

**Layer:** security + storage adapter.


## Coverage map

Keep this in sync when adding a fixture or event type. Audited 2026-06-16.

**Event-type coverage (the canonical ledger event types in [`event-ledger.md`](./event-ledger.md)).** "Sibling test" means a named test in another doc's *Tests this spec requires* section, not a full replay.

| Event | Catalog fixture | Sibling test / other coverage |
|---|---|---|
| `item_created` | — | data-governance gates (`item-empty-names-rejected`, `item-zero-rate-rejected`); projections Items-master |
| `item_updated` | — | data-governance (typo correction, `item-rate-above-ceiling-blocked`); projections |
| `item_archived` | — | data-governance (archived-item-in-bill gate); projections |
| `item_rate_changed` | — | data-governance (`rate-change-empty-reason-rejected`, `rate-flapping-flagged`); projections Rate-history |
| `purchase_recorded` | `purchase-then-sale` | money-units line-total; projections Live-stock |
| `retail_sale_created` | `simple-retail-day`, `staff-billing-owner-review`, `double-tap-*`, … | money-units `bill-total-retail` |
| `wholesale_sale_created` | `wholesale-credit-sale` | money-units `bill-total-wholesale-with-labor` |
| `bill_voided` | `bill-void-after-print` | projections |
| `bill_correction_recorded` | `bill-correction-after-print` | projections |
| `stock_adjustment_recorded` | — | invariants S-rules; concurrency; projections |
| `expense_recorded` | — | projections Cash-on-hand only |
| `withdrawal_recorded` | — | projections Cash-on-hand only |
| `outstanding_payment_received` | `customer-udhaar-settlement` | projections Outstanding |
| `outstanding_payment_made` | — | projections Outstanding (supplier side) only |
| `cash_session_opened` | `simple-retail-day`, `cash-shortage-day-close` | concurrency (`cash-session-second-open-blocked`) |
| `cash_session_closed` | `simple-retail-day`, `cash-shortage-day-close` | time-clock (`session-day-not-midnight`) |
| `print_attempt` | `bill-void-after-print`, `double-tap-print-slow-bt`, … | print-queue; printer-compatibility |
| `print_succeeded` | (same) | print-queue |
| `flag_raised` | `cash-shortage-day-close`, `negative-stock-attempt`, `staff-billing-owner-review`, `backdated-entry` | suspicion-engine (per rule) |
| `flag_resolved` | `cash-shortage-day-close`, `staff-billing-owner-review` | review-queue |
| `user_role_changed` | — | role-permission-matrix (matrix tests) |
| `user_status_changed` | — | role-permission-matrix |
| `shop_profile_updated` | — | suspicion-engine (config), review-queue |
| `shop_timezone_changed` | — | time-clock and reports coverage for shop-local reporting |

Some canonical ledger events have catalog fixtures; the rest have lower-level sibling tests rather than full shop-day replay.

**Scenario-shaped tests outside this catalog:** `time-clock.md` (10, e.g. `future-date-blocked`, `drift-ema-detected`), `money-units-rounding.md` (8, e.g. `rounding-half-to-even-runs`, `migration-roundtrip-equality`), `concurrency.md` (e.g. `bill-number-server-allocated-online`, `double-tap-during-reconnect`), `data-governance.md`, `projections.md`, `offline-sync.md`, `idempotency.md`, `suspicion-engine.md`, `failure-modes.md` (20 pinned tests).

**Known scenario gaps (no full shop-day fixture yet).** A full shop-day fixture lands at M8 because cash sessions bound the shop's day, making M8 the first milestone where a whole day is expressible. Remaining gaps land as their own milestone arrives. Move a gap into the Catalog table and delete its line here when implemented.

**Core lifecycle (the original 9):**

1. `rate-change-day` — `item_rate_changed` mid-day; a bill before the change keeps the old rate (rate-as-of-T), a bill after uses the new rate; Rate-history shows both points.
2. `expenses-and-withdrawals-day` — `expense_recorded` + `withdrawal_recorded` reduce cash-on-hand; day-close reconciles.
3. `supplier-payment` — `outstanding_payment_made` against a purchase credit; supplier outstanding goes to zero.
4. `item-master-lifecycle` — `item_created` → `item_updated` → `item_archived`; archived item refused in a new bill.
5. `two-device-concurrency` — shop-wide session + server bill-number allocation + stock-race-accepted-flagged per [`concurrency.md`](./concurrency.md), as a single replay.
6. `future-dated-block-day` — future-dated bill refused at adapter; draft preserved; promote `time-clock.md` `future-date-blocked` to shop-day replay.
7. `rounding-boundary-day` — half-to-even boundary; Today / Reports / Finance totals reconcile.
8. `data-quality-gates-day` — duplicate item/party, rate-above-ceiling, and empty-name attempts in one flow; promote `data-governance.md` gates.
9. `role-change` — owner promotes staff to manager; permission takes effect and `user_role_changed` is audited.

**Calculation edges (guard the "wrong-but-consistent formula" risk — see [`invariants.md`](./invariants.md) §Calculation integrity):**

10. `hundred-percent-discount` — full discount → `grandTotal == 0`; `M1` still balances with `due == 0`; no divide-by-zero downstream.
11. `multi-bag-weight-sum` — wholesale line with many bag weights; `itemTotal == round(Σweights × rate)` exactly.
12. `labor-deduction-order` — purchase with labor; `M3` `grandTotal == Σitems − labor`, proving labor is applied **after** line sum, not per line.
13. `discount-then-rounding` — line discount + bill discount + rounding in fixed order from [`money-units-rounding.md`](./money-units-rounding.md).
14. `crore-scale-bill` — very large bill; integer-paise math, no overflow, totals reconcile.
15. `mixed-payment-split` — one bill paid cash + online + due all non-zero; `M1` holds.

**Adversarial / fraud (the "staff can't quietly cheat" trust bar):**

16. `staff-skims-cash` — sale rung, cash pocketed; close mismatch raises `cash.mismatch.*`.
17. `void-after-cash-handout` — cash sale completed and printed, then voided to pocket cash; `auth.staff-edits-old-bill` + void-references-original (`B2`).
18. `phantom-discount` — staff over-discounts for a friend; `price.discount.large` / `…exceeds-limit` (`block`).
19. `below-cost-sale` — sell under moving-average cost; `price.below-cost`.
20. `backdate-to-closed-session` — bill backdated into a closed session; `time.backdated` + `bill-outside-session`.
21. `stock-adjustment-cover` — downward adjustment used to hide shrinkage; `stock.adjustment.large`.
22. `duplicate-bill-skim` — same bill rung twice quickly; `bill.duplicate.window`.

**Outstanding & counterparty:**

23. `multi-bill-FIFO-settlement` — one payment clears several bills oldest-first; per-bill allocation correct (`O3`).
24. `overpayment-settlement` — pays more than owed; `outstanding.settlement-overpayment`.
25. `receivables-aging` — dues at 10 / 40 / 70 / 100 days land in the four aging buckets in [`analytics.md`](./analytics.md) §D.

**Operational & resilience:**

26. `printer-fails-then-manual` — retries exhaust → `print_manual_recorded`; `print.exhausted`; no duplicate sale.
27. `power-cut-mid-bill` — process killed between append and print; relaunch shows sale once and print resumes (`B1`, `failure-modes.md`).
28. `day-close-with-pending-sync` — close cash while outbox is not drained; close is consistent after drain.
29. `festival-rush` — 150+ bills in an hour; counter stays monotonic and perf budgets hold.

**Multi-day & period (guard `R1`–`R4`):**

30. `void-in-next-period` — yesterday's bill voided today; reversal lands in the right period and Reports reconcile.
31. `month-spanning-report` — month-boundary activity; period totals equal replay; analytics month projection is sane.

**Rate sanity (manually-entered rate too low / too high):**

32. `fat-finger-low-rate` — sale rate **above cost** but ~1/10 typical sell rate raises `price.unusually-low`, not `price.below-cost`; correct rate raises nothing.
33. `purchase-rate-typo` — purchase rate far from recent purchase rate raises `price.purchase-rate-unusual`; bad rate does not silently shift the moving-average that `price.below-cost` / `unusually-high` / `unusually-low` depend on.

## How to add a new scenario

1. Pick a name; add a row to the catalog above.
2. Define **Intent** in one sentence.
3. List relevant **Profile** values.
4. Describe **Setup state**.
5. Tabulate **Sequence** with `#`, `t`, event/action, payload.
6. List **Expected projections** for stock / cash / outstanding / history / audit as applicable.
7. List **Expected flags** (or "none").
8. Tag the **Layer**.
9. Add a fixture file under `fixtures/` and a test that loads it and asserts.

A scenario without a corresponding test is incomplete.
