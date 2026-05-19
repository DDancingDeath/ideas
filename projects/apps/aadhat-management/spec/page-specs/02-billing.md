# Page spec: Billing (`billing`)

## Purpose
Create a new bill — either **purchase** (we buy from a farmer / supplier)
or **retail sale** (we sell to a walk-in customer). One unified UI with a
mode toggle at the top.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `billing` | `www/templates/billing.html` | `www/js/modules/billing.js` (router), `purchase.js`, `retail-sale.js` |

## Who can use it
Any authenticated user. Staff can create; only owner/admin can edit/delete
existing bills (enforced by `firestore.rules`).

## What the user sees (top → bottom)
1. **Mode toggle**: `#purchaseModeBtn` / `#saleModeBtn`. Default is **Purchase**.
2. **Bill metadata**: bill number (auto-generated, daily counter via
   transaction — see Bill Numbering note), date (defaults to today),
   party name (autocompleted from prior bills).
3. **Items table**: per row — item name (autocompleted from items master),
   weight entries (a list of bag weights in kg), rate (₹/kg), per-row
   total, optional manual labor charge.
4. **Bill-level fields**: heavy-weight toggle (auto-calculates labor
   based on packets), labor charges (overridable), grand total, payment
   split (cash / online / due).
5. **Bottom action row**: WhatsApp share / Save / Print.
   Print uses Bluetooth ESC/POS via Cordova plugin (Android only).

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Switch mode | Re-renders form for purchase vs sale | — |
| Add row | Appends a new item line | — |
| Save | Validates → writes bill + updates stock + updates outstanding | `purchases/` or `retailSales/`, `stock/`, autosave clear |
| Autosave (debounced) | Saves draft so a crash doesn't lose work | `autoSaves/{uid}_{mode}` |
| Save as draft | Manual save without finalizing | `drafts/` |
| Print | Sends ESC/POS to paired BT printer | — |
| WhatsApp share | Opens system share sheet with rendered text | — |
| Pay-Online / Pay-Cash / All-Due quick buttons | Sets that field to `grandTotal`, others to 0 | — |
| 🎤 Voice (per section) | Tap-to-talk: dictate item, weight, rate; auto-fills the form | — |

### Voice input (Hindi + English mixed)
Hindi-shop-floor friendly. Tap **🎤 Voice** in the purchase or sale section
and say what you would normally type:

| You say | Form gets |
|---|---|
| "10 kilo aloo at 30 rupees" | item=Aloo, weight=10, rate=30, weight chip auto-added |
| "5 kg pyaaz 25" | item=Pyaaz, weight=5, rate=25 (no marker → first number = weight, second = rate) |
| "दस किलो आलू तीस" | same as above, in Hindi |
| "do kilo soya" | item=Soya, weight=2, rate left blank (uses last-saved rate) |
| "add to bill" / "जोड़ दो" / "save" | clicks **Add to Bill** for the active section |
| "clear" / "मिटा दो" / "cancel" | clears item, rate, weight inputs (does not clear staged rows) |

Implementation lives in `www/js/modules/voice-billing.js`. The parser
(`parseUtterance`) is pure and fully unit-tested
(`www/js/__tests__/voice-billing.test.js`); the SpeechRecognition wrapper
uses the Web Speech API (`webkitSpeechRecognition`, `lang='hi-IN'`),
falls back to a toast when unsupported, and on Capacitor Android calls
`navigator.mediaDevices.getUserMedia` once to trigger the WebView mic
permission prompt. Item names are matched against `AppState.items` by
substring + token-prefix (longest-match wins so "tomato puree" beats
"tomato"). Numbers can be digits or named (English or Devanagari, 0–100
plus 1000); when a unit marker is missing the spoken order decides
weight-then-rate.

## Calculations / formulas

### Per-item total (both modes)
```
qty            = Σ weights[]                         // kg, from per-bag entries
itemTotal      = round(qty × rate)                   // rupees, integer
```
Source: `purchase.js:174-175`, `retail-sale.js:169-184`.

### Bill total (sum across rows)
```
billTotal      = Σ items.itemTotal                   // rupees
totalPackets   = Σ items.weights.length              // bag count
```

