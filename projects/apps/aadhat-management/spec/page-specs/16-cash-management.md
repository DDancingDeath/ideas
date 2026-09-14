# Page spec: Cash Management (`cash-management` — embedded in Today)

## Purpose
Track the shop day's cash drawer: opening count → cash inflows/outflows
→ counted close → reconciliation. Used for end-of-day mismatch detection.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| *(embedded in `day`)* | `www/templates/cash-management.html` | `www/js/modules/cash-management.js` |

## Who can use it
Any authenticated user.

## What the user sees
1. **Today's session**: opening float, optional opening note, expected
   drawer cash, latest cash entries, deposits, and current mismatch
   preview if a counted value has been typed but not saved.
2. **Add entry**: amount, type (due-paid / due-received / business
   expense / personal expense), payment mode (cash / online), note.
3. **Record deposit**: amount removed from the drawer for the bank,
   optional note, who recorded it, and when.
4. **Close session** button → requires counted cash and optional
   closing note; shows expected closing, signed mismatch, and whether
   a Review Queue flag will be raised.
5. **Session history** with reconciliation details.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Open session | First action of the day opens one cash session with `openingCount` and optional `openingNote` | `cash_session_opened` |
| Add entry | Records the underlying business event; only its cash leg changes drawer cash | sale / purchase / expense / withdrawal / outstanding events |
| Record cash deposit | Records money removed from the drawer for bank deposit | `cash_deposit_recorded` |
| Close session | Records counted cash, expected closing, signed mismatch, and optional `closingNote` | `cash_session_closed`; possibly `flag_raised` |
| Select past session | Opens a read-only detail view | read only |

## Calculations / formulas

### Expected drawer cash during a session
```
expectedCash = openingCount + Σ signed cash entries
```
Only cash legs affect the drawer. Online payments never touch the drawer.

`cash_deposit_recorded.amount` is an outflow:
```
signedAmount = -amount
```

Other signed cash entries:
```
type='due-received' OR type='sale-cash'        → +amount
type='due-paid'     OR type='purchase-cash'
                    OR type='business-expense'
                    OR type='personal-expense' → −amount
```

### Closing reconciliation
On "Close session" the user must enter the physically counted drawer cash:
```
expectedClosing = openingCount + Σ signed cash entries
mismatch        = countedCash − expectedClosing
closedAt        = now()
closedBy        = currentUser.uid
```
`mismatch` is signed: negative means the drawer is short; positive means
it is over. All amounts are integer paise.

The close event records `closingCount` / counted cash, `expectedClosing`,
`mismatch`, and optional `closingNote`. The mismatch is never silently
absorbed into expected cash.

### Mismatch thresholds
| Condition | Result |
|---|---|
| `abs(mismatch) <= shopProfile.cash.mismatchTolerance` | Close succeeds; mismatch is recorded; no flag |
| `abs(mismatch) > shopProfile.cash.mismatchTolerance` and `<= shopProfile.cash.mismatchLarge` | Close succeeds and raises `cash.mismatch.above-tolerance` with severity `medium` |
| `abs(mismatch) > shopProfile.cash.mismatchLarge` | Close succeeds and raises `cash.mismatch.large` with severity `high` |

A session may close with any mismatch because refusing to close would
strand the shop day. It cannot close without a counted cash figure.

### Mismatch resolution
Mismatch flags appear in [`../rebuild/review-queue.md`](../rebuild/review-queue.md).
The Review Queue resolves them by writing `flag_resolved` with
`resolution = approve`, `dismiss`, or `correct`. The cash close event is
immutable; corrections are separate events referenced from the resolution.

### Carry-forward
The next day's `openingCount` should be auto-populated from the previous
day's counted close:
```
openingCount(today) = closingCount(yesterday) ?? promptUser()
```
Currently this auto-closes yesterday's session with `closingBalance=0`
if the user forgot — that's wrong (Issue #8). Should prompt instead.

## Session history detail

The history list is ordered newest session first. Selecting a session opens
a read-only detail view showing:

- opening float (`openingCount`), opener, opened time, and opening note
- counted close (`closingCount`), closer, closed time, and closing note
- expected closing, signed mismatch, and short/over label
- mismatch flag status and Review Queue resolution, if any
- cash deposits in chronological order, with amount, note, recorder, and time
- cash entries in chronological order, showing source event, cash in/out,
  payment mode, note, actor, and timestamp

Closed sessions are read-only. Unclosed past sessions show their entries and
opening note, but no counted close, expected close, or mismatch until closed.

## Data sources
- Event projection for `cash_session_opened`, `cash_deposit_recorded`,
  cash legs of business events, `cash_session_closed`, `flag_raised`, and
  `flag_resolved`.

## Must NOT do
- **Must NOT auto-close yesterday's session with closingBalance=0** if
  the user forgot — current behavior does this (Issue #8). Should
  prompt the owner instead, or carry forward without closing.
- Realtime listener path must use the **prefixed** collection name
  (Issue #6 was about the listener using a non-prefixed name).
- Must not let the user open two sessions for the same shop.
- Must not allow editing a closed session — show a read-only view.
- Must not close a session without counted cash.
- Must not treat online payments as drawer cash.
- Must not hide or absorb a mismatch; the close event records it.

## Known issues
- Auto-close-with-zero issue (REVIEW_ISSUES, Issue #8).
- Listener path issue (Issue #6).

## Example bug reports → what to change
- "Yesterday's cash session closed at zero on its own" → the
  auto-close path. Prompt user instead of writing zero.
- "Two sessions opened today and the running balance is wrong" →
  add a check: if a session for `today` already exists, reuse it
  rather than creating a new doc.
- "The drawer was ₹150 short but nothing showed for review" → check
  that `cash_session_closed.mismatch` was recorded and the suspicion
  engine raised `cash.mismatch.above-tolerance`.
- "The bank deposit made the close look short" → check that
  `cash_deposit_recorded` is included as a cash outflow.
