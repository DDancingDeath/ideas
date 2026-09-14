# AadhatManagement

> A Hindi/English-bilingual business management app for a small
> wholesale/retail shop. One owner + a couple of staff run the day on a
> phone or tablet: billing, sales, stock, cash, outstanding (udhaar),
> reports. Bluetooth thermal printing. Works offline-tolerantly. In
> production since 2025 and used daily by the owner's family business.

- **Live code repo:** <https://github.com/DDancingDeath/AadhatManagementApp>
- **Staging mirror (private):** `DDancingDeath/AadhatManagementApp-staging`
  — these docs were authored there.
- **Status:** in production. v1 spec is essentially frozen; **security
  hardening + refactor pending** (see [`plan/review-issues.md`](./plan/review-issues.md)
  — XSS and Firestore-rule weaknesses are the priority backlog).
  A **from-scratch v2 rebuild** is now scoped — see
  [`spec/rebuild/`](./spec/rebuild/) and [`plan/rebuild/`](./plan/rebuild/).
  To **start building v2**, begin at
  [`plan/rebuild/getting-started.md`](./plan/rebuild/getting-started.md)
  (the Day-0 sequencer).

---

## The idea

Small wholesale/retail shops in India run on paper ledgers plus WhatsApp.
Real pains:

- **Stock is unknown until sale time.** Owner discovers shortages when a
  customer is already at the counter.
- **Outstanding (udhaar) is scattered.** Across notebooks, phone memory,
  and "I'll remember it."
- **Cash drawer mismatches** at end-of-day with no audit trail.
- **Generic ERPs are too expensive, English-only, and Windows-bound.** Not
  designed for a Hindi-first shop floor.
- **Family + staff need different slices** of the same data with
  different permissions — but most low-end POS apps have a single
  shared password.

AadhatManagement is the answer for *this* shop. Mobile-first, bilingual
labels everywhere (no separate locale toggle), three roles with real UI
gating (owner / manager / staff), live dashboards on Firestore
`onSnapshot` so the screen never lies. Anti-users: multi-branch chains,
GST-filing automation, anyone needing iOS or desktop-first.

Deeper detail: [`idea.md`](./idea.md).

---

## How it works

A single-page web app served from Firebase Hosting, wrapped with
Capacitor 7 to run on Android and access Bluetooth printers. Data lives
in Firebase Firestore; the app subscribes to seven `onSnapshot`
listeners so every screen recomputes when anything changes.

```
┌──────────────────────┐                  ┌──────────────────────┐
│  Android phone /     │  Capacitor 7     │  Bluetooth ESC/POS   │
│  tablet (or PWA in   │  ──────────────▶ │  thermal printer     │
│  browser)            │                  │  (Capacitor BLE)     │
└──────────┬───────────┘                  └──────────────────────┘
           │
           │  onSnapshot listeners (items, purchases, retail/wholesale
           │  sales, expenses, stockAdjustments, withdrawals,
           │  cashSessions)
           ▼
┌──────────────────────┐                  ┌──────────────────────┐
│  Firebase Firestore  │  Firebase Auth   │  3 roles:            │
│  9 collections,      │ ───────────────▶ │  owner / manager     │
│  `dev_`-prefix env   │                  │  / staff             │
│  switching           │                  │  (UI + design rules) │
└──────────────────────┘                  └──────────────────────┘
```

**One shared math helper.** Finance, Reports, and Analytics all delegate
to `PeriodMath` for every number on screen — date ranges, cash on hand,
stock value, outstanding, period revenue, payment split. If two of those
three pages disagree on the same number, the bug is in whichever caller
bypassed `PeriodMath`. (See [`spec/page-specs/README.md`](./spec/page-specs/README.md),
"Shared math".)

**Environment switching by collection prefix.** `?env=development` or
`localhost` auto-detection makes the app talk to `dev_purchases`,
`dev_retailSales`, etc. — same Firebase project, isolated data. Cheap,
effective, no second project to manage.

**Voice billing.** Tap-to-talk Hindi+English voice entry on the billing
page is live (v1, commit `56e230f`). V2 is in design — multi-item one-
breath bills, hands-free verification, wider Hindi number vocabulary —
see [`spec/voice-billing-v2.md`](./spec/voice-billing-v2.md).

---

## What it does today

Headline capabilities (full inventory in [`spec/capabilities.md`](./spec/capabilities.md)):

