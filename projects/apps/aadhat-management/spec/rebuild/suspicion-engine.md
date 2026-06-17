# Suspicion engine — rebuild

## Principle

> **The app should be boringly correct. When it is unsure, it should
> stop, flag, explain, and require review.**
>
> Silent acceptance of a number that looks off is the worst failure
> mode for a business app. The suspicion engine is the code that
> watches every write and decides whether to add a Review Queue item
> so the brother / owner can confirm or reject.

## How it runs

- The engine is a pure function: given `(currentState, candidateEvent,
  shopProfile)`, it returns a list of `flag_raised` events.
- It runs **inside the application service**, after domain
  validation succeeds and before the event is appended. The flags
  are appended in the same transaction as the event they describe.
- Some rules are server-side only (e.g. cross-device anomalies).
  Those run in the storage adapter or a background reconciliation
  job and append flags asynchronously.
- A flag does not block the write unless its severity is `block`.
  Most flags are `low` / `medium` / `high` and let the action
  through with a Review Queue entry.

## Severities

| Severity | Behaviour |
|---|---|
| `low` | Logged, shown as info on the bill, listed in the daily digest |
| `medium` | Visible Review Queue entry, shows on Today's "Needs review" widget |
| `high` | Prominent Review Queue entry; brother is notified (notification mechanism: `TODO(spec)`) |
| `block` | The event is rejected; the user is told why and offered an override path that requires owner approval |

## Rules (v2.0, initial set)

> Thresholds in `(…)` are defaults that go into `shopProfile`; every
> shop can tune them.

### Stock rules

| Rule id | Triggers when | Severity |
|---|---|---|
| `stock.negative` | A sale would push computed stock below zero | `medium` |
| `stock.negative.large` | A sale would push computed stock below `−(shopProfile.stock.negativeBlockKg)` (default `TODO(spec)`) | `block` |
| `stock.zero-after-recent-purchase` | An item went from positive to zero within an hour of a purchase being recorded — possible duplicate sale | `medium` |
| `stock.adjustment.large` | An adjustment of magnitude greater than `shopProfile.stock.adjustmentLargeKg` (default `TODO(spec)`) | `medium` |

### Pricing rules

| Rule id | Triggers when | Severity |
|---|---|---|
| `price.below-cost` | Sale rate < latest moving-average purchase rate for that item | `medium` |
| `price.discount.large` | Discount exceeds `shopProfile.pricing.maxDiscountPctByRole[staff]` for the user's role | `medium` |
| `price.discount.exceeds-limit` | Discount exceeds the absolute discount limit for the user's role | `block` |
| `price.zero-rate` | Sale rate == 0 with non-zero quantity | `medium` |
| `price.unusually-high` | Sale rate > `shopProfile.pricing.maxRateMultiple` × moving-average for that item | `medium` |
| `price.unusually-low` | Sale rate is **above cost** (so `price.below-cost` does not fire) but below `(1 / shopProfile.pricing.maxRateMultiple)` × the item's **typical sell rate** — catches a fat-finger such as ₹6 entered for a ₹60 item | `medium` |
| `price.purchase-rate-unusual` | A manually-entered **purchase** rate deviates from the item's recent purchase rate by more than `shopProfile.pricing.maxRateMultiple`× in **either** direction — protects the moving-average cost baseline that the rules above all anchor on | `medium` |

