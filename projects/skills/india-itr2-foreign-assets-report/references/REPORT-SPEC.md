# Interactive HTML report specification

Generate one self-contained HTML file that opens locally without a server.

## Required sections

1. Dashboard
   - Assessment and financial year
   - Return form and regime
   - Total income
   - Foreign income
   - Foreign tax paid
   - FTC status: confirmed or provisional
   - Estimated tax payable
2. Interactive filing guide
3. Salary
4. Income from other sources
5. Deposits and bank interest
6. Capital gains
7. Schedule FSI, Schedule TR and Form 67
8. Schedule FA Table A2
9. Schedule FA Table A3 in the exact 12-column portal format
10. Prior-year Schedule FA reconciliation
11. Taxes paid and tax computation
12. Regime comparison
13. Submission checklist
14. Source files, assumptions and unresolved items

## Interactivity

- Sticky section navigation
- Responsive layout
- Light/dark mode
- Search and status filtering for long tables
- Copy value/table controls
- Print/save-to-PDF mode
- Expand/collapse notes
- Best-effort persistent local checklist using local storage, with a visible note that `file://` browser policies may prevent persistence
- Account/passport/TIN reveal/mask control when explicitly included; PAN and passwords must never be embedded

## Data integrity

- Build the displayed A3 rows from the ready CSV without changing values.
- Do not silently group rows.
- Show totals and row counts.
- Mark estimates and provisional values.
- Keep prior-year reconciliation separate from current portal-entry fields.
- Do not use prior-year closing value as current initial value.

## File links

Use relative links to supporting files placed beside the HTML report. Verify every link exists.

## Privacy

- No external fonts, scripts, analytics or network requests.
- Mask identifiers by default.
- Do not include PAN or passwords, even as hidden HTML data.
- Add a visible local/private-data warning.
