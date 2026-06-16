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

### Foundations

1. [`scope-boundaries.md`](./scope-boundaries.md) — what is shop-custom,
   what is core, what is configurable, what is explicitly out.
2. [`architecture.md`](./architecture.md) — the layered architecture
   (domain core → application services → storage adapters → UI →
   device integrations) and why UI must not own business truth.
3. [`platform-compatibility.md`](./platform-compatibility.md) —
   per-platform capability matrix (Web/PWA / Android / iOS); iOS
   deferred to v2.1 with named gates (BLE Classic SPP, WebKit
   IndexedDB eviction, background BLE); foreground / background /
   suspended contract; storage limits per platform.

### Data and lifecycle

4. [`event-ledger.md`](./event-ledger.md) — every business action is an
   immutable event; stock / cash / outstanding / reports are derived,
   not stored as authoritative numbers.
5. [`event-schemas.md`](./event-schemas.md) — full payload shape for
   each of the 22 event types, with validation rules, examples,
   invariants applied, and idempotency-key shape.
6. [`time-clock.md`](./time-clock.md) — two-timestamp model
   (`at` server-authoritative, `clientAt` device audit-only);
   clock-skew tolerance bands; backdated accepted-with-flag;
   future-dated blocked; shop day = open cash session; reports
   always in shop timezone.
7. [`money-units-rounding.md`](./money-units-rounding.md) — atomic
   units (paise / mg / `paisePerKg` / bps); canonical line and bill
   total formulas with fixed application order; round-half-to-even;
   Indian display formatting; v1 → v2 import conversion with
   round-trip verification.
