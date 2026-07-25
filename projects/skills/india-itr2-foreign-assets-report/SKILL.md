---
name: india-itr2-foreign-assets-report
description: Prepare and cross-check an Indian ITR-2 filing package and self-contained interactive HTML report for salary, bank interest, mutual-fund gains, Fidelity/Microsoft RSU or ESPP holdings, Schedule FA, Schedule FSI, Schedule TR and Form 67. Use when a resident Indian taxpayer needs help organizing or reconciling an ITR involving foreign shares or foreign dividends.
license: MIT
---

# India ITR-2 foreign-assets filing report

Prepare a filing-assistance package from the taxpayer's source documents. Work locally, preserve an audit trail, distinguish calendar-year Schedule FA data from financial-year income data, and never claim that the return has been filed.

Read these references before calculating:

- `references/INPUT-CHECKLIST.md`
- `references/CALCULATION-RULES.md`
- `references/REPORT-SPEC.md`
- `references/SOURCE-PROVENANCE.md`

## Non-negotiable privacy rules

1. Never request or accept income-tax portal credentials, Aadhaar OTPs, bank credentials or broker login credentials.
2. Treat PAN, passport number, foreign TIN, account numbers and PDF passwords as sensitive.
3. Do not write passwords or PAN values into reports, CSV files, scripts, shell history, filenames, logs, checkpoints or notes.
4. Ask for the AIS password and Form 16 password only after explaining that chat/session history may retain entered text. Prefer a secure local handoff or environment variable when available.
5. The Form 16 Part A, Part B and Form 12BA/annexure password is commonly the taxpayer's PAN in uppercase. Ask for the common Form 16 password; if the user supplies PAN instead, use it only as the password and never reproduce it.
6. Process tax documents locally. Do not upload them or their extracted contents to third-party services.
7. Never embed PAN or passwords in the HTML, even as hidden or masked values. Account numbers, passport number and foreign TIN may be masked by default only when the user explicitly wants them included.
8. Remove decrypted temporary PDFs, OCR images and temporary password material after extraction. Preserve only the source files supplied by the user and filing artifacts that contain no passwords.
9. Supply PDF passwords to local tools through stdin, a short-lived environment variable or an interactive prompt. Never place a password in a command-line argument or echo it to the terminal. If the available tool cannot accept a password securely, ask the user to decrypt the file locally instead.

## Intake gate: ask for everything upfront

The first response for a new taxpayer must be an intake request. Do not begin calculations until the user either supplies the required inputs or explicitly asks for a partial report.

Ask for:

1. Assessment year, financial year, taxpayer name and tax-report directory.
2. Residential status, especially whether the taxpayer is Resident and Ordinarily Resident.
3. Scope:
   - Full ITR-2 filing report, or
   - Only Schedule FA/FSI/TR/Form 67 and foreign income.
4. Required files:
   - AIS PDF.
   - Form 16 Part A PDF.
   - Form 16 Part B PDF.
   - Form 12BA or salary annexure PDF.
   - Fidelity calendar-year/year-end account summary.
   - Fidelity transaction summary covering the Schedule FA calendar year.
   - Fidelity January, February and March reports following that calendar year, so the financial-year dividend period is complete.
   - US Form 1042-S or an equivalent annual broker withholding-tax statement, if issued.
   - Fidelity open-lots CSV in original currency.
   - Fidelity closed-lots CSV in original currency.
   - Prior-year filed ITR JSON/PDF or prior-year Schedule FA pages.
5. Passwords:
   - AIS PDF password.
   - Common Form 16/12BA password, normally PAN in uppercase.
6. Additional files for a full return:
   - TIS and Form 26AS if available.
   - Bank interest certificates or statements.
   - Mutual-fund/equity capital-gains statements.
   - Advance-tax and self-assessment-tax challans.
   - Rent/HRA, home-loan and deduction evidence if the old regime should be compared.
7. Foreign-asset details not always visible in statements:
   - Fidelity account number and actual account-opening date.
   - Foreign TIN, or confirmation that passport number will be used.
   - ESPP discount percentage and confirmation that the discount was taxed as salary perquisite.
   - Any foreign bank, brokerage, property, trust, insurance, crypto or other foreign asset outside Fidelity.
   - Any user-supplied historical SBI TT-rate table or market-price evidence; otherwise the skill will retrieve and cite verifiable sources.