- **Billing** (retail + wholesale) with item lookup, weight chips, draft
  bills, ESC/POS print, voice entry.
- **Stock** — live computed from purchases − sales + adjustments; never
  stored, never stale.
- **Cash management** — sign-in / sign-out sessions, opening + closing
  count, drawer reconciliation, day close.
- **Outstanding** — per-customer/supplier ledger; payable and receivable
  in one view.
- **Reports + Analytics + Finance** — daily / weekly / monthly /
  custom; charts; CSV export.
- **Audit log** — owner-only 90-day immutable trail of every critical
  action.
- **Mobile polish** — haptics, pull-to-refresh, toasts; details in
  [`spec/mobile-enhancements.md`](./spec/mobile-enhancements.md).

---

## What v2 (the rebuild) changes

The owner is now scoping a from-scratch rebuild that takes the v1
app as the behavioural reference but is free to change layout,
tech, data shape, and logic where it improves correctness, speed,
or testability. The full spec subtree is at
[`spec/rebuild/`](./spec/rebuild/); opinionated material (roadmap,
agent roster, tech candidates, productization) is at
[`plan/rebuild/`](./plan/rebuild/).

The non-negotiable shifts for v2:

- **Test-first.** Every feature lands with unit, scenario,
  invariant, integration, security, perf, and E2E coverage. Tests
  are not allowed to be weakened to make implementation pass. See
  [`spec/rebuild/quality-bar.md`](./spec/rebuild/quality-bar.md).
- **Event ledger, projections derived.** Stock, cash, outstanding,
  reports, and audit are folds over an append-only event log; no
  silent edits or deletes. See
  [`spec/rebuild/event-ledger.md`](./spec/rebuild/event-ledger.md).
- **Billing and printing are separate.** One user intent = one
  bill, forever. Double-tap, slow Bluetooth, retry, and offline
  replay can never create a duplicate sale. See
  [`spec/rebuild/bill-lifecycle.md`](./spec/rebuild/bill-lifecycle.md)
  and [`spec/rebuild/print-queue.md`](./spec/rebuild/print-queue.md).
- **UI never owns business truth.** A pure domain core computes all
  money math; UI calls services and renders. See
  [`spec/rebuild/architecture.md`](./spec/rebuild/architecture.md).
- **Suspicious data is flagged, never silent.** A suspicion engine
  watches every write; flags route to a new Review Queue page the
  brother / owner uses to monitor the shop. See
  [`spec/rebuild/suspicion-engine.md`](./spec/rebuild/suspicion-engine.md)
  and [`spec/rebuild/review-queue.md`](./spec/rebuild/review-queue.md).
- **Server-side authorization, always.** UI permission checks are
  UX only. See [`spec/rebuild/invariants.md`](./spec/rebuild/invariants.md)
  §Authorization.
- **Shop-1 first, productize later.** Custom for the family shop
  now; designed so generalization to other shops is a configuration
  change, not a rewrite. See
  [`spec/rebuild/scope-boundaries.md`](./spec/rebuild/scope-boundaries.md)
  and [`plan/rebuild/productize-later.md`](./plan/rebuild/productize-later.md).

The build prompt for v2 is
[`prompts/build-rebuild.md`](./prompts/build-rebuild.md). For a v1
reference rebuild, use
[`prompts/build-from-spec.md`](./prompts/build-from-spec.md).

**Pages at a glance** (17 page-specs total, full contracts in
[`spec/page-specs/`](./spec/page-specs/)):

| # | Page | Owner-only |
|---|---|---|
| 0 | Login / Register | — |
| 1 | Today | — |
| 2 | Billing | — |
| 3 | Wholesale Sales | — |
| 4 | Expenses | — |
| 5 | Items | — |
| 6 | History | — |
| 7 | Stocks | — |
| 8 | Outstanding | — |
| 9 | Finance | — |
| 10 | Reports | — |
| 11 | Analytics | — |
| 12 | Admin | **yes** |
| 13 | Diagnostics | **yes** |
| 14 | Settings | — |
| 15 | AI Assistant | — |
| 16 | Cash Management *(embedded in Today)* | — |

---

## Tech stack (current implementation)

