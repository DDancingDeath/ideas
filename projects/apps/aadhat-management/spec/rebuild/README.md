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

### Data and lifecycle

3. [`event-ledger.md`](./event-ledger.md) — every business action is an
   immutable event; stock / cash / outstanding / reports are derived,
   not stored as authoritative numbers.
4. [`event-schemas.md`](./event-schemas.md) — full payload shape for
   each of the 22 event types, with validation rules, examples,
   invariants applied, and idempotency-key shape.
5. [`projections.md`](./projections.md) — the contract for every
   derived view (items, stock, cash, outstanding, history, reports,
   audit, Review Queue) and the rebuild / stale-detection process.
6. [`data-placement.md`](./data-placement.md) — where each piece of
   data lives (authoritative location, local cache, sync rule,
   staleness tolerance, offline behaviour, read/write budgets);
   server vs app responsibility split; "local for speed, server
   for trust, shared domain for consistency" principle.
7. [`bill-lifecycle.md`](./bill-lifecycle.md) — the bill state machine
   and the **billing-vs-printing separation** invariant (double-tap,
   slow Bluetooth, retry, offline — none may create duplicate sales).
8. [`idempotency.md`](./idempotency.md) — `clientActionId` →
   `idempotencyKey` mapping, lifetimes, and the "what happens
   when…" cases (double-tap, offline, tab-close, conflict, etc.).
9. [`print-queue.md`](./print-queue.md) — the background print queue
   contract; what the UI is allowed to wait on and what it is not.
10. [`offline-sync.md`](./offline-sync.md) — per-action offline
    allowance matrix; local UI state vocabulary
    (`Saved` / `Sync pending` / `Synced` / `Sync failed
    (retrying)` / `Needs review` / `Printed` / `Print failed`);
    retry policy with backoff and budget; conflict handling;
    reconnect protocol; what the UI must show.

### Correctness, monitoring, and access

11. [`invariants.md`](./invariants.md) — the business laws the app must
    always hold (stock, cash, udhaar, reports must reconcile against
    the event ledger; staff cannot bypass authorization via API).
12. [`role-permission-matrix.md`](./role-permission-matrix.md) — full
    role × event-type matrix, projection-read matrix, special
    principals (`engine`, `queue worker`), API-bypass guarantee,
    and the staff edit-time-limit rule
    (`shopProfile.staff.editGraceMin`).
13. [`suspicion-engine.md`](./suspicion-engine.md) — the anomaly
    detector that turns "the data looks off" into Review Queue items.
14. [`review-queue.md`](./review-queue.md) — the page the owner /
    brother uses to monitor and approve anomalies. New page, not in
    the v1 page-specs.
15. [`failure-modes.md`](./failure-modes.md) — catalogue of 20 real-
    world failures (app crash, battery die, wrong device clock, old
    client, cache corruption, Firebase down, lost phone…) with
    expected and forbidden system behaviour, and the pinned test
    for each.
16. [`versioning-compatibility.md`](./versioning-compatibility.md) —
    three independent versions (`appVersion`, `schemaVersion`,
    `domainVersion`); support-window with force-upgrade; additive
    vs non-additive event-schema changes and the up-migration
    contract.
17. [`data-governance.md`](./data-governance.md) — ownership /
    access matrix (delete is forbidden; corrections are events);
    PII inventory with retention; master-data governance (item /
    party merges, rate history, archive, typos); bill-numbering
    and legal posture (GST is out of scope for v2.0).
18. [`observability.md`](./observability.md) — notification
    catalogue with severity / channel / audience; supportability
    surface (app / device / user / network / outbox / queues /
    cache); trace ids; one-tap debug bundle with PII-exclusion
    contract.
19. [`ai-boundaries.md`](./ai-boundaries.md) — what AI is allowed
    to do (suggest, summarise, draft, voice-fill — always
    confirmed by a human) and what AI is never allowed to do (no
    event without human confirm; no permission elevation; no
    flag resolve; no silent suppression).
20. [`ergonomics.md`](./ergonomics.md) — shop-floor constraints
    (one-handed, sunlight, noisy, Hindi-first, ₹15–20k phone);
    tap-target floors; WCAG AA contrast; Hindi label sizing;
    two-step confirm only for destructive actions; picker and
    history row design.

### Quality, perf, and definition of done

21. [`scenarios.md`](./scenarios.md) — 15 named fixtures (real shop
    workflows) with setup, sequence, expected projections, expected
    flags, and the test layer each one belongs to.
22. [`performance-budgets.md`](./performance-budgets.md) — concrete UI
    / print / sync numbers, reference device, measurement
    methodology, required perf scenarios, and CI gates.
23. [`quality-bar.md`](./quality-bar.md) — required test layers, the
    "no UI hang" performance bar, and what counts as `done` for a
    feature.
24. [`feature-acceptance.md`](./feature-acceptance.md) — per-feature
    required-test checklist by feature kind, with PR template.
25. [`ci-contract.md`](./ci-contract.md) — exact required CI jobs,
    canonical commands, artefact contract, baseline-bump protocol.
26. [`worked-example.md`](./worked-example.md) — one retail bill
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