Use one consolidated checklist rather than repeatedly requesting individual files. When structured elicitation is available, use it for the directory, assessment year, scope, residency and missing-file confirmations. Request sensitive passwords separately.

## Source hierarchy

Apply this priority when sources conflict:

1. Filed prior-year ITR/Schedule FA for historical continuity.
2. Employer Form 16, Form 12BA and stock-perquisite records.
3. Broker transaction statements and original-currency lot exports.
4. AIS/TIS/26AS and tax challans.
5. Bank and mutual-fund statements.
6. Derived calculations and third-party tools.

Never treat a third-party generated report as the source of truth. Reconcile it against original documents.

## Workflow

### 1. Inventory and validate

- Create a source inventory with filename, period, currency, password status and intended use.
- Confirm that Fidelity coverage includes:
  - The entire Schedule FA calendar year, and
  - The entire Indian financial year for dividends and foreign income.
- Confirm that open and closed lot exports explicitly state that their amounts are in USD or other original currency.
- Detect missing statements, duplicate exports and files from the wrong year.
- Record assumptions and unresolved items separately.
- Confirm Schedule FA/FSI/TR/Form 67 applicability before calculating. Do not generate these schedules by default for an RNOR or non-resident taxpayer; first establish whether the relevant foreign income is taxable and reportable in India.

### 2. Extract locally

- Decrypt password-protected PDFs locally.
- Extract text directly where possible; use OCR only for scanned pages.
- Keep page references for every material figure.
- Never persist passwords.
- Delete temporary decrypted/OCR files after producing validated extracts unless the user explicitly wants local evidence copies.

### 3. Reconcile Indian income

For a full report, reconcile:

- Salary, standard deduction and perquisites from Form 16/12BA.
- Savings and term-deposit interest from AIS and bank records.
- Mutual-fund/equity sale proceeds, cost and gains.
- TDS, advance tax and self-assessment tax.
- Tax payments belonging to another financial year must be excluded.
- Compare old and new regimes using all documented deductions, but do not invent deductions.

### 4. Separate the reporting periods

- Schedule FA uses the relevant calendar year ending 31 December.
- Schedule OS/FSI/TR/Form 67 use the Indian financial year ending 31 March.
- A sale can belong to the prior financial year's capital gains while still appearing in the current Schedule FA calendar-year disclosure.
- Clearly label both periods throughout the report.

### 5. Build Schedule FA Table A2

Use the Fidelity custodial-account information:

- Country and code.
- Institution name and address.
- ZIP code.
- Account number, masked in the report.
- Owner/beneficial-owner status.
- Actual opening date.
- Peak and closing balance for the calendar year.
- Gross dividends/distributions and sale/redemption proceeds credited during the calendar year.

Do not omit A2 merely because the underlying Microsoft shares are also disclosed in A3.

### 6. Build Schedule FA Table A3

- Include every foreign equity interest held at any time during the calendar year.
- Include lots sold during the calendar year, with zero closing value and sale proceeds.
- Exclude lots first acquired after 31 December of the relevant Schedule FA year.
- Keep original broker lots separate unless the user explicitly requests grouping. Never silently group, split or reorder values.
- Use the exact 12-column portal layout:
  1. Serial number
  2. Country name and code
  3. Name of entity
  4. Address
  5. ZIP code
  6. Nature of entity
  7. Acquisition date
  8. Initial value
  9. Peak value
  10. Closing balance
  11. Gross amount paid/credited
  12. Sale/redemption proceeds

#### Initial value

- Use the acquisition-date value and the applicable acquisition-date SBI TT buying rate.
- For RSU/stock-vest shares, the common filing approach is the FMV/perquisite tax basis supported by employer or vest records. Cite the supporting record and mark the position for professional confirmation if official instructions do not resolve the taxpayer's facts.
- For ESPP shares where the discount was taxed as salary perquisite, the common filing approach is full purchase-date FMV rather than the discounted employee cash price. State this assumption, cite the perquisite/plan evidence and flag it for confirmation when facts or guidance are ambiguous.
- If Fidelity displays only the discounted ESPP employee-price basis, calculate full FMV only when the discount percentage is documented.
- Compare all historical initial values against the prior-year filed Schedule FA. Do not change historical figures silently. Show and explain any methodology difference before recommending a filing value.

#### Peak and closing value

