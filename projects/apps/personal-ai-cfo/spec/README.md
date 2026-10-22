# Functional spec — Personal AI CFO

This is the **source of truth for what to build** for the finance engine. An
agent reading only this folder should be able to produce a working
application. Personal AI CFO is also the **Finance box** of
[Life OS](../../life-os/spec/README.md); hub-level finance features (live
data, review queue, document and statement imports, FD maturity, spending
insights, tax report) are specified in
[life-os `boxes/finance.md`](../../life-os/spec/boxes/finance.md).

> Written to the crispness contract in [`AGENTS.md`](../../../../AGENTS.md).
> The project README holds the single changelog.

## Reading order

1. This file — overview, glossary, configuration, data model, NFRs, worked
   example, open questions.
2. [`product-spec.md`](product-spec.md) — the full product specification
   (vision, functional requirements, planning engine, goals, recommendations,
   data ingestion, AI architecture, security, data model, UX). Where it
   recommends a technology, it is a suggestion; where it states behaviour, it
   is normative.
3. [life-os `boxes/finance.md`](../../life-os/spec/boxes/finance.md) — live
   data, imports, spending insights and tax report.

## Overview

- **What it does.** Builds one source-backed record of the owner's financial
  life (assets, liabilities, income, spending, insurance, goals), projects it
  under explicit assumptions with deterministic calculations, simulates
  decisions before money is committed, and ranks recommendations — read-only.
- **Who it's for.** One individual in India, with a data model ready for a
  household later (product-spec §2, §10).
- **Primary user journeys.**
  1. Enter or import the baseline; see net worth, cash flow and what is missing.
  2. Add goals; see required monthly saving and conflicts between goals.
  3. Ask "Can I afford a car for ₹15 lakh next year?" and see the
     with/without liquid path, EMI share and reserve impact — facts, never a
     bare yes/no.
  4. Review ranked recommendations with their assumptions and confidence.
  5. Import a statement or passbook; review the draft; apply it.

## Glossary and vocabulary

Hub terms (fact, tool, `needs_input`, urgency, draft, review queue, stale…)
are defined in the [Life OS glossary](../../life-os/spec/glossary.md).

| Term | Definition |
| --- | --- |
| **Position** | The dated financial inventory of one person (`as_of`): items, cash-flow lines, protection, ownership. |
| **Item** | An asset or liability in the position, with type, value, valuation date, ownership shares, liquidity, verification and source. |
| **Verification** | `verified`, `estimated`, `manual`. |
| **Attributable value** | Gross (100 %) value × the person's ownership share. Liabilities are attributed by their own ownership, never by the share of the asset that secures them. |
| **Excluded item** | An item already inside another item's value (`included_in`) or recorded at historical cost only; excluded from every total and listed with the reason. |
| **Liquidity tier** | How quickly an item can become cash; `liquid` is the first tier drawn in a stress test. |
| **Holding** | Units of an instrument inside an item (mutual fund, NPS scheme, listed or foreign share), valued from the price book. |
| **Price book** | The dated prices and FX rates the owner's instruments were valued with. |
| **Known-only figure / bound** | A total computed from known lines only when some are unknown, labelled "at least" or "at most". |
| **Scenario** | A named assumption set; `conservative`, `expected`, `optimistic` are required, others optional. |
| **Goal** | A target with one or more **stages** (payments), priority (`essential`, `important`, `discretionary`), allocation and funding. |
| **Funding gap** | Required corpus at the first stage − projected funds there (negative = surplus). |
| **Rule** | A configured recommendation check (emergency reserve, term-life cover, health cover, liquidity mix, debt-service share, high-interest debt, concentration, data completeness, stale data). |
| **Area** | `financial_safety`, `debt_strategy`, `savings_and_investments`, `protection`, `data`. |
| **Assessment state** | product-spec §6.3: `secure`, `on_track`, `at_risk`, `needs_attention`, `insufficient_data`. An area takes the worst of its rules in the order `needs_attention` > `at_risk` > `insufficient_data` > `on_track` > `secure`; `secure` drops to `on_track` if any rule of the area is not configured. |
| **Urgency tier** | 1 = protection and liquidity breaches with ≥ 1 dependent; 2 = the same without dependents, and debt rules; 3 = concentration; 4 = data. |
| **Confidence** | `low` (undecided or resting on a bound), `medium` (uses estimated, manual or stale values, or anything is missing), else `high`. |

## Constants and configuration (single home)

