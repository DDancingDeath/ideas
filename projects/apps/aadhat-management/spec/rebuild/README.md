# Spec — Rebuild (v2)

> **What this subtree is.** A from-scratch rebuild of AadhatManagement,
> taking the existing app as reference but free to change layout, tech,
> data shape, and logic where it improves correctness, speed, or
> testability. The owner's stated priority is **test-first business
> correctness**: if anything goes off, the app must flag it.
>
> **What this subtree is NOT.** A description of the live production
> app. The 17 page-specs in [`../page-specs/`](../page-specs/) remain
> the truth for what runs in the family shop today and are the
> behavioural reference for the rebuild ("does v2 still do this?").

## Reading order

Read top to bottom for a full picture. If you only have ten minutes, read
#33 `worked-example.md` first — one bill traced end to end makes the rest
click into place.

### Foundations

| # | Doc | What it settles |
|---|---|---|
| 1 | [`scope-boundaries.md`](./scope-boundaries.md) | Core vs configurable vs shop-custom vs explicitly out |
| 2 | [`architecture.md`](./architecture.md) | Layering: domain core → services → storage adapters → UI → devices. UI never owns business truth |
| 3a | [`navigation.md`](./navigation.md) | The page inventory, the bottom-nav destinations, and who sees each screen |
| 3 | [`platform-compatibility.md`](./platform-compatibility.md) | Per-platform capability matrix; iOS deferred to v2.1 with named gates; foreground/background/suspended contract; storage limits |

### Data and lifecycle

| # | Doc | What it settles |
|---|---|---|
| 4 | [`event-ledger.md`](./event-ledger.md) | Every business action is an immutable event; stock/cash/outstanding/reports are derived, never stored as authoritative |
| 5 | [`event-schemas.md`](./event-schemas.md) | Payload shape for each of the 22 event types: validation, examples, invariants applied, idempotency-key shape |
| 6 | [`time-clock.md`](./time-clock.md) | `at` (server, authoritative) vs `clientAt` (device, audit-only); skew bands; backdating flagged, future-dating blocked; shop day = open cash session |
| 7 | [`money-units-rounding.md`](./money-units-rounding.md) | Integer paise and milligrams; canonical line/bill formulas and their fixed application order; round-half-to-even; v1→v2 import conversion |
| 8 | [`configuration.md`](./configuration.md) | **Single home for every tunable** — type, unit, default, who may change it. Other docs reference a key and never restate its value |
| 9 | [`projections.md`](./projections.md) | Contract for every derived view (items, rate history, stock, cash, outstanding, history, reports, audit, Review Queue) and the rebuild/stale-detection process |
| 10 | [`data-placement.md`](./data-placement.md) | Where each datum lives: authoritative location, cache, sync rule, staleness tolerance, offline behaviour, read/write budgets |
| 11 | [`bill-lifecycle.md`](./bill-lifecycle.md) | Bill state machine and the billing-vs-printing separation — no double-tap, retry, or offline replay may create a duplicate sale |
| 12 | [`idempotency.md`](./idempotency.md) | `clientActionId` → `idempotencyKey` mapping, lifetimes, and every "what happens when…" case |
| 13 | [`print-queue.md`](./print-queue.md) | Background print queue contract; what the UI may and may not wait on |
| 14 | [`printer-compatibility.md`](./printer-compatibility.md) | Supported printers, paper widths, ESC/POS subset, Devanagari-always-bitmap, Android SPP pairing, duplicate-print prevention, manual fallback |
| 15 | [`offline-sync.md`](./offline-sync.md) | Per-action offline allowance; UI state vocabulary; retry/backoff budget; conflict handling; reconnect protocol |
| 16 | [`concurrency.md`](./concurrency.md) | Multi-device contract: shop-wide cash session (C3), bill-number allocation, rate-snapshot-at-intent, first-commit-wins with the loser surfaced in Review Queue |

### Correctness, monitoring, and access

