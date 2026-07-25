# India ITR-2 Foreign Assets Report skill

This GitHub Copilot CLI skill prepares a local, interactive filing-assistance package for an Indian ITR-2 involving Microsoft/Fidelity shares, foreign dividends, Schedule FA, Schedule FSI, Schedule TR and Form 67.

It asks for the complete input set upfront, reconciles prior-year Schedule FA holdings, handles RSU/ESPP acquisition basis, and generates a self-contained HTML filing report plus supporting CSV files.

## Install

### From the extracted folder

```powershell
copilot skill add "C:\path\to\india-itr2-foreign-assets-report"
```

Alternatively copy the `india-itr2-foreign-assets-report` directory to:

```text
%USERPROFILE%\.copilot\skills\
```

Then start Copilot CLI or run:

```text
/skills reload
```

Verify:

```text
/skills info india-itr2-foreign-assets-report
```

## Use

In Copilot CLI:

```text
Use the /india-itr2-foreign-assets-report skill to prepare my AY 2026-27 ITR-2 filing report.
```

The skill will first request the tax directory, reporting year, source files, missing details and PDF passwords.

## Security

- Keep all tax documents local.
- Do not provide portal credentials, bank credentials, Aadhaar OTPs or broker login credentials.
- PDF passwords and PAN values must never be written into generated artifacts.
- Review all calculated values and the current income-tax portal before filing.

## Scope

The skill produces filing aids; it does not log in, pay tax, submit or e-verify a return.

