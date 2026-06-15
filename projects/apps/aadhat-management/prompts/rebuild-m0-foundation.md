# Build prompt — M0 foundation

Paste this prompt to the implementation agent at the very start
of the rebuild. Its job is to take the rebuild repo from "no
code" to "M0 green" — the scaffolding, the CI pipeline, the
fixture runner, and the domain event schemas — so that every
subsequent milestone can stand on the same foundation.

For all later milestones, use
[`build-rebuild.md`](./build-rebuild.md).

---

You are the **Implementation agent**. You are starting M0 of the
v2 rebuild of AadhatManagement.

**Do not invent behaviour.** If something is unclear, ask the
owner or stop and mark `TODO(spec)`.

## Step 1 — load context (read in this order)

1. `../README.md` — top-level orientation for the AadhatManagement
   docs.
2. `../spec/rebuild/README.md` — reading order for the rebuild
   spec subtree.
3. `../spec/rebuild/scope-boundaries.md` — what is in scope for
   v2.0.
4. `../spec/rebuild/architecture.md` — the layered architecture.
   Internalize the "UI is never the source of business truth"
   rule.
5. `../spec/rebuild/worked-example.md` — one retail bill traced
   end-to-end through every layer. This is the single most
   important doc for understanding "what does the scaffold need
   to make possible".
6. `../spec/rebuild/event-ledger.md`,
   `../spec/rebuild/event-schemas.md`,
   `../spec/rebuild/idempotency.md`,
   `../spec/rebuild/projections.md`,
   `../spec/rebuild/data-placement.md`,
   `../spec/rebuild/offline-sync.md`,
   `../spec/rebuild/versioning-compatibility.md` — the data
    layer the M0 scaffold must support. M0 does not implement
    every offline / cache / migration behaviour but the
    scaffold's storage and outbox shapes must be compatible
    with these contracts.
7. `../spec/rebuild/ci-contract.md` — the exact CI jobs the
   scaffold must wire up.
8. `../spec/rebuild/feature-acceptance.md` — the PR template
   the Reviewer agent will enforce starting from your very first
   PR.
9. `../plan/rebuild/decisions.md` — the frozen technical choices
   for v2.0.
10. `../plan/rebuild/roadmap.md` §M0 — the milestone scope.
11. `../plan/rebuild/tech-candidates.md` — background on why the
    `decisions.md` defaults were picked.
12. `../plan/rebuild/migration-cutover.md` — read once so you
    know cutover gates exist; M0 does not implement them.

## Step 2 — confirm decisions before any code

Open `../plan/rebuild/decisions.md`. Verify the M0 freeze
decisions (rows 1–5, and rows 8 & 10 if M0 touches weights or
cutover) are `confirmed`. If any is still `tentative`, **stop
and ask the owner**.

For v2.0 the agent-recommended frozen defaults are:

- UI framework: **SvelteKit**
- Backend: **Firebase (Firestore + Auth + Functions) only, no
  thin server**
- Package manager: **pnpm**
- `shopId` in schema from day one: **yes**, default `shop-1`
- Brother's role: **`owner`** for v2.0; defer dedicated
  `reviewer` to v2.1
- Weight unit: integer **milligrams**
- v1 → v2 cutover strategy: **snapshot import**

Do not start coding until those rows are `confirmed`.

## Step 3 — create the repo

- **Do not modify any file in this `projects/apps/aadhat-management/`
  folder.** This repo is docs-only.
- Do not post to the v1 production repo at
  <https://github.com/DDancingDeath/AadhatManagementApp>.
- Create a new GitHub repo (suggested name `AadhatManagementApp-v2`)
  with the layout below.

```
AadhatManagementApp-v2/
├── apps/
│   └── web/                  # SvelteKit app, Capacitor-wrappable
│       ├── playwright.config.ts
│       ├── visual.config.ts
│       ├── e2e/              # end-to-end flows
│       ├── visual/           # snapshot tests
│       └── perf/             # perf harness
├── packages/
│   ├── domain/               # pure business logic, no I/O
│   │   ├── src/
│   │   │   ├── events/       # event schemas (Zod)
│   │   │   ├── projections/  # apply folds
│   │   │   ├── invariants/   # M/S/O/C/B/A/R/X/T assertions
│   │   │   └── primitives/   # paise, mg, ids, time
│   │   └── test/
│   │       ├── unit/
│   │       ├── scenarios/    # fixture replays
│   │       ├── invariants/
│   │       └── property/
│   ├── app/                  # application services, storage adapters
│   │   ├── src/
│   │   │   ├── services/     # createRetailBill, requestPrint, …
│   │   │   ├── storage/
│   │   │   ├── outbox/
│   │   │   └── queue/        # print queue worker contract
│   │   └── test/
│   │       ├── integration/
│   │       └── security/
│   └── shared/               # cross-cutting types, error codes
├── fixtures/
│   ├── scenarios/            # one JSON per scenario in scenarios.md
│   └── perf-baseline.json
├── tools/
│   ├── perf/                 # perf runner
│   ├── rules/                # security-rule runner
│   └── docs/                 # link-check + recent-changes check
├── .github/workflows/        # CI pipeline (matches ci-contract.md)
├── package.json              # scripts match ci-contract.md exactly
├── pnpm-workspace.yaml
├── tsconfig.json
└── README.md                 # links back to the docs repo
```

The generated repo's README must link back to:

- This folder (the spec): `https://github.com/DDancingDeath/ideas/tree/main/projects/apps/aadhat-management`
- `spec/rebuild/` (authoritative for v2)
- `plan/rebuild/decisions.md` (frozen choices)
- `plan/review-issues.md` (do-not-reintroduce list)

