# Page spec: Stocks (`stock`)

> **Status:** Verified post-redesign. Stock display logic is unchanged
> from the original; this page is a sibling of Finance / Reports /
> Analytics in that those three now read `stockValue` via
> `PeriodMath.stockValue()` (which itself uses the data structures this
> page maintains). So the contract here is: **the values you see on this
> page must equal what `PeriodMath.stockValue()` would compute** —
> if they ever differ, fix the listener / save handler, never patch the
> formula on one side.

## Purpose
Show the current quantity of every item in stock and let the owner make
manual adjustments (with a reason). Stock is **derived** from
purchases − wholesale-sales ± adjustments; the page must show that
computation accurately.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `stock` | `www/templates/stock.html` | `www/js/modules/stock.js` |

## Who can use it
- View: any user.
- Adjust: owner + admin.

## What the user sees
1. Search box.
2. Current stock list (item, qty, last-updated).
3. **Adjust Stock** button → modal with: item picker, mode (add /
   remove / set absolute), quantity, reason (required).
4. Adjustment history below.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Add adjustment | Writes adjustment doc; current stock updates | `stockAdjustments/`, refreshes derived |
| Remove adjustment | Reverses the adjustment | `stockAdjustments/{id}` |

## Calculations / formulas

### Current stock per item
The page reads from `AppState.stock` which is maintained by the
purchase/wholesale-sale save handlers. The display tries multiple keys
to deal with English/Hindi/id collisions:

```
currentStock(item) =
    AppState.stock[item.id]?.quantity        ?? 0
  + AppState.stock[item.englishName]?.quantity ?? 0
  + AppState.stock[item.hindiName]?.quantity   ?? 0
```
Source: `stock.js:361-369`. The triple-lookup is defensive against
historical data with mixed key conventions; on a clean install only
one key is populated per item.

### Manual adjustment math
Three modes:
```
add:    newStock = currentStock + quantity
remove: quantity = clamp(rawQuantity, 0, currentStock)        // can't remove more than exists
        newStock = currentStock − quantity
set:    newStock = quantity                                    // absolute
```
Source: `stock.js:378-391`.

The adjustment doc records:
```
{
    itemKey,
    mode,                      // 'add' | 'remove' | 'set'
    quantity,                  // post-clamp value
    rawQuantity,               // pre-clamp (for 'remove')
    previousStock: currentStock,
    newStock,
    reason,                    // required
    timestamp,
    user
}
```

### Average rate (cost) per item
The `rate` field on `AppState.stock[itemKey]` is a quantity-weighted
moving average maintained by the purchase save handler. Wholesale-sales
read it as the cost of goods sold for profit calc (see
`03-wholesale-sales.md`). Reports / Analytics also consume it via
`PeriodMath.stockValue()` to compute total inventory value:

```
PeriodMath.stockValue() = Σ stock[item].quantity × stock[item].rate
```

If a stock entry has `quantity > 0` but `rate == 0` it shows up as ₹0
in `stockValue`, which silently understates Net Worth on the Finance
page. Audit the purchase save handler to make sure `rate` is written
whenever `quantity` is.

## Data sources
- `AppState.stock` (Firestore listener).
- `AppState.stockAdjustments` (audit list).
- `AppState.items` (for the picker).

## Must NOT do
- Must not let the user adjust stock without a reason string.
- Must not silently change the derivation formula. If `PeriodMath.stockValue()`
  reads `quantity × rate`, this page's listener writes must keep both
  fields aligned.
- 'remove' mode must clamp to current — never write a negative stock.
- Must not refresh the list by re-reading Firestore on every keystroke
  in the search box; filter the in-memory list.

## Known issues
- See `docs/REVIEW_ISSUES.md` Section C for the bottom-of-menu refresh issues.

## Example bug reports → what to change
- "I added an adjustment but the stock total is unchanged" → after
  writing, the stock list isn't recomputing. Check `refreshDerived()`
  is called inside the save handler (and that the listener fires).
- "Stock shows zero for an item I just purchased" → triple-key lookup
  may be missing a key; verify the purchase save writes
  `stock[item.englishName]` (not `stock[item.id]` for legacy data).
- "Finance shows different stock value than this page's qty × rate" →
  `AppState.stock[item].rate` is missing or zero on at least one row.
  Audit the purchase save handler. Do **not** change `PeriodMath.stockValue()`
  to use a different field — it must equal what's shown here.

