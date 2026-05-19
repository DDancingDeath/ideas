# Review Issues & Action Tracker

> **Living checklist of every known defect in the app.**
> When an issue is fixed, update its checkbox to `[x]` and wrap the title
> in `~~strikethrough~~`. Keep the original text — never delete a row, so the
> history stays visible.
>
> **Don't add fixes that bypass the staging clone safety model.** All write
> fixes must be made and verified in this clone first; promotion to prod
> happens via cherry-pick PR.

Sources:
- **[SEC]** entries — from the original security/code review (chat transcript, prior to staging clone).
- **[WALK]** entries — from the deep functional walkthrough (`docs/CAPABILITIES.md` was generated from the same audit).
- **[ARCH]** entries — architecture-level decisions / refactors.

Severity legend: 🔴 Critical · 🟠 High · 🟡 Medium · 🟢 Low/UX

---

## Architecture decisions

- [x] 🟢 ~~**[ARCH] Finance / Reports / Analytics share the math via `PeriodMath`**~~ —
  All date ranges, period sums, profit numbers, position snapshots and
  payment splits go through the new `www/js/utils/period-math.js`
  helper (19 jest tests). Finance redesigned to be a right-now position
  view (no period filter) with two subtabs (Position + Withdrawals);
  Reports is now the canonical home of past-period numbers and surfaces
  **two profit numbers** (cash-flow vs realized) with explanatory
  caption; Analytics overview is forward-looking only and points users
  to Reports/Outstanding for past-period totals. Per-page specs
  (`docs/page-specs/09-finance.md`, `10-reports.md`, `11-analytics.md`)
  rewritten to match. **466 tests across 27 suites — all green.**


## A. Security & infrastructure

### Critical

- [x] 🔴 ~~**[SEC] Stored XSS via unescaped user input in lists**~~ — Many `innerHTML` writes interpolate Firestore field values (party names, item names, expense descriptions) without escaping. A malicious entry like `<img src=x onerror=...>` saved by any authorised user is executed by every other user's browser. Files: most rendering paths in `history.js`, `items.js`, `outstanding.js`, `wholesale-sales.js`, `miscellaneous.js`, `finance.js`. **Plan**: introduce a single `Helpers.escapeHtml()` and route all string interpolations through it (Plan task `p4-escape-helper`, `p4-xss-batch-1/2`). **Batch 1 fixed (commit XSS-1)**: `diagnostics.js` (audit logs, error cards, formatDetails), `history.js` (renderBills list + table view + viewBill modal + datalist + empty state), `outstanding.js` (due-transaction list). Inline-onclick handlers now use a defensive whitelist (`/[^A-Za-z0-9_-]/g` for ids, `/[^a-z]/gi` for enums, `Number()` for indices) to prevent the escapeHtml→browser-decode→JS-string-context bypass. Regression suite `xss-batch-1.test.js` added (17 assertions). **Batch 2 fixed (commit XSS-2)**: `users.js` (pending + active user lists), `miscellaneous.js` (datalists + business/personal expense lists + viewExpenseDetails modal), `items.js` (renderItems cards + renderItemsTable + renderModalRates), `wholesale-sales.js` (renderWholesaleBill + customer datalist + renderSalesOutstanding + renderSalesHistory + reprintSale + billDetails modal), `finance.js` (renderCustomAccounts + withdrawal datalist + renderWithdrawalHistory), `billing.js` (drafts list). Introduces a new safe-inline-handler pattern via `Helpers.toBase64Utf8`/`fromBase64Utf8` to defeat the escapeHtml→browser-decode→JS-string-context bypass for free-text fields (names, emails) passed into `onclick` arguments — used in `users.js` with `*B64` wrapper methods (`showChangeRoleDialogB64`, `resetUserPasswordB64`, `deleteUserB64`). Regression suite `xss-batch-2.test.js` added (35 assertions).
- [ ] 🔴 **[SEC] Firestore rules allow `users` collection to be read by anyone signed in** — Any authorised account can read every other user's `displayName`, `role`, `email`. Should be `request.auth.uid == userId` for non-admins. File: `firestore.rules`. **Plan**: redesign in `p4-prod-rules-design`.
- [ ] 🔴 **[SEC] Firestore rules don't validate write payloads** — Most rules check only `request.auth != null`; payload shape, money fields, and timestamps are unchecked. A malicious client could write arbitrary documents. **Plan**: same as above.

### High