> **Baseline and new items.** The high/low *sale*-rate rules need a
> reference. They anchor on the item's **typical sell rate** — its
> configured master rate, else the recent median from the
> [`projections.md`](./projections.md#rate-history-per-item)
> Rate-history projection; the cost-based rules anchor on the
> moving-average purchase rate. An item's **first-ever** transaction
> has neither baseline, so its rate is then guarded only by the item
> master's `rateCeilingPaise` ceiling
> ([`data-governance.md`](./data-governance.md) §Validation gates)
> and `price.zero-rate`. `TODO(spec)`: add a symmetric
> `shopProfile.items.rateFloorPaise` (or require owner-confirm on the
> first sale of a never-sold item) to cover the weakest case — a
> brand-new item priced far too low with no history to compare to.

### Duplicate / replay rules

| Rule id | Triggers when | Severity |
|---|---|---|
| `bill.duplicate.window` | Same `(party, billTotal, lineItems[])` saved within `shopProfile.bills.duplicateWindowSec` (default `TODO(spec)`) | `medium` |
| `bill.idempotency-mismatch` | Same `idempotencyKey` arrived with a different payload (client bug or tampering) | `block` |
| `bill.client-clock-skew` | Client-claimed timestamp differs from server arrival time by more than `shopProfile.time.skewToleranceSec` | `low` |

### Cash rules

| Rule id | Triggers when | Severity |
|---|---|---|
| `cash.mismatch.above-tolerance` | `|closing − expected| > shopProfile.cash.mismatchTolerance` | `medium` |
| `cash.mismatch.large` | `|closing − expected| > shopProfile.cash.mismatchLarge` | `high` |
| `cash.session.long-open` | A session has been open for more than `shopProfile.cash.maxSessionHours` | `low` |
| `cash.session.opened-without-close` | A new session opens while a previous one is still open | `block` |
| `cash.paid-but-no-entry` | A bill is marked paid (cash / online) but no matching cash inflow / online-entry event exists | `medium` |

### Outstanding rules

| Rule id | Triggers when | Severity |
|---|---|---|
| `outstanding.changed-without-bill` | A party's outstanding moves without a linked transaction (manual adjustment) | `medium` |
| `outstanding.settlement-overpayment` | A settlement event pays more than the outstanding for the referenced bill(s) | `medium` |
| `outstanding.long-overdue` | A bill has been outstanding for more than `shopProfile.outstanding.longOverdueDays` | `low` |

### Timing rules

| Rule id | Triggers when | Severity |
|---|---|---|
| `time.backdated` | Event's claimed bill date is more than `shopProfile.time.backdateToleranceDays` before today | `medium` |
| `time.future-dated` | Event's claimed bill date is in the future | `medium` |

### Authorization rules

| Rule id | Triggers when | Severity |
|---|---|---|
| `auth.staff-edits-old-bill` | Staff submits a correction or void against a bill from before today | `medium` (requires owner approval) |
| `auth.role-escalation-attempt` | A request was rejected because the principal lacked permission; multiple within `shopProfile.auth.escalationWindowMin` triggers this | `high` |
| `auth.session-anomaly` | Sign-in from a new device, country, or after a long absence (`TODO(spec)`: pick signals) | `low` |

### Item / unit rules

| Rule id | Triggers when | Severity |
|---|---|---|
| `unit.mismatch` | Bill line uses a unit not in the item's allowed unit list | `medium` |
| `item.archived` | Bill line references an archived item | `medium` |

### Printing rules

| Rule id | Triggers when | Severity |
|---|---|---|
| `print.repeated-failures` | A print job's `attemptNo` exceeds `shopProfile.printer.attemptsBeforeFlag` (default `TODO(spec)`) | `low` |
| `print.exhausted` | A job has exhausted retries (terminal `failed`) | `medium` |
| `print.many-reprints` | A bill has been reprinted more than `shopProfile.printer.reprintsBeforeFlag` times (possible duplicate-handout) | `low` |

### Reconciliation rules (background)

| Rule id | Triggers when | Severity |
|---|---|---|
| `recon.report-vs-ledger` | A daily report total disagrees with the replay-from-events total for that day | `high` |
| `recon.projection-mismatch` | A live projection disagrees with a fresh replay on the same time window | `high` |
| `recon.audit-gap` | A money-affecting event has no corresponding audit row (should be impossible by construction; if it ever fires, it is a system bug) | `high` |

## What gets stored

Each fired rule appends a `flag_raised` event with:

- `targetEventId` (the event that caused the flag, or `null` for
  background-detected flags)
- `ruleId`
- `severity`
- `summary` (one-line human description)
- `context` (rule-specific structured data — e.g. `{ expected, got,
  tolerance }`)
- `raisedAt`, `raisedBy: 'engine'`

When the brother / owner resolves it, a `flag_resolved` event
appends with:

- `flagId`
- `resolution`: `approve` (the data is correct) | `dismiss` (it's
  a false positive, do nothing) | `correct` (a correction event
  was filed; reference it)
- `note` (optional)
- `resolvedAt`, `resolvedBy`

## What the engine must not do

- It must not modify any other event. It is read-only over state
  plus the candidate event; it only produces flag events.
- It must not raise flags that cannot be acted on. Every rule must
  have at least one of `approve` / `dismiss` / `correct` as a
  meaningful resolution.
- It must not be silent. Every flag has a human-readable `summary`.
- It must not be the only line of defense for `block`-severity
  rules. Those are also enforced by the domain or storage adapter
  so a tampered client cannot bypass them.

## Configurability

Each rule is on by default but can be:

- Disabled in `shopProfile` (audit: a `shop_profile_updated` event
  records the change).
- Re-thresholded in `shopProfile`.
- Promoted / demoted between severities in `shopProfile`.

A disabled high-severity rule shows a persistent banner on the
Diagnostics page so the owner knows. `block` rules cannot be
disabled — only their thresholds tuned.

## Tests this spec requires

- For each rule: one fixture that triggers it, one that does not.
- For each `block` rule: confirmation that the storage adapter
  rejects the event even when the engine is bypassed.
- For background reconciliation rules: a scheduled run on every
  scenario fixture; the fixture's expected flag set is asserted.
- Property-based: generate random sale / purchase / payment /
  void / correction sequences; assert that no invariant is ever
  violated without a corresponding `flag_raised` (or a `block`
  rejection).

## Recent changes

- _2026-06-17_ · Closed the manually-entered-rate gap. Added
  `price.unusually-low` (a sale rate above cost but far below the
  item's typical sell rate — the fat-finger ₹6-for-₹60 case, which
  `price.below-cost` and `price.unusually-high` both miss) and
  `price.purchase-rate-unusual` (a manually-entered purchase rate
  far from recent, in either direction — protects the moving-average
  cost baseline the other rate rules anchor on). Documented the
  baseline each rule uses and flagged the brand-new-item-no-history
  case as the weakest spot (`TODO(spec)`: `rateFloorPaise` or
  first-sale owner-confirm).
