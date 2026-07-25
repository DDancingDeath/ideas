# Exchange-rate and market-price provenance

Schedule FA, foreign income and FTC calculations must be reproducible. Never use an uncited historical rate or price.

## Exchange rates

Preferred order:

1. User-supplied official SBI TT buying-rate document.
2. Archived SBI-issued rate PDF or official bank record.
3. A reputable historical archive that preserves the original SBI rate and date.
4. A second independent source used only as a cross-check.

For every rate record, store:

- Currency
- Effective date and time if available
- SBI TT buying rate
- Tax rule/purpose: acquisition, peak, closing, sale, Rule 115 income or Rule 128 foreign tax
- Source filename or URL
- Retrieval date
- Whether the source is official, archived-official or secondary
- Cross-check result

If an archived source differs from another source, retain both values, explain the chosen value and mark the row for review.

## Market prices

Preferred order:

1. Broker/employer transaction record for acquisition FMV.
2. Official exchange or issuer historical data.
3. A reputable market-data provider with daily open/high/low/close values.
4. A second provider for cross-checking material values.

For every market-price record, store:

- Symbol and exchange
- Date
- Price type: acquisition FMV, daily high, closing price or sale price
- Price and currency
- Source filename or URL
- Retrieval date
- Cross-check result

## Required artifacts

Create:

- `Exchange-rate-audit.csv`
- `Market-price-audit.csv`

The interactive report should summarize provenance and link to these files. If a value is unverified, label all calculations depending on it as provisional.

