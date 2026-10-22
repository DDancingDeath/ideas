# Personal AI CFO

> A personal financial intelligence app that unifies your whole financial life, projects your future position with explicit assumptions and deterministic calculations, tests goals and life events, and gives prioritized, trustworthy recommendations - read-only, privacy-first, and designed to extend to family finances later.

It is also the **Finance box** of [Life OS](../life-os/), the personal life
hub; the hub's Ask box uses these calculations for cross-area questions.

---

## The idea

Personal finances are scattered across banks, EPF, NPS, mutual funds, shares,
loans and insurance. Expense trackers show the past; chatbots answer with
numbers nobody can check. Nothing tells an individual in India where they
stand, where they are heading, whether a goal is affordable and what to do
next — from their own records, with the assumptions on the table.

Target users: one individual (primary); a household, joint owners and family
businesses later on the same data model. Not for people wanting trade
execution or generic AI financial advice.

Success: the five core questions (product-spec §1) answered from the owner's
records; every figure reproducible from its inputs and engine version; every
missing value shown as missing, never zero.

Non-goals: money movement of any kind, tax filing, unverifiable AI figures.

---

## How it works

```
 source documents · statements · alerts · prices      owner edits
              │ extract → validate → match → draft              │
              ▼                                                 ▼
        review queue ── owner applies ──►  position · loan · assumptions · planning
                                                   │
                                                   ▼
             deterministic engine (Decimal, schemas, conventions, inputs_sha256)
                                                   │
       net worth · cash flow · projections · scenarios · goals · stress · affordability
                     · ranked recommendations with assumptions and confidence
```

Every value keeps its source and observation date. The engine has no built-in
rates or thresholds: anything it needs and the owner has not given comes back
as `needs_input`.

---

## What it does today (and what's next)

Status: working build (as the Finance box of Life OS).

- Net worth (attributable vs gross), cash flow with known unknowns, loans with
  prepayment what-ifs, projections in three scenarios (nominal and real),
  goals with funding gaps, stress test, affordability, prepay vs invest,
  sensitivity, retirement corpus, ranked recommendations, history.
- Bank/card CSV import with confirmed column mapping, categories, recurring and
  yearly payments.
- Document imports: EPF passbook, payslip, mutual-fund CAS, NPS statement.
- Live data: daily NAV revaluation of held units, owner-imported share prices,
  read-only mailbox and SMS drafts into a review queue.

Next: real owner data; FD maturity reminders, spending insights and a tax
report (Life OS M5); statutory EPF/NPS rules later.

---

## Tech stack

Negotiable. Part of the contract: deterministic decimal engine, JSON Schemas
per calculation, the result envelope with `inputs_sha256` and
`engine_version`, and the conventions in [`spec/README.md`](./spec/README.md).
The Life OS build runs it locally (home server or in the browser).

---

## Reading order for an agent

1. `idea.md` — vision only.
2. `spec/README.md` — overview, glossary, configuration, worked example; then
   `spec/product-spec.md`.
3. `plan/README.md` — status, known issues, decision log. **Do not
   reintroduce** known issues.
4. `prompts/build-from-spec.md` — paste this to a coding agent.

## Layout

```
personal-ai-cfo/
├── README.md           ← (this doc) the narrative entry point
├── idea.md             ← vision in detail
├── spec/               ← README (registry, glossary) + product-spec.md
├── plan/               ← roadmap + known issues + decision log
├── prompts/            ← ready-to-paste agent prompts
└── assets/             ← mockups, screenshots, diagrams
```

## Recent changes

- _2026-10-17_ · initial scaffold
- _2026-10-22_ · spec §4.1: corrected the illustrative EPF projection to ₹73.26 lakh (5 y) / ₹1.368 crore (10 y) and stated the compounding convention (effective monthly rate, end-of-month contributions), with nominal r/12 figures for comparison
- _2026-10-22_ · README, spec/README (glossary, finance configuration registry with no-default keys, data model, NFRs, goal-funding worked example, open questions) and plan (status, milestones, decision log) filled in; noted as the Finance box of Life OS
- _2026-10-22_ · product-spec §7.1: Account Aggregator stated as unavailable to an individual's own app; share-price sources corrected; live data linked to the Life OS Finance box spec; §3.4 illustrative net-worth figure replaced by a placeholder; §12 marked as superseded by the local-first hosting decision
