# Aadhat Management App — Capabilities

> **Source of truth for what this app does today.**
> Generated from a deep, read-only walkthrough of the production code at commit
> `bc2a434` (mirrored into this staging clone). When code changes here, update
> this file in the same PR.

This is a **single-page web app** for a small wholesale + retail business
(Hindi/English UI, Indian currency/locale). It runs in a browser, as a PWA, or
inside Capacitor on Android. Data lives in a single Firebase project
(Firestore + Firebase Auth). A subset of features (printing) needs Cordova
Bluetooth Serial on Android.

---

## 1. App shell

| Capability | Where |
|---|---|
| SPA bootstrap loads HTML templates dynamically and exposes `window.app` for inline `onclick` handlers | `www/index.html`, `www/js/template-loader.js`, `www/js/main.js` |
| Tab system: a single fixed shell with `#<tabname>` divs swapped via `NavigationManager.showTab()` | `www/js/modules/navigation.js`, `www/templates/navigation.html` |
| Global app state, listeners, and date helpers | `www/js/modules/state.js`, `www/js/modules/helpers.js` |
| Firebase wrapper (`FirebaseService`) for all Firestore reads/writes, with environment-prefixed collection names | `www/js/firebase/firestore-service.js` |

The app deliberately **does not** use a build step or framework. All scripts
load via `<script>` tags from `www/index.html` and use the Firebase compat
SDK (global `firebase.*`).

---

## 2. Authentication & roles

| Capability | Notes |
|---|---|
| Email/password login | `auth.html`, `authentication.js` |
| New-user registration with `pending` status | New users are blocked from app until an Admin approves them |
| Password reset email | Standard Firebase reset flow |
| Logout | Returns to login screen; clears local app state |
| Role-based UI hiding | Admin and Diagnostics nav links are hidden unless role ∈ {`owner`, `admin`} |
| Pending / rejected gating | If `users/{uid}.status` is `pending` or `rejected`, login is blocked with a message |
| Owner bootstrap | First user becomes `owner` (see `firestore.rules`); subsequent users get `staff` by default |

User profile data lives in the `users/{uid}` Firestore document
(`displayName`, `role`, `status`).

---

## 3. Navigation (full tab list)

The hamburger / side menu exposes **15 tabs**. Documented top-to-bottom:

| # | Tab id | Label | Module | Purpose |
|---|---|---|---|---|
| 1 | `day` | Today | `day.js` | Today's totals, transaction list, embedded cash-management subtab |
| 2 | `billing` | Billing | `billing.js` (+ `purchase.js`, `retail-sale.js`) | Create new purchase or retail-sale bill |
| 3 | `wholesale-sales` | Sales | `wholesale-sales.js` | Wholesale sale from existing stock |
| 4 | `expenses` | Expenses | `miscellaneous.js` *(yes, the file name is `miscellaneous.js`)* | Business + personal expenses |
| 5 | `items` | Items | `items.js` | Item master (English/Hindi names + 3 rates) |
| 6 | `history` | History | `history.js` | Combined view of all bills (purchase + retail + wholesale) |
| 7 | `stock` | Stocks | `stock.js` | Derived stock + manual adjustments |
| 8 | `due` | Outstanding | `outstanding.js` | Unpaid bills (purchase + retail) and payment recording |
| 9 | `finance` | Finance | `finance.js` | Dashboard, withdrawals, custom finance accounts |
| 10 | `reports` | Reports | `reports.js` | Period reports, charts, CSV/PDF export |
| 11 | `analytics` | Analytics | `analytics.js` | Rule-based business insights |
| 12 | `admin` | Admin *(owner only)* | `admin.js` | User management + business config + data tools |
| 13 | `diagnostics` | Diagnostics *(owner only)* | `diagnostics.js` | Telemetry + audit log viewer |
| 14 | `settings` | Settings | `settings.js` | Theme, Hindi display, Bluetooth printer |
| 15 | `chat` | AI Assistant | *(none — see issues doc)* | UI is wired up but the implementing module does not exist |

