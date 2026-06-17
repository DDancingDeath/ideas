# Quality bar — rebuild

## Principle

> **A feature is not done until its tests prove the business numbers
> stay correct, the UI does not hang, and the suspicion engine
> catches what it is supposed to catch.**

This document is the contract for "done". It is intentionally strict
because the owner has named testing as the top priority for the
rebuild.

## Required test layers

Every feature lands with a contribution to each layer it touches.

### 1. Unit tests (domain core)

- Pure functions only. No I/O. Run in milliseconds.
- Cover every formula in `architecture.md` layer 1: bill totals,
  labor (purchase deducts; retail has none), payment-split
  invariant, stock derivation, cash reconciliation, outstanding
  per party, period aggregations, permission rules.
- Minimum: every domain function has at least one positive case
  and one negative / edge case.

### 2. Scenario tests (fixtures → expected projections)

Scenarios are the heart of the suite. Each is a sequence of events
plus the expected final values of every projection.

Required fixtures for v2.0:

| Fixture | Covers |
|---|---|
| `simple-retail-day` | open session, several retail sales, mixed payment, close session, mismatch zero |
| `wholesale-credit-sale` | wholesale sale on credit, outstanding correctly created, stock correctly decremented |
| `purchase-then-sale` | purchase recorded, moving-average rate updated, subsequent wholesale sale uses new stock |
| `cash-shortage-day-close` | close with mismatch above tolerance, flag raised, owner approves with reason |
| `customer-udhaar-settlement` | outstanding payment received against multiple bills, partial allocation |
| `staff-billing-owner-review` | staff creates bill with discount > limit, flag raised, owner approves / corrects |
| `bill-void-after-print` | sale created, printed, voided; projections exclude it, audit retains everything including print |
| `bill-correction-after-print` | sale created, printed, corrected; latest values in projections, reprint uses corrected payload |
| `offline-bill-replay` | network off, bill saved to outbox, reconnect; exactly one sale, idempotent replay |
| `double-tap-create` | same `clientActionId` fires twice; exactly one sale |
| `double-tap-print-slow-bt` | three taps within 5s on a slow connection; one printout, three UI attempts, one `print_attempt` event |
| `negative-stock-attempt` | wholesale sale that would push stock < 0; flag raised, sale stored |
| `negative-stock-block` | wholesale sale beyond block threshold; rejected; user offered override path |
| `backdated-entry` | bill_date older than tolerance; flag raised |
| `cross-shop-isolation` | event from `shopId=A` is invisible to `shopId=B`'s reads (when multi-shop is enabled) |

Each fixture is replayed in tests and the projection results must
match the expected snapshot exactly. Scenario tests run on every
PR.

### 3. Invariant tests (R1–R4 and friends)

For every scenario fixture and for every random seed in the
property-based suite:

- `R1`: `report(period).totalSales == replay(events ∈ period).totalSales`
- `R2`: `report(end-of-period).cashOnHand == replay(cash events).cashOnHand`
- `R3`: `report(end-of-period).outstanding == replay(outstanding events).outstanding`
- `R4`: Today / Finance / Reports / Analytics show identical numbers
  for any period they all render
- Plus all entries in `invariants.md` (M1–M5, S1–S4, O1–O3, C1–C5,
  B1–B5, A1–A5, X1–X3, T1–T2)

An invariant failure is a `Sev-1` and blocks the build.

### 4. Property-based tests

Generate random valid event sequences (purchases, sales, payments,
voids, corrections, settlements) with bounded sizes. For each
sequence assert:

- Every invariant in `invariants.md` holds, or a corresponding
  `flag_raised` was emitted, or the storage adapter rejected the
  write.
- Replaying the same event log twice produces identical
  projections.
- Reordering commutative events (purchases on different items)
  yields identical final projections.

Recommended library: a property-based runner (`fast-check` or
equivalent — see `plan/rebuild/tech-candidates.md`).

### 5. Integration tests (services + storage)

- Each application service is run against an in-memory storage
  adapter plus a mock print queue and a mock printer driver.
- Tests for: idempotency, outbox replay, server-assigned
  timestamps, transactional bill numbering, authorization
  enforcement, flag generation.

### 6. Security-rule tests

If using Firestore: against the emulator.
If using another backend: against the real rules layer in test
mode.

- Unauthenticated principal cannot read or write anything.
- Staff cannot append owner-only event types.
- Staff cannot read finance-restricted projections.
- Manager has the allowed subset, no more.
- Owner has everything.
- Audit log is read-only for every role.
- Cross-shop reads return empty (and writes are rejected).
- Idempotency key cannot be reused with a different payload.

### 7. End-to-end tests (Playwright or equivalent)

Cover real user workflows. Keep the suite small but every test
genuinely drives the screen.

Mandatory flows:

- Login as staff → create retail bill → see in History → mocked
  printer confirms → cash close shows it
- Login as owner → see Review Queue → resolve a flag of each kind
- Staff fails to access owner-only page (redirect / blocked)
- Slow Bluetooth: tap Print 3× within 2s; verify one printout
- Network kill mid-create: reconnect; verify exactly one sale
- Print-then-void; print-then-correct
- Settle outstanding against one bill, against multiple bills
- Open and close a cash session with a mismatch above tolerance
- Today / Finance / Reports agree on the same period (R4)
- Hindi / English labels render and fit on phone viewport

