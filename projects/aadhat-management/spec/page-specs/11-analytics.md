# Page spec: Analytics (`analytics`)

> **Status:** Redesigned. Analytics is now strictly **forward-looking**:
> "what's coming?", not "what happened?". The old Month Summary card
> (revenue / purchases / profit / expenses for the current month) and
> Outstanding Dues card have been removed from the overview because
> Reports and Outstanding own those numbers, and showing them in two
> places led to mismatches when a fix landed in only one.

## Purpose
Heuristic, rule-based "what should the owner be looking at?" insights.
No ML; just deterministic math over `AppState`. Specifically:

- **Today** — predict end-of-day revenue and the cash that'll be needed
  given the day's pace so far.
- **This month, projected** — straight-line from month-to-date averages
  to month-end, so the owner can course-correct mid-month.
- **Trends** — profit trend line + buy/sell rate trends per item.
- **Items** — items to focus on (over-bought or under-bought relative
  to sales) and top performers.
- **Insights** — customer concentration + smart suggestions
  (rule-based "you owe a lot, prioritize clearing high-interest dues",
  "low stock alert", etc).

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `analytics` | `www/templates/analytics.html` | `www/js/modules/analytics.js` |

Math is delegated to:
- `www/js/utils/period-math.js` — all date ranges, period sums, and
  position snapshots. Eliminates the old DD/MM/YYYY parse bugs that
  silently dropped records on this page.

## Who can use it
Any authenticated user. View only — no writes.

## Subtabs
| Subtab | What it shows |
|---|---|
| **Overview** | Today Prediction + Month-End Projection + a pointer to Reports / Outstanding for past-period numbers. |
| **Trends** | Profit-trend line chart (last 7 / 30 / 90 days) + buy/sell rate trends per item. |
| **Items** | Items to focus on + top performers. |
| **Insights** | Customer insights + Smart Suggestions panel. |

## Calculations / formulas

All date math goes through `PeriodMath`. The page-local convenience
helpers are thin wrappers:

```js
this.currentMonthRange()  // PeriodMath.range('month')
this.lastMonthRange()     // PeriodMath.range('lastMonth')
this.monthMeta()          // { daysInMonth, dayOfMonth, daysRemaining }
this.filterByRange(records, range)   // PeriodMath.filter
this.getTotal(record)                // grandTotal | salesTotal | totalAmount | amount
```

### Today Prediction
```text
day                  = PeriodMath.range('today')      // [00:00 today, 00:00 tomorrow)
salesSoFar           = Σ getTotal(retail+wholesale sales filtered to day)
purchasesSoFar       = Σ getTotal(purchases    filtered to day)
expensesSoFar        = Σ amount  (business expenses filtered to day)

hoursElapsed         = max(1, currentHour − businessOpenHour)   // default open = 09:00
hoursRemaining       = max(0, businessCloseHour − currentHour)  // default close = 21:00

salesPerHour         = salesSoFar / hoursElapsed
predictedDayRevenue  = salesSoFar  + salesPerHour × hoursRemaining
predictedCashNeed    = max(0, purchasesSoFar + expensesSoFar − salesSoFar)
                       // pessimistic: assumes the rest of the day is purchase-heavy
```
Element ids: `predictedTodayRevenue`, `predictedCashNeed`.

### Month-End Projection (now the primary overview card)
```text
{ daysInMonth, dayOfMonth, daysRemaining } = PeriodMath.monthMeta()

R                    = PeriodMath.range('month')
salesMTD             = Σ getTotal(retail+wholesale sales filtered to R)
purchasesMTD         = Σ getTotal(purchases       filtered to R)
expensesMTD          = Σ amount   (business expenses filtered to R)

dailyAvgRevenue      = dayOfMonth > 0 ? salesMTD     / dayOfMonth : 0
dailyAvgPurchases    = dayOfMonth > 0 ? purchasesMTD / dayOfMonth : 0
dailyAvgExpenses     = dayOfMonth > 0 ? expensesMTD  / dayOfMonth : 0

projectedRevenue     = salesMTD     + dailyAvgRevenue   × daysRemaining
projectedPurchases   = purchasesMTD + dailyAvgPurchases × daysRemaining
projectedExpenses    = expensesMTD  + dailyAvgExpenses  × daysRemaining
projectedProfit      = projectedRevenue − projectedPurchases − projectedExpenses
projectedCashRequired = max(0, dailyAvgPurchases × daysRemaining
                              + dailyAvgExpenses × daysRemaining)
```
Element ids: `projectedRevenue`, `projectedProfit`, `projectedCashRequired`,
`daysRemaining`, `daysInMonth`.

This is a **straight-line projection**, not a model. It implicitly
assumes the second half of the month looks like the first half.
Surface it that way (the card title says "Month-End Projection" with
a "Straight-line projection from your month-to-date pace" caption).

