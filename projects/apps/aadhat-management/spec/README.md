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
three groups (Foundations / Data and lifecycle / Correctness,
monitoring, and access / Quality, perf, and definition of done).
The short list:

1. **[`rebuild/README.md`](./rebuild/README.md)** — orientation for the
   rebuild subtree and its relationship to the v1 page-specs.
2. **[`rebuild/scope-boundaries.md`](./rebuild/scope-boundaries.md)** —
   core vs configurable vs shop-custom vs not-doing.
3. **[`rebuild/architecture.md`](./rebuild/architecture.md)** — layered
   architecture; the "UI is never the source of business truth" rule.
4. **[`rebuild/event-ledger.md`](./rebuild/event-ledger.md)** —
   append-only event store; everything else is a projection.
5. **[`rebuild/event-schemas.md`](./rebuild/event-schemas.md)** — full
   payload shape for each of the 22 event types, with validation
   rules, examples, invariants applied, and idempotency-key shape.
6. **[`rebuild/projections.md`](./rebuild/projections.md)** — the
   contract for every derived view and the rebuild /
   stale-detection process.
7. **[`rebuild/bill-lifecycle.md`](./rebuild/bill-lifecycle.md)** — bill
   state machine; idempotency; billing-vs-printing separation.
8. **[`rebuild/idempotency.md`](./rebuild/idempotency.md)** —
   `clientActionId` → `idempotencyKey` mapping, lifetimes, and the
   "what happens when…" cases.
9. **[`rebuild/print-queue.md`](./rebuild/print-queue.md)** — background
   print queue; UI never waits on the printer.
10. **[`rebuild/invariants.md`](./rebuild/invariants.md)** — business
    laws (money, stock, cash, outstanding, lifecycle, auth, reconciliation).
11. **[`rebuild/role-permission-matrix.md`](./rebuild/role-permission-matrix.md)** —
    role × event-type matrix, projection-read matrix, special
    principals, API-bypass guarantee.
12. **[`rebuild/suspicion-engine.md`](./rebuild/suspicion-engine.md)** —
    anomaly rules that feed the Review Queue.
13. **[`rebuild/review-queue.md`](./rebuild/review-queue.md)** — new
    page for the brother / owner to monitor the shop.
14. **[`rebuild/scenarios.md`](./rebuild/scenarios.md)** — 15 named
    fixtures (real shop workflows) with expected projections and
    flags.
15. **[`rebuild/performance-budgets.md`](./rebuild/performance-budgets.md)** —
    concrete UI / print / sync numbers, reference device,
    measurement methodology, CI gates.
16. **[`rebuild/quality-bar.md`](./rebuild/quality-bar.md)** — required
    test layers and "no UI hang" perf budgets.
17. **[`rebuild/feature-acceptance.md`](./rebuild/feature-acceptance.md)** —
    per-feature required-test checklist by feature kind, with PR
    template.

Opinion / strategy material for the rebuild lives under
[`../plan/rebuild/`](../plan/rebuild/) (roadmap, **decisions**
freeze list, agent roster, tech candidates, **migration &
cutover**, productization).

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
- iOS.
- Desktop-only UX.

## Recent changes

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
