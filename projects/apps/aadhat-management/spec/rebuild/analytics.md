# Analytics — rebuild

> What the shop should **look at to run better** — and exactly which
> events and projections each insight is computed from. v1 shipped a
> rich, forward-looking Analytics page
> ([`../page-specs/11-analytics.md`](../page-specs/11-analytics.md));
> the v2 projection catalogue
> ([`projections.md`](./projections.md)) only carried a generic
> period-binning stub forward. This file is the v2 analytics
> contract: it re-homes the v1 insights on the event ledger and adds
> the business analytics the owner asked for.

## Ground rules (inherited, non-negotiable)

- **Analytics never owns an authoritative total.** It reads the
  same projections Reports / Today / Finance read. No screen-local
  period math (`M5`, `AC1`); cross-screen agreement holds (`R4`).
- **Past-period totals live on Reports, not here.** Analytics is
  *forward-looking and comparative* ("what's coming / what's
  changing"), per the v1 redesign. It may *reference* a number but
  not be its source.
- **Every projection/heuristic is labelled.** A straight-line
  forecast says so on the card; a stale projection shows its badge
  (`AC8`). The owner must never confuse a heuristic with a fact.
- **No ML / LLM.** Deterministic, rule-based math over projections.
  The chat tab is the only LLM surface.
- **Read-only.** Analytics appends no events. It cannot resolve a
  flag or change a setting.

## The data we already capture (and what it enables)

Analytics is downstream of the ledger; it needs no new write path,
only new read projections. What the existing events carry:

| Signal | Source field(s) | Enables |
|---|---|---|
| Sale amount + time | sale events `grandTotal`, envelope `at` | revenue trend, today/month forecast, peak-hour |
| Payment mix | `payment.{cash,online,due}` | cash-vs-UPI-vs-credit mix, cash-flow forecast |
| Line economics | `BillLine.{itemId, weights, rate, discountPaise}` | per-item revenue, margin, discount load |
| Cost basis | Live-stock `movingAvgRate`; `purchase_recorded` line `rate` | margin per item, below-cost detection |
| Rate over time | `item_rate_changed` + transacted rates (Rate-history projection) | margin compression, supplier price creep |
| Party (wholesale; optional on retail) | sale `party.{partyId,name}` | top customers, concentration, receivables by party |
| Outstanding age | bill `billDate` + `outstanding_payment_*` | receivables / payables aging |
| Stock movement | purchase vs wholesale-sale qty per item | dead stock, over/under-buying |
| Expenses | `expense_recorded.{category, amount, kind}` | expense breakdown, expense-to-revenue ratio |

**Known data limits (call them out, do not paper over):**

- **Retail customer attribution is optional.** `retail_sale_created.party`
  is "walk-in often empty". Customer-level analytics (top customers,
  concentration, receivables) is exact for wholesale and for the
  subset of retail where a party was attached; it is **not** a
  whole-of-retail view. Surface it as "named customers", never
  "all customers".
- **No per-line cost on retail margin when the item was never
  purchased through the app** (opening-snapshot items carry an
  import cost basis — see [`money-units-rounding.md`](./money-units-rounding.md)
  import table). Margin for such items is flagged "cost basis:
  imported".
- **Category granularity is the owner's free text.** Expense
  breakdown is only as clean as the `category` field; the
  data-governance generic-value flag helps but does not normalise.
- `TODO(spec)` — decide whether to add an **optional phone** on
  retail for a future loyalty view. Deferred; not v2.0.

## The analytics catalogue

Each insight names the **projection(s)** it reads (never raw events
in the UI) and the **events** ultimately behind them. v1 formulas in
[`../page-specs/11-analytics.md`](../page-specs/11-analytics.md) are
the behavioural reference; reproduce them over v2 projections.

### A. Forward-looking (the headline of the page)

| Insight | Reads | Note |
|---|---|---|
| **Today prediction** — end-of-day revenue + cash needed, from the day's pace | Today summary projection + `at` timestamps | straight-line from `salesPerHour`; label it |
| **Month-end projection** — revenue / profit / cash-required to month end | Period reports projection | straight-line from month-to-date; label it |
| **Cash-flow runway** — projected cash position given pending payables and dues | Cash-on-hand + Outstanding projections | "if you collect nothing new" pessimistic line |

### B. Trends (comparative over a 7 / 30 / 90-day window)

| Insight | Reads | Backed by |
|---|---|---|
| **Profit trend** — daily `sales − purchases − businessExpenses` | Period reports (per-day buckets) | sale / purchase / expense events |
| **Rate & margin trend per item** — buy vs sell rate; margin = sell − movingAvgRate | Rate-history per item + Live-stock | `item_rate_changed`, purchase/sale lines |
| **Payment-mix trend** — cash vs online vs credit share over time | Period reports (payment split) | `payment.*` on sale events |
| **Peak hours / peak days** — sales bucketed by hour-of-day and weekday | History projection bucketed by `at` | needs no new data; `at` is server time |

### C. Inventory focus

| Insight | Reads | Surfacing rule (from v1) |
|---|---|---|
| **Items to focus** — purchased-qty ÷ sold-qty over window | Live-stock + History | `>2` overstocked, `<0.3` running out |
| **Dead / slow stock** — positive stock with no sale in N days | Live-stock + History (last-sale-`at`) | `shopProfile.analytics.deadStockDays` (`TODO(spec)` default) |
| **Low-stock alert** — qty under reorder point | Live-stock | feeds Smart Suggestions |
| **Top performers** — top items by revenue and by margin | History + Live-stock | top 5 each |

### D. Customer & counterparty

| Insight | Reads | Note |
|---|---|---|
| **Top customers** (named) | Outstanding + History by party | wholesale + attributed retail only |
| **Customer concentration** | revenue share by party | warn if top customer > 40 % (v1 rule) |
| **Receivables aging** — dues bucketed 0–30 / 31–60 / 61–90 / 90+ days | Outstanding projection + `billDate` | drives collection priority |
| **Payables aging** — what we owe suppliers, by age | Outstanding (supplier side) | drives payment priority |

### E. Health & expenses

| Insight | Reads | Note |
|---|---|---|
| **Expense breakdown** — by `category`, business only | Period reports / expense events | `kind == 'business'` only (personal excluded) |
| **Expense-to-revenue ratio** | Period reports | Smart-Suggestion trigger at >10 % |
| **Smart suggestions** — rule-based nudges | all of the above | reproduce the v1 rule set; rules, not ML |

## Smart suggestions (rule set, reproduced and extended)

Deterministic, threshold-driven, every threshold in `shopProfile`.
Reproduce v1's rules (collect dues, prioritise payables, loss-month,
on-track, expense ratio, low daily sales, low stock) and add:

