# Page spec: Finance (`finance`)

> **Status:** Redesigned. The previous Dashboard subtab and `setDateFilter`
> machinery have been removed. Finance is now strictly a **right-now
> position** view (no period filtering); period totals belong on Reports.

## Purpose
Owner's "where do I stand right now" page. Two questions:
1. **Position** — how much am I worth at this moment?
   (Cash + Stock + Receivable + CustomAssets − Payable − CustomLiabilities)
2. **Withdrawals** — how much money have I taken out of the business
   over its lifetime, and how much is "available" by the rough cash-flow
   profit definition?

Anything that depends on a period (this month's revenue, last week's
expenses, year-to-date profit) lives on **Reports**, not here.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `finance` | `www/templates/finance.html` | `www/js/modules/finance.js` |

Math is delegated to:
- `www/js/utils/period-math.js` — `PeriodMath` static helper. Every
  number on this page goes through it so the same money formula is
  used by Reports, Analytics, and Finance.

## Who can use it
- View: any user.
- Add withdrawal: owner + admin (writes blocked anyway by the staging
  read-only guard).

## Subtabs
| Tab button | Default? | What it shows |
|---|---|---|
| **Position** | yes | Net Worth hero card + Assets / Liabilities / Custom Accounts breakdowns. |
| **Withdrawals** | no | Available headline + log of past withdrawals. |

The old `dashboard` and `assets` tab ids are kept as aliases inside
`filterTab()` so external links / chat-router intents don't break — they
both route to **Position**.

## Calculations / formulas

All money math goes through `PeriodMath`. The methods used on this page:

```text
PeriodMath.cashOnHand()
    = Σ paymentSplit(retailSalesHistory).cash      // money received cash, retail
    + Σ paymentSplit(salesHistory).cash            // money received cash, wholesale
    − Σ paymentSplit(purchaseHistory).cash         // money paid cash, purchases
    − Σ businessExpenses where mode='cash' .amount
    − Σ withdrawals.amount

PeriodMath.stockValue()
    = Σ stock[item].quantity × stock[item].rate

PeriodMath.outstanding()
    = { receivable, payable }
      receivable = Σ paymentSplit(retail+wholesale sales).due
      payable    = Σ paymentSplit(purchases).due

PeriodMath.cashFlowProfit(allTimeRange)
    = totalSalesValue − purchasesValue − businessExpensesValue
      // personal expenses NOT subtracted

PeriodMath.withdrawalsValue(allTimeRange)
    = Σ withdrawals.amount
```

### Position hero card (Net Worth)
```text
totalAssets       = cashOnHand + stockValue + receivable + customAssets
totalLiabilities  = payable + customLiabilities
netWorth          = totalAssets − totalLiabilities
```
The hero card surfaces `netWorth` prominently and shows the two
totals in a small mini-row underneath so the user can see how the
final number was assembled.

### Why "Business Balance" row was removed
The old layout had a "Business Balance" row that tried to estimate the
P&L of unsold inventory. It was wrong: `stockValue` already represents
the cost of unsold purchases (qty × rate where rate is the moving-avg
cost), so adding a separate "business balance" line **double-counted**
the same money. Stock has been left as the single canonical "tied-up
in inventory" figure.

### Custom finance accounts
User-added buckets like "Personal Loan from XYZ" or "Savings Account
balance ₹1,00,000". Stored in `AppState.customFinanceAccounts` (still
mirrored to `localStorage` until Issue #29 is closed). Each entry:
```js
{ name: string, type: 'asset' | 'liability', amount: number }
```
Type 'asset' adds to `customAssets`; type 'liability' adds to
`customLiabilities`. They flow into the Net Worth formula above.

### Withdrawals — "Available" headline
```text
available = PeriodMath.cashFlowProfit(allTime)
          − PeriodMath.withdrawalsValue(allTime)
```
This is a **headline**, not actual cash. It tells the owner "by the
all-time cash-flow profit definition, you've earned X and taken out Y,
so Z is the conceptual envelope still untaken." For the **real** cash
that's actually in the safe right now, see `cashOnHand` on the Position
tab.

## Data sources
- `AppState.purchaseHistory`, `AppState.retailSalesHistory`,
  `AppState.salesHistory` — all routed through `PeriodMath`.
- `AppState.expensesHistory` — only `category='business'` consumed.
- `AppState.withdrawals`.
- `AppState.stock` — for `stockValue()`.
- `AppState.customFinanceAccounts` — for the Custom Accounts card.
- Settings: `AppState.settings.showHindi` for label language.

## Must NOT do
- Must not add a "period filter" to Position. Position is by definition
  a right-now snapshot. Period numbers belong on Reports.
- Must not add a "Business Balance" row that adds `revenue − costs`
  on top of `stockValue` — it double-counts. (See "Why Business
  Balance row was removed" above.)
- Must not store custom finance accounts only in `localStorage` — they
  need to sync across devices (Issue #29).
- Must not include personal expenses in the Net Worth or Available
  calculation (only `category='business'` flows through).
- Must not bypass `PeriodMath` and re-implement the formulas inline.
  If a number on this page disagrees with a number on Reports for the
  same definition, the bug is in whichever side bypassed `PeriodMath`.

## Known issues
- Custom accounts in localStorage only (REVIEW_ISSUES Issue #29).
- Issue #30 (calendar date boundaries) is **closed** by `PeriodMath`
  and no longer applies to this page (which has no period filter
  anyway).

## Example bug reports → what to change
- "Net Worth dropped by ₹50,000 even though I didn't sell anything" →
  almost always a stock rate change or a stale `cashOnHand` listener.
  Audit `AppState.stock[item].rate` and the cash-flow listeners; do
  NOT touch the formula.
- "Available shows negative" → owner withdrew more than the all-time
  cash-flow profit so far. Working as intended; surface it as red text,
  not a bug.
- "Custom account I added on phone doesn't show on web" → Issue #29
  (localStorage isolation). Migrate to Firestore.
- "Cash on hand doesn't match what I have in my wallet" → an expense
  / withdrawal wasn't recorded, OR a sale recorded the wrong payment
  mode (cash vs online). Reconcile from the Cash Management tab, not
  by changing the formula.

## Where past-period numbers went (migration note)
The old Finance Dashboard subtab used to show "Today / Week / Month /
Year totals" — those are now on **Reports** (canonical) and **Analytics
overview** (forward-looking projections). The "Open Reports" CTA on
Position points the user there.