**Selector convention.** E2E flows select elements by a stable
`data-testid` (or ARIA role + an `aria-label` key) — **never by
visible text.** The UI is Hindi/English bilingual and labels switch
by mode, so a text selector (`getByText('Save' / 'सहेजें')`) is
inherently flaky and would force a separate selector per language.
The *same* flow must pass unchanged in both language modes by keying
on language-independent test-ids. Every interactive control a flow
touches carries a `data-testid`; adding one is part of building the
feature, not an afterthought in the test.

### 8. Visual regression tests

Screenshot the following at the phone viewport (configured exact
size in test setup):

- Today page
- Billing page (purchase + retail + wholesale modes)
- History page with mixed bills
- Stock page
- Outstanding page
- Cash close page with mismatch
- Reports page
- Review Queue with at least one of each severity
- All major pages in Hindi-leading and English-leading label modes

Snapshot diffs above a small tolerance fail the build.

### 9. Performance tests

The "no UI hang" bar is a product requirement, not polish. The
following must hold on a mid-range Android phone (`TODO(spec)`:
pick a reference device):

| Action | Budget |
|---|---|
| Tap Save on a bill | UI responds within 100 ms; sale appears in History within 500 ms when online |
| Tap Print | Button transitions to `Printing…` within 100 ms; UI thread remains responsive (no input lost) |
| Open History | First page of recent bills paints within 500 ms |
| Open Today | All KPIs paint within 500 ms |
| Open Reports for "last month" | First chart paints within 1500 ms |
| Switch tabs | < 100 ms transition; no input dropped |
| Voice billing | First-token-to-form-field within 300 ms after the user stops speaking |

These budgets are asserted in automated perf tests (frame-time
sampling, long-task counting) on a defined synthetic dataset.

### 10. Printer-mock tests

- ESC/POS payload assertions: line width, alignment, Hindi /
  English mix, totals row, footer, reprint marker, correction
  marker.
- Failure simulation: disconnect mid-send; timeout on ACK; printer
  out of paper; wrong protocol version.
- Reprint of a corrected bill uses the corrected payload, not the
  cached original.

### 11. Offline / sync tests

- App loads from cache when offline.
- Bill draft survives reload.
- Outbox queues writes when offline.
- Reconnect replays writes; idempotency keys prevent duplicates.
- Conflict resolution (same `billId` proposed from two devices) is
  deterministic and surfaces a flag if mismatch.

### 12. Accessibility tests

- All interactive elements are reachable by keyboard / focus order.
- Touch targets ≥ 44×44 dp.
- Color contrast meets WCAG AA for body text.
- Screen-reader labels exist for primary actions.

(Lower priority than business correctness, but in scope for v2.0.)

## Definition of done

A feature ships when:

1. Spec is updated (this folder).
2. Domain unit tests cover all new pure code.
3. Scenario tests cover the new workflows.
4. Invariants in `invariants.md` still hold.
5. Service-level integration tests cover the new service surface.
6. Security-rule tests cover any new permission paths.
7. Relevant Playwright workflow exists.
8. Visual snapshots are updated and reviewed.
9. Perf budgets pass on the reference device profile.
10. The suspicion engine has rules and tests for any new anomaly
    class introduced.
11. The audit log shows the new event type with a human-readable
    summary.
12. A short release note exists describing what changed for the
    owner and for the brother.

## What is forbidden

- Weakening a test to make a change pass. If the test was wrong,
  rewrite it with explicit justification in the commit message.
- Mocking the domain in domain tests. The domain is what is under
  test there.
- Adding a feature without a scenario fixture for it.
- Bypassing the suspicion engine for a "trusted" code path. There
  is no such thing.
- Letting UI components own a money number that is not derived
  from a service call or domain selector.
- Catching an invariant failure and continuing. Invariant failure
  surfaces, always.

## CI gates

- Unit + scenario + invariant + integration + security-rule + perf
  + visual tests run on every PR.
- Playwright runs on every PR against an in-memory backend; nightly
  against a real backend.
- Property-based suite runs on every PR with a fixed seed and
  nightly with random seeds.
- Coverage threshold for domain core: `≥ 95%`. For services:
  `≥ 85%`. UI components do not have a coverage floor (covered by
  Playwright + visual).

## Manual smoke test

Before any production release, a 15-minute manual smoke test on a
real phone with a real printer:

- Create one retail bill; print; void; correct.
- Open and close a cash session with intentional mismatch.
- Settle outstanding.
- Walk through Today / Finance / Reports; numbers agree.
- Open Review Queue; resolve any flags raised during smoke.

This is the only place hardware is touched; everything else is
mocked in CI.

## Recent changes

- _2026-06-17_ · Added a **selector convention** to §7 (E2E):
  Playwright flows select by stable `data-testid` / ARIA role, never
  by visible text, so the same flow passes unchanged in both
  Hindi-leading and English-leading label modes (the bilingual UI
  would otherwise make text selectors flaky). Every interactive
  control carries a `data-testid` as part of the feature.