| Layer | Choice | Negotiable? |
|---|---|---|
| Frontend | Vanilla ES6 modules | Yes — Lit/Svelte plausible |
| Data | Firebase Firestore (compat SDK) | **No — data shape is part of the spec** |
| Auth | Firebase Auth (email/password) | Yes |
| Mobile | Capacitor 7.x (Android) | Yes |
| Hosting | Firebase Hosting | Yes |
| Printing | Bluetooth ESC/POS via Capacitor BLE | **No — required** |
| Testing | Jest + Babel | Yes |
| i18n | Inline `Hindi / English` labels | Yes |

**The Firestore collection shape and the three-role model are part of
the spec** — see [`spec/firestore-rules-design.md`](./spec/firestore-rules-design.md).
The shipped Firestore rules are intentionally weaker than that design
while the app stabilizes; new work must move toward the design, not away
from it.

---

## Known issues (do not reintroduce)

Full list: [`plan/review-issues.md`](./plan/review-issues.md). The
priority ones:

- **Stored XSS** — 144 + `innerHTML` interpolations of user-controlled
  data across 19 files; only 5 are escaped. Worst sink:
  `diagnostics.js:328` (`<strong>${log.userName}</strong>`) which gives
  staff → owner privilege escalation via audit log injection.
- **Firestore rules are too permissive** — `allow read, write: if
  isSignedIn()` on financial collections means a staff user with the
  API can bypass UI role checks and write anywhere. The shipped rules
  vs. the designed rules diverge; see
  [`spec/firestore-rules-design.md`](./spec/firestore-rules-design.md).
- **Audit-log cleanup is dead code** — `auditLogs` has `allow update,
  delete: if false` but cleanup batches try to delete; fails silently
  every owner login.
- **CI is broken** — workflows run `npm ci && npm run build` but there
  is no `build` script and `npm ci` fails on `canvas` peer dep.
- **Service worker install fails** — STATIC_ASSETS lists files that no
  longer exist; `cache.addAll` is atomic, so offline support doesn't
  work despite README claiming it does.

---

## Reading order

Three tracks, listed file-by-file with line counts in
[`READING-TRACKS.md`](./READING-TRACKS.md):

- **Owner** (~1 500 lines) — what the app promises and what it refuses to
  let happen: this README, [`idea.md`](./idea.md),
  [`scope-boundaries.md`](./spec/rebuild/scope-boundaries.md),
  [`suspicion-engine.md`](./spec/rebuild/suspicion-engine.md),
  [`role-permission-matrix.md`](./spec/rebuild/role-permission-matrix.md),
  [`analytics.md`](./spec/rebuild/analytics.md),
  [`decisions.md`](./plan/rebuild/decisions.md),
  [`roadmap.md`](./plan/rebuild/roadmap.md).
- **Engineer** (~900 lines) — whether the design holds up: the
  [index](./spec/rebuild/README.md),
  [`worked-example.md`](./spec/rebuild/worked-example.md),
  [`invariants.md`](./spec/rebuild/invariants.md),
  [`architecture.md`](./spec/rebuild/architecture.md),
  [`event-ledger.md`](./spec/rebuild/event-ledger.md).
- **Agent** — everything. Enter at
  [`spec/rebuild/README.md`](./spec/rebuild/README.md) and follow its order;
  [`spec/README.md`](./spec/README.md) covers the v1 docs.

**Ten-minute version (~390 lines):** the index → the worked example → the
`Constitution` table at the top of `invariants.md`.

**Building v2?** Start with
[`prompts/rebuild-m0-foundation.md`](./prompts/rebuild-m0-foundation.md) for
the M0 scaffolding milestone, then
[`prompts/build-rebuild.md`](./prompts/build-rebuild.md) for M1 onward. Both
thread through `spec/rebuild/` and `plan/rebuild/` in the right order. For a
v1 reference rebuild use
[`prompts/build-from-spec.md`](./prompts/build-from-spec.md).

## Layout