### Labor charges (purchase mode only)
The heavy-weight toggle and the items master per-item labor rate combine:

```
heavyPacketsCount     = Σ items.weights.length where item is flagged heavy
autoCalculatedLabor   = laborRate × heavyPacketsCount        // rupees
laborCharges          = manualOverride OR autoCalculatedLabor
```
Source: `purchase.js:353` for the auto formula.

### Grand total

**Purchase**: labor is what the supplier pays the laborer, so it is
**deducted** from what we owe the supplier:
```
grandTotal     = billTotal − laborCharges            // rupees, rounded
amountPayable  = grandTotal
```
Source: `purchase.js:382` and `:611`.

**Retail sale**: no labor field. Total receivable equals bill total:
```
grandTotal        = salesTotal = Σ items.itemTotal
amountReceivable  = salesTotal
```
Source: `retail-sale.js:349-355`.

### Payment split (both modes)
The user enters two of three; the third is computed. Invariant:
```
online + cash + due == grandTotal                    // rupees
```
Save is blocked if this invariant is broken.

When the **Pay Online** quick button is clicked: `online = grandTotal,
cash = 0, due = 0`. **Pay Cash** and **All Due** are symmetric.
Source: `purchase.js:419-435`, `retail-sale.js:399-414`.

### Bill numbering
On Save, a Firestore **transaction** runs on `counters/{date}_{type}`
(e.g. `counters/2026-05-09_purchase`):
```
nextNumber = (existingCounter ?? 0) + 1
write counter = nextNumber
bill.number = nextNumber
```
Atomic — no `count + 1` race. Reverted bills do not roll back the counter
(numbers are strictly increasing per day per type).

### Stock impact (purchase only)
On a purchase save, for each row:
```
stock[itemKey].quantity  += qty
stock[itemKey].rate       = movingAvg of (oldRate, rate)   // weighted by qty
```
On retail sale: no stock impact (retail is from over-the-counter
inventory not tracked here). Wholesale sales DO touch stock — see
`03-wholesale-sales.md`.

## Data sources
- `AppState.items` for item autocomplete.
- `AppState.purchaseHistory` / `.retailSalesHistory` for party autocomplete.
- `AppState.settings` for default labor rate, heavy-weight default.

## Must NOT do
- **Must NOT generate bill numbers via `count + 1`.** Use the daily
  counter transaction (already fixed; see REVIEW_ISSUES Section H).
- Must not allow saving when payment split doesn't equal grand total.
- Must not lose unsaved work on accidental tab switch — autosave covers it.
- Must not write `dueAmount` without also writing the nested `payment.due`
  (and vice versa). Outstanding tab reads `payment.due`; History reads
  `dueAmount`. Both must agree.
- Must not call `firebase.firestore()` directly — must go through
  `FirebaseService` so the env prefix (`prod_*` / `staging_*`) is applied.
- **Purchase**: must NOT add labor to grand total. Labor is a deduction.
- **Retail**: must NOT subtract labor from grand total. There is no labor
  field on retail.

## Known issues
- ~~AI Assistant (`15-chat.md`) was broken because of `firebaseConfig.js`
  shadowing — fixed (STG-WALK-5).~~
- ~~Bottom action buttons (Save / Print / WhatsApp) clipped by OS taskbar
  — fixed (STG-WALK-6).~~
- Bill numbering race fixed in this clone (REVIEW_ISSUES H).

## Example bug reports → what to change
- "Heavy-weight bill — the labor isn't auto-calculating" → check
  `heavyPacketsCount` in `purchase.js`; the items master flag for
  `isHeavy` may not be reaching the per-row data structure.
- "I saved a bill but the outstanding tab still shows it as due" →
  payment split ≠ grand total, or `dueAmount` written but `payment.due`
  not. Check the save handler.
- "Customer name isn't autocompleting" → autocomplete reads from
  `AppState.retailSalesHistory`; verify it's populated before form
  renders.
- "Two bills got the same number today" → daily counter transaction
  not running (or being run outside `runTransaction`). Inspect bill
  save path.
