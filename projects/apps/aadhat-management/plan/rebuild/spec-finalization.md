# Spec finalization — decisions needed from the owner

> Step 2 of Happa's build order. Nothing downstream starts until this is
> answered: mockups, architecture and the first slice all assume a settled spec.
> Building ahead of one is what sank the previous attempt.

## How to use this

Every item below has a **recommendation**. You can answer the whole document
with *"all recommendations accepted"* and the spec is finished — then only the
ones you disagree with need discussing.

Each answer gets written back into the spec as an asserted fact, and the
`TODO(spec)` deleted, in the same commit.

## State of the spec

| | Count |
| --- | ---: |
| Open `TODO(spec)` items total | 97 |
| Already carry a milestone **and** a concrete default — adopted unless you object | 82 |
| **Need your answer** (below) | 15 |
| ⚠ Provisional config values | 5 |
| Known contradictions | 3 |

The 82 with concrete defaults are not listed here. They were written as
recommendations by whoever drafted the section, and adopting them is the
default path. Ask for the full list if you want to review them too.

---

## A. Provisional configuration values

These were written down by reading a build attempt that is not authoritative,
not by deciding them on their merits. None requires a schema migration to
change later.

| # | Key | Proposed | The question |
| --- | --- | --- | --- |
| A1 | `time.maxFutureMin` | `60` | How far ahead of server time may a device's clock be before the event is rejected? An hour is generous for a shop phone; 15 min would be stricter. |
| A2 | `pricing.maxRateMultiple` | `5` | Flag a sale when its rate exceeds N× the item's moving average. Is 5× right, or so loose it never fires? 2× would catch far more. |
| A3 | `printer.maxRetries` | `3` (4 attempts) | How many times should a failed print retry before the job is marked failed? |
| A4 | `stock.negativeBlockMg` | `5 kg` | How far below zero may computed stock go before a wholesale sale is **blocked outright**? |
| A5 | `stock.adjustmentLargeMg` | `20 kg` | What size of manual stock adjustment is "large" enough to flag for review? |

**Recommendation:** accept A1, A3, A4, A5 as-is. **Reconsider A2** — 5× is loose
enough that an item normally ₹40/kg would need to be billed at ₹200/kg before
anyone is told. If the point of the rule is catching a mis-keyed rate, 2× is
the more useful setting.

---

## B. Known contradictions

Two documents currently disagree. Each needs one side chosen.

| # | Conflict | Recommendation |
| --- | --- | --- |
| B1 | The printed-marker for a bill is held **in memory**, but a test asserts it survives an app restart. One of the two is wrong. | Persist the marker. A marker that dies with the process cannot prevent the duplicate print it exists to prevent. |
| B2 | Offline bill-number blocks are described as **per session** in two documents and **per device** in another. This decides whether invariant `B5` (bill numbers strictly increasing, never reused) can hold. | **Per device.** Two devices sharing a session would collide; a device-bound block cannot. |
| B3 | `scenarios.md` uses a 23rd event type that `event-schemas.md` has not frozen. | Freeze the event list first (see C1) and rewrite the fixture to match it. |

---

## C. Open questions

### C1 — Which proposed event types ship in v2.0?

Six types are referenced across the spec but never specified:
`item_rate_changed`, `party_updated`, `item_merged`, `party_merged`,
`print_manual_recorded`, `shop_timezone_changed`.

Two of them already have hard dependents: the rate-history projection needs
`item_rate_changed`, and the timezone rule needs `shop_timezone_changed`.

**Recommendation:** freeze those two into v2.0 and specify them properly. Defer
the other four to v2.1 — merges and manual-print marking are rare enough to
handle by hand in year one, and each one you add costs a schema, a permission
row, a count test and an access-control entry.

### C2 — How does a party first enter the ledger?

Explicitly via a `party_created` event, or implicitly the first time a sale
names them?

**Recommendation:** implicitly, on first use. A shopkeeper billing a walk-in
who becomes a regular should never have to stop and "create a customer" first.

### C3 — Cross-device cache coherence

Two devices in the same shop can show different Today summaries once they drift
beyond the staleness tolerance. What protocol prevents that?

**Recommendation:** none for v2.0 — accept the drift and label it. The staleness
badge already tells the user the number is `as of HH:MM`. The shop runs one or
two devices; a coherence protocol is real complexity for a rare confusion.
Revisit if the pilot shows it actually bites.

### C4 — Rate history projection shape

One merged projection, or separate master-rate and transacted-rate views? What
retention applies for high-volume items? Should a purchase-implied buy rate
raise `master-set`?

**Recommendation:** one merged projection with a `source` field
(`master` | `transacted` | `purchase-implied`), retained for the same window as
the ledger. Two projections over one concept is how they drift apart.

### C5 — What does an owner override do to a blocked rule?

Append a new attempt referencing an owner-approval event, or short-circuit the
rule entirely?

**Recommendation:** append the approval event and reference it. An override that
leaves no trace defeats the audit trail, which is the whole point of the
suspicion engine.

### C6 — How is a possible duplicate print marked for review?

When the app dies mid-print, it cannot know whether paper came out.

**Recommendation:** mark the job `duplicate-suspect` and raise a low-severity
Review Queue flag. Never silently reprint, and never silently swallow it —
ESC/POS gives no acknowledgement, so an honest "we are not sure" is the only
truthful state.

### C7 — Which signals count as an auth session anomaly?

New device, new location, or a long absence?

**Recommendation:** new device only, for v2.0. Location needs geo-IP the app
does not otherwise collect, and a shop phone does not move.

### C8 — Which scenario gaps become test fixtures, and when?

**Recommendation:** a full shop-day fixture at M8 (once cash sessions exist,
since that is what bounds a day). The rest as their milestone lands. This is a
planning call, not a design one — low stakes.

---

## After this is answered

1. Each answer is written into the spec as an asserted fact and its
   `TODO(spec)` deleted, in the same commit.
2. Confirmed values move into `configuration.md` without the ⚠.
3. Any answer that supersedes a `decisions.md` row gets a dated `superseded`
   entry rather than a silent edit.
4. Step 2 closes and mockups begin.