8. [`projections.md`](./projections.md) — the contract for every
   derived view (items, **rate history**, stock, cash, outstanding,
   history, reports, audit, Review Queue) and the rebuild /
   stale-detection process. The business insights on top of these
   are in [`analytics.md`](./analytics.md) (#26).
9. [`data-placement.md`](./data-placement.md) — where each piece of
   data lives (authoritative location, local cache, sync rule,
   staleness tolerance, offline behaviour, read/write budgets);
   server vs app responsibility split; "local for speed, server
   for trust, shared domain for consistency" principle.
10. [`bill-lifecycle.md`](./bill-lifecycle.md) — the bill state machine
    and the **billing-vs-printing separation** invariant (double-tap,
    slow Bluetooth, retry, offline — none may create duplicate sales).
11. [`idempotency.md`](./idempotency.md) — `clientActionId` →
    `idempotencyKey` mapping, lifetimes, and the "what happens
    when…" cases (double-tap, offline, tab-close, conflict, etc.).
12. [`print-queue.md`](./print-queue.md) — the background print queue
    contract; what the UI is allowed to wait on and what it is not.
13. [`printer-compatibility.md`](./printer-compatibility.md) — which
    printers v2.0 supports, paper widths, ESC/POS command subset,
    Devanagari-always-bitmap rule, Android BT Classic SPP pairing
    path with foreground service + battery whitelist, iOS refused
    in v2.0, four-layer duplicate-print prevention, manual-print
    fallback, production-printer-smoke release gate.
14. [`offline-sync.md`](./offline-sync.md) — per-action offline
    allowance matrix; local UI state vocabulary
    (`Saved` / `Sync pending` / `Synced` / `Sync failed
    (retrying)` / `Needs review` / `Printed` / `Print failed`);
    retry policy with backoff and budget; conflict handling;
    reconnect protocol; what the UI must show.
15. [`concurrency.md`](./concurrency.md) — multi-device contract.
    Cash session is shop-wide (C3); bill numbers server-allocated
    with device-bound offline blocks; rate-snapshot-at-intent for
    in-progress bills; concurrent-sale-into-negative-stock
    accepted-and-flagged per S2; default rule "first server
    commit wins, losing write surfaces in Review Queue".

### Correctness, monitoring, and access

16. [`invariants.md`](./invariants.md) — the business laws the app must
    always hold. Opens with `## Constitution` summarising the eight
    AC rules ("no false data") and mapping each to the
    M / S / C / B / R label that enforces it.
17. [`role-permission-matrix.md`](./role-permission-matrix.md) — full
    role × event-type matrix, projection-read matrix, special
    principals (`engine`, `queue worker`), API-bypass guarantee,
    and the staff edit-time-limit rule
    (`shopProfile.staff.editGraceMin`).
18. [`suspicion-engine.md`](./suspicion-engine.md) — the anomaly
    detector that turns "the data looks off" into Review Queue items.
19. [`review-queue.md`](./review-queue.md) — the page the owner /
    brother uses to monitor and approve anomalies. New page, not in
    the v1 page-specs.
20. [`failure-modes.md`](./failure-modes.md) — catalogue of 20 real-
    world failures (app crash, battery die, wrong device clock, old
    client, cache corruption, Firebase down, lost phone…) with
    expected and forbidden system behaviour, and the pinned test
    for each.
21. [`versioning-compatibility.md`](./versioning-compatibility.md) —
    three independent versions (`appVersion`, `schemaVersion`,
    `domainVersion`); support-window with force-upgrade; additive
    vs non-additive event-schema changes and the up-migration
    contract.
22. [`data-governance.md`](./data-governance.md) — ownership /
    access matrix (delete is forbidden; corrections are events);
    PII inventory with retention; master-data governance (item /
    party merges, rate history, archive, typos); `## Validation
    gates` mapping each master-data quality rule to an adapter
    result code; bill-numbering and legal posture (GST is out of
    scope for v2.0).
23. [`observability.md`](./observability.md) — notification
    catalogue with severity / channel / audience; supportability
    surface (app / device / user / network / outbox / queues /
    cache); trace ids; one-tap debug bundle with PII-exclusion
    contract.
24. [`ai-boundaries.md`](./ai-boundaries.md) — what AI is allowed
    to do (suggest, summarise, draft, voice-fill — always
    confirmed by a human) and what AI is never allowed to do (no
    event without human confirm; no permission elevation; no
    flag resolve; no silent suppression).
25. [`ergonomics.md`](./ergonomics.md) — shop-floor constraints
    (one-handed, sunlight, noisy, Hindi-first, ₹15–20k phone);
    tap-target floors; WCAG AA contrast; Hindi label sizing;
    two-step confirm only for destructive actions; picker and
    history row design.

26. [`analytics.md`](./analytics.md) — the business insights built
    on the projections (today / month-end forecasts, profit and
    margin trends, items-to-focus, dead stock, receivables /
    payables aging, customer concentration, payment-mix and
    peak-hour trends, smart suggestions); each mapped to the events
    and projections it reads, with the retail-attribution data limit
    called out. Analytics never owns an authoritative total.

### Quality, perf, and definition of done

27. [`scenarios.md`](./scenarios.md) — 15 named fixtures (real shop
    workflows) with setup, sequence, expected projections, expected
    flags, and the test layer each one belongs to.
28. [`performance-budgets.md`](./performance-budgets.md) — concrete UI
    / print / sync numbers, reference device, measurement
    methodology, required perf scenarios, and CI gates.
29. [`quality-bar.md`](./quality-bar.md) — required test layers, the
    "no UI hang" performance bar, and what counts as `done` for a
    feature.
30. [`feature-acceptance.md`](./feature-acceptance.md) — per-feature
    required-test checklist by feature kind, with PR template.
31. [`ci-contract.md`](./ci-contract.md) — exact required CI jobs,
    canonical commands, artefact contract, baseline-bump protocol.
32. [`platform-test-matrix.md`](./platform-test-matrix.md) — which
    physical surfaces (Chromium headless / headed, Android
    emulator / real device / real device + printer, iOS Safari /
    Capacitor, low-end Android) run which CI jobs; manual smoke
    gates (`G-PRINT-PROD`, `G-OFFLINE-RECON`, `G-CASH-CYCLE`,
    `G-COLD-START`, `G-FORCE-UPGRADE`, `G-PWA-OWNER`,
    `G-PWA-SAFARI`); release-gate matrix by release type;
    release-record JSON manifest.
33. [`worked-example.md`](./worked-example.md) — one retail bill
    traced end-to-end through every layer (UI intent → service →
    event → projection → print → audit → tests). Read this once
    to make every other doc click into place.

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

## Recent changes

- _2026-06-16_ (later) · Added [`analytics.md`](./analytics.md) (#26)
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