- [ ] 🟠 **[SEC] CI workflow is broken** — `.github/workflows/*.yml` references missing scripts / wrong Node version; PRs do not run tests. **Plan**: `p5-first-pr-fix-prod-ci`.
- [x] 🟠 ~~**[SEC] Service worker is broken**~~ — Registered but caches the wrong URLs / has no fetch handler / disables itself on every load. Means the app does not work offline as advertised. File: `www/service-worker.js`. **Plan**: rewrite as part of staging cutover (also Layer 2 of write-blocking). **Fixed (staging only, commits across the staging cutover + 1b8f928)**: rewritten with a real `fetch` handler (cache-first with network-fallback-and-store), an explicit `STATIC_ASSETS` precache list refreshed to match the actual module/template/CSS graph (chat, voice-billing, admin, diagnostics, telemetry, period-math, validator, etc. — see commit `1b8f928`), and `CACHE_NAME = aadhat-staging-v5` so installs re-fetch on bump. Layer 2 of the safety model lives in the same handler (non-GET → Firebase data hosts blocked with 403). Regression guard `www/js/__tests__/service-worker-precache.test.js` walks `main.js`'s import graph + `styles.css` `@import`s and fails the build if STATIC_ASSETS drifts. **Open**: promote the rewrite to the prod repo (owner action; this clone cannot push there).
- [x] 🟠 ~~**[SEC] Bill numbering uses `Date.now()` client-side**~~ — Two devices writing in the same millisecond can collide. **Plan**: `p4-bill-numbering` switches to a Firestore `runTransaction` counter doc. **Fixed (commit BILL-N)**: `Helpers.generateBillNumber` rewritten to use `db.runTransaction` against a per-prefix-per-day counter document (`billCounters/{prefix}-{YYYYMMDD}`). The transaction reads the current count, increments, and writes back atomically — Firestore serialises concurrent transactions on the same doc via OCC retries, so two devices in the same millisecond now produce two distinct sequence numbers. The legacy `snapshot.size + 1` path is retained as a defensive fallback for environments where the transaction is unavailable (e.g. the staging clone's read-only-guard neutralises `runTransaction`). Regression suite `bill-numbering.test.js` added (5 assertions: source uses `runTransaction`, reads/writes the new `billCounters/{prefix}-{date}` doc, retains legacy path; behaviour: serial calls return 001/002/003, and `Promise.all` of 5 concurrent calls returns 5 distinct sequential numbers with no gaps).
- [x] 🟠 ~~**[SEC] Notifications loop on every render**~~ — Several modules write a telemetry / notification doc on each render call, producing thousands of writes per session. Cost + rate-limit risk. **Plan**: `p4-batch-notifications`. **Fixed (commit BATCH-N)**: `firestore-service.js` — both fan-out paths (`notifyOwnersOfEdit`, `notifyRateChange`) converted from `for await collection.add()` (one round-trip per recipient) to `WriteBatch.commit()` chunked at the Firestore 500-write limit. Single round-trip per chunk; the current user is now filtered out once at the top of `notifyRateChange` rather than re-checked inside the loop. Regression suite `batch-notifications.test.js` added (6 source-level assertions verifying no `.add()` remains in either function and that both use `getDb().batch()` + `BATCH_LIMIT=500` chunking).

### Medium

- [ ] 🟡 **[SEC] No CSP** — `index.html` has no Content-Security-Policy header; combined with the XSS risk above this is a real attack surface. Add a CSP that disallows `unsafe-inline` once XSS fixes are in.
- [ ] 🟡 **[SEC] Firebase config + API key checked into repo** — Acceptable for client-side Firebase, but should be paired with strict App Check + tight Firestore rules to make abuse expensive.
- [ ] 🟡 **[SEC] No App Check** — Anyone with the Firebase web config can issue Firestore requests directly without using the app. Add Firebase App Check (reCAPTCHA v3 for web, Play Integrity for Android).

---

## B. AI Assistant (chat)

- [x] 🔴 ~~**[WALK-1] AI Assistant is non-functional**~~ — `chat.html` calls global `askChatbot()` / `sendChatMessageFromTab()` but no implementation or module exists. Clicking any button throws. Files: `www/templates/chat.html`, missing `www/js/modules/chat.js`. **Plan**: build a real assistant in Phase 4. See `docs/CAPABILITIES.md` §4.16 for the green-field opportunity. **Fixed (commit CHAT-1)**: New `www/js/modules/chat.js` orchestrator + `chat/intent-router.js` (pure regex/keyword classifier) + `chat/appstate-queries.js` (pure data layer querying `AppState`). Updated `chat.html` so every quick-reply button + `Send` button + Enter-to-submit goes through `app.chat.ask(...)` / `app.chat.sendFromInput()`. `main.js` imports `ChatManager` and exposes `window.app.chat`. Architecture documented in `docs/CHAT_DESIGN.md`. Test suites: `chat-intent-router.test.js` (70 assertions), `chat-queries.test.js` (27 assertions), `chat-render.test.js` (13 assertions).
- [x] 🟡 ~~**[WALK-1b] Assistant should be data-aware, not generic**~~ — Once implemented, the assistant should read from `AppState` (stock, sales, outstanding) and answer "how much rice do I have", "who owes me the most", "show today's profit". A pure LLM call won't suffice — design as: small intent classifier + structured queries against AppState + LLM only for natural-language summarisation. **Fixed (commit CHAT-1)**: 13 deterministic intents implemented (`stock_all`, `stock_item`, `sales_today`, `sales_period`, `purchases_today`, `purchases_period`, `outstanding_top`, `outstanding_party`, `expenses_today`, `expenses_period`, `profit_period`, `nav`, `help`) — all answered from `AppState` with no LLM round-trip. Item-name slot extraction supports both English (`Rice`) and Hindi (`गेहूं`). Party-name slot extraction is built from the union of `customerName` across all transaction histories. Period extraction supports `today | yesterday | week | month | year | all`. The fallback for `intent === 'unknown'` is a deterministic "I didn't catch that — try help" message; the LLM fallback path (Firebase Function) is the next iteration (Phase 4c-5, todo `p4-chat-llm`) and intentionally deferred so the assistant ships useful on day one without depending on a paid API.

---

## C. Bottom-of-menu tabs

These are the tabs the user specifically called out as "having a lot of issues".

### Stocks (`stock`)

- [x] 🟠 ~~**[WALK-25] Stock adjustment refresh checks wrong DOM id**~~ — Code checks `stockCurrentSection`, template uses `currentStockSection`. After an adjustment the current-stock pane doesn't refresh. Files: `stock.js`, `stock.html`. **Fixed**: `applyStockAdjustment` now checks the correct id (`currentStockSection`) so the pane re-renders inline after every save.
- [x] 🟠 ~~**[WALK-26] "Remove" can drive saved stock negative**~~ — UI clamps to zero, but the saved adjustment lets `firestore-service.js:538-543` produce negative quantity/value. Files: `stock.js`, `firestore-service.js`. **Fixed**: clamp the *saved* `quantity` (not just `newStock`) to `min(rawQuantity, currentStock)` for `remove`. If current stock is 0, the adjustment is rejected with a toast instead of silently going through and corrupting the totals.
- [x] 🟡 ~~**[WALK-27] Stock adjustment writes legacy local key**~~ — Writes to `AppState.stock[itemName]` even though the canonical key is `itemId`, leaving stale parallel state. **Fixed**: removed the stale local write — `FirebaseService.calculateStock()` is called immediately after the save, so the local mutation was both wrong (created ghost entries that fooled wholesale dropdown) and dead (overwritten 2 lines later).
- [x] 🟡 ~~**[WALK-28] Wholesale sale dropdown misses Hindi-name stock keys**~~ — Checks `id`/`name` only; stock map uses Hindi names for legacy items, so they're invisible in the wholesale form. Files: `wholesale-sales.js`, `firestore-service.js:465-467`. **Fixed**: introduced `WholesaleSalesManager.getStockDataForItem(item, name)` which checks `id → name → hindiName → bare-name fallback`. All three dropdown/details/add-to-bill paths route through it. Covered by 8 new Jest tests.

### Outstanding (`due`)

- [x] 🟠 ~~**[WALK-11] "Mark as cleared" bypasses environment-prefixed collection names**~~ — Calls `db.collection('purchases'|'retailSales'|'wholesaleSales')` directly. Will hit `prod_*` while connected to `staging_*` (or vice versa). File: `outstanding.js:293-309`. **Fixed (outstanding.js)**: routed through `FirebaseService.updatePurchase/updateRetailSale/updateWholesaleSale`, which honour the env-prefix wrapper. Looks up the transaction in AppState first and surfaces a toast if missing.
- [x] 🟠 ~~**[WALK-13] Payment recording fails for legacy/top-level due fields**~~ — UI renders `dueAmount`, but the save reads `transaction.payment?.due || 0`, so legacy bills (no nested `payment` object) silently get rejected. File: `outstanding.js:95-123` / `:230-264`. **Fixed (outstanding.js)**: validation now reads through `Helpers.parsePaymentBreakdown(transaction)` so legacy bills with only top-level `dueAmount/cashPayment/onlinePayment` are accepted.
- [x] 🟠 ~~**[WALK-14] Payment updates only the nested `payment` object**~~ — Top-level `dueAmount`, `cashPayment`, etc. stay stale. Finance + Reports read those top-level fields, so totals diverge from the source of truth. **Fixed (outstanding.js)**: after recording, mirrors `cash/online/due/total` back to the legacy top-level fields whenever they exist on the source document, so any reader (history rendering, finance, reports) sees consistent numbers regardless of which shape it prefers. Bills that never carried legacy fields don't grow them spuriously.

### Finance (`finance`)

- [x] 🟠 ~~**[WALK-20] Outstanding ignores retail sales**~~ — Only considers purchases + wholesale; retail receivables are missing from Finance dashboards. File: `finance.js`. **Fixed**: `calculateOutstanding()` now spreads `[salesHistory, retailSalesHistory]` together so retail dues count toward "Due to Receive".
- [x] 🟠 ~~**[WALK-21] Outstanding payment parsing inconsistent**~~ — Mixes `amountPaid`, `cashPayment`, `onlinePayment`, and nested `payment.*` paths in ways that drop values for some bills. **Fixed**: introduced `Helpers.parsePaymentBreakdown(record)` that handles modern (`payment.{cash,online,due,total}`) AND legacy (`cashPayment`/`onlinePayment`/`dueAmount`/`amountPaid`) shapes uniformly, including over-paid clamp and explicit-due preservation. 9 new Jest tests cover each shape and edge case. Finance now routes through it.
- [x] 🟡 ~~**[WALK-29] Custom finance accounts are localStorage-only**~~ — Not shared across devices/users. File: `finance.js:603-694`. **Fixed**: added `FirebaseService.{load,save}FinanceCustomAccounts()` which read/write `users/{uid}/preferences/financeAccounts`. `loadCustomAccounts()` reads localStorage synchronously (instant render) then async-syncs from cloud and re-renders if different. `saveCustomAccounts()` dual-writes; cloud failures don't block the UI. Local-only entries are seeded up to cloud on first sync rather than wiped.
- [x] 🟡 ~~**[WALK-30] "Week / month / year" mean rolling 7d / 1mo / 1yr, not calendar periods**~~ — Misleads users who expect "this month". File: `finance.js:185-215`. **Fixed**: `isInDateRange` now uses calendar boundaries — Mon→now, 1st→now, Jan-1→now — to match the visible labels.
- [x] 🟡 ~~**[WALK-31] UTC date strings used for local business days**~~ — `toISOString().split('T')[0]` shifts dates for IST users near midnight. Files: `finance.js:762-812`, `cash-management.js`. **Fixed (finance.js)**: added `Helpers.localDateString(date)` and switched `setDefaultDate()` to use it. `cash-management.js` is tracked under p4-fix-cash and will adopt the same helper. (Also fixed a separate bug here: `recordWithdrawal` was calling the non-existent `FirebaseService.addWithdrawal`; the real method is `saveWithdrawal`. Withdrawals would have thrown silently.)

### Reports (`reports`)

- [x] 🟠 ~~**[WALK-22] Payment totals use incompatible schemas**~~ — Reads `payment.cash/online/due` only, but bills also store top-level fields. Some bills count, some don't. **Fixed (reports.js)**: routed every payment-total/outstanding through `Helpers.parsePaymentBreakdown(record)` (overview, purchases, sales, compare, CSV export).
- [x] 🟠 ~~**[WALK-23] Item aggregations use mismatched field names**~~ — Some code expects `item.name/item.qty`; bills also use `item.item/quantity`. Aggregations drop rows. **Fixed (reports.js)**: added `ReportsManager.itemName(item)` and `ReportsManager.itemQty(item)` helpers; switched all aggregations and filter dropdowns to use them.
- [x] 🟡 ~~**[WALK-37] Daily chart sorts `DD/MM/YYYY` strings via `new Date()`**~~ — Produces `Invalid Date`; chart points end up out of order. **Fixed (reports.js)**: bucketed both trend and compare charts by `Helpers.localDateString(d)` (sortable ISO `YYYY-MM-DD`); kept en-IN labels for display only.
- [x] 🟡 ~~**[WALK-38] Chart math divides by zero on empty data**~~ — Heights/coordinates become `NaN`; SVG renders blank. **Fixed (reports.js)**: trend/compare charts and `renderItemComparison` floor `maxValue` at 1 when all bars are zero.
- [x] 🟡 ~~**[WALK-39] Average rate divides by zero**~~ — `(value / qty).toFixed(2)` shows `Infinity`/`NaN`. **Fixed (reports.js)**: `renderItemBreakdown` and PDF item table now show `0.00` when `qty === 0`.
- [x] 🟡 ~~**[WALK-40] Outstanding section is not date-filtered consistently**~~ — Period reports include all-time outstanding. **Fixed (reports.js)**: overview, purchases, sales and compare now sum dues over the date-filtered arrays (matching the period the rest of the card describes).

### Analytics (`analytics`)

(No specific bugs found in the walkthrough beyond the data-source bugs above
that feed into it. Issues will likely surface once Reports/Finance bugs above
are fixed.)

### Settings (`settings`)

- [x] 🔴 ~~**[WALK-2] Settings tab can crash on load**~~ — `loadSettings()` reads `settingHeavyWeight`, `settingLaborRate`, `settingAutoLabor` IDs that no longer exist in `settings.html`. Throws `null.value`. File: `settings.js:21-27`. **Fixed**: added the labor/heavy-weight/auto-labor inputs back to `settings.html` under a new "Calculations" card, AND replaced every `getElementById(id).value` with `setValue(id, ...)` / `setChecked(id, ...)` helpers that no-op when the element is missing.
- [x] 🔴 ~~**[WALK-3] "Show Hindi" save crashes**~~ — Same labor-rate IDs are read by `saveSettings()`. Toggling Hindi can throw. File: `settings.js:79-83`. **Fixed**: same null-guard pattern in `saveSettings()` (`readNumber`/`readChecked` helpers); save also wrapped `window.app.items.render()` and `loadItemsDropdown()` in optional-chaining so a missing module no longer breaks the save.
- [x] 🟠 ~~**[WALK-42] Printer status/test reads wrong API surface**~~ — Settings expects `window.app.printer.device` / `.write`; exposed printer API has neither. File: `settings.js:204-264` vs `main.js:460-469`. **Fixed**: added `isConnected()` and `getDeviceName()` to both `PrinterService` and the `window.app.printer` facade in `main.js`. `Settings.updatePrinterStatus()` now calls those, and `Settings.testPrint()` now calls `window.app.printer.test()` (which routes through `PrinterService.testPrint()`) instead of the missing `.write()`.
- [x] 🟠 ~~**[WALK-43] `PrinterService.print()` calls undefined manager methods**~~ — Calls `generateESCPOS()` and `print()` not defined on `BluetoothPrinterManager`. File: `services/printer.js:803-806`. **Fixed**: deleted the dead `PrinterService.print()` method (was unreachable - main.js wires `window.app.printer.print` to `PrinterService.printBill`, which works correctly via `manager.write()`).

### AI Assistant (`chat`)

See section B above.

---

## D. Cash management

- [x] 🟠 ~~**[WALK-6] Realtime listener uses the wrong collection name**~~ — Service saves/loads `cashManagement` but listens on `cashSessions`. Cash UI never live-refreshes. File: `firestore-service.js:1149-1187` vs `:910-923`. **Fixed (firestore-service.js)**: changed listener to `col('cashManagement')` (matches save/load), and the snapshot handler now also re-renders the Today tab when visible since due totals now feed those hero cards.
- [x] 🟠 ~~**[WALK-7] Cash sessions not loaded into AppState on startup**~~ — `main.js` loads purchases/sales/expenses but not cash sessions; Today reads `AppState.cashManagement` and shows nothing. File: `main.js:155-173`. **Fixed (state.js, main.js, firestore-service.js)**: added `AppState.cashSessions = []`, `FirebaseService.loadCashSessions()` to bootstrap `Promise.all`, and the live listener writes the snapshot back to `AppState.cashSessions` so Day/Reports can read sessions immediately.
- [x] 🟠 ~~**[WALK-8] Auto-close prior session uses `closingBalance: 0`**~~ — Produces false negative differences without user review. File: `cash-management.js:116-167`. **Fixed (cash-management.js)**: auto-close now sets `closingBalance: expectedBalance, difference: 0` and flags the session with `requiresReview: true` + an `autoSignOutReason` string. No fabricated discrepancies; user can amend from history.
- [x] 🟠 ~~**[WALK-9] Cash due payments don't update the source bill**~~ — Records are session-internal only; the actual `purchases/retailSales/wholesaleSales` document still shows the bill as outstanding. File: `cash-management.js:771-856` vs `outstanding.js:205-270`. **Fixed (cash-management.js)**: added `applyCashPaymentToOutstanding(party, amount, type)` helper that FIFOs the cash payment against the party's oldest outstanding bills (purchase for `paid`, retail+wholesale sale for `received`), updates each via `FirebaseService.update*`, and rolls back the in-memory mutation if the Firestore write fails. Toast surfaces how much was applied vs kept as advance.
- [x] 🟡 ~~**[WALK-32] Sign-in/sign-out disallow zero cash**~~ — `if (!amount || amount < 0)` rejects valid `0` balance. File: `cash-management.js:660-769`. **Fixed (cash-management.js)**: replaced both checks with `!Number.isFinite(amount) || amount < 0` so 0 is accepted and NaN/null/undefined are rejected.
- [x] 🟡 ~~**[WALK-33] Cash detail totals read wrong field names**~~ — Details use `duePayments/cashExpenses` but saved data has `dueReceived/duePaid/businessExpenses/personalExpenses`. File: `cash-management.js:1015-1223`. **Fixed (cash-management.js)**: detail modal now reads the actual saved field names (`dueReceived` for cash-in, `businessExpenses + personalExpenses + duePaid` for cash-out). Test pinned to break if the wrong names are reintroduced.
- [x] 🟡 ~~**[WALK-34] Today totals exclude due in/out from headline**~~ — Due summary is shown separately but not added to hero in/out. File: `day.js:71-238`. **Fixed (day.js)**: hero `todayTotalIn` now includes `dueReceived`, `todayTotalOut` includes `duePaid`, and `netOutflow` reflects both. Source switched from non-existent `AppState.cashManagement` to `AppState.cashSessions` filtered by today's `localDateString`.
- [x] 🟡 ~~**[WALK-10] Today subtab clones `cash-management` markup and duplicates IDs**~~ — `getElementById` may target the hidden / original tab. File: `day.js:420-440`. **Fixed (day.js)**: stopped cloning markup. Sub-tab now renders a read-only summary tile (opening / expected / cash-in / cash-out / due-received / due-paid) and an "Open Cash Management →" button that navigates to the real tab. No more duplicate IDs.

---

## E. Bills, history, items, expenses

- [x] 🟠 ~~**[WALK-12] History delete bypasses env-prefixed collection names AND deletes by timestamp query**~~ — **Fixed (history.js)**: routes through `FirebaseService.deletePurchase/deleteRetailSale/deleteWholesaleSale` by document id; aborts with toast if id missing. Was: `db.collection(name).where('timestamp', '==', ...)` could miss/over-delete.
- [x] 🟠 ~~**[WALK-15] Wholesale sale payment is all-due only**~~ — **Fixed (wholesale-sales.html + wholesale-sales.js)**: form now has `salesCashAmount`/`salesOnlineAmount` inputs and a live-updated `salesDueAmount` display. New `computePaymentBreakdown()` and `updatePaymentBreakdown()` helpers; `completeSale()` writes the real split and rejects over-pay.
- [x] 🟠 ~~**[WALK-16] Wholesale profit always overstated**~~ — **Fixed (firestore-service.js + wholesale-sales.js)**: `calculateStock()` now writes both `rate` and `avgRate` (alias) on every entry; `renderWholesaleBill`/`updateProfitCalculation` read `stockData.avgRate || stockData.rate || 0` for back-compat.
- [x] 🟠 ~~**[WALK-17] Wholesale history reprint can open the wrong sale after filtering**~~ — **Fixed (wholesale-sales.js)**: `renderSalesHistory` now calls `reprintSaleById('${sale.id}')` instead of passing the filtered index into `reprintSale(index)`.
- [x] 🟠 ~~**[WALK-18] Expenses edit deletes before saving replacement**~~ — **Fixed (`miscellaneous.js`, `firestore-service.js`)**: `editExpense` now only populates the form and sets `window.currentEditingExpenseId/Category` flags — the old document is preserved. `saveBusinessExpense`/`savePersonalExpense` detect the flag and call new `FirebaseService.updateExpense({id, ...})` (set+merge by doc id) instead of `saveExpense` (which would create a duplicate). Edit flag is cleared on success and is category-scoped so a cross-category save creates a fresh insert. If the user navigates away mid-edit, the original record stays intact.
- [x] 🟠 ~~**[WALK-19] Expenses save calls missing `cashManagement.render()`**~~ — **Fixed (`cash-management.js`, `main.js`, `miscellaneous.js`)**: added a public `static render()` on `CashManagementManager` that re-runs `calculateTodayTransactions` + `updateUI` + `renderHistoryFromCache`, exposed it as `window.app.cashManagement.render`, and the expenses-save call sites now feature-detect before calling so an older app version doesn't throw.
- [x] 🟡 ~~**[WALK-35] Expenses immediate state update uses singular typo**~~ — **Fixed (`miscellaneous.js`)**: replaced both `AppState.expenseHistory` typos with `AppState.expensesHistory` (matches the listener and the rest of the app). Test asserts that pre-set garbage on the typo'd field stays untouched after a save.
- [x] 🟡 ~~**[WALK-36] Expenses delete relies on async listener for UI refresh**~~ — **Fixed (`miscellaneous.js`)**: `deleteExpense` now does a synchronous `AppState.expensesHistory.filter(...)` immediately after the Firebase delete and calls `renderExpenseHistory()` so the row disappears without waiting for the snapshot. (Also renamed `renderexpensesHistory` → `renderExpenseHistory` and kept the old name as a deprecated alias for in-flight callers.)
- [x] 🟡 ~~**[WALK-41] Items frequency badges use obsolete state names**~~ — **Fixed (items.js)**: `calculateItemFrequency` now reads `AppState.purchaseHistory`/`salesHistory`/`retailSalesHistory`; tolerates legacy `itemName`/`item` keys; defensive against missing arrays.

---

## F. Admin / users

- [x] 🟠 ~~**[WALK-4] Admin user reset/delete buttons wired to unexposed methods**~~ — **Fixed (`main.js`)**: added `resetUserPassword` and `deleteUser` to the `window.app.admin` surface so the buttons in `admin.html` can invoke them. Both methods already existed on `AdminManager` — they just were not exposed.
- [x] 🟠 ~~**[WALK-5] Deleting/rejecting users only removes the Firestore doc, not the Auth account**~~ — **Fixed in two places**: (1) `admin.js#rejectUser` and `#deleteUser` now read the user's email/name BEFORE deleting the `users/` doc, then write a `bannedUsers/{uid}` document with reason (`rejected_by_admin` / `deleted_by_admin`), email, and the admin uid. (2) `authentication.js#login` now checks `bannedUsers/{uid}` immediately after `signInWithEmailAndPassword`; if a ban entry exists it signs out and shows a "deleted/rejected" message — so a deleted user can no longer slip past the existing "User account not found" branch by re-creating their `users/` doc. The actual Firebase Auth account deletion still requires the Admin SDK (no client-side API for deleting other users' accounts) — a deployable Cloud Function skeleton is now at `functions/admin-deleteAuthUser.js` with deployment instructions in its file header. Toast/modal copy updated to set the right user expectation.
- [x] 🟡 ~~**[WALK-47] Admin Configure and Settings use separate localStorage schemas**~~ — **Fixed (`admin.js`)**: `renderConfigure` reads from `AppState.settings` and `saveConfigure` writes the canonical `settings` JSON localStorage key (the same one `state.js` reads on load and `SettingsManager.saveSettings` writes). Legacy individual keys (`heavyWeightThreshold`, `laborChargeRate`, `autoLaborCharges`) are removed during save so old installs migrate forward and there's no possibility of two stale copies disagreeing. Field names are also corrected: `laborChargeRate` → `laborRate`, `autoLaborCharges` → `autoLaborEnabled`.
- [x] 🟢 ~~**[WALK-46] Admin approve uses `status: "approved"` while other code/comments use `active/pending/rejected`**~~ **Fixed (admin.js)**: `AdminManager.approveUser` now writes `status: 'active'`, matching `users.js`. Auth gate (which only blocks `pending` and `rejected`) keeps reading legacy `'approved'` docs without issue, but every new write converges on the canonical `{pending, active, rejected}` enum. Added regression test in `admin.test.js`.

