# Page spec: Outstanding (`due`)

## Purpose
Show every bill that still has unpaid money on it, split by direction
(we owe / customer owes), and let the user record a partial or full
payment against any of them.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `due` | `www/templates/due.html` | `www/js/modules/outstanding.js` |

## Who can use it
Any authenticated user.

## What the user sees
1. **Subtab toggle**: Purchase outstanding (we owe supplier) / Retail
   outstanding (customer owes us).
2. **Search + filter** (party, item, date).
3. **List of unpaid bills** with the open balance per bill.
4. **Per-bill record-payment row**: cash / online split inputs +
   "Mark cleared" button.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Record payment | Reduces `dueAmount` + `payment.due` on the bill; appends a payment entry | `purchases/{id}` or `retailSales/{id}` |
| Mark cleared | Sets due to 0 | same as above |
| Open bill | Navigates to History detail | — |

## Calculations / formulas

### Open balance per bill
```
openBalance(bill) = bill.payment?.due ?? bill.dueAmount ?? 0
```
A bill appears in the list iff `openBalance > 0`.

### Record payment
For a payment entry `{ cash, online }`:
```
paid              = cash + online
newDue            = max(0, openBalance − paid)

bill.dueAmount     := newDue                 // top-level field
bill.payment.due   := newDue                 // nested canonical field
bill.payment.cash  += cash
bill.payment.online+= online
bill.payment.entries.push({ cash, online, timestamp, user })
```

**Both `dueAmount` and `payment.due` must be written in the same update**
because History reads `dueAmount` and Outstanding reads `payment.due`.

### Mark cleared
```
paid               = openBalance
newDue             = 0
bill.dueAmount     := 0
bill.payment.due   := 0
bill.payment.entries.push({ cleared: true, timestamp, user, paid })
```

### List subtotal (top of subtab)
```
totalReceivable = Σ retailSalesHistory.openBalance      // customer owes us
totalPayable    = Σ purchaseHistory.openBalance         // we owe suppliers
```

## Data sources
- `AppState.purchaseHistory.filter(b => openBalance > 0)`.
- `AppState.retailSalesHistory.filter(b => openBalance > 0)`.

## Must NOT do
- Must not double-count payments. Check payment-entry idempotency
  (prefer a client-generated id on each entry).
- Must always update **both** `dueAmount` and nested `payment.due`
  fields in the same write.
- Must not let the user record a negative payment.
- Must not allow `paid > openBalance` (would create a refund situation
  the schema doesn't model). Block at the input level.

## Known issues
- See REVIEW_ISSUES Section C for outstanding bugs.

## Example bug reports → what to change
- "I marked a bill cleared but it still shows up here" → bill's
  `dueAmount` was updated but `payment.due` was not, and Outstanding
  reads `payment.due`. Update both fields atomically.
- "The subtotal at the top doesn't change after a payment" → listener
  fires, but the recompute reads the stale value. Force a re-derive
  after the write resolves.