- **Margin compression** — an item whose sell − buy spread fell more
  than `x%` over the window (from the Rate & margin trend).
- **Dead stock** — capital parked in items unsold for N days.
- **Aging receivable** — a specific party's due crossed 60 / 90 days.
- **Concentration risk** — top customer share crossed 40 %.

Each suggestion is **actionable and escapes user text**
(`item`/`party` names may contain markup — `X1`).

## Invariants this page must honour

- `AC1` / `M5` / `C5` — no authoritative total computed on this page.
- `R4` — any number also shown on Today / Finance / Reports must
  match to the paisa.
- `AC8` — a stale projection is rendered with its staleness badge.
- `X1` — every item / party / category string is escaped before
  render.
- Forward-looking cards must carry the "heuristic, not a guarantee"
  caption (v1 "Must NOT" rule).

## Tests this spec requires

- **Reconciliation:** for any window, each analytics number that is
  also a Reports number equals the Reports value (`R4`) — asserted
  on every scenario fixture that spans a period.
- **Forecast determinism:** Today / Month-end projections are a pure
  function of the projection snapshot + clock; same input → same
  output; no hidden randomness.
- **Aging buckets:** a fixture with dues at 10 / 40 / 70 / 100 days
  lands one in each bucket; a payment moves it correctly.
- **Margin sign:** a fixture where buy rate rises above sell rate
  produces a negative-margin / `price.below-cost`-consistent signal.
- **Concentration:** a fixture with one party > 40 % revenue raises
  the concentration suggestion; at 39 % it does not.
- **Dead stock:** an item bought and never sold for N+1 days appears;
  selling one unit clears it.
- **Empty period:** every card renders "Not enough data", never
  `NaN` / crash (v1 regression).
- **Escaping:** an item named `<b>x</b>` renders as text in every
  analytics surface.

## Build order

Analytics is **M9** in [`../../plan/rebuild/roadmap.md`](../../plan/rebuild/roadmap.md)
(Today / Finance / Reports / Analytics), after the period-report and
projection layer (M2) and the suspicion/rate-history work (M5) it
reads from. The forecasts and aging views are the new build; the
trend/focus/customer views are v1 formulas re-homed on projections.

## Recent changes

- _2026-06-16_ · File created. Re-homes v1's forward-looking
  Analytics page on the v2 event ledger and adds the business
  analytics the owner asked for (receivables / payables aging,
  payment-mix and peak-hour trends, margin-per-item, dead-stock),
  each mapped to the projection and events behind it. Documents the
  retail-customer-attribution data limit explicitly. Replaces the
  bare period-binning stub that was the only analytics in
  `projections.md`.