The "bottom of the menu" (where the user reports a lot of breakage) is
**Stocks → Outstanding → Finance → Reports → Analytics → Settings → AI Assistant**.
All seven of these have functional bugs documented in `REVIEW_ISSUES.md`.

---

## 4. Module deep-dives

### 4.1 Today (`day`)

- Shows today's headline in/out totals (cash + online), separated by purchase / retail / wholesale.
- Lists today's transactions with type filters.
- Embeds a **subtab clone of `cash-management`** inside the Today page (see Issue #10).

Data sources: `AppState.purchaseHistory`, `AppState.retailSalesHistory`, `AppState.salesHistory` (wholesale), `AppState.expensesHistory`, `AppState.cashManagement`.

### 4.2 Billing (`billing`)

Two modes selected by tab buttons:

- **Purchase** (`purchase.js`) — record a purchase from a farmer/supplier. Captures party name, items × (quantity, weight, rate, labor), payment split (cash/online/due), heavy-weight toggle (subtracts a per-bag deduction), labor rate per qty.
- **Retail Sale** (`retail-sale.js`) — record a retail customer sale. Same shape as purchase, but flows the other direction (sale total = receivable).

Shared features:

- Autosave to `autoSaves/{userUid}_{mode}` so an unfinished bill survives a crash.
- Drafts saved to `drafts/`.
- Print via Bluetooth ESC/POS.
- WhatsApp share button.
- Person autocomplete from prior bill history.

### 4.3 Wholesale Sales (`wholesale-sales`)

- Sells **from existing stock** (purchase items already received), not new purchases.
- Profit preview (cost from stock vs. sale rate).
- "Complete all due" bulk action.
- Reprint / WhatsApp / print existing wholesale sales.
- **Currently all-due only** — the form has no cash/online split for wholesale sales (Issue #15).

### 4.4 Expenses (`miscellaneous.js`)

- Two categories: **business** and **personal**.
- Print receipt.
- Person autocomplete.
- History list with detail / edit / delete.

Note the module is named `miscellaneous.js` even though the tab and template
are called `expenses`.

### 4.5 Items (`items`)

- Item master with English name (canonical), Hindi name, and three rates: purchase / retail / wholesale.
- Modal-based add/edit.
- Excel import + export via SheetJS (`xlsx`).
- Frequency badges (most-used items).
- Staff role sees fewer fields than owner/admin.

### 4.6 History (`history`)

- Unified view of `purchaseHistory` + `retailSalesHistory` + `salesHistory` (wholesale).
- Card view + table view toggle.
- Search / date filter.
- Detail modal per bill.
- Edit / delete entry points.

### 4.7 Stock (`stock`)

- Derived current stock = purchases received − wholesale sales − adjustments.
- Manual stock adjustment: add / remove / set absolute, with reason.
- Adjustment history list.
- Search.

### 4.8 Outstanding (`due`)

- Two subtabs: **Purchase outstanding** (we owe the supplier) and **Retail outstanding** (customer owes us).
- Per-bill payment recording (cash / online split).
- "Mark cleared" button.
- Links back to the originating bill.

### 4.9 Finance (`finance`)

- Dashboard with assets, liabilities, withdrawals.
- Date filter (note: "week"/"month"/"year" mean rolling 7d/1mo/1yr, not calendar — Issue #30).
- Custom finance accounts (currently localStorage-only — Issue #29).
- Withdrawals collection (`withdrawals/`).

### 4.10 Reports (`reports`)

Four report types:
1. **Overview** — combined totals.
2. **Purchases** — by item / by party / time series.
3. **Sales** — same shape as purchases but for retail+wholesale.
4. **Compare** — side-by-side period comparisons.

Outputs:
- On-screen charts (Chart.js).
- CSV download.
- PDF download.
- Date filter.

### 4.11 Analytics (`analytics`)

Rule-based heuristics (no ML):
- Cash prediction for the next month based on recent trends.
- Monthly summary cards.
- Profit trend line.
- Item focus suggestions ("you're buying a lot of X but selling little").
- Generic suggestions panel.

### 4.12 Cash Management (`cash-management`, embedded in Today)

- Per-day cash session: opening balance → transactions during the day → closing balance.
- Transactions: due paid/received, business expense, personal expense.
- Reconciliation view.
- Session history with details.
- **Auto-closes the previous session at sign-in with closingBalance=0** if user forgot to close (Issue #8).
- Stored in `cashManagement/` collection (Issue #6: realtime listener uses the wrong name).

### 4.13 Admin (owner-only, `admin`)

Three subtabs:
- **Configure** — business config (name, address, phone, GSTIN, default labor rate, default heavy-weight, etc.) stored in `localStorage` `settings` key.
- **Users** — list of all users; approve/reject pending; change role; delete.
- **Data** — wipe / reseed test data, export, etc.

Note: there is also a standalone `configure.html` template that is loaded but
not currently navigable from the menu (see Issue #48).

### 4.14 Diagnostics (owner-only, `diagnostics`)

- Telemetry events table (write/read/error counts).
- Audit log viewer.
- Clear / delete buttons.
- Reads `telemetry/` and `auditLogs/` collections.

### 4.15 Settings (`settings`)

- Dark mode toggle.
- "Show Hindi" toggle (renders Hindi name alongside English in lists).
- Bluetooth printer: scan / connect / disconnect / test print.
- Logout button.

The settings UI in the visible template only exposes dark/Hindi/printer,
but the JS still tries to read labor-rate fields that no longer exist
(Issues #2, #3).

### 4.16 AI Assistant (`chat`)

The template exists with a chat UI that calls `askChatbot()` and
`sendChatMessageFromTab()` — but **no implementation is loaded**. There is no
`chat.js` module, no LLM integration, no rule-based responder.

The user has explicitly asked for "a better AI chatbot", so this is a green
field: anything we add will be the first implementation. Plan v2 captures
this work under Phase 4.

---

## 5. Data model (Firestore collections)

All collection names are **environment-prefixed** by `FirebaseService` (e.g.
`prod_purchases`, `staging_purchases`). A few modules bypass the wrapper and
hit raw collection names — those are listed as bugs in `REVIEW_ISSUES.md`.

| Collection | Purpose |
|---|---|
| `users` | Auth user profile + role + status |
| `purchases` | Purchase bills |
| `retailSales` | Retail sale bills |
| `wholesaleSales` | Wholesale sale records (uses `salesHistory` in app state) |
| `expenses` | Business + personal expenses |
| `items` | Item master |
| `stockAdjustments` | Manual stock adjustments |
| `withdrawals` | Owner withdrawals (Finance) |
| `cashManagement` | Daily cash sessions |
| `drafts` | Saved bill drafts |
| `autoSaves` | Per-user / per-mode unfinished-bill autosave |
| `telemetry` | Write/read/error counters |
| `auditLogs` | Admin action log |

Some modules also persist to `localStorage`:
- `settings` (business config from Admin → Configure).
- `customFinanceAccounts` (Finance custom accounts).
- Theme + Hindi toggle.

---

## 6. Integrations

- **Firebase** (Auth + Firestore) — primary backend.
- **Cordova Bluetooth Serial** — Bluetooth printer (Android via Capacitor).
- **SheetJS / `xlsx`** — Excel import/export of items.
- **Chart.js** — Reports charts.
- **WhatsApp** — `wa.me/` deep link with a templated message; no API call.

---

## 7. What this app does **not** do

- No real-time multi-user collaboration UI (last-write-wins).
- No GST invoice generation (only captures GSTIN as static text).
- No barcode / QR scanning.
- No SMS / email notifications.
- No backup / restore beyond Excel item export.
- No actual AI / LLM in the AI Assistant tab.
- No web-server side: everything is static + Firestore client SDK.

---

## 8. Known operational notes

- `npm install` requires `--legacy-peer-deps` because `canvas@^3.2.0` clashes with `jest-environment-jsdom@29.7.0`. Plan removes the `canvas` dep.
- Tests: `npm test` runs Jest with jsdom; baseline is **103/103 passing** at commit `bc2a434`.
- Local dev: `npm start` runs `firebase serve` on the `www/` folder.
- CI workflow exists (`.github/workflows/`) but is broken in prod (documented in `REVIEW_ISSUES.md`).
