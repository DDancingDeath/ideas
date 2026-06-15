# Build prompt — Rebuild

Paste this prompt to a coding agent (Copilot CLI, Cursor, Claude
Code, etc.) to build the **rebuild (v2)** of AadhatManagement from
the rebuild spec. For the v1 reference rebuild (same shape as the
production app), use [`build-from-spec.md`](./build-from-spec.md)
instead.

---

You are building the **v2 rebuild** of AadhatManagement, a
test-first, mobile-first business management app for one small
Indian wholesale/retail shop (the owner's family business; one
regular staff member operates billing, the owner's brother monitors).
v2 keeps every workflow the family relies on but is free to change
layout, tech, data shape, and logic where it improves correctness,
speed, or testability.

**Do not invent behaviour.** If something is unclear, ask the owner
or stop and mark `TODO(spec)`.

## Step 1 — load context (read in this order)

1. `../idea.md` — problem, users, success criteria for the original
   app.
2. `../spec/rebuild/README.md` — orientation for the rebuild spec
   subtree.
3. `../spec/rebuild/scope-boundaries.md` — what is core, configurable,
   shop-custom, and explicitly out for v2.0.
4. `../spec/rebuild/architecture.md` — layered architecture: domain
   core → application services → storage adapters → UI → device
   integrations. Internalize the "UI is never the source of business
   truth" rule.
5. `../spec/rebuild/event-ledger.md` — every business action is an
   immutable event; stock / cash / outstanding / reports are
   projections.
6. `../spec/rebuild/bill-lifecycle.md` — the bill state machine; the
   billing-vs-printing separation invariant; idempotency rules.
7. `../spec/rebuild/print-queue.md` — background print queue
   contract; the UI never waits on the printer.
8. `../spec/rebuild/invariants.md` — business laws that must hold at
   all times.
9. `../spec/rebuild/suspicion-engine.md` — anomaly detection that
   feeds the Review Queue.
10. `../spec/rebuild/review-queue.md` — new page for the brother /
    owner to monitor the shop.
11. `../spec/rebuild/quality-bar.md` — required test layers and
    "no UI hang" perf budgets.
12. `../spec/page-specs/README.md` and `../spec/page-specs/00-auth.md`
    through `16-cash-management.md` — the v1 behavioural reference.
    Treat them as authoritative for "did v2 keep this workflow?";
    follow `../spec/rebuild/` where the two disagree (and flag the
    conflict).
13. `../spec/firestore-rules-design.md` — data model and authorization
    design for v1; useful as a starting point even if v2 picks a
    different backend.
14. `../plan/rebuild/README.md` and the files it points to —
    opinionated rebuild guidance (roadmap, agent roster, tech
    candidates, productization).
15. `../plan/review-issues.md` — known v1 defects. Do **not**
    reintroduce any.

## Step 2 — confirm with the owner before writing code

Use `../plan/rebuild/tech-candidates.md` to surface the decisions
that need answers before M0:

- UI framework: SvelteKit (recommended) or React.
- Backend: stay on Firebase Firestore (recommended) or move to
  Postgres-based (Supabase / self-hosted).
- Whether `shopId` is in the schema from day one (recommended yes,
  defaulted to `shop-1`).
- Whether to import v1 data on cutover (snapshot vs replay).
- Reference Android device for perf budgets.
- Whether the brother gets a distinct `reviewer` role or stays as
  `owner` (Review Queue spec open question).

Do not start coding until each is answered.

## Step 3 — generate code in a new location

- **Do not modify any file in this `projects/apps/aadhat-management/`
  folder.** This repo is docs-only.
- Do not post to the v1 production repo at
  <https://github.com/DDancingDeath/AadhatManagementApp>.
- Generate the v2 app in a separate directory or new GitHub repo
  (e.g. `D:\AadhatApp\aadhat-v2`).
- In the generated repo's README, link back to:
  - This folder (for the spec)
  - `../plan/rebuild/` (for the opinionated guidance)
  - `../plan/review-issues.md` (for the do-not-reintroduce list)

## Step 4 — build in the order in the roadmap

Follow `../plan/rebuild/roadmap.md` M0 → M12. For each milestone:

1. Update `spec/rebuild/` if anything is unclear or has changed.
2. Add or extend scenario fixtures.
3. Write the tests (unit, scenario, invariant, integration,
   security, perf, E2E as applicable) **before** the
   implementation.
4. Implement the smallest coherent change that makes the tests
   pass.
5. Add or update UI only after the service it consumes is green.
6. Produce a release note describing what changed for the owner
   and for the brother.

## Step 5 — stand up the agent roster

`../plan/rebuild/agent-roster.md` defines six agent roles (Spec,
Test, Implementation, Performance, QA, Security, Reviewer). The
master prompt is in that file. Stand them up before milestone M1.

If a single human / agent will play multiple roles for now, the
roles still apply — switch hats explicitly and record which hat made
which decision.

## Quality bar (recap; full version in
`../spec/rebuild/quality-bar.md`)

- Domain unit test coverage `≥ 95%`; services `≥ 85%`.
- Every scenario fixture's replay matches its expected projection
  exactly.
- Every invariant in `../spec/rebuild/invariants.md` is asserted
  by an automated test.
- Every flow in `../spec/rebuild/quality-bar.md` §7 has a Playwright
  test.
- No UI action exceeds its budget in `../spec/rebuild/quality-bar.md`
  §9 on the reference device.
- No user-controlled string is ever rendered as raw HTML.
- Server-side rules enforce the role × event-type matrix. UI checks
  are advisory.

## What you must NOT do

- Don't write authoritative money math in any UI component.
- Don't mutate or delete events. Corrections / voids are new
  events.
- Don't create a sale event from the print path under any
  circumstance.
- Don't enable the Save button until the previous save call has
  resolved.
- Don't weaken a test to make implementation pass.
- Don't bypass the suspicion engine for "trusted" code paths.
- Don't relax server-side authorization for convenience.
- Don't add a feature without a scenario fixture for it.
- Don't post to the v1 production repo.
- Don't invent behaviour. `TODO(spec)` and ask.

## What to do when you finish

- Open a PR in the new repo with a short release note linking back
  here.
- Run the manual smoke test from `../spec/rebuild/quality-bar.md`
  on a real phone with a real printer before any production
  release.
- Tell the owner what changed, what is still risky, and what the
  Review Queue has been flagging.