| # | Doc | What it settles |
|---|---|---|
| 17 | [`invariants.md`](./invariants.md) | The business laws. Opens with the Constitution: eight AC rules mapped to the M/S/C/B/R label that enforces each |
| 18 | [`role-permission-matrix.md`](./role-permission-matrix.md) | Role × event-type and projection-read matrices, special principals, API-bypass guarantee, staff edit grace, owner-configurable role visibility (narrows the ceiling, never widens) |
| 19 | [`suspicion-engine.md`](./suspicion-engine.md) | Anomaly rules that turn "this looks off" into Review Queue items. Owns the one severity scale: `block`/`high`/`medium`/`low` |
| 20 | [`review-queue.md`](./review-queue.md) | The page owner/brother use to approve or dismiss anomalies. New in v2 |
| 21 | [`failure-modes.md`](./failure-modes.md) | 20 real-world failures (crash, dead battery, wrong clock, stale client, Firebase down, lost phone…) with expected and forbidden behaviour, plus the pinned test for each |
| 22 | [`versioning-compatibility.md`](./versioning-compatibility.md) | Three independent versions (`appVersion`, `schemaVersion`, `domainVersion`); support window and force-upgrade; additive vs breaking schema changes |
| 23 | [`data-governance.md`](./data-governance.md) | Ownership/access matrix (no deletes — corrections are events), PII inventory and retention, master-data governance, validation gates, bill numbering and legal posture |
| 24 | [`observability.md`](./observability.md) | Notification catalogue by severity/channel/audience; supportability surface; trace ids; one-tap debug bundle with PII exclusion |
| 25 | [`ai-boundaries.md`](./ai-boundaries.md) | AI may suggest, summarise, draft and voice-fill — always human-confirmed. It may never write an event unconfirmed, elevate permission, resolve a flag, or suppress one |
| 26 | [`ergonomics.md`](./ergonomics.md) | Shop-floor constraints: one-handed, sunlight, noise, Hindi-first, ₹15–20k phone; tap targets, WCAG AA contrast, two-step confirm only when destructive |
| 27 | [`analytics.md`](./analytics.md) | Business insights over the projections (forecasts, margins, dead stock, aging, concentration, payment mix, peak hours). Never owns an authoritative total |

### Quality, performance, definition of done

| # | Doc | What it settles |
|---|---|---|
| 28 | [`scenarios.md`](./scenarios.md) | 15 named fixtures of real shop workflows: setup, sequence, expected projections and flags, and the test layer each belongs to |
| 29 | [`performance-budgets.md`](./performance-budgets.md) | Concrete UI/print/sync numbers, the reference device, measurement methodology, required perf scenarios, CI gates |
| 30 | [`quality-bar.md`](./quality-bar.md) | Required test layers, the "no UI hang" bar, and what `done` means for a feature |
| 31 | [`feature-acceptance.md`](./feature-acceptance.md) | Per-feature required-test checklist by feature kind, with the PR template |
| 32 | [`ci-contract.md`](./ci-contract.md) | Required CI jobs, canonical commands, artefact contract, baseline-bump protocol |
| 33 | [`platform-test-matrix.md`](./platform-test-matrix.md) | Which surfaces run which jobs; manual smoke gates (`G-PRINT-PROD`, `G-OFFLINE-RECON`, `G-CASH-CYCLE`, `G-COLD-START`, `G-FORCE-UPGRADE`, `G-PWA-OWNER`, `G-PWA-SAFARI`); release-gate matrix; release-record manifest |
| 34 | [`worked-example.md`](./worked-example.md) | One retail bill traced end to end: UI intent → service → event → projection → print → audit → tests. **Read this first if you read nothing else.** |
| 35 | [`ui-standards.md`](./ui-standards.md) | Production-grade UI bar with v1 as the floor: design tokens, reusable components, bottom nav, every-state coverage, accessibility, UI definition of done |
| 36 | [`localization.md`](./localization.md) | Full Hindi/English via one runtime toggle: message catalog, Hindi-first authoring, v1 terminology, data-vs-chrome split, number/currency/date handling |

## Relationship to the v1 page-specs

The page-specs in [`../page-specs/`](../page-specs/) describe screens
and workflows from the production app. They remain the **behavioural
reference**: the rebuild must preserve every workflow that the family
shop currently relies on, unless this rebuild spec explicitly
supersedes it.

Where the rebuild changes a workflow, the new spec lives here and the
matching page-spec is left intact for historical comparison. Agents
implementing v2 must read both, treat this subtree as authoritative
where they disagree, and flag any conflict to the owner before acting.

## What is opinion (in `plan/rebuild/`)

Tech stack choices, agent roster, rebuild order, productization
strategy, and any "we recommend X" material live under
[`../../plan/rebuild/`](../../plan/rebuild/). This subtree stays
factual.

## Open questions

All ten freeze-list decisions in
[`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md)
were `confirmed` on 2026-06-15. The remaining open items are
milestone-specific (see the "Open questions that block specific
milestones" table in that file).