### Profit Trend (Trends subtab)
For each day in the chosen window (`7days` / `30days` / `90days`):
```text
bucketKey            = YYYY-MM-DD                        // sortable lexically
profit(bucket)       = sales(bucket) − purchases(bucket) − businessExp(bucket)
```
The bucket key was changed from `toLocaleDateString('en-IN')`
(DD/MM/YYYY, requires a custom sort) to `YYYY-MM-DD` so chronological
sort is just `Object.keys().sort()` — no parse round-trip.

### Rate Trends (Trends subtab)
For each tracked item, plot the moving average of buy rate and sell
rate over the chosen window:
```text
buyRatePoints[item]  = chronological list of purchaseRow.rate
sellRatePoints[item] = chronological list of (retail|wholesale)Row.rate
```
Useful for spotting when a supplier silently raised prices or when
margin compressed because sell rate stayed flat while buy rate rose.

### Items to Focus
For each item, compute purchase qty vs. sale qty over the window:
```text
purchasedQty(item)   = Σ purchaseRows.qty             where item
soldQty(item)        = Σ (retail+wholesale).qty       where item
ratio                = soldQty > 0 ? purchasedQty / soldQty : ∞

surface if ratio > 2     → "buying 2× what you sell — overstocked"
surface if ratio < 0.3   → "running out — sales outpace purchases"
```

### Top Performers
Sorted by total revenue contribution; show top 5 by item, top 5 by
customer.

### Customer Insights
```text
revenue(customer)    = Σ (retail + wholesale).total where customer
customerShare(c)     = revenue(c) / Σ revenue(all customers)
```
Surface the top-3 customers + their share. If the top customer is
> 40 % of revenue, surface a concentration warning ("If they leave,
40 % of your revenue leaves with them").

### Smart Suggestions (rule-based)
```text
{ receivable, payable } = PeriodMath.outstanding()

if receivable > 50000        → "Collect ₹X in pending dues"
if payable > receivable×1.5
   and payable > 30000       → "You owe ₹X — prioritize clearing"
if profit (this month) < 0   → "Loss month: review expenses & margins"
if profit > 0 and dayOfMonth > 15 → "On track for ₹X — keep going"
if expenses / revenue > 0.1  → "Expenses are X% of revenue — find savings"
if avgDailySales < 10000
   and dayOfMonth > 7        → "Avg daily sales low — consider promotions"
if any item.qty < 10         → "Low stock: itemA, itemB, ..."
fallback                     → "Business is running smoothly!"
```
All user-supplied text in suggestions is `Helpers.escapeHtml`'d before
rendering (defense-in-depth — item / customer names could contain
HTML).

## Data sources
- All bill histories (`AppState.purchaseHistory`,
  `AppState.retailSalesHistory`, `AppState.salesHistory`).
- `AppState.expensesHistory` (filtered to `category != 'personal'`).
- `AppState.stock` for stock-level checks.

## Must NOT do
- Must not show **past-period totals** on the overview tab (revenue,
  profit, expenses for "this month"). Those live on **Reports**.
  Showing them in two places led to drift when a fix landed in only
  one.
- Must not show **outstanding dues** as a top-level overview card.
  Outstanding has its own tab. (Smart Suggestions can mention dues
  because they're recommendations, not totals.)
- Must not present projections without making the heuristic visible
  ("Straight-line projection from your month-to-date pace"). Owner
  must never confuse a heuristic with a guarantee.
- Must not call any external ML / LLM API. The chat tab is the only
  page that talks to an LLM.
- Must not crash on an empty period — show "Not enough data".
- Must not bypass `PeriodMath`. The whole point of the redesign is
  that Finance, Reports, and Analytics agree on what "this month"
  means.

## Known issues
- See `docs/REVIEW_ISSUES.md` Section C.

## Where past-period numbers went (migration note)
- Old "Month Summary" card → **Reports → Overview** (with the new
  cash-flow vs realized profit split).
- Old "Outstanding Dues" overview card → **Outstanding** tab (which
  was always the canonical home anyway).
- A pointer card on the Analytics overview links to both, so users
  who land on Analytics looking for those numbers find them in one
  click.

## Example bug reports → what to change
- "Today Prediction is ₹0 at noon even though I made sales" → check
  `PeriodMath.range('today')` includes records timestamped before
  noon. Most likely a date-format issue in the new sale; do **not**
  patch the analytics filter — fix the saver.
- "Month-End Projection wildly off" → it's a straight-line projection
  and amplifies any single-day spike or drought early in the month.
  Document it; don't change the math without owner sign-off.
- "Profit Trend chart shows dates in the wrong order" → with the
  YYYY-MM-DD bucket key this should not happen; verify
  `Object.keys(buckets).sort()` is being used and not
  `Object.keys(buckets).sort((a,b)=>parseDate(a)-parseDate(b))`.
- "Smart Suggestions show HTML tags as text" → expected; we escape
  user text with `Helpers.escapeHtml`. The fix is to strip HTML at
  data entry time, not to weaken the escape.