Every `finance.*` and `prices.*` key. `required — no default` keys make the
dependent calculation `needs_input` (or, for rule thresholds, the rule *not
evaluated*) until set.

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `finance.disclaimer` | every finance output | text | "Planning estimate from your own data, not a guarantee or regulated financial advice." | build |
| `finance.taxDisclaimer` | tax report | text | "Estimate from your documents and the tax rules you verified — not tax filing advice." | build |
| `finance.arithmeticDigits` | engine | significant decimal digits | `34` (no binary floats) | build |
| `finance.moneyRounding` | engine output | rule | 2 dp, half-up, at output only; required monthly contribution rounded **up** to the paisa | build |
| `finance.ratioDecimals` | engine output | dp | `4` | build |
| `finance.projectionMonthlyRate` | projections, goals | formula | effective: `(1 + r_a)^(1/12) − 1` | build |
| `finance.loanMonthlyRate` | loans | formula | nominal: `r_a / 12` (Indian reducing balance) | build |
| `finance.contributionTiming` | projections, goals | rule | end of each month; step-up applied at months 13, 25, … | build |
| `finance.loanMaxPayoffMonths` | loans | months | `1200` | build |
| `finance.rates.*` (return, inflation, step-up, category growth per scenario) | projections | annual decimal fraction | `required — no default` | owner |
| `finance.projectionHorizonsMonths` | projections | list of months | `required — no default` | owner |
| `finance.monthlyBudget` | goal plan | rupees | `required — no default` | owner |
| `finance.stress.withdrawalHaircut` | stress | fraction per liquidity tier | `required — no default` | owner |
| `finance.reserveTargetMonths` | emergency-reserve rule | months | optional; rule not evaluated when unset | owner |
| `finance.rules.*` (term-life multiple, health cover minimum, liquidity-mix minimum, debt-service maximum, high-interest rate, concentration maximum, `timeToActDays`) | recommendations | per rule | optional; rule not evaluated when unset | owner |
| `finance.staleAfterDays` | freshness | days | `required — no default` | owner |
| `finance.priceStaleAfterDays` | freshness | days | `required — no default` once any units are tracked | owner |
| `finance.autoApply` | review queue | bool per source / rule | `false` | owner |
| `finance.inbox.readFrom` | mailbox connector | date per mailbox | `required — no default` | owner |
| `finance.connectors.dailyRunTime` | home server | local time | `required — no default` | owner |
| `finance.importPdfMaxBytes` | document imports | bytes | `10 MB` | build |
| `finance.statements.excludeTransfers` | statement analysis | bool | `required — no default` | owner |
| `finance.statements.recurringAmountTolerance` | statement analysis | fraction of the typical amount | `required — no default` | owner |
| `finance.statements.recurringMinMonths` | statement analysis | months | `required — no default` | owner |
| `finance.statements.recurringDayWindow` | statement analysis | days | `required — no default` | owner |
| `finance.statements.irregularMinMonths` | statement analysis | months | `required — no default` (to use yearly/occasional treatments) | owner |
| `finance.spending.driftBaselineMonths` | spending insights | full months | `required — no default` | owner |
| `finance.spending.driftThresholdPct` | spending insights | percent | `required — no default` | owner |
| `prices.maxFetchesPerDay` | price fetch | per source | `1` | build |
| `prices.minSecondsBetweenRequests` | price fetch | seconds per host | `5` | build |

## Data model (high level)

Entities and ownership rules: product-spec §10.1–10.3. Data documents:

| Document | Holds | Written by |
| --- | --- | --- |
| Position | `as_of`, items (with optional holdings), cash-flow lines (`amount: null` = unknown), protection, known gaps | owner edits; applied drafts |
| Loan | principal, rate or remaining months, EMI, prepayments | owner |
| Assumptions | scenario rates, inflation, horizons, stress, reserve target, purchase plans, retirement plans, sensitivity | owner |
| Planning | dependents, rules, goals, monthly budget | owner |
| Statement categories | category rules, overrides, recurring and irregular settings | owner |
| Snapshots | dated copies of the position | owner action |
| Price book | dated prices and FX for the owner's instruments | price fetch / owner import |
| Review queue | drafts from connectors and imports | connectors, imports |

Every calculation returns the [calculation envelope](../../life-os/spec/box-contract.md#calculation-envelope).

## Non-functional requirements

| Area | Requirement |
| --- | --- |
| Correctness | Every formula tested against independent cases; conventions listed in every result. |
| Reproducibility | `inputs` + `engine_version` reproduce any result. |
| Read-only | No capability to move money, place orders, redeem or change account settings exists (a technical boundary, not an instruction). |
| Privacy | As Life OS: [privacy-security.md](../../life-os/spec/privacy-security.md). |
| Offline / performance / accessibility | As Life OS: [spec/README.md](../../life-os/spec/README.md#non-functional-requirements). |

## Worked example

Goal funding (synthetic): a car costing ₹10,00,000 today, needed in 24 months
(one stage); `finance.rates` inflation 6 % and funding return 7 % a year;
₹2,00,000 already allocated; no planned contribution.

| Step | Formula | Result |
| --- | --- | --- |
| Future cost | 10,00,000 × 1.06^(24/12) = 10,00,000 × 1.1236 | ₹11,23,600.00 |
| Required corpus at the first stage | one stage, so = future cost | ₹11,23,600.00 |
| Projected funds | 2,00,000 × 1.07^(24/12) = 2,00,000 × 1.1449 | ₹2,28,980.00 |
| Funding gap | 11,23,600.00 − 2,28,980.00 | ₹8,94,620.00 (`funded: false`) |
| Monthly rate | r_m = 1.07^(1/12) − 1 | ≈ 0.0056541 |
| Required monthly contribution | (11,23,600 − 2,00,000 × (1 + r_m)^24) × r_m / ((1 + r_m)^24 − 1) = 8,94,620 × r_m / 0.1449 = 34,908.982… → rounded up | ₹34,908.99 |

(1 + r_m)^24 = 1.07² = 1.1449 exactly, so (1 + r_m)^24 − 1 = 0.1449.
A second worked example — EPF growth under both monthly-rate conventions — is
in product-spec §4.1.

## Open questions

- `TODO(spec, blocks: M4)` — Bank data through Account Aggregator via a
  regulated partner (only regulated Financial Information Users can request
  AA data)? **Default:** no; statements, alert messages and public prices
  only.
- `TODO(spec, blocks: Later)` — Statutory EPF/NPS contribution and withdrawal
  rules in projections? **Default:** owner-entered contribution and growth
  inputs only, until a verified, versioned rule set exists (same verification
  rule as tax rule sets).
- `TODO(spec, blocks: Later)` — Regulatory posture if the app is ever used by
  anyone other than its owner? **Default:** stay single-owner; outputs remain
  planning assessments; review Indian investment-advisory and data-protection
  duties before any sharing.

## Out of scope

Payments, trading, redemptions or any account write; tax filing; automatic
property valuation; detailed business accounting; family sharing UI and
consolidated family wealth (data model only); autonomous AI actions.
