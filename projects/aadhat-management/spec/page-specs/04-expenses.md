# Page spec: Expenses (`expenses` — module file is `miscellaneous.js`)

## Purpose
Record business and personal cash outflows that aren't bills. Keep
business and personal segregated for finance reporting.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `expenses` | `www/templates/expenses.html` | `www/js/modules/miscellaneous.js` *(file is named differently from the tab)* |

## Who can use it
Any authenticated user.

## What the user sees
1. **Category toggle**: Business / Personal.
2. **Form**: amount, person/payee (autocomplete), reason, date,
   payment mode (cash / online).
3. **Recent expenses list** below the form, with edit / delete.
4. **Print receipt** button on each entry.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Save | Records expense | `expenses/` |
| Edit / Delete | Updates / removes existing | `expenses/{id}` |
| Print | ESC/POS receipt | — |

## Calculations / formulas
None on this page directly — every input is stored verbatim. The only
derived number is the category running total at the top of the list:
```
businessTotal = Σ expenses where category='business'
personalTotal = Σ expenses where category='personal'
```

## Data sources
- `AppState.expensesHistory`.

## Must NOT do
- Must not mix business and personal categories in summary cards.
- Must not write without `category` (`'business' | 'personal'`) — the
  schema requires it for Reports / Finance to filter.
- Must not let staff see personal expenses (current enforcement is
  client-side filter — verify in `firestore.rules` if owner is concerned
  about confidentiality).

## Known issues
None blocking.

## Example bug reports → what to change
- "Personal expenses are showing in Reports" → Reports module should
  filter `category == 'business'` for the business overview.
- "Edit doesn't preserve the date" → check the edit modal pre-fills
  `date` field; `Helpers.parseDate` must be used.
