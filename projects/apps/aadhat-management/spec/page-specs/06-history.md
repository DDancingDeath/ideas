# Page spec: History (`history`)

## Purpose
One unified, searchable, filterable view of every bill ever recorded —
purchases, retail sales, wholesale sales — so the user can find / reprint
/ edit a past transaction without remembering which tab created it.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `history` | `www/templates/history.html` | `www/js/modules/history.js` |

## Who can use it
Any authenticated user.

## What the user sees
1. **Type filter**: All / Purchase / Retail / Wholesale.
2. **Search** (party name, item, bill number).
3. **Date range filter**.
4. **View toggle**: Card view / Table view.
5. **List of bills**, newest first.
6. **Per-bill actions**: Open detail modal, Edit (owner/admin),
   Delete (owner/admin), Print, WhatsApp share.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Open detail | Modal with full bill | — |
| Edit | Routes to billing tab in edit mode | depends |
| Delete | Removes bill (owner/admin only) | `purchases/{id}` etc; cascades to stock + outstanding |
| Print / WhatsApp | Same as billing | — |

## Calculations / formulas

### List composition
```
allBills = [
    ...purchaseHistory.map(b => ({ ...b, type: 'purchase' })),
    ...retailSalesHistory.map(b => ({ ...b, type: 'retail' })),
    ...salesHistory.map(b => ({ ...b, type: 'wholesale' }))
]
visible = allBills
    .filter(b => typeFilter === 'all' || b.type === typeFilter)
    .filter(b => date in range)
    .filter(b => searchMatch(b))
    .sort((a, b) => parseDate(b.date) - parseDate(a.date))
```

### Per-bill outstanding
```
outstanding(bill) = bill.payment?.due ?? bill.dueAmount ?? 0
```
The nested `payment.due` is the canonical source when present; the
top-level `dueAmount` is read as a fallback for older docs.

### Delete cascade
On delete, the same batch must:
1. Remove the bill doc.
2. Reverse the stock impact (purchase: subtract qty; wholesale-sale: add
   qty back; retail: no stock change).
3. Remove any related outstanding entries (the bill doc itself was the
   record; removing it removes it from the outstanding view).

## Data sources
- `AppState.purchaseHistory`, `.retailSalesHistory`, `.salesHistory`.

## Must NOT do
- Must not show entries from another business (role gating + multi-tenant
  guard, currently enforced at Firestore rule level).
- Delete must cascade — never leave stock or outstanding pointing at a
  deleted bill.
- Must not silently swallow a date-parse error in the sort comparator;
  bills with bad dates should land at the bottom, not crash the sort.

## Known issues
- See REVIEW_ISSUES Section E for known history bugs.

## Example bug reports → what to change
- "Deleting a bill leaves the stock wrong" → delete handler doesn't
  reverse stock deduction; need to undo the matching `stock/`
  adjustment in the same batch.
- "Search misses bills with capitalised party name" → search comparator
  must `.toLowerCase()` both sides.