- Use the highest applicable daily market price while the lot was held during the calendar year and the relevant SBI TT buying rate.
- For a lot sold during the year, do not use a market date after its sale.
- Use the 31 December market close and rate for year-end holdings.
- Sold lots have closing value zero.
- Every historical market price and exchange rate must have a traceable source. Follow `references/SOURCE-PROVENANCE.md`; never invent or silently estimate a missing rate.

#### Prior-year continuity

- Reconcile prior-year closing quantities to current-year opening quantities.
- The prior-year closing market value is not the current A3 "initial value"; A3 has no opening-value column.
- Show:
  - Shares at prior 31 December.
  - Shares sold during the current calendar year.
  - Shares carried forward.
  - New shares acquired.
  - Shares at current 31 December.
- Quantity continuity should reconcile exactly. Value continuity may differ because acquisition value and market value are different concepts.

### 7. Reconcile foreign dividends and Schedule OS

- Capture every Microsoft dividend and every Fidelity money-market/sweep distribution.
- Include foreign income even when no foreign tax was withheld.
- Convert dividends using Rule 115 and the SBI telegraphic-transfer buying rate for the specified date.
- Preserve exact converted amounts through aggregation; round only at the schedule/return level.
- Produce transaction-level and quarterly Schedule OS breakdowns.

### 8. Prepare Schedule FSI, TR and Form 67

- Foreign tax paid is the actual tax deducted or paid, converted under Rule 128.
- Do not confuse foreign tax paid with Indian tax attributable to the income.
- Compute FTC separately for each source/country as required.
- FTC is not automatically equal to foreign tax paid. It is capped by the lower permitted amount under Rule 128 and the applicable DTAA.
- Show the exact formula and inputs used for Indian tax attributable.
- If the correct portal treatment of average versus incremental tax is not unambiguous, calculate both, cite the rule, mark the FTC as unresolved, and require portal/qualified-tax-professional confirmation. Never present an uncertain FTC as final.
- Identify section 90/90A/91 and the applicable DTAA article.
- Prepare a local supporting-evidence PDF from the relevant broker statement pages.
- Recommend filing Form 67 before the ITR as the conservative workflow, while checking the current statutory deadline.

### 9. Produce the interactive filing report

Follow `references/REPORT-SPEC.md`.

The report must:

- Be a single self-contained HTML file with no external dependencies.
- Include all filing schedules, values, source notes and assumptions.
- Include the full 12-column A3 table without changing source values.
- Include prior-year FA reconciliation in a separate audit section.
- Mask sensitive identifiers by default.
- Provide search/filter, copy, print/PDF, dark mode and a persistent local checklist.
- Link to local supporting CSV/PDF files.
- Clearly distinguish confirmed, estimated, provisional and unresolved figures.

### 10. Validate before handoff

Confirm:

- All source files are represented in the inventory.
- A3 row count and totals match the ready CSV.
- A2 and A3 are both considered.
- Prior-year quantities reconcile.
- Sold lots are included exactly once.
- Calendar-year and financial-year transactions are not mixed.
- Dividend totals reconcile to statements.
- Foreign withholding reconciles to evidence.
- FSI, TR, Form 67 and Schedule OS agree after documented rounding.
- Tax payments belong to the correct year.
- Regime comparison uses the same income base.
- HTML JavaScript parses and all local links exist.
- No password, PAN or unmasked sensitive identifier appears in generated artifacts.

## Required output

Create a clearly named package inside the taxpayer's chosen tax directory:

- `ITR2-Interactive-Filing-Report.html`
- `ITR2-filing-guide.txt`
- `Source-inventory.csv`
- `Assumptions-and-open-items.txt`
- `Schedule-FA-A2-ready.csv`
- `Schedule-FA-A3-ready.csv`
- `Schedule-FA-A3-audit.csv`
- `Schedule-FA-prior-year-reconciliation.csv`
- `Form67-FSI-TR-ready.csv`
- `Foreign-dividend-detail.csv`
- `Capital-gains-ready.csv`
- `Tax-payments-ready.csv`
- `Tax-computation-estimate.csv`
- `Regime-comparison.csv`
- `Exchange-rate-audit.csv`
- `Market-price-audit.csv`
- Supporting Form 67 evidence PDF

Do not submit the return. State that login, final portal calculation, payment, submission and e-verification remain with the taxpayer.
