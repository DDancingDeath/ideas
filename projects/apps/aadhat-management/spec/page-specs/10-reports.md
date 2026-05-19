# Page spec: Reports (`reports`)

> **Status:** Redesigned. The misleading single "Gross Profit" stat has
> been replaced with **two clearly-labeled profit numbers**
> (Cash-Flow Profit + Realized Profit) so the owner sees the difference.
> Reports is now the **canonical** home for past-period totals
> (revenue / profit / expenses for a chosen period). Finance and
> Analytics defer to it.

## Purpose
Show the owner what *did* happen across a chosen period: how much money
came in (revenue), how much went out (purchases + business expenses),
and **two different profit numbers** that mean different things.

This is the page to print / screenshot for an accountant, lender, or
business partner.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `reports` | `www/templates/reports.html` | `www/js/modules/reports.js` |

Math is delegated to:
- `www/js/utils/period-math.js` — `PeriodMath`. Same helper Finance and
  Analytics use, so all three pages cannot disagree on what "this
  month" means or how a sale's profit is computed.

## Who can use it
Any authenticated user.

## Subtabs
| Subtab | What it shows |
|---|---|
| **Overview** | Period totals + two profit numbers + business expenses + margin. |
| **Sales** | Per-item / per-party sales breakdown for the period. |
| **Purchases** | Per-item / per-party purchase breakdown for the period. |
| **Compare** | Pick two periods (A, B); show side-by-side + delta. |

## Date filter
Chips: **Today / Yesterday / This week / Last week / This month / Last
month / This year / All / Custom**. All chips delegate to:

```js
PeriodMath.range(this.currentDateFilter, this.customStartDate, this.customEndDate)
PeriodMath.filter(records, range)
```

`PeriodMath.range` returns a half-open `[from, to)` interval. Week
starts on **Monday**. "This month" means the calendar month
(1st → end-of-month), not a rolling 30-day window. Boundary cases
(records at exactly `to`) are excluded so adjacent ranges don't
double-count.

## Calculations / formulas

Let `R = filtered set of records` for the chosen range.

### The two profit numbers (this is the headline change)

#### 1. Cash-Flow Profit
```text
cashFlowProfit(R)
    = totalSalesValue(R) − purchasesValue(R) − businessExpensesValue(R)
```
**What it answers:** "If I dropped the period like an envelope of cash
on the table, how much net cash did the business move?"

**When it's right:** for a stable inventory level over the period —
e.g., quarterly review where you started and ended with roughly the
same stock on hand.

**When it lies:** end-of-period inventory ≠ start-of-period inventory.
Buying ₹2,00,000 of stock that's still sitting on the shelf at month
end *understates* cash-flow profit (the stock will be sold later);
selling off ₹2,00,000 of old stock *overstates* it (you booked the
revenue but the cost was paid in a previous period).

The HTML element id `reportsGrossProfit` is **reused** for this number
(so the existing chart and any external integrations don't break).
A new id `reportsCashFlowProfit` was added for clarity but they hold
the same value.

#### 2. Realized Profit (wholesale only, for now)
```text
realizedProfit(R) = Σ wholesaleSale.profit
                    where wholesaleSale ∈ filtered salesHistory
```
The wholesale-sale flow records each sale's profit at the moment of
sale, computed from `(sellPrice − stockAvgRate) × qty`. So this is the
true realized margin on each unit you actually sold during the period,
unaffected by inventory swings.

**Why it's wholesale only:** retail sales (`retailSalesHistory`)
historically don't store a per-line profit field — only the total. To
compute retail realized profit we'd need to look up the rate at the
time of each retail line, which is fragile against rate changes. Until
that's done, retail realized profit shows as N/A. Element id:
`reportsRealizedProfit`.

#### Margin (cash-flow basis)
```text
cashFlowMargin = totalSales > 0 ? (cashFlowProfit / totalSales) × 100 : 0
```
Element id: `reportsProfitMargin`. Now explicitly a *cash-flow* margin,
not a gross margin.

### Other Overview numbers
```text
totalSales       = totalSalesValue(R)            // retail + wholesale
totalPurchases   = purchasesValue(R)
businessExpenses = expensesValue(R, 'business')   // 'personal' excluded
```

Element ids: `reportsTotalSales`, `reportsTotalPurchases`,
`reportsBusinessExpenses` (this last one is rendered in the slot that
used to say "Labor Cost" — labor is a sub-category of business expenses
that wasn't worth its own stat).

### Sales subtab
```text
revenue(item)  = Σ (retail.lines + wholesale.lines).itemTotal where item
revenue(party) = Σ (retail + wholesale).total            where partyName == party
```
Time series: bucket by day / week / month based on range size.

### Purchases subtab
Same shape, on `purchaseHistory`:
```text
spend(item)  = Σ purchaseRow.itemTotal where purchaseRow.itemName == item
spend(party) = Σ purchase.grandTotal   where purchase.partyName == party
```

### Compare subtab
Two sub-ranges A and B picked by the user. Each is fed independently
into `PeriodMath` (Recompute from scratch — do **not** apply the
second range to a list already filtered by the first). Then:
```text
deltaSales      = totalSales(B) − totalSales(A)
deltaSalesPct   = totalSales(A) > 0 ? deltaSales / totalSales(A) × 100 : null
```
Same shape for cash-flow profit, realized profit, and expenses.

### CSV / PDF export
The same numbers the chart shows. Header row uses English or Hindi
column names depending on `AppState.settings.showHindi`. Currency is
rupees, integer.

## Data sources
- `AppState.purchaseHistory`, `AppState.retailSalesHistory`,
  `AppState.salesHistory`, `AppState.expensesHistory` — all filtered
  via `PeriodMath`.
- `AppState.settings.showHindi` for label / column names.

## Must NOT do
- Must not show a single "Profit" number without making it explicit
  whether it's cash-flow or realized. The owner asked for both, side
  by side.
- Must not bypass `PeriodMath`. If Finance, Reports, and Analytics
  disagree about "this month's revenue", the bug is in whichever
  caller bypassed the helper.
- Must not export raw user PII (phone, address) without explicit
  confirmation in the export modal.
- Must not crash on an empty range — show "No data in this period".
- Must not include personal expenses in business profit numbers
  (`PeriodMath.expensesValue(range, 'business')` already enforces this).

## Known issues
- Retail realized profit is N/A — see "Why it's wholesale only" above.
- See `docs/REVIEW_ISSUES.md` Section C for any newly-filed bugs.

## Example bug reports → what to change
- "Cash-Flow Profit and Realized Profit are wildly different" → not
  necessarily a bug. Inventory swings make these two diverge by
  design. Show the explanation caption (already in the HTML) more
  prominently if owners keep asking.
- "Realized Profit shows ₹0 even though I made wholesale sales" →
  the wholesale-sale save handler didn't write the `profit` field on
  those rows. Audit `wholesale-sales.js` save logic; backfill any old
  rows with `profit = (sellPrice − stockRate) × qty`.
- "Compare A vs B shows identical numbers" → the second range got
  applied to the already-filtered list. Recompute from each base
  collection per range (each call to `PeriodMath.filter()` should
  start from the unfiltered `AppState.X`).
- "PDF export missing the totals row" → `generatePdf()` adds detail
  rows but skips the footer. Add the summary row before `pdf.save()`.
