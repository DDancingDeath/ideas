# Aadhat Management App — Capabilities

> **v1 scope.** This document records the shipped v1 app capabilities. If it disagrees with `spec/rebuild/`, `spec/rebuild/` wins.
>
> Generated from production code at commit `bc2a434`. Update when v1 behaviour changes.

Hindi/English single-page POS app for a small wholesale + retail shop. Runs in browser, PWA, and Capacitor Android. Backend: one Firebase project (Firestore + Firebase Auth). Android printing uses Cordova Bluetooth Serial.


## 1. App shell

| Capability | Where |
|---|---|
| SPA bootstrap loads HTML templates dynamically and exposes `window.app` for inline `onclick` handlers | `www/index.html`, `www/js/template-loader.js`, `www/js/main.js` |
| Tab system: a single fixed shell with `#<tabname>` divs swapped via `NavigationManager.showTab()` | `www/js/modules/navigation.js`, `www/templates/navigation.html` |
| Global app state, listeners, and date helpers | `www/js/modules/state.js`, `www/js/modules/helpers.js` |
| Firebase wrapper (`FirebaseService`) for all Firestore reads/writes, with environment-prefixed collection names | `www/js/firebase/firestore-service.js` |

No build step or framework. Scripts load via `<script>` from `www/index.html`; Firebase compat SDK is global `firebase.*`.


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

User profile doc: `users/{uid}` with `displayName`, `role`, `status`.


## 3. Navigation (full tab list)

The hamburger / side menu exposes 15 tabs.

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

Bottom menu sequence: Stocks → Outstanding → Finance → Reports → Analytics → Settings → AI Assistant. Bugs are in `REVIEW_ISSUES.md`.


## 4. Module deep-dives

| Module | v1 capabilities / notes |
|---|---|
| Today (`day`) | Today's cash/online in/out totals split by purchase / retail / wholesale; transaction list with type filters; embedded `cash-management` clone (Issue #10); data from `AppState.purchaseHistory`, `AppState.retailSalesHistory`, `AppState.salesHistory`, `AppState.expensesHistory`, `AppState.cashManagement`. |
| Billing (`billing`) | Purchase (`purchase.js`): farmer/supplier purchase with party, items × (quantity, weight, rate, labor), cash/online/due split, heavy-weight per-bag deduction, labor rate per qty. Retail Sale (`retail-sale.js`): same shape, opposite cash flow, sale total = receivable. Shared: `autoSaves/{userUid}_{mode}`, `drafts/`, Bluetooth ESC/POS print, WhatsApp share, person autocomplete. |
| Wholesale Sales (`wholesale-sales`) | Sell from existing purchase stock; profit preview (stock cost vs sale rate); "Complete all due" bulk action; reprint / WhatsApp / print existing wholesale sales; all-due only, no cash/online split (Issue #15). |
| Expenses (`miscellaneous.js`) | Business and personal categories; print receipt; person autocomplete; history with detail / edit / delete. File is `miscellaneous.js`; tab/template are `expenses`. |
| Items (`items`) | Item master with English name, Hindi name, purchase / retail / wholesale rates; modal add/edit; SheetJS (`xlsx`) Excel import/export; frequency badges; staff sees fewer fields than owner/admin. |
| History (`history`) | Unified `purchaseHistory` + `retailSalesHistory` + `salesHistory`; card/table toggle; search / date filter; detail modal; edit / delete entry points. |
| Stock (`stock`) | Current stock = purchases received − wholesale sales − adjustments; manual adjustment add / remove / set absolute with reason; adjustment history; search. |
| Outstanding (`due`) | Purchase outstanding (we owe supplier) and Retail outstanding (customer owes us); per-bill cash/online payment recording; "Mark cleared"; originating bill links. |
| Finance (`finance`) | Assets, liabilities, withdrawals; rolling date filter (`week` / `month` / `year` = 7d / 1mo / 1yr, Issue #30); custom finance accounts are localStorage-only (Issue #29); uses `withdrawals/`. |
| Reports (`reports`) | Overview combined totals; Purchases by item / party / time series; Sales same shape for retail + wholesale; Compare period comparisons; outputs Chart.js charts, CSV, PDF, date filter. |
| Analytics (`analytics`) | Rule-based only: next-month cash prediction, monthly summary cards, profit trend line, item focus suggestions, generic suggestions panel. |
| Cash Management (`cash-management`) | Per-day session opening balance → transactions → closing balance; transactions are due paid/received, business expense, personal expense; reconciliation; session history; auto-closes forgotten previous session with `closingBalance=0` at sign-in (Issue #8); stored in `cashManagement/`, listener bug uses wrong name (Issue #6). |
| Admin (`admin`, owner-only) | Configure: business name, address, phone, GSTIN, default labor rate, default heavy-weight, etc. in localStorage `settings`; Users: list, approve/reject pending, change role, delete; Data: wipe / reseed test data, export. `configure.html` loads but is not menu-navigable (Issue #48). |
| Diagnostics (`diagnostics`, owner-only) | Telemetry write/read/error counts; audit log viewer; clear / delete buttons; reads `telemetry/` and `auditLogs/`. |
| Settings (`settings`) | Dark mode; "Show Hindi"; Bluetooth printer scan / connect / disconnect / test print; logout; JS still reads removed labor-rate fields (Issues #2, #3). |
| AI Assistant (`chat`) | Template calls `askChatbot()` / `sendChatMessageFromTab()`, but no `chat.js`, LLM integration, or rule-based responder is loaded. v2 plans this under Phase 4. |


## 5. Data model (Firestore collections)

`FirebaseService` environment-prefixes collection names (for example `prod_purchases`, `staging_purchases`). Raw-name bypasses are bugs in `REVIEW_ISSUES.md`.

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

Local storage:

- `settings` (Admin → Configure business config).
- `customFinanceAccounts`.
- Theme + Hindi toggle.


## 6. Integrations

- Firebase Auth + Firestore.
- Cordova Bluetooth Serial for Android Bluetooth printer.
- SheetJS / `xlsx` for item Excel import/export.
- Chart.js for Reports charts.
- WhatsApp `wa.me/` deep link; no API call.


## 7. What this app does **not** do

- Real-time multi-user collaboration UI (last-write-wins).
- GST invoice generation; GSTIN is static text only.
- Barcode / QR scanning.
- SMS / email notifications.
- Backup / restore beyond Excel item export.
- Actual AI / LLM in AI Assistant tab.
- Server side; everything is static + Firestore client SDK.


## 8. Known operational notes

- `npm install --legacy-peer-deps` is required because `canvas@^3.2.0` clashes with `jest-environment-jsdom@29.7.0`; plan removes `canvas`.
- `npm test`: Jest/jsdom; baseline **103/103 passing** at commit `bc2a434`.
- `npm start`: `firebase serve` on `www/`.
- CI exists in `.github/workflows/` but is broken in prod; see `REVIEW_ISSUES.md`.
