# CI contract — rebuild

> The exact pipeline gates the v2 rebuild repo's CI must enforce.
> Lives in `spec/` (not `plan/`) because the gates are part of the
> definition of "merged" — they are not opinions.

## Required jobs (every PR)

| # | Job ID | Purpose | Fails the build when |
|---|---|---|---|
| 1 | `lint` | Static style + formatting | Any lint or formatter error |
| 2 | `typecheck` | TypeScript strict | Any type error in `packages/**`, `apps/**` |
| 3 | `unit` | Domain pure-function tests | Any failure; domain coverage < **95 %**; services coverage < **85 %** |
| 4 | `scenario` | Scenario fixture replays from [`scenarios.md`](./scenarios.md) | Any fixture's replay diverges from its expected projections |
| 5 | `invariant` | Invariant assertions over fixtures + property-based with **fixed seed** | Any `M/S/O/C/B/A/R/X/T` invariant in [`invariants.md`](./invariants.md) fails |
| 6 | `security` | Role × event-type tests + cross-shop isolation + idempotency-conflict tests | Any forbidden write succeeds, any allowed write fails, any cross-shop read leaks, any idempotency-conflict is accepted |
| 7 | `integration` | Application services against in-memory storage + mock printer + mock BT | Service contract drift; outbox replay duplication; ordering bug |
| 8 | `playwright` | End-to-end UI flows from [`quality-bar.md`](./quality-bar.md) §7 against in-memory backend | Any required flow fails; `print_attempt` count diverges from user intent count |
| 9 | `visual` | Phone-viewport snapshot diff for changed pages | Snapshot diff above tolerance and not reviewer-accepted |
| 10 | `perf` | Budgets from [`performance-budgets.md`](./performance-budgets.md) on the synthetic dataset against the reference profile | Any budget regresses > **10 %** vs `fixtures/perf-baseline.json` |
| 11 | `rules` | Backend security-rules tests (Firestore emulator or chosen backend's test mode) | Any rule from [`role-permission-matrix.md`](./role-permission-matrix.md) misbehaves |
| 12 | `docs` | Markdown link-check + dated `Recent changes` entry presence for every spec file touched | Any broken relative link; any modified `spec/rebuild/**` file missing a `Recent changes` entry for the PR's date |

All 12 jobs run in parallel on every PR. A PR cannot merge with
any required job failing.

## Required jobs (nightly)

| # | Job ID | Purpose |
|---|---|---|
| N1 | `playwright-real-backend` | Same E2E suite as `playwright` but against the real backend in a staging project |
| N2 | `invariant-random-seeds` | Property-based suite with **random seeds** (not the fixed PR seed) |
| N3 | `perf-lower-end` | Perf suite on the lower-end device profile; **record only**, not blocking |
| N4 | `migration-check` | Run `migration check *` commands from [`../../plan/rebuild/migration-cutover.md`](../../plan/rebuild/migration-cutover.md) against the latest snapshot import |
| N5 | `bundle-size` | UI bundle size budget; non-blocking warning above threshold |

Nightly failures open a `Sev-2` issue automatically and notify the
brother + owner agents.

## Canonical commands

The rebuild repo's `package.json` must expose **exactly** the
following scripts so every agent and human invokes the same thing:

```jsonc
{
  "scripts": {
    "lint":         "<linter> --max-warnings 0",
    "typecheck":    "tsc --noEmit",
    "unit":         "<vitest|equivalent> run --coverage packages/**/test/unit",
    "scenario":     "<vitest|equivalent> run packages/**/test/scenarios",
    "invariant":    "<vitest|equivalent> run packages/**/test/invariants",
    "security":     "<vitest|equivalent> run packages/**/test/security",
    "integration":  "<vitest|equivalent> run packages/**/test/integration",
    "playwright":   "playwright test --config=apps/web/playwright.config.ts",
    "visual":       "playwright test --config=apps/web/visual.config.ts",
    "perf":         "node tools/perf/run.mjs --baseline fixtures/perf-baseline.json",
    "rules":        "node tools/rules/run.mjs",
    "docs":         "node tools/docs/linkcheck.mjs && node tools/docs/recentchanges.mjs",
    "ci":           "npm-run-all -p lint typecheck unit scenario invariant security integration rules docs && npm-run-all -p playwright visual perf"
  }
}
```

Notes:

- `<vitest|equivalent>` resolves to the runner picked in
  [`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md).
- `ci` is the single command an agent runs locally to reproduce
  the pipeline. If it passes locally, it must pass in CI; any
  divergence is a CI bug, not a flake.

## Job inputs and artefacts

Every job declares its inputs and what it writes:

| Job | Inputs | Artefacts |
|---|---|---|
| `lint` | source files | none |
| `typecheck` | source + `tsconfig` | none |
| `unit` | source + `packages/**/test/unit/**` | coverage report (uploaded) |
| `scenario` | source + `packages/**/test/scenarios/**` + fixture JSONs | per-fixture replay log on failure |
| `invariant` | source + `packages/**/test/invariants/**` | seed + counterexample on failure |
| `security` | source + `packages/**/test/security/**` | per-rule pass/fail matrix |
| `integration` | source + `packages/**/test/integration/**` | service-call trace on failure |
| `playwright` | `apps/web` + flows | trace zip + screenshots on failure |
| `visual` | `apps/web` + baseline snapshots | diff images on failure |
| `perf` | synthetic dataset + baseline | measurement JSON; if green, uploaded as new candidate baseline |
| `rules` | backend rules + test cases | per-rule pass/fail matrix |
| `docs` | all `.md` files | broken-link list on failure |

All artefacts are downloadable from the PR check page so the
implementing agent (and the reviewer agent) can diagnose without
re-running.

## Baseline-bump protocol

`perf` and `visual` jobs compare to a checked-in baseline. To
update a baseline:

1. Land the change with the failing assertion (the PR is red).
2. Open a separate follow-up PR titled `perf:baseline: <area> <delta>` or `visual:baseline: <page>`.
3. The follow-up PR contains **only** the baseline update plus a
   reviewer-approved rationale.
4. Reviewer agent verifies the rationale matches the original
   change and merges.

Direct edits to baseline files in a feature PR are rejected by
the Reviewer agent.

## Flakiness policy

- A test that flakes ≥ 3 times in 30 days is automatically
  quarantined (skipped from required gates) and an issue is filed.
- Quarantined tests do **not** count toward coverage.
- An invariant or security test cannot be quarantined — it must
  be fixed or rewritten, never silenced.

## Forbidden in CI

- Disabling a required job to make a PR mergeable.
- Re-running a single job to flip red → green without a code
  change. (Re-runs to confirm flake are allowed and logged.)
- Lowering coverage thresholds without an owner-signed-off PR
  carrying the diff in this file.
- Adding `--forceExit`, `--bail`, `--retries`, or anything that
  hides a test failure.
- Marking a snapshot or baseline as accepted from inside a
  feature PR.

## Recent changes

- _2026-06-15_ · file created. Required jobs, nightly jobs,
  canonical commands, artefact contract, baseline-bump protocol,
  flakiness policy.
