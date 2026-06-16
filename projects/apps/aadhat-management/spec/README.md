# Spec — AadhatManagement

This is the source of truth for what the app does.

> **Two specs in one folder.** The page-specs and the v1 design docs
> describe the **live production app** (what runs in the family shop
> today). The new [`rebuild/`](./rebuild/) subtree captures the
> **v2 rebuild** the owner is now scoping — same business, free to
> change layout / tech / data shape where it improves correctness or
> testability. When the two disagree, the rebuild subtree wins for v2
> work; for the live app, the page-specs win.

## Reading order — v1 (live app)

1. **[`capabilities.md`](./capabilities.md)** — exhaustive feature inventory
   ("what the code does today"). Read this for breadth.
2. **[`page-specs/README.md`](./page-specs/README.md)** — explains the page
   spec contract (Purpose / Files / Calculations / Must NOT do / etc.).
3. **[`page-specs/00-auth.md`](./page-specs/00-auth.md) → `16-cash-management.md`**
   — page-by-page contracts. These are the canonical truth when behavior is
   in dispute.
4. **[`firestore-rules-design.md`](./firestore-rules-design.md)** — data
   model, collections, role-based authorization, and the **production**
   Firestore rules design (the current shipped rules are weaker — see
   `../plan/review-issues.md`).
5. **[`chat-design.md`](./chat-design.md)** — design for the AI assistant
   tab (page `15-chat.md` is the surface; this doc is the implementation
   design behind it).
6. **[`voice-billing-v2.md`](./voice-billing-v2.md)** — design doc for v2
   of the tap-to-talk voice billing feature on `02-billing.md`. V1 is live
   (commit `56e230f` on the live repo); v2 is in design.

## Reading order — v2 (rebuild)

The rebuild subtree's own README organizes its reading order in
four groups (Foundations / Data and lifecycle / Correctness,
monitoring, and access / Quality, perf, and definition of done).
The short list:

1. **[`rebuild/README.md`](./rebuild/README.md)** — orientation for the
   rebuild subtree and its relationship to the v1 page-specs.
2. **[`rebuild/scope-boundaries.md`](./rebuild/scope-boundaries.md)** —
   core vs configurable vs shop-custom vs not-doing.
3. **[`rebuild/architecture.md`](./rebuild/architecture.md)** — layered
   architecture; the "UI is never the source of business truth" rule.
4. **[`rebuild/platform-compatibility.md`](./rebuild/platform-compatibility.md)** —
   per-platform capability matrix (Web/PWA / Android / iOS); iOS
   deferred to v2.1 with named gates (BLE Classic SPP, WebKit
   IndexedDB eviction, background BLE).
5. **[`rebuild/event-ledger.md`](./rebuild/event-ledger.md)** —
   append-only event store; everything else is a projection.
6. **[`rebuild/event-schemas.md`](./rebuild/event-schemas.md)** — full
   payload shape for each of the 22 event types, with validation
   rules, examples, invariants applied, and idempotency-key shape.
7. **[`rebuild/time-clock.md`](./rebuild/time-clock.md)** — two-
   timestamp model (`at` server-authoritative, `clientAt` device
   audit-only); skew bands; backdate accepted-with-flag;
   future-date blocked; shop day = open cash session; reports in
   shop timezone.
8. **[`rebuild/money-units-rounding.md`](./rebuild/money-units-rounding.md)** —
   atomic units (paise / mg / `paisePerKg` / bps); canonical line
   and bill total formulas with fixed application order; round-
   half-to-even; Indian display formatting; v1 → v2 conversion.
9. **[`rebuild/projections.md`](./rebuild/projections.md)** — the
   contract for every derived view and the rebuild /
   stale-detection process.
10. **[`rebuild/data-placement.md`](./rebuild/data-placement.md)** —
    where each piece of data lives (authoritative location, local
    cache, sync rule, staleness tolerance, offline behaviour);
    server vs app responsibility split.
11. **[`rebuild/bill-lifecycle.md`](./rebuild/bill-lifecycle.md)** — bill
    state machine; idempotency; billing-vs-printing separation.
12. **[`rebuild/idempotency.md`](./rebuild/idempotency.md)** —
    `clientActionId` → `idempotencyKey` mapping, lifetimes, and the
    "what happens when…" cases.
13. **[`rebuild/print-queue.md`](./rebuild/print-queue.md)** — background
    print queue; UI never waits on the printer.
14. **[`rebuild/printer-compatibility.md`](./rebuild/printer-compatibility.md)** —
    supported printer profiles (58 mm / 80 mm BT Classic SPP),
    ESC/POS command subset, Devanagari-always-bitmap rule, Android
    BT pairing path with foreground service + battery whitelist,
    iOS refused in v2.0, four-layer duplicate-print prevention,
    manual-print fallback, production-printer-smoke release gate.
15. **[`rebuild/offline-sync.md`](./rebuild/offline-sync.md)** — per-
    action offline allowance matrix; local UI state vocabulary;
    retry policy; conflict handling; reconnect protocol.
16. **[`rebuild/concurrency.md`](./rebuild/concurrency.md)** — multi-
    device contract. Cash session is shop-wide (C3); bill numbers
    server-allocated with device-bound offline blocks; rate-
    snapshot-at-intent for in-progress bills; concurrent-sale-
    into-negative-stock accepted-and-flagged per S2.
17. **[`rebuild/invariants.md`](./rebuild/invariants.md)** — business
    laws (money, stock, cash, outstanding, lifecycle, auth,
    reconciliation, time). Opens with the `## Constitution` —
    eight AC rules ("no false data") summarising the contract.
