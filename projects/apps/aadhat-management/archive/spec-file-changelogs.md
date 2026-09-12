# Archived per-file spec changelogs

Until 2026-09-12 every file in `spec/` carried its own `## Recent changes`
block — 567 lines across 33 files, enforced by `ci-contract.md` job 12.
The crispness contract now keeps a single changelog in the project README,
so those blocks were removed from the spec. They are preserved verbatim here.

## `spec/README.md`


- _2026-06-16_ (later) · Added `rebuild/analytics.md` (#34) — the v2
  business-analytics contract (forecasts, profit/margin trends,
  items-to-focus, dead stock, receivables/payables aging, customer
  concentration, payment-mix and peak-hour trends, smart
  suggestions) re-homing v1's forward-looking Analytics page on the
  ledger. Also added a `## Calculation integrity` section to
  `rebuild/invariants.md` and grew the `rebuild/scenarios.md`
  Coverage-map gap list from 9 to 31 scenarios.
- _2026-06-16_ · Added the platform / accuracy / concurrency
  layer to the v2 reading order. New under `spec/rebuild/`:
  `platform-compatibility.md` (item 4), `time-clock.md` (7),
  `money-units-rounding.md` (8), `printer-compatibility.md`
  (14), `concurrency.md` (16), `platform-test-matrix.md` (32).
  Extended `invariants.md` with a `## Constitution` section
  (AC1–AC8) and `data-governance.md` with a `## Validation
  gates` section. New under `plan/rebuild/`:
  `release-health-gates.md` (10-gate pre-release checklist).
  Updated the "Out of scope" iOS line to reflect "v2.0 not
  v2.1" rather than "iOS forever".
- _2026-06-15_ (later same day) · Added the operational-concerns
  layer to the v2 reading order: `data-placement.md`,
  `offline-sync.md`, `failure-modes.md`, `versioning-
  compatibility.md`, `data-governance.md`, `observability.md`,
  `ai-boundaries.md`, `ergonomics.md` under `spec/rebuild/`;
  `operations-runbook.md` and `backup-restore.md` under
  `plan/rebuild/`. Extended `role-permission-matrix.md` with
  the staff edit-time-limit rule; re-framed the Save perf budget
  as three explicit thresholds (UI ≤ 100 ms / bill visible
  locally ≤ 300 ms / server-confirmed ≤ 500 ms) and added a
  `Required perf scenarios` table.
- _2026-06-15_ (later same day) · Added `ci-contract.md` (exact
  required CI jobs and canonical commands) and `worked-example.md`
  (one retail bill traced end-to-end) to the v2 reading order.
- _2026-06-15_ (later same day) · Expanded the v2 rebuild reading
  order with the new contract docs (`event-schemas.md`,
  `projections.md`, `idempotency.md`, `role-permission-matrix.md`,
  `scenarios.md`, `performance-budgets.md`,
  `feature-acceptance.md`) and pointed to the plan-side
  `decisions.md` and `migration-cutover.md`.
- _2026-06-15_ · Added [`rebuild/`](../spec/rebuild/) — v2 rebuild spec
  subtree (architecture, event ledger, bill lifecycle, print queue,
  invariants, suspicion engine, Review Queue, quality bar). v1
  page-specs remain authoritative for the live app; rebuild docs
  are authoritative for the v2 rebuild.

## `spec/rebuild/ai-boundaries.md`


- _2026-06-15_ · file created. Allowed AI uses (explain,
  draft, search, voice fill — always suggestion-only);
  forbidden AI uses (no event without human confirm; no
  permission elevation; no flag resolve; no silent
  suppression); three contract rules
  (suggestion-not-action / same-permissions / transparent-
  attribution); drift and hallucination handling; required
  tests.

## `spec/rebuild/analytics.md`


- _2026-06-16_ · File created. Re-homes v1's forward-looking
  Analytics page on the v2 event ledger and adds the business
  analytics the owner asked for (receivables / payables aging,
  payment-mix and peak-hour trends, margin-per-item, dead-stock),
  each mapped to the projection and events behind it. Documents the
  retail-customer-attribution data limit explicitly. Replaces the
  bare period-binning stub that was the only analytics in
  `projections.md`.

## `spec/rebuild/architecture.md`


- _2026-06-17_ · Added `## Engineering conventions` — two cross-cutting
  guidelines the agents and code follow: (1) **entity identity** —
  reference every entity by a stable opaque id (`itemId`, `partyId`,
  `billId`, …), never by name (names are mutable display data; keying
  by name caused the v1 WALK-27 ghost-stock bug); (2) **robust data
  structures and algorithms** — keyed maps over name scans, no
  super-linear work on hot paths, exact integer money math with
  BigInt, deterministic/total algorithms (no NaN leaks), append-only
  immutable data, bound everything.

## `spec/rebuild/ci-contract.md`


- _2026-06-15_ · file created. Required jobs, nightly jobs,
  canonical commands, artefact contract, baseline-bump protocol,
  flakiness policy.

## `spec/rebuild/concurrency.md`


- _2026-06-16_ · file created. Cash session is shop-wide (C3);
  bill numbers server-side allocated with device-bound offline
  blocks; rate-snapshot-at-intent for in-progress bills;
  concurrent-sale-into-negative-stock accepted-and-flagged
  per S2; default rule "first server commit wins, losing
  write surfaces in Review Queue"; storage-adapter contract
  consolidated; cross-references offline-sync.md conflict
  matrix and idempotency.md.

## `spec/rebuild/data-governance.md`


- _2026-06-16_ (later) · §Rate change history now points to the new
  **Rate history per item** projection in
  [`projections.md`](../spec/rebuild/projections.md#rate-history-per-item), so
  "rate history" has a defined view (rate set-points with reasons +
  transacted buy / sell trend over time), not just the underlying
  events.
- _2026-06-16_ (later) · Removed a duplicated `## Recent changes`
  heading, and repointed the intro "audit log" link from the
  non-existent `review-queue.md#audit` anchor to
  [`projections.md#audit-log`](../spec/rebuild/projections.md#audit-log), where
  the audit-log projection is actually defined.
- _2026-06-16_ · added `## Validation gates` section between
  `## Master data governance` and `## Required tests`. Folds
  the data-quality-gates rules (duplicate item / party
  detection, impossible rate ceilings, empty-name rejection,
  archived item in bill, rate-flapping flag, merge contracts)
  into governance rather than spawning a separate file. Each
  rule maps to the canonical adapter result code
  (`SCHEMA_INVALID`, `BLOCKED_BY_RULE`,
  `INVARIANT_VIOLATION`, `REFERENCE_INVALID`,
  `PERMISSION_DENIED`) and to a UI-level recovery (merge,
  create-anyway-with-flag, unarchive-first). Required tests
  extended with gate-level cases.
- _2026-06-15_ · file created. Ownership / access matrix
  (delete is forbidden; corrections are events); minimised
  PII inventory with voice-transcript discard rule;
  master-data governance for merges, rate history, archive,
  typo correction, Hindi/English names; retention table;
  staff-leaves and lost-phone flows; export contract with
  audit-event coupling; bill-numbering and legal posture
  with GST out of scope; required tests.

## `spec/rebuild/data-placement.md`


- _2026-06-15_ · file created. Three-layer model (shared domain
  · app layer · server layer); per-data placement table with
  staleness tolerance and offline behaviour; read- and
  write-path budgets per data type; server-vs-app
  responsibilities table; offline contract with outbox
  retention; cache versioning by domain version.

## `spec/rebuild/ergonomics.md`


- _2026-06-15_ · file created. Shop-floor constraints
  (one-handed, sunlight, noisy, Hindi-first, ₹15–20k phone);
  tap-target floors (48 / 56 dp); WCAG AA contrast with
  icon-not-colour status; Hindi label sizing rules;
  two-step confirm only for destructive actions;
  single-tap Save / Print backed by idempotency; picker
  design; history row design; required tests.

## `spec/rebuild/event-ledger.md`


- _2026-06-16_ · Aligned the `print_attempt` summary row's `outcome`
  values from `(queued / sent / failed)` to
  `(queued / connecting / sending / failed)` so the at-a-glance
  table matches the canonical enum in
  [`event-schemas.md`](../spec/rebuild/event-schemas.md) §`print_attempt`. No
  behaviour change; the summary had simply drifted.

## `spec/rebuild/event-schemas.md`


- _2026-06-17_ · Extended `shop_profile_updated` validation for the
  new owner-configurable role layer: a `changes.roleConfig` patch is
  validated against the hard floors in `role-permission-matrix.md`
  §Owner-configurable role visibility & capabilities (grants beyond
  the matrix ceiling are clamped; floor violations are rejected with
  `SCHEMA_INVALID`). No new event type — role visibility rides the
  existing owner-only `shop_profile_updated`.
- _2026-06-16_ (later) · Reframed the stale weight-unit `TODO(spec)`
  in §Open questions from "decide kg vs mg before M0" to "decision is
  frozen (decisions row 8 = integer mg); migrate this file's kg
  schemas/examples to the mg model during M0". The decision was
  already frozen in `decisions.md` row 8 and
  [`money-units-rounding.md`](../spec/rebuild/money-units-rounding.md); only the
  literal schemas here still used kg. Annotated the `Quantity`
  primitive comment accordingly. No schema values changed.
- _2026-06-16_ · Added the `## Referenced events not yet specified
  here` reconciliation table. It names every event referenced by
  other rebuild docs that does not yet have a frozen schema here
  (`item_rate_changed`, `party_updated`, `item_merged`,
  `party_merged`, `print_manual_recorded`, `shop_timezone_changed`,
  and the proposed `overpayment_recorded`), so the canonical
  registry and the prose docs stop drifting. Also documented which
  referenced names are deliberately **not** ledger events
  (telemetry `screen_view` / `action_*`; the `print_failed` bill
  state) and flagged the missing `party_created` event as a
  `TODO(spec)`. No payloads were invented; all entries are
  `TODO(spec)` / Proposed.

## `spec/rebuild/failure-modes.md`


- _2026-06-15_ · file created. 20 failure modes with expected
  behaviour, forbidden behaviour, and pinned test fixture;
  universal rules; cross-links to print-queue, offline-sync,
  data-placement, versioning-compatibility, review-queue, and
  the operations runbook.

## `spec/rebuild/invariants.md`


- _2026-06-16_ (later) · Added `## Calculation integrity — what
  catches a wrong number`: an honest split between an *inconsistent*
  number (caught by reject-at-append + `recon.*` + the property test)
  and a *consistently-wrong shared formula* (caught only by fixtures
  with externally-known numbers + the independent closed-form
  rounding test). Makes explicit that calculation-edge fixture
  coverage is a correctness control, not just test hygiene.
- _2026-06-16_ (later) · Namespaced the T2 backdate-tolerance key to
  `shopProfile.time.backdateToleranceDays` (was the un-prefixed
  `shopProfile.backdateToleranceDays`) to match the
  `shopProfile.time.*` namespace used by the other clock keys in
  [`time-clock.md`](../spec/rebuild/time-clock.md) and
  [`suspicion-engine.md`](../spec/rebuild/suspicion-engine.md).
- _2026-06-16_ · added `## Constitution — the "no false data"
  rules` section at the top. Eight AC rules (AC1–AC8) restate
  the accuracy contract in plain language and map each to the
  M / S / C / B / R label that enforces it. The constitution is
  a summary, not an independent source of truth — changes flow
  from M/S/C/B/R rows into the AC summary, never the other way.


## `spec/rebuild/localization.md`


- _2026-06-18_ · File created. Makes a **full-app Hindi/English
  language toggle** a first-class requirement (the owner's
  "localization support" ask), superseding the earlier "inline
  bilingual, not a locale toggle" line in `scope-boundaries.md`.
  Specifies a key-based message catalog (single source, `{en, hi}`,
  CI-checked coverage), Hindi-first authoring, the rule to **adopt the
  v1 app's terminology** (no invented names like "udhaar"; a
  `TODO(spec)` table to fill verbatim from v1), the data-vs-chrome
  reconciliation (item names stay bilingual data; chrome is
  localized), number/currency/date handling, the toggle's behaviour
  and default, and the required tests. Cross-references
  `ui-standards.md`, `quality-bar.md`, `ergonomics.md`.
- _2026-06-18_ (later) · Filled the canonical terminology table verbatim
  from the v1 app's `navigation.html` (Today, Billing, **Sales** =
  wholesale, Purchase, **Stocks**, **Outstanding**, Items, Cash,
  Reports) — the `TODO(spec)` is closed. These names + the EN↔HI toggle
  are implemented in the `bahi` web app (`apps/web/src/lib/messages.ts`,
  `i18n.svelte.ts`) and locked by `apps/web/test/i18n.test.ts`.
- _2026-06-19_ · Added §"Item-name entry: auto-transliterate the other
  field" — typing one item name auto-fills the other (EN↔HI) as an
  **editable, best-effort** suggestion that never clobbers a manual edit;
  runs offline. Owner request ("if I added Mahua in English, Hindi should
  default to महुआ … should be modifiable"). Implemented in the Bahi Items
  screen with a unit test.

## `spec/rebuild/money-units-rounding.md`


- _2026-06-16_ · file created. Atomic units (paise / mg /
  paisePerKg / bps); rate representation (per-kg or
  per-piece, never both); line and bill total formulas with
  canonical application order; round-half-to-even rule;
  Indian display formatting; v1 → v2 conversion table with
  migration round-trip verification; required tests pinned to
  CI `unit` and `invariant` jobs.

## `spec/rebuild/observability.md`


- _2026-06-15_ · file created. Notification catalogue with
  severity / channel / audience; channels (in-app always, push
  / WhatsApp / email opt-in); idempotent delivery with
  high-severity bypass; supportability surface (app / device /
  user / network / outbox / queues / cache); trace ids;
  one-tap debug bundle with PII-exclusion contract;
  Crashlytics / Analytics PII boundary; required tests.

## `spec/rebuild/offline-sync.md`


- _2026-06-15_ · file created. Per-action allow / block matrix
  with offline rules; local UI state vocabulary
  (`Saved` / `Sync pending` / `Synced` / `Sync failed
  (retrying)` / `Needs review` / `Printed` / `Print failed`);
  exponential-backoff retry policy with 6-attempt budget;
  conflict handling matrix; reconnect protocol; required UI
  surfaces; ten required test fixtures.

## `spec/rebuild/performance-budgets.md`


- _2026-06-15_ (later same day) · Reframed the Save budget as
  three explicit thresholds (UI ≤ 100 ms / bill visible locally
  ≤ 300 ms / server-confirmed ≤ 500 ms) so the local-first
  contract from [`data-placement.md`](../spec/rebuild/data-placement.md) and
  [`offline-sync.md`](../spec/rebuild/offline-sync.md) is measurable. Added
  a `Required perf scenarios` table covering item-search-with-
  large-catalog, save-while-printer-disconnected, today-render-
  with-large-history, stock-search-with-large-items, cold-vs-
  warm startup, double-tap-under-slow-network, offline-burst
  reconnect, history at 1k / 5k / 20k rows, long-task-absence
  during billing, and concurrent-print-retry. Added the
  "Reports > 500 ms must show progress or run off-main-thread"
  UX rule under Read pages.

## `spec/rebuild/platform-compatibility.md`


- _2026-06-16_ · file created. Per-platform capability matrix
  (Web/PWA / Android / iOS); iOS deferred to v2.1 with named
  gates (BLE Classic SPP, WebKit IndexedDB eviction, background
  BLE); foreground / background / suspended contract; storage
  limits per platform; forced-upgrade deep-link targets;
  required tests cross-linked to platform-test-matrix.

## `spec/rebuild/platform-test-matrix.md`


- _2026-06-16_ · file created. Eight physical surfaces
  (P1–P8); job-family × surface matrix; manual smoke gates
  G-PRINT-PROD / G-OFFLINE-RECON / G-CASH-CYCLE /
  G-COLD-START / G-FORCE-UPGRADE / G-PWA-OWNER /
  G-PWA-SAFARI; per-platform constraints; release-gate
  matrix by release type; release-record JSON manifest
  shape; explicit "not tested" list.

## `spec/rebuild/printer-compatibility.md`


- _2026-06-16_ · file created. Supported printer table with 58
  mm / 80 mm reference profiles; ESC/POS command subset;
  Devanagari = always bitmap rule; Android BT Classic SPP
  pairing path with foreground service + battery whitelist; iOS
  refused in v2.0 with v2.1 gate; PWA does not print directly;
  print timeouts table; retry behaviour anchored to
  print-queue.md and idempotency.md; four-layer duplicate-print
  prevention; manual-print fallback with audit event; required
  tests including production smoke gate.

## `spec/rebuild/projections.md`


- _2026-06-16_ · Added the **Rate history per item** projection
  (sources: `item_rate_changed` master set-points plus transacted
  `buy` / `sell` rates from purchase and sale lines), giving v2 an
  event-sourced home for tracking an item's price over time and
  carrying forward v1's Analytics "Rate Trends" — which the
  projection catalogue previously lacked. Added a required test. The
  exact view shape depends on finalizing the `item_rate_changed`
  schema (`TODO(spec)` in `event-schemas.md`).

## `spec/rebuild/quality-bar.md`


- _2026-06-17_ · Added a **selector convention** to §7 (E2E):
  Playwright flows select by stable `data-testid` / ARIA role, never
  by visible text, so the same flow passes unchanged in both
  Hindi-leading and English-leading label modes (the bilingual UI
  would otherwise make text selectors flaky). Every interactive
  control carries a `data-testid` as part of the feature.

## `spec/rebuild/README.md`


- _2026-06-18_ · Added two production docs and indexed them (34, 35):
  [`ui-standards.md`](../spec/rebuild/ui-standards.md) (production-grade UI bar — v1
  is the floor, with tokens/components/nav/states/accessibility) and
  [`localization.md`](../spec/rebuild/localization.md) (full Hindi/English app toggle
  via a message catalog, Hindi-first, adopt-v1-terminology). Updated
  [`scope-boundaries.md`](../spec/rebuild/scope-boundaries.md) Core: replaced the old
  "inline bilingual, not a locale toggle" line with the real
  language-switch requirement and a production-UI-quality line. Driven
  by the owner's "make it production, not POC" and "localization
  support" asks.

- _2026-06-17_ · Ran a full **v1 ↔ v2 feature-parity audit** (~248 v1
  features in `AadhatManagementApp` vs this rebuild spec). Result:
  the rebuild covers every core domain. Recorded the four v1 features
  that had no bucket — frequency-sorted item dropdown, Excel item
  import/export, custom finance accounts, native contact picker — in
  [`scope-boundaries.md`](../spec/rebuild/scope-boundaries.md) §v1 parity gaps with
  a recommended bucket and `TODO(spec)` for owner sign-off, plus
  three deliberate simplifications pinned so they are not re-added as
  "gaps".
- _2026-06-17_ · Extended [`role-permission-matrix.md`](../spec/rebuild/role-permission-matrix.md)
  with §Owner-configurable role visibility & capabilities — the
  in-product control the owner asked for. The role × permission
  matrices become the fixed **ceiling**; `shopProfile.roleConfig`
  lets the owner, from Admin → Roles & Visibility, hide pages and
  switch off optional within-ceiling capabilities per non-owner role
  at runtime. Config **narrows, never widens** (no escalation), with
  hard floors (owner immutable, structural owner-only powers
  unreachable, audit/block-rules immovable, visibility ⊇ action,
  don't-lock-out-billing), enforced server-side on the same path as
  the base matrix. Cross-referenced from
  [`scope-boundaries.md`](../spec/rebuild/scope-boundaries.md) (Configurable
  bucket) and [`event-schemas.md`](../spec/rebuild/event-schemas.md)
  (`shop_profile_updated` validation). Default config reproduces the
  spec cell-for-cell.
- _2026-06-16_ (later) · Added [`analytics.md`](../spec/rebuild/analytics.md) (#26)
  — the v2 business-analytics contract (forecasts, profit/margin
  trends, items-to-focus, dead stock, receivables/payables aging,
  customer concentration, payment-mix and peak-hour trends, smart
  suggestions), each mapped to the events/projections it reads, with
  the retail-attribution data limit called out. Re-homes v1's
  forward-looking Analytics page on the ledger; replaces the bare
  period-binning stub in `projections.md`. Also added a
  `## Calculation integrity` section to `invariants.md` and expanded
  the `scenarios.md` Coverage-map gap list from 9 to 31 scenarios
  (calculation-edge + adversarial/fraud classes added).
- _2026-06-16_ · Added the platform / accuracy / concurrency
  layer in response to the owner's "web + Android + iOS, fast,
  always accurate" review. New spec docs:
  `platform-compatibility.md` (per-platform capability matrix
  with iOS deferred to v2.1 and named gates),
  `printer-compatibility.md` (supported printers, ESC/POS
  subset, Devanagari = always bitmap, Android BT Classic SPP
  path, four-layer duplicate-print prevention, manual-print
  fallback), `money-units-rounding.md` (atomic units, canonical
  formulas, round-half-to-even, v1 → v2 import conversion),
  `time-clock.md` (two-timestamp model, skew bands, backdate
  accepted-with-flag, future-date blocked, shop-day = open
  cash session), `concurrency.md` (shop-wide cash session,
  server-allocated bill numbers with device-bound offline
  blocks, rate-snapshot-at-intent, stock-race accepted-and-
  flagged, "first server commit wins"),
  `platform-test-matrix.md` (eight physical surfaces, manual
  smoke gates, release-gate matrix by release type). New plan
  doc: `plan/rebuild/release-health-gates.md` (10-gate pre-
  release checklist with hot-fix subset and sign-off record).
  Extended `invariants.md` with `## Constitution — the "no
  false data" rules` summarising AC1–AC8 and mapping each to
  the M / S / C / B / R label that enforces it (no standalone
  `accuracy-contract.md`, to avoid duplication drift).
  Extended `data-governance.md` with `## Validation gates`
  mapping master-data quality rules to adapter result codes
  (`SCHEMA_INVALID`, `BLOCKED_BY_RULE`, `INVARIANT_VIOLATION`,
  `REFERENCE_INVALID`, `PERMISSION_DENIED`) and UI-level
  recoveries (merge, create-anyway-with-flag, unarchive).
- _2026-06-15_ (later same day) · Added the operational-concerns
  layer in response to the owner's "what about offline / failure
  modes / observability / governance / ergonomics / AI?" review.
  New spec docs: `data-placement.md` (where each datum lives,
  read/write budgets, staleness rules), `offline-sync.md`
  (per-action allowance, state vocabulary, retry policy,
  conflict handling), `failure-modes.md` (20 real-world failures
  with expected behaviour and pinned tests), `versioning-
  compatibility.md` (`appVersion` / `schemaVersion` /
  `domainVersion` and force-upgrade contract), `data-
  governance.md` (PII inventory, retention, master-data
  governance, bill numbering, GST posture),
  `observability.md` (notifications + supportability + debug
  bundle with PII-exclusion), `ai-boundaries.md` (suggestion-
  not-action contract for every AI flow), `ergonomics.md`
  (shop-floor constraints, tap targets, sunlight, Hindi label
  sizing). New plan docs: `plan/rebuild/operations-runbook.md`
  (daily / weekly / monthly + 12 failure procedures + release
  rules + escalation) and `plan/rebuild/backup-restore.md`
  (what / where / monthly drill that turns backups into proof).
  Extended `role-permission-matrix.md` with the staff
  edit-time-limit rule (`shopProfile.staff.editGraceMin`,
  default 5 min, enforced by the storage adapter). Re-framed
  the Save perf budget as three explicit thresholds (UI ≤
  100 ms / bill visible locally ≤ 300 ms / server-confirmed ≤
  500 ms) and added a `Required perf scenarios` table.
- _2026-06-15_ (later same day) · Added two more contract docs:
  `ci-contract.md` (exact required CI jobs, canonical commands,
  baseline-bump protocol) and `worked-example.md` (one retail
  bill traced end-to-end through every layer). Added the
  Foundations / Data and lifecycle / Correctness, monitoring,
  and access / Quality, perf, and definition of done groupings
  to the reading order.
- _2026-06-15_ (later same day) · Added agent-ready contract docs:
  `event-schemas.md`, `scenarios.md`, `role-permission-matrix.md`,
  `idempotency.md`, `projections.md`, `performance-budgets.md`,
  `feature-acceptance.md`. Plan-side additions
  (`plan/rebuild/decisions.md`, `migration-cutover.md`) referenced
  from this README's open-questions section.
- _2026-06-15_ · Initial draft of the rebuild spec subtree, derived
  from the owner's stated priorities: test-first correctness, no UI
  hang, no duplicate bills from double-tap or slow Bluetooth,
  explicit anomaly flagging, brother-as-monitor usage pattern.

## `spec/rebuild/role-permission-matrix.md`


- _2026-06-17_ · Added §Owner-configurable role visibility &
  capabilities — the in-product control the owner asked for. The
  matrices stay the fixed **ceiling**; `shopProfile.roleConfig` lets
  the owner, from **Admin → Roles & Visibility**, hide pages and
  switch off optional within-ceiling capabilities per non-owner role
  at runtime. Config **narrows, never widens** (no escalation), with
  hard floors (owner immutable, structural owner-only powers
  unreachable, audit/block-rules immovable, visibility ⊇ action,
  don't-lock-out-billing). Enforced server-side on the same path as
  the base matrix; changes are owner-only audited
  `shop_profile_updated` events; default config reproduces the spec
  cell-for-cell.
- _2026-06-15_ (later same day) · Added §Time-limit rules for
  staff edits — staff may edit / void / correct only their own
  bill, within the current cash session AND within
  `shopProfile.staff.editGraceMin` (default 5 min); enforced by
  the storage adapter, not just UI. Closes the recurring
  "can staff fix a typo?" question without giving staff a back
  door into older history.

## `spec/rebuild/scenarios.md`


- _2026-06-17_ · Added a `Rate sanity` scenario group (32
  `fat-finger-low-rate`, 33 `purchase-rate-typo`) alongside the new
  `price.unusually-low` / `price.purchase-rate-unusual` suspicion
  rules, so a manually-entered rate that is too low (above cost) or a
  bad purchase rate is covered by a fixture.
- _2026-06-16_ (later, 2) · Expanded the Coverage-map gap list from 9
  to 31 named scenarios, grouped by class — core lifecycle,
  **calculation edges** (guarding the wrong-but-consistent-formula
  risk), **adversarial / fraud** (the trust bar), outstanding &
  counterparty, operational & resilience, and multi-day / period
  (guarding `R1`–`R4`). Still intent-level; the Test agent authors
  each fixture in its milestone.
- _2026-06-16_ (later) · Added a `## Coverage map` section: an
  event-type → fixture table (13 / 22 events have a catalog fixture;
  9 do not), a register of the scenario-shaped tests that live in
  sibling docs (time-clock, money-units, concurrency,
  data-governance, projections, failure-modes, …) so the catalog
  indexes them, and a prioritised list of 9 known `TODO(spec)`
  scenario gaps (rate-change-day, expenses-and-withdrawals-day,
  supplier-payment, item-master-lifecycle, two-device-concurrency,
  future-dated-block-day, rounding-boundary-day,
  data-quality-gates-day, role-change). No fixture values changed.
- _2026-06-16_ · Clarified the Conventions note on weights: values
  are **shown** in kg (2 dp) for readability, but the canonical
  storage unit is integer milligrams (decisions row 8 /
  [`money-units-rounding.md`](../spec/rebuild/money-units-rounding.md)). Resolves
  the contradiction with the frozen weight-unit decision; no fixture
  values changed.

## `spec/rebuild/scope-boundaries.md`


- _2026-06-18_ · Replaced the "inline bilingual, not a locale toggle"
  Core line with **full Hindi/English localization via a single
  app-wide toggle** (new `localization.md`) and added a
  **production-grade UI quality** Core line (new `ui-standards.md`),
  both driven by the owner's "make it production, not POC" +
  "localization support" asks. Item/party names stay bilingual data;
  app chrome is now catalog-driven and toggle-switched.

- _2026-06-17_ (later) · Noted under the Voice-billing disputed item
  that **zero-touch / hands-free activation** (no-touch app launch +
  full bill by voice) is now a recorded v2.1 sub-goal — full spec in
  `../voice-billing-v2.md` §9, mechanism `TODO(spec)`.
- _2026-06-17_ · Added §v1 parity gaps — a full v1↔v2 feature audit
  (~248 v1 features) confirmed the rebuild covers every core domain
  and recorded the four v1 features that had no bucket
  (frequency-sorted dropdown, Excel item import/export, custom
  finance accounts, native contact picker) with a recommended bucket
  and `TODO(spec)` for owner sign-off. Also pinned three deliberate
  simplifications (orphan stock buckets, full-history replay, voice /
  barcode / LLM-chat) so they are not mistaken for gaps.
- _2026-06-17_ · Added "Per-role page visibility and optional
  capabilities" to the **Configurable** bucket — owner-editable at
  runtime from Admin → Roles & Visibility, narrowing (never widening)
  the fixed role × permission ceiling. Generalises the existing
  "Wholesale vs retail availability per role" and "Discount limit per
  role" lines. Full contract in `role-permission-matrix.md`
  §Owner-configurable role visibility & capabilities.

## `spec/rebuild/suspicion-engine.md`


- _2026-06-17_ (later) · Specified **where a flag surfaces**: a
  cashier-triggerable flag (rate sanity, discount, zero-rate,
  stock-negative) now shows **inline at billing time** as a
  client-side advisory pre-check with a Save-anyway / Fix confirm
  (server still appends the authoritative flag — "save anyway"
  records it, never skips it), **and** appears in the **daily
  report** grouped by severity even if waved through at the counter.
  Reworked the Severities table into counter / Review-Queue / daily-
  report columns.
- _2026-06-17_ · Closed the manually-entered-rate gap. Added
  `price.unusually-low` (a sale rate above cost but far below the
  item's typical sell rate — the fat-finger ₹6-for-₹60 case, which
  `price.below-cost` and `price.unusually-high` both miss) and
  `price.purchase-rate-unusual` (a manually-entered purchase rate
  far from recent, in either direction — protects the moving-average
  cost baseline the other rate rules anchor on). Documented the
  baseline each rule uses and flagged the brand-new-item-no-history
  case as the weakest spot (`TODO(spec)`: `rateFloorPaise` or
  first-sale owner-confirm).

## `spec/rebuild/time-clock.md`


- _2026-06-16_ (later) · Namespaced the backdate key to
  `shopProfile.time.backdateToleranceDays` throughout this file (was
  the un-prefixed `shopProfile.backdateToleranceDays`), and added an
  Open-items `TODO(spec)` to unify the three competing clock-skew
  keys — `time.toleranceMin` (here), `time.clockSkewMaxMin`
  ([`failure-modes.md`](../spec/rebuild/failure-modes.md)), and
  `time.skewToleranceSec` ([`suspicion-engine.md`](../spec/rebuild/suspicion-engine.md))
  — without silently choosing a threshold.
- _2026-06-16_ (later) · Renamed the timezone-override audit event
  from `shop-timezone-changed` to `shop_timezone_changed` to match
  the snake_case event-naming convention used by all 22 types in
  [`event-schemas.md`](../spec/rebuild/event-schemas.md); the event is listed in
  that file's "Referenced events not yet specified here" table.
- _2026-06-16_ · file created. Two-timestamp model
  (`at` authoritative, `clientAt` audit-only); offline
  preservation rule; clock-skew tolerance bands; backdated
  events accepted-with-flag; future-dated events blocked;
  shop day = open cash session per decisions row 9; reports
  always in shop timezone; storage-adapter responsibilities;
  required tests.

## `spec/rebuild/ui-standards.md`


- _2026-06-18_ · File created. Establishes the production-grade UI bar
  the owner asked for ("it has to be production kind, not POC kind"),
  with the v1 app as the floor to beat: a single-sourced design-token
  system, a reusable component set, a real mobile navigation pattern,
  an all-states component quality bar (incl. empty/loading/error),
  Hindi-first localizable layout, and a UI definition-of-done. Cross-
  references `quality-bar.md` (tests), `ergonomics.md` (shop floor),
  and the new `localization.md`.

## `spec/rebuild/versioning-compatibility.md`


- _2026-06-15_ · file created. Three independent versions
  (`appVersion`, `schemaVersion`, `domainVersion`); support
  window with force-upgrade rules; additive vs non-additive
  event-schema changes with up-migration contract; cache
  poisoning vs outbox separation; release cadence cross-link
  to operations runbook; required tests.

## `spec/rebuild/worked-example.md`


- _2026-06-15_ · file created. One worked example end-to-end —
  UI intent → service → event → projection → print job → audit →
  tests — pinning every layer in the architecture.

## `spec/voice-billing-v2.md`


- _2026-06-17_ · Added §9 *Future: zero-touch / hands-free activation
  (v2.1)* capturing the owner's "I don't touch my mobile and can
  still activate the app and create a bill" ask. Reframed the §1
  "No wake-word" boundary as a **v2.0-only** cut and pointed it at
  §9. Recorded two candidate activation mechanisms — (A) OS-assistant
  launch via Android App Actions, recommended; (B) in-app wake-word
  foreground mode, fallback — with battery/privacy/platform/effort
  tradeoffs, acceptance criteria, and dependencies (B7/A1/A5/C12).
  Mechanism left as `TODO(spec)` for owner sign-off; full bill-by-voice
  was already designed for v2.1, so activation is the only new piece.

