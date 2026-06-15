# Feature acceptance checklist — rebuild

> The contract that turns "I built it" into "it is done". Every
> feature in v2 lands with the layers below filled out. PRs missing
> any applicable layer are rejected by the Reviewer agent.

This file complements [`quality-bar.md`](./quality-bar.md): that
document defines the *test layers*, this one defines *which layers
a given feature must hit* and *what evidence each layer needs*.

## How to use this document

1. Find the feature kind in §3 ("Feature kinds").
2. Read its required layers (✅) and recommended layers (🟡).
3. For each ✅, satisfy the evidence requirement in §2 ("Evidence
   per layer").
4. Fill in the PR template in §4 and link the artefacts.

## 1. The seven layers

| Tag | Layer | Lives in |
|---|---|---|
| `unit` | Domain unit tests | `packages/domain/test/**` |
| `scenario` | Scenario fixture replays | `packages/domain/test/scenarios/**` |
| `invariant` | Invariant assertions over fixtures + random sequences | `packages/domain/test/invariants/**` |
| `security` | Permission / role / cross-shop rule tests | `packages/app/test/security/**` or rules emulator project |
| `playwright` | End-to-end UI tests | `apps/web/e2e/**` |
| `visual` | Visual regression snapshots | `apps/web/visual/**` |
| `perf` | Performance budgets from [`performance-budgets.md`](./performance-budgets.md) | `apps/web/perf/**` |

## 2. Evidence per layer

For each ✅ layer the PR must show:

### `unit`

- New or extended pure-function test(s) in `packages/domain/test/`.
- At least one positive case and one edge / negative case for any
  new formula or branch.
- Coverage delta does not drop the domain package below 95 %.

### `scenario`

- One of: a new fixture under `packages/domain/test/scenarios/`
  with intent / setup / sequence / expected projections / flags
  (per the template in [`scenarios.md`](./scenarios.md)), **or**
  an extension to an existing fixture's expected results.
- The scenario name appears in
  [`scenarios.md`](./scenarios.md) §catalogue.
- The replay passes deterministically (10 reruns in CI, fixed
  seed).

### `invariant`

- The label of every invariant relevant to the change is asserted
  by at least one fixture (mark the labels in the PR description).
- If the change introduces a new invariant, it is added to
  [`invariants.md`](./invariants.md) with an `M/S/O/C/B/A/R/X/T`
  label and tested across **every** existing fixture (not just the
  new one).
- Property-based suite seeds still pass.

### `security`

- For every event type the feature can append: a role-allowed
  test and a role-denied test (see
  [`role-permission-matrix.md`](./role-permission-matrix.md)).
- For every projection the feature reads: a cross-shop isolation
  test (when multi-shop is enabled).
- For any new idempotency-key shape: the conflict-rejection test
  (see [`idempotency.md`](./idempotency.md)).
- Audit log immutability test still passes.

### `playwright`

- One workflow end-to-end at the phone viewport.
- The workflow drives real UI events (no shortcut into the
  service layer).
- Workflow asserts the user-visible outcome and at least one side
  effect (history row, flag, projection value, audit row).
- Where printing is involved, the mock printer driver records
  exactly one `print_attempt` per user intent and the assertion
  pins the count.

### `visual`

- Updated screenshots committed alongside the change for each
  page that visibly changed.
- Snapshot diff reviewed in the PR; reviewer agent comments on
  any unintended change.
- Hindi-leading and English-leading variants both updated when
  labels change.

### `perf`

- The relevant budget(s) in
  [`performance-budgets.md`](./performance-budgets.md) are
  re-measured against the synthetic dataset.
- Regression ≤ 10 %; otherwise the PR includes a profiling note
  and a fix or a baseline bump (separate commit, reviewer
  sign-off).
- For any new long-running operation: a worker / off-main-thread
  test confirming the UI thread stays responsive.

## 3. Feature kinds → required layers

Legend: ✅ required, 🟡 recommended, — not applicable.

| Feature kind | `unit` | `scenario` | `invariant` | `security` | `playwright` | `visual` | `perf` |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| New event type (e.g. new sale variant) | ✅ | ✅ | ✅ | ✅ | ✅ | 🟡 | 🟡 |
| New invariant or rule | ✅ | ✅ | ✅ | 🟡 | 🟡 | — | — |
| New suspicion-engine rule | ✅ | ✅ | 🟡 | 🟡 | ✅ | 🟡 | — |
| New domain formula change (totals, COGS, etc.) | ✅ | ✅ | ✅ | — | 🟡 | — | 🟡 |
| New projection or projection field | ✅ | ✅ | ✅ | ✅ | ✅ | 🟡 | ✅ |
| New page or page section | 🟡 | 🟡 | — | ✅ | ✅ | ✅ | ✅ |
| New form field that affects an event payload | ✅ | ✅ | 🟡 | ✅ | ✅ | ✅ | 🟡 |
| Bill / print flow change | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Permission or role change | ✅ | 🟡 | 🟡 | ✅ | ✅ | — | — |
| Idempotency-key shape change | ✅ | ✅ | ✅ | ✅ | ✅ | — | 🟡 |
| Outbox / sync behaviour | ✅ | ✅ | ✅ | ✅ | ✅ | — | ✅ |
| Reconciliation job change | ✅ | ✅ | ✅ | 🟡 | 🟡 | — | ✅ |
| Visual-only refactor (no logic change) | — | — | — | — | 🟡 | ✅ | 🟡 |
| Internal refactor (no behaviour change) | ✅ | 🟡 | ✅ | 🟡 | 🟡 | — | 🟡 |
| Performance optimization | ✅ | 🟡 | ✅ | — | 🟡 | — | ✅ |
| New dependency or tooling change | — | — | — | 🟡 | 🟡 | — | 🟡 |
| Docs / spec only | — | — | — | — | — | — | — |

Notes:

- A "🟡 recommended" layer becomes ✅ if the change touches the
  layer's domain in any way. The Reviewer agent makes that call.
- Bill / print flow changes hit every layer because they are the
  highest-risk path in the product. There are no shortcuts here.
- Visual-only refactor still demands `visual`; that is the entire
  point of the refactor.

## 4. PR template

Every feature PR includes:

```markdown
## Summary
<one paragraph: what changed, why>

## Feature kind
<from §3>

## Spec deltas
- spec/rebuild/<file>.md — what section, what changed
- spec/rebuild/<other>.md — what section, what changed

## Test evidence
- unit: <files / test names>
- scenario: <fixture name + path>
- invariant: <labels M1/S2/...>
- security: <files / scenarios>
- playwright: <flow name + path>
- visual: <screenshots updated>
- perf: <budgets measured / regression %>

## Suspicion-engine impact
<new rule? existing rule affected? tests proving rule fires?>

## Audit-log impact
<new event type or new summary string? human-readable check?>

## Owner / brother release note
<one sentence each: what the owner will notice / what the brother will notice>
```

The Reviewer agent rejects PRs missing the kind, the spec deltas,
or any ✅ evidence line.

## 5. Definition of done (mirrored)

For convenience the definition of done from
[`quality-bar.md`](./quality-bar.md) is repeated here. A feature
ships when:

1. Spec is updated.
2. Domain unit tests cover new pure code.
3. Scenario tests cover new workflows.
4. Invariants still hold.
5. Service / integration tests cover the new service surface.
6. Security-rule tests cover any new permission paths.
7. Relevant Playwright workflow exists.
8. Visual snapshots updated and reviewed.
9. Perf budgets pass on the reference device profile.
10. Suspicion engine has rules and tests for any new anomaly class.
11. Audit log shows the new event type with a human-readable
    summary.
12. Release note exists.

## 6. Things that do not count as evidence

- "I tried it locally." — every layer must be in CI.
- A scenario without expected projections.
- An invariant assertion that catches only the happy path.
- A Playwright test that calls the service directly instead of
  driving the UI.
- A visual snapshot that was auto-accepted without review.
- A perf number measured on the development machine.

## 7. Reviewer agent contract

The Reviewer agent's checklist for each PR:

- [ ] Feature kind matches the diff
- [ ] Every ✅ for that kind has evidence
- [ ] Spec deltas exist and read sensibly
- [ ] Invariants list in PR matches what the diff actually touches
- [ ] Suspicion engine and audit log impacts addressed
- [ ] Release-note line is concrete enough that the owner /
      brother understands what changes for them
- [ ] No forbidden patterns (see [`quality-bar.md`](./quality-bar.md) §"What is forbidden")
- [ ] Recent-changes entry added to every modified spec file