---

## G. UX / consistency

- [x] 🟡 ~~**[WALK-24] Toast severity strings hide messages immediately**~~ — Many calls use `showToast(msg, 'error'|'success')`, but `UIManager` treats arg 2 as numeric duration. Strings coerce to `NaN` → toast hides immediately. File: `ui-manager.js:71-88`. **Fixed** in clone: `showToast` now accepts either a numeric duration OR a severity string (`'error'`/`'warning'`/`'success'`/`'info'`), applies the matching CSS class, uses sensible per-severity defaults, and falls back to 2000ms for invalid args. 11 new Jest tests cover the contract.
- [x] 🟢 ~~**[WALK-44] `DateFilterManager` public API is dead** — Calls non-existent `AppState.getState()` and global IDs; templates use module-specific filters instead. File: `datefilter.js:20-29`.~~ **Fixed (datefilter.js, main.js, service-worker.js)**: deleted the orphan module, dropped the `DateFilterManager` import + `window.app.dateFilter` wiring from `main.js`, and removed the precache entry from the service worker. Per-module `window.app.reports.setDateFilter` / `window.app.finance.setDateFilter` (which the templates actually call) remain the live entry points.
- [x] 🟢 ~~**[WALK-45] Default Billing tab shown without nav active state** — Startup calls `NavigationManager.showTab('billing')` directly rather than the wrapper that sets active styling. File: `main.js:190-191`.~~ **Fixed (main.js)**: switched startup to `NavigationManager.showTabFromNav('billing')`, which sets `.nav-menu a.active`, runs `resetFilterButtons('billing')`, and triggers `billing.switchMode('purchase')` so the side menu link is highlighted from the first paint.
- [x] 🟢 ~~**[WALK-48] Standalone `configure.html` is loaded but not navigable** — Admin has its own configure subtab. The orphan template misleads agents/contributors. File: `template-loader.js:18-40`.~~ **Fixed (configure.html, template-loader.js, service-worker.js)**: deleted `www/templates/configure.html` (a duplicate of the labor-charge inputs in `settings.html` — both used the same `settingHeavyWeight`/`settingLaborRate`/`settingAutoLabor` ids, so `getElementById` silently returned whichever was injected first), dropped it from the loader array + injection block, and removed the precache entry. Admin → Configure subtab continues to use its own distinct `adminHeavyWeight`/`adminLaborRate`/`adminAutoLabor` ids.