18. **[`rebuild/role-permission-matrix.md`](./rebuild/role-permission-matrix.md)** —
    role × event-type matrix, projection-read matrix, special
    principals, API-bypass guarantee, staff edit-time-limit rule.
19. **[`rebuild/suspicion-engine.md`](./rebuild/suspicion-engine.md)** —
    anomaly rules that feed the Review Queue.
20. **[`rebuild/review-queue.md`](./rebuild/review-queue.md)** — new
    page for the brother / owner to monitor the shop.
21. **[`rebuild/failure-modes.md`](./rebuild/failure-modes.md)** — 20
    real-world failures with expected and forbidden behaviour and
    the pinned test for each.
22. **[`rebuild/versioning-compatibility.md`](./rebuild/versioning-compatibility.md)** —
    three independent versions and the force-upgrade contract;
    additive vs non-additive event-schema changes and the
    up-migration contract.
23. **[`rebuild/data-governance.md`](./rebuild/data-governance.md)** —
    ownership / access matrix (delete is forbidden), PII
    inventory, retention, master-data governance, `## Validation
    gates` mapping master-data quality rules to adapter result
    codes, bill numbering and GST posture.
24. **[`rebuild/observability.md`](./rebuild/observability.md)** —
    notifications catalogue (severity / channel / audience),
    supportability surface, debug bundle with PII-exclusion.
25. **[`rebuild/ai-boundaries.md`](./rebuild/ai-boundaries.md)** —
    suggestion-not-action contract for every AI flow; AI may
    never resolve a flag or change settings.
26. **[`rebuild/ergonomics.md`](./rebuild/ergonomics.md)** — shop-
    floor constraints; tap targets; sunlight readability; Hindi
    label sizing; two-step confirm only for destructive actions.
27. **[`rebuild/scenarios.md`](./rebuild/scenarios.md)** — 15 named
    fixtures (real shop workflows) with expected projections and
    flags.
28. **[`rebuild/performance-budgets.md`](./rebuild/performance-budgets.md)** —
    concrete UI / print / sync numbers, reference device,
    measurement methodology, required perf scenarios, CI gates.
29. **[`rebuild/quality-bar.md`](./rebuild/quality-bar.md)** — required
    test layers and "no UI hang" perf budgets.
30. **[`rebuild/feature-acceptance.md`](./rebuild/feature-acceptance.md)** —
    per-feature required-test checklist by feature kind, with PR
    template.
31. **[`rebuild/ci-contract.md`](./rebuild/ci-contract.md)** —
    exact required CI jobs, canonical commands, artefact
    contract, baseline-bump protocol.
32. **[`rebuild/platform-test-matrix.md`](./rebuild/platform-test-matrix.md)** —
    eight physical surfaces (Chromium headless / headed, Android
    emulator / real device / + real printer, iOS Safari /
    Capacitor, low-end Android); manual smoke gates; release-gate
    matrix by release type; release-record JSON manifest.
33. **[`rebuild/worked-example.md`](./rebuild/worked-example.md)** —
    one retail bill traced end-to-end through every layer (UI
    intent → service → event → projection → print → audit →
    tests). The fastest way to understand the whole architecture.
34. **[`rebuild/analytics.md`](./rebuild/analytics.md)** — the
    business insights built on the projections (read with #9): today
    / month-end forecasts, profit and margin trends, items-to-focus,
    dead stock, receivables / payables aging, customer concentration,
    payment-mix and peak-hour trends, smart suggestions — each mapped
    to the events and projections it reads, with the retail-customer-
    attribution data limit called out. Never owns an authoritative
    total.

Opinion / strategy material for the rebuild lives under
[`../plan/rebuild/`](../plan/rebuild/) (roadmap, **decisions**
freeze list, agent roster, tech candidates, **migration &
cutover**, **operations runbook**, **backup / restore**,
**release health gates**, productization).

## Glossary

- **Aadhat / Aadhat-i** (आढ़त) — Hindi for "commission / wholesale
  brokerage". The shop's traditional business name.
- **Khaata / Udhaar** — customer credit / outstanding balance.
- **Day close** — the end-of-day routine: count cash, reconcile drawer,
  archive the day.
- **Owner / Manager / Staff** — the three roles. Owner sees everything;
  manager has limited admin; staff can bill + lookup only.

## Notes for agents reading these docs

- Some links inside the per-page specs reference paths from the original
  source repo (e.g. `docs/CAPABILITIES.md`, `www/js/utils/...`). Mentally
  re-map:
  - `docs/CAPABILITIES.md` → `./capabilities.md`
  - `docs/REVIEW_ISSUES.md` → `../plan/review-issues.md`
  - `docs/PROD_FIRESTORE_RULES_DESIGN.md` → `./firestore-rules-design.md`
  - `docs/CHAT_DESIGN.md` → `./chat-design.md`
  - `www/js/...` → original implementation (not in this repo)
- The page-specs `Calculations / formulas` sections are the math truth. If
  a screen shows a different number, the screen is wrong.
- The page-specs `Must NOT do` sections are invariants — never violate them
  when implementing.

## Out of scope (deliberately)

- GST / e-invoicing.
- Multi-tenant / multi-branch.
- iOS in v2.0. (iOS is a v2.1 **stretch target** documented in
  [`rebuild/platform-compatibility.md`](./rebuild/platform-compatibility.md)
  §iOS posture, gated on a real-device printer verification or
  a Wi-Fi printer path.)
- Desktop-only UX.

## Recent changes

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
- _2026-06-15_ · Added [`rebuild/`](./rebuild/) — v2 rebuild spec
  subtree (architecture, event ledger, bill lifecycle, print queue,
  invariants, suspicion engine, Review Queue, quality bar). v1
  page-specs remain authoritative for the live app; rebuild docs
  are authoritative for the v2 rebuild.