```
aadhat-management/
├── README.md                       ← (this doc) narrative entry point
├── idea.md                         ← vision in detail
├── spec/
│   ├── README.md
│   ├── capabilities.md
│   ├── chat-design.md
│   ├── firestore-rules-design.md
│   ├── mobile-enhancements.md
│   ├── voice-billing-v2.md
│   ├── page-specs/                 ← 17 per-page contracts + README (v1)
│   └── rebuild/                    ← v2 rebuild spec (architecture,
│                                     platform compatibility,
│                                     event ledger, event schemas,
│                                     time & clock, money/units/
│                                     rounding, bill lifecycle,
│                                     idempotency, print queue,
│                                     printer compatibility,
│                                     projections, data placement,
│                                     analytics, offline-sync,
│                                     concurrency,
│                                     invariants (with constitution
│                                     and calculation integrity),
│                                     role matrix, suspicion engine,
│                                     Review Queue, failure modes,
│                                     versioning & compatibility,
│                                     data governance (with
│                                     validation gates),
│                                     observability, ai boundaries,
│                                     ergonomics, scenarios, perf
│                                     budgets, quality bar, feature
│                                     acceptance, CI contract,
│                                     platform test matrix, worked
│                                     example)
├── plan/
│   ├── review-issues.md
│   ├── promotion.md
│   ├── staging-smoke-checklist.md
│   ├── legacy-agents-orientation.md
│   ├── setup/                      ← env, printer, firebase, staging
│   └── rebuild/                    ← v2 roadmap, decisions, agent
│                                     roster, tech candidates,
│                                     migration & cutover,
│                                     operations runbook,
│                                     backup & restore,
│                                     release health gates,
│                                     productize-later
├── prompts/
│   ├── build-from-spec.md          ← v1 reference rebuild
│   ├── build-rebuild.md            ← v2 milestones M1+
│   └── rebuild-m0-foundation.md    ← v2 M0 foundation
└── assets/                         ← mockups / screenshots / diagrams
```

## Notes on these docs

- The docs in `spec/` and `plan/` were authored against the staging
  repo's `docs/` folder. Some internal links inside them still
  reference the original repo paths (e.g. `docs/CAPABILITIES.md`,
  `www/js/...`). Treat those as historical pointers; the canonical
  location is now this folder. The spec/README has a full re-map table.

## Recent changes

- _2026-09-14_ · **Closed the v1 parity gaps that were blocking UI design.**
  Specified drawer reconciliation (counted cash, signed mismatch, tolerance bands,
  Review-Queue resolution — the spec previously defined only the *expected*
  closing figure, so the screen meant to catch a drawer mismatch could not be
  drawn), plus cash deposits, session notes, session-history detail, oversell
  confirmation (wholesale-only; retail has no oversell case under `S3`), the
  print-comments flag, and draft line edit/delete. Placed the four unbucketed v1
  features — frequency-sorted item dropdown to **Core**, since billing works today
  and the ordering is what makes it fast. Orphan stock buckets needed nothing:
  already designed out by the entity-by-id rule.

- _2026-09-14_ · **Spec finalization closed.** All fifteen `Default: none agreed`
  questions are answered and asserted as fact; zero none-agreed, zero malformed
  and zero ⚠ provisional markers remain. Adopted at the recommended defaults and
  recorded as [`decisions.md`](./plan/rebuild/decisions.md) rows S1–S19 with
  status `tentative` — the agent's default, unreviewed — so each is a one-line
  override. Material changes: `maxRateMultiple` 5→2, offline bill blocks are
  per-device not per-session (per-session breaks invariant `B5`),
  `item_rate_changed` and `shop_timezone_changed` frozen into v2.0 with full
  schemas while four other proposed types defer to v2.1 (24 event types total),
  a flat `maxDiscountBps` replacing the per-role map, parties entering the ledger
  implicitly, and the print marker persisted rather than in-memory. 76 TODO(spec)
  items remain, all milestone-scoped with concrete defaults — questions to confirm
  at their milestone, not holes.

- _2026-09-14_ · Added a **design-system decision brief**
  ([`plan/rebuild/design-system-decision.md`](./plan/rebuild/design-system-decision.md))
  for step 4 of Happa's build order. Reframes the Fluent-vs-Material question:
  with SvelteKit already frozen (`decisions.md` row 1), neither candidate ships a
  component library worth using, so either answer means building our own set —
  which `ui-standards.md` requires anyway. The real question is which language to
  borrow tokens, metrics and interaction patterns from. Recommends Material 3 for
  interaction and accessibility metrics (it is what Android and the users' other
  apps speak, and `ergonomics.md` already cites it for the 48 dp rule), Fluent's
  discipline for how the token layer is built, and our own components either way.

- _2026-09-14_ · Added the three missing **labor-charge settings** to
  [`spec/rebuild/configuration.md`](./spec/rebuild/configuration.md) —
  `labor.heavyPacketThresholdMg` (30 kg), `labor.ratePerHeavyPacketPaise` (₹6) and
  `labor.autoCalculateDefault` (`true`). They are owner-tunable in the live app and
  feed invariant `M3`, where labor is *deducted* from the supplier's payment, but
  the registry's 34 keys did not include them even though
  `scope-boundaries.md:55` names them as in-scope. Gap A7 from the coverage audit.