---

## H. Quality / DX

- [x] 🟡 ~~**[SEC] `npm install` requires `--legacy-peer-deps`**~~ — `canvas@^3.2.0` clashes with `jest-environment-jsdom@29.7.0`. The dep isn't actually used at runtime. **Fixed** in clone: `canvas` removed from `package.json`; plain `npm install` now works.
- [ ] 🟡 **[SEC] `configure.html` template is loaded by template-loader but unreachable from nav** — Confuses anyone reading the codebase. Either wire it up or delete it.
- [ ] 🟢 **[SEC] No type checking** — Vanilla JS, no JSDoc types, no TS. Many of the schema-mismatch bugs above (#22, #23, #33, #35, #41) would have been caught by even loose JSDoc. Consider opt-in JSDoc + `tsc --checkJs` in a future pass.

---

## I. Bugs surfaced by automated staging walkthrough

These items were discovered by running `tools/_walk-pages.js` against
the deployed staging URL, walking every top-level tab, and capturing
console errors. They are *not* directly visible to a human user (the
broken behaviour is silent or fails-closed) — but the data is wrong.

- [ ] 🔴 **[STG-WALK-1] Custom finance accounts silently broken in production**
  - **Symptom**: Loading the Finance tab logs
    `FirebaseError: Missing or insufficient permissions` and the
    Custom-Accounts list shows empty. Loader catches the error and
    returns `[]`, so users see no accounts and no error UI.
  - **Root cause**: `firestore-service.js#loadFinanceCustomAccounts`
    reads `users/{uid}/preferences/financeAccounts`. Prod's
    `firestore.rules` only declares a rule for `/users/{userId}` —
    there is no rule for the `preferences` subcollection, so default-
    deny applies. Affects ALL users in production, not just staging.
  - **Fix**: append a `match /users/{userId}/preferences/{prefId}`
    rule. Diff included in `docs/STAGING_RULES_PATCH.md` under the
    "REAL PROD BUG DISCOVERED DURING STAGING WALKTHROUGH" heading.
    Goes into prod via the same rules-deploy that lands the
    staging-readonly patch. Tracked in plan as `p15-deploy-rules`.

- [x] 🟡 ~~**[STG-WALK-2] Service worker over-blocked Firestore Listen
  channel**~~ — *(fixed in commit `<this commit>`; SW now whitelists
  `/google.firestore.v1.Firestore/Listen/` POSTs which are read-
  subscription transport rather than writes; new
  `__tests__/service-worker-block.test.js` pins the corrected
  behaviour)*. Symptom was every real-time-subscription page logging
  `client is offline` and rendering empty.

- [x] 🔴 ~~**[STG-WALK-3] `diagnostics.js` had a syntax error that
  broke the entire app on the deployed staging URL**~~ —
  *(fixed in commit `a280de5`; orphan duplicated template-literal
  block at lines 246-268 removed; new
  `__tests__/syntax-check.test.js` parses every file under
  `www/js/` with acorn so this can't recur)*.

- [x] 🟡 ~~**[STG-WALK-4] `staging-config.js` parse error on Firebase
  Hosting when the file is absent**~~ — *(fixed in commit `a280de5`;
  Firebase's SPA rewrite returns HTTP 200 + HTML for missing files,
  so `<script onerror>` never fires; replaced with an inline XHR
  loader that sniffs Content-Type before eval)*.

- [x] 🔴 ~~**[STG-WALK-5] AI Assistant Send button silently broken
  in PROD too — `let app` in firebaseConfig.js shadowed `window.app`
  in inline event handlers**~~ — *(fixed in commit `<this commit>`;
  `let app = firebase.initializeApp(...)` renamed to
  `let firebaseApp = ...`. Inline `onclick="app.chat.X()"` in
  `chat.html` rewritten to `onclick="window.app.chat.X()"`. Two new
  pinned regression tests: `firebase-app-shadow.test.js` blocks the
  variable name, and `chat-render.test.js` requires the
  `window.app.chat.*` form.)*
  - **Symptom**: Clicking any quick-question button or the **Send**
    button in the AI Assistant tab threw `Cannot read properties of
    undefined (reading 'sendFromInput')` (and similar for `ask`). No
    request was made, no message sent, no LLM call. The chat UI
    rendered fine but every interaction failed silently to the user.
  - **Root cause**: `firebaseConfig.js` declared
    `let app = firebase.initializeApp(...)`. In a classic (non-module)
    `<script>`, `let app` at top level creates a binding in the
    *global lexical environment*. That environment lives "above"
    `window` in the scope chain seen by inline event handlers, so
    `onclick="app.chat.X()"` resolved `app` to the **Firebase App
    instance** (which has no `.chat`) rather than to `window.app`
    (the application's namespace, which has `.chat.sendFromInput`).
    `typeof window.app === 'object'` was correct in DevTools — but
    inline handlers don't go through `window`.
  - **Why missed**: existing `chat-render.test.js` only string-matched
    HTML and main.js — it never invoked any handler. The tab visibly
    rendered, so casual smoke tests passed. Bug was found by the new
    Playwright `tools/_interact-pages.js` driver that *clicks* every
    interactive element.
  - **Same bug exists in PROD repo**: prod's `firebaseConfig.js` has
    the identical `let app = ...`. AI Assistant has been broken in
    prod since it was first wired up. Promotion PR back to prod
    branch `fix/firebaseconfig-app-shadowing` is mandatory.

- [x] 🟠 ~~**[STG-WALK-6] Bottom action buttons (Save / Print / WhatsApp)
  on Bills clipped by browser/OS chrome**~~ — *(fixed in commit
  `<this commit>`; `www/css/tabs.css` `.tab` rule changed
  `padding: 70px 16px 24px 16px` → `padding: 70px 16px calc(96px +
  env(safe-area-inset-bottom, 0px)) 16px`. Verified by Playwright at
  viewport heights 600 and 720 — both buttons fully on-screen with
  margin to spare.)*
  - **Symptom**: On the Bills tab, scrolling to the bottom of the form
    showed the WhatsApp / Save / Print row partially or fully hidden
    behind the Windows taskbar (and behind dynamic browser chrome on
    mobile Chrome / Safari). Owner reported this with a screenshot of
    Save being half-cut.
  - **Root cause**: `.tab` had `padding: 70px 16px 24px 16px` combined
    with `height: 100vh` (not `min-height`). 24 px is below the Windows
    taskbar height (~40 – 50 px), and `height: 100vh` locks the tab
    height to viewport at the moment the page loaded — so it never
    re-flows when the mobile browser's URL bar/keyboard appears.
  - **Fix**: Increased bottom padding to 96 px and added the iOS
    home-indicator safe area on top via `env(safe-area-inset-bottom)`.
    `height: 100vh` was kept (replacing it is a larger refactor with
    risk of breaking the inner-scroll behavior on Android).
  - **Same bug exists in PROD repo**: prod's `www/css/tabs.css` has the
    identical `padding: 70px 16px 24px 16px;`. Promotion PR back to
    prod branch `fix/tab-bottom-padding` is recommended.

- [x] 🟡 ~~**[STG-WALK-7] Staging banner overlapped the side-navigation
  drawer header**~~ — *(fixed in commit `<this commit>`;
  `www/css/staging-banner.css` `.staging-banner` rule moved from a
  full-width 48-px-tall horizontal strip across the top of the page to
  a 32-px-wide vertical strip on the right edge. Body padding switched
  from `padding-top: 48px` to `padding-right: 32px`. Sub-line detail
  span hidden in the side-banner variant. Verified by Playwright probe
  `tools/_verify-banner-position.js` that the banner is flush right /
  full-height and the open drawer (left=0..280) does not overlap the
  banner (left=1248..1280) on a 1280×800 viewport.)*
  - **Symptom**: Owner reported the red striped "STAGING — READ-ONLY
    MIRROR — WRITES ARE BLOCKED" banner covered the top of the
    side-navigation drawer (the "Aadhat Billing / Hitesh / ×" header)
    when the drawer was opened.
  - **Root cause**: banner was `position: fixed; top: 0; left: 0;
    right: 0` with z-index 100000 and 48-px height, which rendered
    above the drawer's nav-header — the drawer is also fixed-position
    but at z-index 1001, so the banner painted over it.
  - **Fix**: moved banner to the right edge (`top: 0; right: 0;
    bottom: 0; width: 32px`) with vertical writing-mode so the message
    reads top-to-bottom along the right side. The drawer is on the
    left, so the two no longer share screen real estate. Body
    `padding-right: 32px` keeps app content out from under the new
    strip. Staging-only — does not exist in prod.

---



When a fix lands in this clone:

1. Find the row.
2. Change `[ ]` to `[x]`.
3. Wrap the title text in `~~ ~~`.
4. Append a fix note: ` *(fixed in commit `<sha>`, see PR #N)*`.

Example:

```markdown
- [x] 🔴 ~~**[WALK-1] AI Assistant is non-functional**~~ — *(fixed in commit `a1b2c3d`, see PR #5; new `chat.js` module with intent router + AppState queries)*
```

Never delete a row, even if a fix was reverted — leave history intact and add
a follow-up row underneath.

---

## [AUDIT] Sweep results (commits `41a74bb` → `4307f9c`)

This section was added at the end of a focused 4-batch audit pass. Goal:
hunt the staging codebase for concrete defects across security, schema
consistency, timezone correctness, and test coverage. Findings were
sourced from 5 background `explore` agents (payment-schema, XSS, dead
code, date/timezone, validation/race/null-deref) and verified by jest
between every batch. Test count went from **466 → 506 (+40)**.

| ID         | Severity | Category        | Site (file:line)                                                                 | Fix                                                                                          |
|------------|----------|-----------------|----------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| AUDIT-1    | High     | payment-schema  | `wholesale-sales.js:511`                                                         | Route through `Helpers.parsePaymentBreakdown(sale)`                                          |
| AUDIT-2    | High     | payment-schema  | `history.js:230`                                                                 | Same; dropped dead legacy fallback                                                           |
| AUDIT-3    | High     | payment-schema  | `billing.js:870` (edit-prefill)                                                  | Normalise via `parsePaymentBreakdown(bill)` so legacy bills prefill identically to modern ones |
| AUDIT-4    | High     | payment-schema  | `wholesale-sales.js:678` (history render)                                        | Same; legacy schemas now surface in history list                                             |
| AUDIT-5    | High     | XSS             | `admin.js:261`+`:306` (user.name/email/role/id in pending+active user cards)     | Wrap each in `Helpers.escapeHtml`; added `Helpers` import                                     |
| AUDIT-6    | High     | XSS             | `purchase.js:241`+`:259` (item.name in weight breakdown + bill table)            | Wrap in `Helpers.escapeHtml`                                                                  |
| AUDIT-7    | High     | XSS             | `retail-sale.js:250`+`:267` (same)                                               | Wrap in `Helpers.escapeHtml`                                                                  |
| AUDIT-8    | High     | timezone        | `cash-management.js` × 8 sites: `toISOString().split('T')[0]` + manual parsers   | All routed through `Helpers.localDateString` + `Helpers.parseDate`. ~24-line manual Indian-locale parser deleted. |
| AUDIT-9    | High     | timezone        | `reports.js:887/898/930/1113/1117` (sort + display + CSV processor)              | `Helpers.parseDate` everywhere                                                               |
| AUDIT-10   | High     | timezone        | `finance.js:597/601` (withdrawals sort + display)                                | Same                                                                                         |
| AUDIT-11   | Med      | timezone        | `stock.js:456-460` (adjustments sort)                                            | Mixed timestamp/date sort with `Helpers.parseDate` fallback                                  |
| AUDIT-12   | Med      | timezone        | `outstanding.js:139-143` (dueTransactions sort)                                  | Same                                                                                         |
| AUDIT-13   | Med      | timezone        | `printer.js:620-624` (expense.timestamp + new Date(expense.date))                | `Helpers.parseDate`; added Helpers import                                                    |
| AUDIT-14   | Med      | timezone        | `day.js:390-401` (sort + render fallback)                                        | `Helpers.parseDate` (Helpers import already present)                                         |
| AUDIT-15   | High     | timezone        | `firestore-service.js:432` (withdrawals load normalisation)                      | `Helpers.parseDate(data.date)` so saved DD/MM/YYYY round-trips correctly                     |
| AUDIT-16   | Med      | timezone        | `chat/appstate-queries.js:62` + `chat/chat-llm.js:49`                            | Inline DD/MM/YYYY-aware parser (chat modules can't import Helpers due to module isolation)   |
| AUDIT-17   | Med      | timezone        | `chat/chat-llm.js` summary `today` comparison                                    | Local YYYY-MM-DD instead of `toISOString().slice(0,10)` (UTC drift bug)                       |
| AUDIT-18   | Med      | helpers         | `Helpers.parseDate`                                                              | Extended to handle bare YYYY-MM-DD as **local** date (round-trips with `localDateString`)    |
| AUDIT-19   | Med      | dedup           | `analytics.js:122` `monthMeta()`                                                 | Promoted to `PeriodMath.monthMeta()`; analytics is now a thin delegate                       |
| AUDIT-20   | Med      | validation      | `finance.js:439-470` (updateAccount / deleteAccount)                             | `parseInt(...)` could return NaN → `splice(NaN, 1)` deletes index 0. Added explicit guard with toast. |
| AUDIT-21   | Low      | logging         | `printer.js:993, 1147` (share-fail console.log)                                  | Upgraded to `console.warn` with bill/expense disambiguation                                  |
| AUDIT-22   | -        | coverage        | `period-math.js` (was 80%)                                                       | +15 tests covering yesterday/lastWeek/lastYear/custom, cashOnHand, withdrawals, monthMeta — now ~95% |
| AUDIT-23   | -        | coverage        | `helpers.js` (parseDate / localDateString)                                       | +8 tests (round-trip, DD/MM/YYYY, Indian locale w/ time, Firestore Timestamp, null/garbage) |
| AUDIT-24   | -        | coverage        | `analytics.js` (was 0%)                                                          | +17 tests covering pure delegations + getTotal precedence                                    |

### Findings investigated and intentionally NOT acted on

| Site                                                                                                  | Why not                                                                                     |
|-------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| `finance.js:202-217` — shims (`updateDateFilterButtons`, `setDateFilter`, `applyCustomDateFilter`, ...) | Agent confirmed `main.js:593-597` still references some via `window.app.finance` — not safely deletable yet |
| Orphaned analytics HTML ids                                                                           | Agent confirmed zero matches in templates / JS — already cleaned                            |
| `miscellaneous.js:71/158` (expense `Number()`)                                                        | Existing `!amount \|\| amount <= 0` guard does correctly reject `Number('') === 0`. Skip.    |
| `finance.js:531` (withdrawal `parseFloat`)                                                            | Same — `!amount \|\| amount <= 0` already handles NaN (`!NaN` is true). Skip.                 |
| `retail-sale.js:54` / `purchase.js:53` weight `parseFloat`                                            | `!weight` guard handles NaN. Skip.                                                          |
| `wholesale-sales.js:114` rate/quantity                                                                | Already through `Helpers.getInputNumber` which validates finiteness. Skip.                  |
| `billing.js:89` `autoSaveToCloud` not awaited                                                         | Intentionally fire-and-forget (UX requirement: don't block tab switch). Acceptable.         |
| `printer.js:993/1147` share fail                                                                      | Real fallback path exists; just upgraded log level to `console.warn`. No real regression.   |

### Test deltas

| Suite                  | Before | After | Δ   |
|------------------------|--------|-------|-----|
| period-math.test.js    | 19     | 34    | +15 |
| helpers.test.js        | n      | n+8   | +8  |
| analytics.test.js      | 0      | 17    | +17 |
| **Repo total**         | **466**| **506** | **+40** |

All 28 suites green at end of pass.

### Commits

```
41a74bb  test(period-math): cover yesterday/lastWeek/lastYear/custom + cashOnHand + withdrawals + monthMeta
6ee8d14  audit(payment-schema+xss): route 8 sites through parsePaymentBreakdown / escapeHtml
ae972ee  audit(timezone): cash-management adopts Helpers.localDateString + parseDate everywhere
2866922  audit(timezone): reports/finance/stock/outstanding/printer/day/firestore/chat adopt Helpers.parseDate + local YYYY-MM-DD comparisons
4307f9c  audit(payment-schema+validation+coverage): billing/wholesale prefill via parsePaymentBreakdown; finance account index NaN guard; analytics test suite (17 tests)
```

---

## Cross-reference

- Issues that block other phases of the staging plan (`plan.md`) are marked with their plan task id (`p4-...`, `p5-...`).
- Functional walkthrough that produced the `[WALK-*]` items: see `docs/CAPABILITIES.md` for the same modules viewed as features.
- Agent navigation guide: `AGENTS.md`.
