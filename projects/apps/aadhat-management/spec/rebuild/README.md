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
6. [`bill-lifecycle.md`](./bill-lifecycle.md) — the bill state machine
   and the **billing-vs-printing separation** invariant (double-tap,
   slow Bluetooth, retry, offline — none may create duplicate sales).
7. [`idempotency.md`](./idempotency.md) — `clientActionId` →
   `idempotencyKey` mapping, lifetimes, and the "what happens
   when…" cases (double-tap, offline, tab-close, conflict, etc.).
8. [`print-queue.md`](./print-queue.md) — the background print queue
   contract; what the UI is allowed to wait on and what it is not.

### Correctness, monitoring, and access

9. [`invariants.md`](./invariants.md) — the business laws the app must
   always hold (stock, cash, udhaar, reports must reconcile against
   the event ledger; staff cannot bypass authorization via API).
10. [`role-permission-matrix.md`](./role-permission-matrix.md) — full
    role × event-type matrix, projection-read matrix, special
    principals (`engine`, `queue worker`), API-bypass guarantee.
11. [`suspicion-engine.md`](./suspicion-engine.md) — the anomaly
    detector that turns "the data looks off" into Review Queue items.
12. [`review-queue.md`](./review-queue.md) — the page the owner /
    brother uses to monitor and approve anomalies. New page, not in
    the v1 page-specs.

### Quality, perf, and definition of done

13. [`scenarios.md`](./scenarios.md) — 15 named fixtures (real shop
    workflows) with setup, sequence, expected projections, expected
    flags, and the test layer each one belongs to.
14. [`performance-budgets.md`](./performance-budgets.md) — concrete UI
    / print / sync numbers, reference device, measurement
    methodology, and CI gates.
15. [`quality-bar.md`](./quality-bar.md) — required test layers, the
    "no UI hang" performance bar, and what counts as `done` for a
    feature.
16. [`feature-acceptance.md`](./feature-acceptance.md) — per-feature
    required-test checklist by feature kind, with PR template.

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

- `TODO(spec)`: Should v2 keep Firebase Firestore as the backend, or
  move to a relational store (Postgres / Supabase) where the
  event-ledger model is more natural? Architecture doc lists both as
  candidates; pick before M0. Tracked in
  [`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md)
  row 2.
- `TODO(spec)`: Multi-shop / productization is out of scope for v2.0
  but the data shape should not block it. Confirm with owner whether
  to design `shopId` into the schema from day one. Tracked as
  [`decisions.md`](../../plan/rebuild/decisions.md) row 4.
- `TODO(spec)`: The brother / owner monitoring role — is it the same
  as v1's `owner` role, or a distinct `reviewer` role that can
  approve / dismiss Review Queue items without other admin powers?
  Default assumption in `review-queue.md` and
  `role-permission-matrix.md`: same as `owner` for v2.0. Tracked as
  [`decisions.md`](../../plan/rebuild/decisions.md) row 5.

## Recent changes

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