- _2026-09-14_ · **v1 → v2 feature coverage audit**
  ([`plan/rebuild/v1-coverage-audit.md`](./plan/rebuild/v1-coverage-audit.md)).
  Read all 93 files / ~29 000 lines of the live app against the spec. Split by the
  owner's assessment that Stock, Finance, Analytics and Reports do not work well
  in v1 — parity is the goal only for the pages that do work, and the weak four
  are redesigned from requirements rather than matched. Result: 14 parity gaps
  (drawer reconciliation, cash deposits, session notes, retail oversell warning,
  print-comments flag, bill-line edit/delete, labor-charge config keys and more),
  8 items on the weak pages kept as requirements, and 5 already-declared scope
  drops needing owner confirmation. Also confirmed three non-gaps: purchase is a
  mode inside `02-billing.md`, `configure.html` is dead markup whose settings
  moved to `admin.js`, and v1 having no print queue is an improvement in v2.

- _2026-09-14_ · **Spec finalization pass (Happa step 2).** Reshaped all 97 open
  `TODO(spec)` items into the reviewable form — question, blocking milestone,
  recommended default — so none is a bare marker; 82 now carry a concrete default
  and are adopted unless the owner objects. Closed two that were already settled
  and had gone stale (the reference device, `decisions.md` row 6; and v1 data
  import on cutover, row 10). The remaining 15 genuine questions, plus the 5 ⚠
  provisional config values and 3 known contradictions, are batched for a single
  owner pass in
  [`plan/rebuild/spec-finalization.md`](./plan/rebuild/spec-finalization.md) —
  each with a recommendation, so "all recommendations accepted" closes the step.

- _2026-09-12_ · Demoted six values in
  [`spec/rebuild/configuration.md`](./spec/rebuild/configuration.md) that had been
  written down by reading a prior build attempt rather than decided on their merits.
  Five are now marked ⚠ **provisional** with a section stating exactly what each
  still needs confirmed (`time.maxFutureMin`, `pricing.maxRateMultiple`,
  `printer.maxRetries`, `stock.negativeBlockMg`, `stock.adjustmentLargeMg`) — safe
  to build against, not settled. `cash.mismatchLarge` reverted to ₹200, the only
  figure anyone signed off on (`decisions.md` M8); the ₹500 alternative came from
  that same non-authoritative attempt and carried no recorded reasoning. A
  fabricated justification ("day-to-day experience at the shop points to ₹500")
  was removed — it was invented to avoid citing code and was worse than the
  citation.

- _2026-09-12_ · Established a **one-way dependency**: a project references this
  idea, never the reverse. The spec no longer cites, tracks, or defers to any
  implementation — it is normative on its own authority. Rule added to repo
  [`AGENTS.md`](../../../AGENTS.md).
