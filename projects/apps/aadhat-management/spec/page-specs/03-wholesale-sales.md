# Page spec: Wholesale Sales (`wholesale-sales`)

## Purpose
Record a wholesale sale **from existing stock** (i.e., goods previously
purchased and sitting in stock). Different from retail sale because
(a) the inventory side matters, (b) the buyer is a business, (c) a
profit preview is required, (d) the bill stationery is separate.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `wholesale-sales` | `www/templates/wholesale-sales.html` | `www/js/modules/wholesale-sales.js` |

## Who can use it
Any authenticated user.

## What the user sees (top → bottom)
1. **New wholesale sale form**: party, date, items × (qty, rate),
   sale total, **profit preview**, expenses field (loading, transport),
   total.
2. **History list** of past wholesale sales below the form.
3. **"Complete all due"** bulk-payment button.
4. **Per-row reprint / WhatsApp / print** in the history list.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Save | Records sale + deducts from stock | `wholesaleSales/`, `stock/` |
| Complete all due | Marks every open wholesale-sale as paid | each `wholesaleSales/{id}` |
| Reprint | Re-sends ESC/POS for an existing sale | — |
| WhatsApp / Print | Same as billing | — |

## Calculations / formulas

### Sale total
```
saleTotal = Σ items.itemTotal              // rupees
```

### Buy amount (auto from stock average rates)
For each line item, look up the average cost in `AppState.stock`:

```
buyRate          = stock[itemKey].avgRate ?? stock[itemKey].rate ?? 0
itemBuyAmount    = qty × buyRate
totalBuyAmount   = Σ itemBuyAmount         // rupees
```
Source: `wholesale-sales.js:202-212`. Note `avgRate` is a back-compat
alias for `rate`; either lookup works (WALK-16).

### Profit preview
```
profit         = saleTotal − totalBuyAmount − expenses     // rupees
profitPercent  = saleTotal > 0 ? (profit / saleTotal) × 100 : 0
```
Source: `wholesale-sales.js:245-247`. Both shown in the profit pill on
the form. Expenses is the user-entered "loading + transport" field on
the form.

### Stock impact
On save, for each row, the same operation as retail-sale-but-reversed:
```
stock[itemKey].quantity  -= qty
```
Stock + sale must be in the same Firestore batch (atomic).

### Outstanding (for "Complete all due")
For each saved sale:
```
outstanding = sale.totalAmount − sale.paidAmount      // rupees
```
"Complete all due" sets `paidAmount = totalAmount` for every sale where
`outstanding > 0`. Single batch write.

## Data sources
- `AppState.salesHistory` (note: "salesHistory" without prefix means
  **wholesale** here; retail uses `retailSalesHistory`).
- `AppState.stock`, `.items` for cost lookup.

## Must NOT do
- Must not allow selling more than current stock for an item (warn or
  block; current behavior is warn — confirm with owner before tightening).
- Must not bypass the stock-deduction write — sale + stock update must
  be an atomic batch, otherwise stock and sales drift.
- Must not silently drop the cash/online split. (REVIEW_ISSUES C/15
  notes the form is currently all-due-only — a real gap, not a bug.)
- Must not look up cost from `AppState.items.wholesaleRate` — the
  authoritative cost is the **moving average in `AppState.stock`**, not
  the item master rate.

## Known issues
- All-due-only (no cash/online split on the form) — REVIEW_ISSUES C/15.

## Example bug reports → what to change
- "Stock didn't decrease after a wholesale sale" → save handler isn't
  writing `stock/{itemKey}.quantity -= qty` in the same batch as the
  sale doc. Check `wholesale-sales.js` save flow.
- "Profit shows the wrong percent" → recheck `(profit / saleTotal) × 100`
  isn't using `Math.round` on `profit` before division (rounding error).
- "I want to record a partial cash payment when I save a wholesale sale"
  → real feature gap; needs cash/online/due fields added to the form.
