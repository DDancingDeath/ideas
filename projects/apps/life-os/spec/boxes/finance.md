# Box spec — Finance

The finance engine (inventory, net worth, cash flow, loans, projections,
scenarios, goals, rule-based recommendations) is specified in the
[personal-ai-cfo spec](../../../personal-ai-cfo/spec/README.md), which is the
source for every finance calculation, convention and `finance.*` / `prices.*`
key. This file specifies how Finance plugs into Life OS and the hub-level
finance features: live data, document and statement imports, FD maturity,
spending insights and the tax report.

## In the box contract

| Member | Content |
| --- | --- |
| `glance` | Net worth attributable to the owner, with liquid assets as a line; missing count from the position's gaps |
| `facts` | From net worth and cash flow, ratios, recommendations, goal plan and stress results |
| `tools` | The finance calculations, with inputs built from the owner's documents (affordability, stress, net-worth projection, prepay vs invest, retirement, goal plan, recommendations, position) |
| `recommendations` | The finance engine's ranked recommendations. Urgency: engine tier 1 → `high`, 2 → `medium`, 3–4 → `low`. Category by rule: emergency reserve, liquidity mix → `liquidity`; term life, health cover → `protection`; debt-service share, high-interest debt → `debt`; concentration → `optimisation`; data completeness, stale data → `data` |
| `missing` | Every null cash-flow amount, owner-declared gap, unset required key and stale value |
| `reminders` | Policy renewals, FD maturities, snapshot day |
| `review_queue` | Drafts from connectors, document imports and the Documents box |
| Disclaimer | `finance.disclaimer` |

Household dependents for finance rules come from the household profile unless
the owner's planning document sets them explicitly (an explicit value wins).

## Live data

The system keeps figures current **without** portal passwords, scraping or
Account Aggregator access. Every value keeps `source {type, ref, observed_at}`
and its valuation date.

| What | How it updates | Source of the value |
| --- | --- | --- |
| Mutual funds | units × the official daily NAV published by AMFI | public NAV file, fetched by the home server |
| NPS | units × the NPS Trust daily NAV per scheme | public NAV report, fetched by the home server |
| Foreign shares (e.g. employer stock) | units × a price the owner enters with its date × the ECB reference rate | owner entry; ECB reference rates |
| Indian listed shares (NSE / BSE) | units × the closing price from a bhavcopy file **the owner downloads** | exchange bhavcopy, imported by the owner (exchange terms forbid automated download) |
| Bank balance | the available balance in alert emails or SMS; e-statement PDFs | the bank's own messages |
| EPF | EPFO passbook PDF; contribution SMS or emails | EPFO messages and passbook |
| Statements (mutual-fund CAS, NPS, EPF, payslips) | read-only mailbox connector → the document importers | PDFs emailed to the owner |

| Rule |
| --- |
| Automatic fetches run at most `prices.maxFetchesPerDay` per source, from the owner's own home server, over HTTPS, with an honest user agent, at least `prices.minSecondsBetweenRequests` between requests to one host, a size cap and a timeout. Only the prices of the owner's instruments are kept, with the URL, fetch time, file SHA-256 and dates; the public file is not stored or redistributed. |
| A changed source format fails loudly and leaves the price book untouched. A row the source marks not available is reported, never priced at zero. |
| A holding is valued at units × the latest price on or before `as_of` (× the latest FX rate for foreign holdings). An item is revalued only when **every** holding has a price; otherwise its entered value is kept and the gap reported. An entered value newer than the prices is kept. |
| The prices used are copied into the calculation input, so results are reproducible from `inputs_sha256`. Snapshots freeze the prices of their date. |
| Mailboxes are read with read-only scopes through OAuth for installed apps (authorization code + PKCE, loopback redirect), with the owner's own OAuth client; the owner chooses the date to read from (`finance.inbox.readFrom`). |
| The owner's rules map sender + subject to a document type (`mf_cas`, `nps_statement`, `epf_passbook`, `payslip`, `alert`, `alert_attachment`); a rule names a saved PDF password by reference, never the password itself. |
| SMS and alert text is parsed by owner-editable templates (SAMPLE until saved): paste now, forwarded by the Android app later. |
| The home server runs connectors daily at `finance.connectors.dailyRunTime`. |

### Review queue and auto-apply

| Rule |
| --- |
| Every connector and import writes a **draft** into the Finance review queue, with its source (provider, message or file, received date, SHA-256). |
| *Apply* writes through the versioned save; the value gets `source` and `observed_at`. An observation older than the item's current value is refused. |
| Auto-apply is off for every source until the owner turns it on per source or rule (`finance.autoApply`); even then only balances mapped to an account, or statement rows matched by id, folio, ISIN or PRAN, are applied. |

### Freshness

| Rule |
| --- |
| A value is stale when Today − valuation date > `finance.staleAfterDays`; a market price is stale when older than `finance.priceStaleAfterDays` (required once any units are tracked). Historical-cost records are never stale. |
| Overview shows a *Data freshness* table; Ask's caveats name every stale value used with its date. |

