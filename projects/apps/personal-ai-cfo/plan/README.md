# Build plan — Personal AI CFO

The plan answers **what to do next and in what order**, not what to build.
For "what to build", see [`../spec/`](../spec/README.md).

## Current status

Built as the Finance box of Life OS in the private repository
[`DDancingDeath/personal-ai-cfo`](https://github.com/DDancingDeath/personal-ai-cfo),
which owns code, issues and live status. As of 2026-10-22 the finance engine
(projections, scenarios, goals, loans, net worth, cash flow, analytics,
rule-based recommendations, goal plan, timeline), statement import and
spending analysis, document imports (EPF passbook, payslip, mutual-fund CAS,
NPS statement) and live data (daily NAV revaluation, owner-imported share
prices, read-only mailbox and SMS drafts with a review queue) are done. Real
owner data and assumptions are not yet entered.

## Roadmap

Milestone ids are shared with the [Life OS plan](../../life-os/plan/README.md).

| Milestone | Finance scope | Status (2026-10-22) |
| --- | --- | --- |
| M1 — Finance foundation | Projection engine, scenarios, goals, loans, net worth, cash flow, dashboard, analytics, planning, statement import | Done |
| M4 — Your data & personalisation | Owner data replaces illustrative assumptions; live data; document imports | Live data and imports done; owner data entry open; Account Aggregator decision open |
| M5 — Chief of staff | FD maturity reminders, spending insights, tax report (verified rule sets per assessment year), documents routed from the Documents box | Not started |
| Later | Statutory EPF/NPS rules; consolidated household wealth | Open |

## Backlog (unordered)

- Statutory EPF/NPS contribution and withdrawal rules (build #31).
- Salary growth and promotions in projections.
- Household (V2) views on the existing multi-owner data model.

## Known issues / debt

- Fixed, keep fixed: yearly and irregular payments skewing monthly averages
  (build #41); unreadable EPF passbook rows treated as zero (#66); chart axes
  labelling only start and end (#38); saves rewriting file formatting and two
  tabs overwriting each other (#37).

## Decision log

Append-only. Each entry: date · decision · rationale · alternatives considered.

- 2026-10-17 · Product spec imported as the source of truth · — · —
- 2026-10-22 · Projections use the effective monthly rate with end-of-month
  contributions; loans use the nominal r/12 convention · Matches how returns
  are quoted (annual effective) and how Indian lenders compute EMIs ·
  Considered: one convention for both.
- 2026-10-22 · No built-in rates, thresholds or reserve targets; unknown
  amounts are never zero · Trust · Considered: market-average defaults.
- 2026-10-22 · Finance is a box of Life OS; hub-level finance features are
  specified in the Life OS idea · One hub, one contract · Considered: a
  separate finance app.
- 2026-10-22 · Account Aggregator not available to an individual's own app;
  live data from statements, alerts and public prices; no scraping or portal
  credentials; NSE/BSE prices from owner-downloaded bhavcopies (automated
  download forbidden; broker APIs such as Kite Connect are paid) · Regulation,
  terms and cost · Considered: AA via a partner (open), broker API, scraping.
