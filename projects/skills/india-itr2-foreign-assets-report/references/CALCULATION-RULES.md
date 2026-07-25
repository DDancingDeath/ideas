# Calculation and reconciliation rules

## Periods

- Indian taxable income: 1 April through 31 March.
- Schedule FA: relevant calendar year ending 31 December.
- Label every table with its applicable period.

## Source values

- Use original-currency broker data.
- Never infer that a CSV is INR or USD; confirm from the file.
- Keep transaction-level precision until final aggregation.
- Do not reuse a prior-year tax payment.

## Schedule FA A3

- Report assets held at any time during the calendar year.
- Include sold lots with zero closing value.
- Preserve broker-lot rows unless grouping is explicitly requested.
- Do not change numbers while reformatting.
- Compare historical acquisition values against the prior filed Schedule FA.

## RSU and ESPP

- RSU initial value commonly follows the supported acquisition FMV/perquisite basis; cite the employer evidence and disclose the interpretation.
- For ESPP with a discount taxed as salary perquisite, full FMV on purchase date is the common filing approach; disclose and support the interpretation.
- Discounted employee cash price is not the retained-share tax basis in that case.
- Require documentary confirmation of the discount percentage before grossing up a broker value.
- If official instructions or the taxpayer's evidence do not resolve the basis, show the alternatives and require professional confirmation.

## Market values

- Peak: quantity multiplied by the highest applicable market price while held, then converted using the applicable SBI TT buying rate.
- Closing: quantity multiplied by 31 December closing price and relevant rate.
- Sold lots: closing value zero; sale proceeds converted at the applicable rate.
- Cite the source file/URL and retrieval date for every exchange rate and market price.
- If no verifiable historical source is available, mark the value unresolved or estimated. Never generate a plausible-looking rate.

## Dividends

- Use gross dividend, not net cash.
- Include broker sweep/MMF distributions.
- Use Rule 115 specified-date SBI TT buying rate.
- Aggregate exact INR values and then apply return-level rounding.

## FTC

- Foreign tax paid and Indian tax attributable are different values.
- Convert foreign withholding under Rule 128.
- Credit is limited by Rule 128 and the DTAA.
- Compute source-wise.
- Document the Indian-tax-attributable formula.
- If average-rate versus incremental-rate treatment is unresolved, show both and leave the credit provisional.

## Regime comparison

- Use the same income under both regimes.
- Include only documented exemptions and deductions.
- Show comparison before FTC as well as after any confirmed FTC, so an FTC uncertainty does not distort the regime recommendation.

## Cross-checks

- Prior closing shares - current sold shares + current acquisitions = current closing shares.
- A3 CSV totals = HTML A3 totals.
- FSI foreign income = foreign component included in Schedule OS.
- TR relief = Form 67 credit claimed.
- Withholding evidence = foreign tax entered.
- Salary stock perquisites must not be added again as separate income.