## Document imports

Flow: collect → extract → validate → normalise → match → review → apply.
Nothing is saved until the owner has reviewed the draft and ticked rows.

| Document | Read | Suggested updates |
| --- | --- | --- |
| EPF passbook | Per member id: establishment, opening balance, monthly contributions (employee, employer, pension), interest, transfers, withdrawals, closing balance | EPF value (employee + employer share; pension shown, never added); retirement balance; latest monthly contribution |
| Payslip | Pay month, gross, basic, PF (both shares), income tax, deductions, net pay — by **labels the owner confirms** per employer | Salary income line (net pay); monthly EPF contribution |
| Mutual-fund CAS | Per folio and scheme: ISIN, units, NAV and date, cost, value; units × NAV checked | One item per holding; the owner chooses category and liquidity of a new item |
| NPS statement | PRAN, tier values, scheme units, NAV and values (checked against the total) | NPS values; retirement balances |
| Form 16, AIS, ITR | Per assessment year: income by head, deductions, TDS | Inputs of the [tax report](#tax-report) |

| Rule |
| --- |
| Every extracted value has a confidence (high / medium / low by its number of issues); failed checks and every unrecognised line are listed. A row that cannot be read is flagged, never treated as zero. |
| PDFs are read locally; a PDF password is used once unless the owner saves it (encrypted); a scanned PDF is read by OCR only on request, and every OCR row needs review. Upload limit `finance.importPdfMaxBytes`. |
| Matching prefers the same id, then folio / member id / PRAN / ISIN, then scheme name, then type words — so a re-import updates instead of duplicating. The owner can change the target or add a new item. |
| A document dated after the position's `as_of` is refused unless the owner also moves `as_of`; a document older than the current value is flagged. |
| Applied rows carry a note with the file name, its SHA-256 and the date. |

## Statement import and spending

| Rule |
| --- |
| Any bank or card CSV is read with a column mapping **the owner confirms** (date column and format, description, amount mode: signed / debit+credit / Dr-Cr column / Dr-Cr suffix); no bank layout is assumed. The header row is found by the mapped names; Indian grouping, ₹/Rs., bracketed negatives and BOMs are handled. Every unreadable row is reported with its line number. |
| Transactions are classified by the owner's category rules (first match wins; per-transaction overrides win). Category kinds: `living`, `debt_service`, `insurance`, `investment`, `transfer`, `income`, `other`. SAMPLE starter rules are shown only until the owner saves rules. |
| Duplicates across overlapping statements (same date, amount, normalised description and account) count once. |
| A month is *full* only inside the period and every account's coverage; averages use full months only. |
| Transfers are excluded when `finance.statements.excludeTransfers` is true. Recurring payments need `finance.statements.recurringMinMonths`, `finance.statements.recurringAmountTolerance` and `finance.statements.recurringDayWindow`. |
| Yearly or occasional payments (seen in fewer than `finance.statements.irregularMinMonths` of the full months) take the owner's treatment: average, annualise (÷ max(months, 12)), exclude or one-off. |
| Suggested monthly cash-flow lines (living, debt service, insurance) are applied only by the owner; investments, transfers and principal are never suggested as expenses. |

## FD maturity

Each fixed deposit item records its maturity date (and maturity amount when
known). The Finance box emits a reminder due on the maturity date; it shows in
*Coming up* within `reminders.upcomingDays`. A deposit without a maturity date
is listed in `missing`. A matured deposit stays in the position at its last
value until the owner updates it.

## Spending insights

| Insight | Rule |
| --- | --- |
| Category share | Each category's average monthly `net_outflow` over full months and its share of total spending |
| Recurring commitments | The recurring payments found, with cadence and typical amount |
| Spending drift | A category whose latest full month exceeds its average over the previous `finance.spending.driftBaselineMonths` full months by more than `finance.spending.driftThresholdPct` → a recommendation of category `optimisation`, citing both figures |
| Where to save | Categories ranked by average outflow, with recurring commitments and drift; facts only, never a judgement of the owner's choices |

No insight runs without enough full months for its baseline; the gap is listed
in `missing`.

## Tax report

| Rule |
| --- |
| Calculations use **tax rule sets**: versioned data files, one per assessment year and regime, each rule citing its official source and effective date. |
| A rule set must be verified by the owner before use; a calculation with an unverified rule set is refused (`invalid`, naming the rule set). No tax rule is built into code. |
| Inputs come from the owner's imported Form 16, AIS and ITR documents and the Finance position; a missing input is `needs_input`. |
| Outputs per assessment year: income by head; deductions claimed and available under each regime; estimated tax under each regime; TDS and advance tax against the estimate; mismatches between Form 16, AIS and the ITR. |
| *Tax saving* recommendations (category `optimisation`) cite the rule and the amount of unused deduction headroom. |
| Every output carries `finance.taxDisclaimer`: an estimate from the owner's documents and verified rules, not tax filing advice. |