## Step 4 — M0 deliverables (in this order)

For each numbered item: write the **tests first**, then the
implementation. PRs must satisfy
`spec/rebuild/feature-acceptance.md` for the kind "Internal
refactor (no behaviour change)" because nothing user-visible
ships in M0.

### M0.1 — Primitives

- `Paise` and `Mg` integer brand types.
- `IdempotencyKey` brand type.
- UUID v7 generator (`EventId`, `BillId`, etc.).
- `IsoTimestamp` and time-utility helpers.
- Coverage: 100 % on this package.

### M0.2 — Event schemas

- Zod schemas for all 22 event types from
  `spec/rebuild/event-schemas.md`, exporting both the runtime
  validator and the inferred TS type.
- Common envelope schema applied uniformly.
- Round-trip test: each example JSON in `event-schemas.md`
  parses, validates, re-serializes byte-equal.
- Negative tests for every "invalid examples" call-out.

### M0.3 — Scenario fixture runner

- Loads `fixtures/scenarios/<id>.json` (one per fixture named in
  `spec/rebuild/scenarios.md`).
- Each fixture file has the schema:
  ```jsonc
  {
    "id":            "simple-retail-day",
    "setup":         [ /* opening events */ ],
    "sequence":      [ /* events under test */ ],
    "expected": {
      "projections": { "stock": …, "cash": …, "outstanding": …,
                       "today": …, "audit": … },
      "flags":       [ /* expected flag rows */ ]
    }
  }
  ```
- For M0, ship **only one fixture (`simple-retail-day`)** so the
  runner is end-to-end exercisable. Later milestones add the
  remaining 14 from `spec/rebuild/scenarios.md`.

### M0.4 — Projection skeletons

- Implement the `apply` fold for every projection listed in
  `spec/rebuild/projections.md`, but only as much as
  `simple-retail-day` exercises. Stubs for the rest are allowed
  with `TODO(M<N>)` markers.

### M0.5 — Invariant runner

- Each M/S/O/C/B/A/R/X/T label is an `Invariant` object with
  `label`, `description`, `check(state) → InvariantResult`.
- Runner iterates all invariants after each fixture step.
- Failure produces a typed counterexample with label, fixture
  step, expected vs actual.

### M0.6 — In-memory storage adapter

- Implements `appendEvent` with the result codes documented in
  `spec/rebuild/idempotency.md` §Adapter contract.
- Implements `idempotencyKey` uniqueness, payload-equality
  re-use, and `IDEMPOTENCY_CONFLICT` rejection.
- No Firestore yet; M1 wires that.

### M0.7 — CI pipeline

- `.github/workflows/ci.yml` runs the 12 required jobs from
  `spec/rebuild/ci-contract.md`. Jobs that have nothing to run
  yet (e.g. `playwright`, `visual`, `perf`) execute a no-op
  passing stub so the matrix slot exists.
- `package.json` exposes the canonical scripts exactly as named
  in `ci-contract.md`.
- `npm-run-all` (or pnpm equivalent) wires `pnpm ci` to reproduce
  the pipeline locally.
- The docs link-check job runs against the rebuild repo's own
  Markdown.

### M0.8 — Reviewer-agent enforcement

- Add a PR template at `.github/pull_request_template.md` that
  mirrors `spec/rebuild/feature-acceptance.md` §4.
- Add a check (`tools/docs/recentchanges.mjs`) that fails CI if
  any spec file linked from the PR was modified without a dated
  Recent-changes entry. (For M0 there is no spec subtree inside
  the rebuild repo; this check is a no-op until M1.)

### M0.9 — Worked-example smoke test

- A single Playwright-less, in-memory test reproduces the trace
  in `spec/rebuild/worked-example.md`:
  setup → `retail_sale_created` event → projections updated →
  print-attempt → print-succeeded → audit-log has 3 rows → all
  invariants green.
- This test is the **canary**: if it fails, the foundation is
  broken and M1 cannot start.

## Step 5 — exit criteria for M0

M0 is done when all of the following are true:

- [ ] Repo created with the layout above.
- [ ] `pnpm ci` passes locally on a fresh clone.
- [ ] CI pipeline green on `main`.
- [ ] The 12 jobs in `ci-contract.md` each have a slot (real or
      no-op stub) and report status on every PR.
- [ ] `simple-retail-day` scenario fixture replays cleanly.
- [ ] The worked-example smoke test is green.
- [ ] Domain package coverage `≥ 95 %` (it is tiny; this is
      easy at M0 and sets the discipline).
- [ ] Reviewer agent's PR template is the default for new PRs.
- [ ] Repo README links back to this docs repo.

When all green, file a PR titled `M0: foundation green` against
the rebuild repo's `main`, get the Reviewer agent's sign-off,
merge, and then start M1.

## What you must NOT do at M0

- Don't write any screen UI yet. M0 is foundation only.
- Don't import v1 data. That belongs to cutover, not M0.
- Don't wire Firebase yet. In-memory only; M1 swaps the adapter.
- Don't add more than the one fixture (`simple-retail-day`).
  Later milestones add the rest as the features land.
- Don't weaken a test to make a job pass. If the test was wrong,
  rewrite it with explicit justification.
- Don't bypass the Reviewer agent's PR template even for the
  scaffolding PRs.

## What to do when you finish

- File `M0: foundation green` and tag the Reviewer agent.
- Tell the owner: scaffold is up, foundation is green, M1
  (auth + roles) is ready to start, and what (if anything) the
  brother should look at in the new CI pipeline.
