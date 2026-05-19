# Page spec: Items (`items`)

## Purpose
Master list of everything the business buys/sells. Each item has an
English name (canonical key), a Hindi name (for display), and three
default rates: purchase / retail / wholesale.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `items` | `www/templates/items.html` | `www/js/modules/items.js` |

## Who can use it
- **Add / Edit / Delete**: owner + admin only.
- **View / Excel import-export**: any role.

## What the user sees
1. Search box.
2. Items grid/list with: English name, Hindi name, purchase rate,
   retail rate, wholesale rate, frequency badge.
3. **Add Item** button (owner/admin only) → modal.
4. **Excel Import / Export** buttons.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Add | Modal → save → appears in list | `items/{englishName}` |
| Edit | Modal → save | `items/{englishName}` |
| Delete | Removes item | `items/{englishName}` |
| Excel Import | Parses .xlsx with SheetJS, batch writes | many `items/*` |
| Excel Export | Downloads .xlsx | — |

## Calculations / formulas

### Frequency badge
For each item, count how many times it appears across bill histories:
```
frequency(item) =
    Σ purchases[*].items     where item.name == englishName
  + Σ retailSales[*].items   where item.name == englishName
  + Σ wholesaleSales[*].items where item.name == englishName
```
Items are sorted by frequency desc on the "most-used" view.

### Excel import row validation
For each row in the imported sheet:
```
englishName     = trim(row['English Name'])     // required
hindiName       = trim(row['Hindi Name'])       // optional
purchaseRate    = parseFloat(row['Purchase Rate']) || 0
retailRate      = parseFloat(row['Retail Rate'])   || 0
wholesaleRate   = parseFloat(row['Wholesale Rate']) || 0
```
Row is skipped (not blocked) if `englishName` is empty.

## Data sources
- `AppState.items` (single Firestore listener on `items/`).

## Must NOT do
- Must not allow two items with the same English name (it's the doc id).
- Must not let staff see the Add/Edit buttons (role-gate the buttons in
  the template, not just the save handler).
- Must not corrupt the Excel parser when a row has a non-numeric rate —
  fall back to 0 and continue.

## Known issues
None.

## Example bug reports → what to change
- "Hindi name doesn't show in the bill items dropdown" → check
  `AppState.settings.showHindi` is read in the items autocomplete
  renderer, not just in the items list.
- "Excel import overwrote my edits" → import is doing
  `set` instead of `merge`. Switch to `set({ merge: true })` or do a
  pre-flight diff modal.
