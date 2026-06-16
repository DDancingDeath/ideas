# Getting started — Day 0

> The single "where do I actually begin?" sequencer for the v2
> rebuild. Everything here links to the doc that owns the detail;
> this page only puts the steps in order so nothing is missed on
> day one. Read [`roadmap.md`](./roadmap.md) for the milestone map
> and [`../../spec/rebuild/worked-example.md`](../../spec/rebuild/worked-example.md)
> to understand the architecture before you write any code.

## Are we ready to start? (readiness gate)

Start M0 only when every box is checked. As of 2026-06-16 the spec
and plan rows are done; the prerequisites are the owner's to tick.

**Spec / plan readiness — done:**

- [x] Roadmap M0 → M12 sequenced ([`roadmap.md`](./roadmap.md)).
- [x] Freeze-before-M0 decisions confirmed — rows 1–10 are
      `confirmed` ([`decisions.md`](./decisions.md)). No row is
      `tentative`.
- [x] Milestone-blocking open questions captured with
      recommendations (M3–M11 in [`decisions.md`](./decisions.md)
      §Open questions). None block M0.
- [x] M0 playbook written
      ([`../../prompts/rebuild-m0-foundation.md`](../../prompts/rebuild-m0-foundation.md)).
- [x] M1-onward build prompt written
      ([`../../prompts/build-rebuild.md`](../../prompts/build-rebuild.md)).
- [x] Agent roster + master prompt written
      ([`agent-roster.md`](./agent-roster.md)).
- [x] CI contract, quality bar, scenarios, and worked example exist
      in [`../../spec/rebuild/`](../../spec/rebuild/).

**Prerequisites — owner to tick before M0:**

- [ ] A new, empty GitHub repo (suggested `AadhatManagementApp-v2`).
      Do **not** reuse the v1 repo and do **not** touch this
      docs repo.
- [ ] Node LTS + **pnpm** installed (stack frozen in
      [`decisions.md`](./decisions.md) rows 1–3;
      [`tech-candidates.md`](./tech-candidates.md) for background).
- [ ] Firebase project access with the **emulator suite** available
      for local rule tests (backend frozen as Firebase, row 2; v1
      project notes in [`../setup/firebase-setup.md`](../setup/firebase-setup.md)
      and [`../setup/environment-setup.md`](../setup/environment-setup.md)).
- [ ] The reference Android device in hand for perf baselines
      (mid-range ₹15–20k, [`decisions.md`](./decisions.md) row 6).
      Not needed to start M0; needed by M0's perf-budget stub and
      seriously by M7+.
- [ ] A real ESC/POS Bluetooth printer for the M11 smoke test
      (background in [`../setup/bluetooth-printer.md`](../setup/bluetooth-printer.md)
      and [`../../spec/rebuild/printer-compatibility.md`](../../spec/rebuild/printer-compatibility.md)).
      Not needed until M11.

## The first five steps

1. **Confirm the freeze is still frozen.** Open
   [`decisions.md`](./decisions.md). Every freeze row must read
   `confirmed`. If anyone slipped one back to `tentative`, stop and
   resolve it — silent reverts are forbidden.
2. **Create the repo** with the layout in
   [`../../prompts/rebuild-m0-foundation.md`](../../prompts/rebuild-m0-foundation.md)
   §Step 3, and link it back to this docs folder, to
   `spec/rebuild/`, and to
   [`../review-issues.md`](../review-issues.md) (the
   do-not-reintroduce list).
3. **Run M0.** Paste
   [`../../prompts/rebuild-m0-foundation.md`](../../prompts/rebuild-m0-foundation.md)
   into the Implementation agent. It takes the repo from "no code"
   to "M0 green": primitives, the 22 event schemas, the scenario
   fixture runner, projection skeletons, the invariant runner, the
   in-memory storage adapter, the CI pipeline
   ([`../../spec/rebuild/ci-contract.md`](../../spec/rebuild/ci-contract.md)),
   and the worked-example smoke test.
4. **Pass the M0 exit criteria** listed at the end of that prompt
   (`pnpm ci` green on a fresh clone; the 12 CI jobs each have a
   slot; `simple-retail-day` replays; the worked-example canary is
   green; domain coverage ≥ 95 %). File `M0: foundation green`.
5. **Stand up the agents and start M1.** Switch to
   [`../../prompts/build-rebuild.md`](../../prompts/build-rebuild.md)
   and the roster in [`agent-roster.md`](./agent-roster.md), driven
   by [`agent-orchestration.md`](./agent-orchestration.md) (the
   Orchestrator, the task-ticket format, and sub-agent fan-out).
   From here every milestone follows the same loop: spec → fixtures →
   tests → implementation → UI → release note
   ([`roadmap.md`](./roadmap.md) §Sequencing principle).

## The loop, every milestone after M0

```
spec/rebuild  →  scenario fixtures  →  tests  →  implementation
      ▲                                              │
      └──────────  UI (only after service green)  ───┘
                            │
                   audit + release note
```

Release discipline is in
[`release-health-gates.md`](./release-health-gates.md); operations
and rollback in [`operations-runbook.md`](./operations-runbook.md);
the v1 → v2 switch in
[`migration-cutover.md`](./migration-cutover.md) (M12, not before).

## Known open items that are not M0 blockers

These are captured so they are not forgotten; none of them stop you
from starting M0 today.

- **How the agents are driven** is settled in
  [`agent-orchestration.md`](./agent-orchestration.md) (Orchestrator
  role, task-ticket format, sub-agent fan-out, recommended Copilot
  CLI host). A single builder can still start M0 solo; read the
  orchestration doc before scaling past one agent.
- **The 9 scenario-fixture gaps** in
  [`../../spec/rebuild/scenarios.md`](../../spec/rebuild/scenarios.md)
  §Coverage map (rate-change-day, expenses-and-withdrawals-day,
  supplier-payment, …). Each is written as its feature milestone
  lands, not up front.
- **Per-milestone open questions** (M3–M11) in
  [`decisions.md`](./decisions.md) §Open questions — each only needs
  an answer when that milestone is approached.
- **The kg → mg schema migration** inside
  [`../../spec/rebuild/event-schemas.md`](../../spec/rebuild/event-schemas.md)
  §Open questions is an explicit M0 task (the unit is decided —
  integer mg — only the literal schemas still show kg).

## Recent changes

- _2026-06-16_ (later) · Pointed step 5 and the "known open items" at
  the new [`agent-orchestration.md`](./agent-orchestration.md); the
  agent-host item is no longer a `TODO(plan)` (a recommended Copilot
  CLI host is now settled there).
- _2026-06-16_ · File created. Consolidates the previously scattered
  start steps (prerequisites, freeze check, repo creation, the M0
  prompt, exit criteria, agent standup) into one Day-0 sequencer so
  nothing is missed on the first day. Pure connective tissue; every
  detail still lives in the doc that owns it.