- _2026-09-12_ · Corrected six values in
  [`spec/rebuild/configuration.md`](./spec/rebuild/configuration.md) that had been
  populated from spec and plan prose and were wrong on inspection:
  `time.maxFutureMin` 5→60, `pricing.maxRateMultiple` 2→5, `printer.maxRetries`
  now 3 retries (4 attempts), `stock.adjustmentLargeMg` 10→20 kg, and
  `stock.negativeBlockMg` confirmed at 5 kg. Two values are recorded as open
  questions with recommended defaults rather than asserted: `cash.mismatchLarge`
  (₹500 recommended, superseding `decisions.md` M8's ₹200) and
  `pricing.maxDiscountPctByRole` (flat 10% cap recommended over a per-role map).

- _2026-09-12_ · Encoded a **crispness contract** into the spec-authoring
  agents after a full-tree review found four structural defects (decisions
  frozen in `plan/` never propagated into `spec/`; no config registry for 37
  `shopProfile.*` keys; two severity scales with no mapping; worked examples
  contradicting their own invariants). Nine rules now live in repo
  [`AGENTS.md`](../../../AGENTS.md); the Spec and Reviewer prompts in
  [`plan/rebuild/agent-roster.md`](./plan/rebuild/agent-roster.md) carry them
  with the concrete failure behind each; `agent-orchestration.md` requires
  decision→spec propagation in one commit; `ci-contract.md` job 12 now lints
  the contract instead of mandating per-file changelogs. Review report:
  spec-crispness-review (session artifact).

- _2026-06-20_ · `event-schemas.md` · added optional `payee` (who was paid) to
  `expense_recorded`, alongside the existing `note?`, to support v1's Expenses
  payee/person + reason fields (page-spec `04-expenses`); mirrors
  `withdrawal_recorded.payee`.
- _2026-06-20_ · Mined the (now-deleted) `AadhatManagementApp-staging` repo's
  May-2026 audit/fix pass for v2-relevant findings (most were already covered).
  Added the carried-over spec rules: **no ad-hoc date parsing**
  ([`spec/rebuild/time-clock.md`](./spec/rebuild/time-clock.md)), **mutate-by-id,
  not by rendered index** ([`spec/rebuild/ergonomics.md`](./spec/rebuild/ergonomics.md)),
  **App Check as a production gate**
  ([`spec/rebuild/data-governance.md`](./spec/rebuild/data-governance.md)),
  **usage-driven test priority** ([`spec/rebuild/quality-bar.md`](./spec/rebuild/quality-bar.md)),
  a **performance-diagnostics panel + local-first usage analytics**
  ([`spec/rebuild/observability.md`](./spec/rebuild/observability.md),
  [`spec/rebuild/performance-budgets.md`](./spec/rebuild/performance-budgets.md)),
  a **`users/{uid}/preferences`** Firestore rule
  ([`spec/firestore-rules-design.md`](./spec/firestore-rules-design.md)), and three
  voice-grammar refinements ([`spec/voice-billing-v2.md`](./spec/voice-billing-v2.md)).
  The v2-side correctness gaps it surfaced (caller-supplied bill numbers, UTC
  bill-date defaults, unpersisted per-bill settlement allocations, receipt ESC/POS
  hygiene) are implementation concerns, tracked wherever v2 is being built.
- _2026-06-16_ (later, 3) · Added a v2 **analytics** spec
  ([`spec/rebuild/analytics.md`](./spec/rebuild/analytics.md)) —
  forecasts, profit/margin trends, items-to-focus, dead stock,
  receivables/payables aging, customer concentration, payment-mix
  and peak-hour trends, smart suggestions — re-homing v1's
  forward-looking Analytics page on the ledger. Added a
  `## Calculation integrity` section to `invariants.md` (what does
  and does not catch a wrong number) and expanded the scenario
  Coverage-map gap list from 9 to 31 (calculation-edge and
  adversarial/fraud classes).
- _2026-06-16_ (later, 2) · Added an agent **orchestration** layer at
  [`plan/rebuild/agent-orchestration.md`](./plan/rebuild/agent-orchestration.md)
  — Orchestrator role, task-ticket format (one ticket = one branch =
  one PR), sub-agent fan-out / fan-in, the `paths` collision rule,
  the parallelization model, the milestone loop, and a recommended
  Copilot CLI host — resolving the roster's open "where the agents
  live" question.
- _2026-06-16_ (later) · Added a Day-0 **getting-started**
  sequencer at
  [`plan/rebuild/getting-started.md`](./plan/rebuild/getting-started.md)
  (readiness gate, prerequisites checklist, the first five steps)
  and pointed to it from the status line and the `plan/rebuild/`
  entry. Added a scenario `## Coverage map` and a `Rate history per
  item` projection, and ran a spec consistency clean-up (event-
  registry reconciliation, stale weight-unit TODO reframed, broken
  audit-log anchor fixed, clock-skew / backdate config-key
  drift flagged).
- _2026-06-16_ · Added the platform / accuracy / concurrency
  layer to the v2 rebuild spec in response to the owner's
  "web + Android + iOS, fast, always accurate" review. New under
  [`spec/rebuild/`](./spec/rebuild/):
  `platform-compatibility.md`, `printer-compatibility.md`,
  `money-units-rounding.md`, `time-clock.md`, `concurrency.md`,
  `platform-test-matrix.md`. New under
  [`plan/rebuild/`](./plan/rebuild/):
  `release-health-gates.md` (the 10-gate pre-release checklist).
  Extended `spec/rebuild/invariants.md` with a `## Constitution`
  section summarising AC1–AC8 and mapping each to the
  M / S / C / B / R label that enforces it (no standalone
  `accuracy-contract.md` — kept as a summary inside `invariants.md`
  to avoid duplication drift). Extended
  `spec/rebuild/data-governance.md` with a `## Validation gates`
  section mapping master-data quality rules (duplicate item /
  party detection, impossible rates, empty names, archived item
  in bill, rate-flapping, merge contracts) to adapter result
  codes and UI-level recoveries. iOS is documented as a v2.1
  stretch target with named gates (BLE Classic SPP, WebKit
  IndexedDB eviction, background BLE); v2.0 stays web + Android.
- _2026-06-15_ (later same day) · Added the operational-concerns
  layer to the v2 rebuild spec in response to the owner's
  "what about offline, failures, observability, governance,
  ergonomics, AI?" review. New under
  [`spec/rebuild/`](./spec/rebuild/):
  `data-placement.md`, `offline-sync.md`, `failure-modes.md`,
  `versioning-compatibility.md`, `data-governance.md`,
  `observability.md`, `ai-boundaries.md`, `ergonomics.md`.
  New under [`plan/rebuild/`](./plan/rebuild/):
  `operations-runbook.md` (daily / weekly / monthly checklists,
  12 failure procedures matched to the spec catalogue, release
  with rollback rules) and `backup-restore.md` (what / where /
  who can restore + the monthly drill that proves restore
  works). Extended `spec/rebuild/role-permission-matrix.md`
  with the staff edit-time-limit rule
  (`shopProfile.staff.editGraceMin`, default 5 min, enforced
  by the storage adapter). Re-framed the
  `spec/rebuild/performance-budgets.md` Save budget as three
  explicit thresholds (UI ≤ 100 ms / bill visible locally
  ≤ 300 ms / server-confirmed ≤ 500 ms) and added a
  `Required perf scenarios` table.
- _2026-06-15_ (later same day) · Added `spec/rebuild/ci-contract.md`
  (exact required CI jobs, canonical commands, baseline-bump
  protocol) and `spec/rebuild/worked-example.md` (one retail bill
  traced end-to-end). Added `prompts/rebuild-m0-foundation.md`
  for the implementation agent to take the rebuild repo from "no
  code" to "M0 green". Froze every row in
  `plan/rebuild/decisions.md` (1–10) to `confirmed` so M0 can
  begin: SvelteKit / Firebase-only / pnpm / `shopId` from day one
  (`shop-1`) / brother stays as `owner` for v2.0 / mid-range
  Android (₹15–20k) as perf reference / Firebase
  Crashlytics+Analytics for telemetry / integer milligrams for
  weight / open-session-window as the "today" boundary /
  snapshot import as the v1→v2 cutover strategy.
- _2026-06-15_ (later same day) · Made the v2 rebuild spec
  agent-ready. Added contract docs under
  [`spec/rebuild/`](./spec/rebuild/): `event-schemas.md` (22 event
  types with payload schemas and idempotency keys),
  `scenarios.md` (15 fixtures), `role-permission-matrix.md`,
  `idempotency.md`, `projections.md`, `performance-budgets.md`,
  `feature-acceptance.md`. Added under
  [`plan/rebuild/`](./plan/rebuild/): `decisions.md` (freeze list
  with agent-recommended defaults), `migration-cutover.md`
  (snapshot strategy, dual-run window, rollback). The rebuild
  README's reading order and the `prompts/build-rebuild.md`
  thread were updated to include the new docs.
- _2026-06-15_ · Scoped the **v2 rebuild**. Added
  [`spec/rebuild/`](./spec/rebuild/) with architecture, event ledger,
  bill lifecycle, print queue, invariants, suspicion engine,
  Review Queue, and quality bar; added [`plan/rebuild/`](./plan/rebuild/)
  with roadmap, agent roster, tech candidates, and productize-later
  guidance; added
  [`prompts/build-rebuild.md`](./prompts/build-rebuild.md). v1
  page-specs are unchanged and remain the behavioural reference
  for what runs in the family shop today.
- _2026-05-20_ · Brought in remaining docs from the staging mirror:
  `MOBILE_ENHANCEMENTS.md` → `spec/mobile-enhancements.md`; root-level
  `AGENTS.md` → `plan/legacy-agents-orientation.md`; setup notes
  (Bluetooth printer, environment, Firebase, staging-readme,
  staging-rules-patch) → `plan/setup/`. README rewritten as the
  narrative entry point.
- _2026-05-20_ · Added `spec/voice-billing-v2.md` — v2 design doc
  imported from the staging mirror's working tree (was uncommitted
  there).
- _2026-05-19_ · Initial import of spec + plan docs from
  `AadhatManagementApp-staging/docs/`.
