# Page spec: Cash Management (`cash-management` — embedded in Today)

## Purpose
Track per-day cash session: opening balance → in/out throughout the day
→ closing balance. Used for end-of-day reconciliation.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| *(embedded in `day`)* | `www/templates/cash-management.html` | `www/js/modules/cash-management.js` |

## Who can use it
Any authenticated user.

## What the user sees
1. **Today's session**: opening balance, current running total, latest
   entries.
2. **Add entry**: amount, type (due-paid / due-received / business
   expense / personal expense), payment mode (cash / online), note.
3. **Close session** button → records `closingBalance`.
4. **Session history** with details.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Open session | First action of the day creates `cashManagement/{date}` | `cashManagement/{date}` |
| Add entry | Appends to today's session | `cashManagement/{date}.entries` |
| Close session | Records closing total | `cashManagement/{date}.closingBalance` |

## Calculations / formulas

### Running balance during a session
```
runningBalance = openingBalance + Σ entries[].signedAmount
```
where `signedAmount` is positive for inflows and negative for outflows:
```
type='due-received' OR type='sale-cash'        → +amount
type='due-paid'     OR type='purchase-cash'
                    OR type='business-expense'
                    OR type='personal-expense' → −amount
```

### Closing balance
On "Close session" the closingBalance is set equal to the
runningBalance at the moment of close:
```
closingBalance = runningBalance
closedAt       = now()
closedBy       = currentUser.uid
```

### Carry-forward
The next day's `openingBalance` should be auto-populated from the
previous day's `closingBalance`:
```
openingBalance(today) = closingBalance(yesterday) ?? promptUser()
```
Currently this auto-closes yesterday's session with `closingBalance=0`
if the user forgot — that's wrong (Issue #8). Should prompt instead.

## Data sources
- `AppState.cashManagement` (Firestore listener on `cashManagement/`).

## Must NOT do
- **Must NOT auto-close yesterday's session with closingBalance=0** if
  the user forgot — current behavior does this (Issue #8). Should
  prompt the owner instead, or carry forward without closing.
- Realtime listener path must use the **prefixed** collection name
  (Issue #6 was about the listener using a non-prefixed name).
- Must not let the user open two sessions for the same date.
- Must not allow editing a closed session — show a read-only view.

## Known issues
- Auto-close-with-zero issue (REVIEW_ISSUES, Issue #8).
- Listener path issue (Issue #6).

## Example bug reports → what to change
- "Yesterday's cash session closed at zero on its own" → the
  auto-close path. Prompt user instead of writing zero.
- "Two sessions opened today and the running balance is wrong" →
  add a check: if a session for `today` already exists, reuse it
  rather than creating a new doc.
