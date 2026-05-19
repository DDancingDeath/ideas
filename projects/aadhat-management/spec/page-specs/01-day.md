# Page spec: Today (`day`)

## Purpose
At-a-glance summary of *today's* business: cash in, cash out, by channel
(purchase / retail / wholesale), and a quick way to jump into the
cash-management session for the day.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `day` | `www/templates/day.html` | `www/js/modules/day.js`, embeds `cash-management.js` |

## Who can use it
Any authenticated user.

## What the user sees (top → bottom)
1. **Today's headline cards**: cash in, cash out, online in, online out.
   Split by purchase / retail / wholesale.
2. **Filter chips** to show only one transaction type.
3. **Today's transactions list** (chronological).
4. **Embedded Cash Management subtab** (see `16-cash-management.md`).

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Filter chips | Local UI filter only | — |
| Tap a transaction | Opens detail / edit modal | — |
| Use embedded cash-management | See `16-cash-management.md` | `cashManagement/` |

## Calculations / formulas
Let `today = startOfDay(now)`, `tomorrow = startOfDay(now) + 1 day`.

For each bill / expense, parse its date with `Helpers.parseDate()` (mixed
ISO-8601 and `DD/MM/YYYY` strings — must NOT use `new Date(string)`).

```
todayPurchases       = purchaseHistory.filter(b => today ≤ parseDate(b.date) < tomorrow)
todayRetailSales     = retailSalesHistory.filter(b => today ≤ parseDate(b.date) < tomorrow)
todayWholesaleSales  = salesHistory.filter(b => today ≤ parseDate(b.date) < tomorrow)
todayExpenses        = expensesHistory.filter(e => today ≤ parseDate(e.date) < tomorrow)
```

Then for each headline card:

```
cashIn   = Σ retailSale.cashPayment + Σ wholesaleSale.cashReceived
cashOut  = Σ purchase.cashPayment   + Σ expense (where mode='cash')
onlineIn = Σ retailSale.onlinePayment + Σ wholesaleSale.onlineReceived
onlineOut= Σ purchase.onlinePayment   + Σ expense (where mode='online')
```

Each subdivided card just restricts the source list (e.g., the "Purchase
cash out" card is `Σ purchase.cashPayment` only).

All sums are in rupees, integer (display via `Math.round`).

## Data sources
- `AppState.purchaseHistory`, `.retailSalesHistory`, `.salesHistory`
  (wholesale), `.expensesHistory`, `.cashManagement`.
- All filtered to today in code; no Firestore range query.

## Must NOT do
- Must not show data from other days.
- Must not double-count transactions that appear in both a bill history
  and an expense history.
- Must not block input if cashManagement service hasn't loaded yet —
  show a spinner / empty state instead.
- Must not call `new Date(billDate)` on a `DD/MM/YYYY` string. Use
  `Helpers.parseDate`.

## Known issues
- Embedded cash-management subtab duplicates the standalone tab
  (REVIEW_ISSUES Section C / Issue #10).

## Example bug reports → what to change
- "Today shows yesterday's bills" → date comparison wrong; bills store
  dates as `DD/MM/YYYY` strings — must use `Helpers.parseDate`, never
  `new Date(string)`.
- "Cash-in card double-counts retail sales" → check the filter chips
  also reset before recomputing the main card.
