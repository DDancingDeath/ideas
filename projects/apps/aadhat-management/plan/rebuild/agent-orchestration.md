# Agent orchestration — rebuild

> Opinion: [`agent-roster.md`](./agent-roster.md) says **who** the
> agents are. This file says **how they are driven** — decomposition,
> the task format, sub-agent fan-out, coordination, and the
> human-in-the-loop seams — so a milestone can be executed by agents
> in parallel without stepping on each other or drifting from the
> spec. Roles without orchestration stall; orchestration without
> role separation produces one over-eager do-everything agent, which
> is exactly what the rebuild exists to escape.

## The three layers

| Layer | Who | Lifetime | Owns |
|---|---|---|---|
| **Orchestrator** (lead) | 1 per active milestone | the milestone | the backlog, decomposition, assignment, sequencing, owner reporting |
| **Role agents** | the 7 in [`agent-roster.md`](./agent-roster.md) | long-running | their slice of every task (Spec / Test / Implementation / Performance / QA / Security / Reviewer) |
| **Sub-agents** | spawned on demand | one bounded task | a single fan-out unit (one fixture, one projection, one probe); no memory of their own |

The Orchestrator is **new** relative to the roster — it is the
coordination layer the roster's linear `Spec → … → Reviewer` diagram
assumes but never names.

## The Orchestrator

One Orchestrator drives one milestone at a time. It is the owner's
single point of contact.

**Each milestone it:**

1. Reads [`roadmap.md`](./roadmap.md) §M-N and the relevant
   `spec/rebuild/` docs.
2. Decomposes the milestone into **task tickets** (schema below).
3. Builds the dependency graph (what is serial, what is parallel —
   see [§Parallelization](#parallelization-model)).
4. Assigns each ticket to a role agent and tracks status on the
   board.
5. Drives the per-task loop and unblocks stalls.
6. Batches questions to the owner instead of interrupting per-ticket.
7. Produces the milestone release note and updates
   [`release-health-gates.md`](./release-health-gates.md) state.

**It never:** writes production code or tests itself, overrides the
Reviewer, merges a PR, or invents an answer to a `TODO(spec)`. Those
belong to the role agents and the owner.

## The task envelope — the format every agent task uses

Every unit of agent work is a **ticket** with this shape (it
formalises the "for every task you accept" list in the roster's
master prompt). One ticket = one branch = one PR.

```jsonc
{
  "id":         "M1-T07",                 // milestone-task id
  "milestone":  "M1",
  "role":       "Implementation",         // the owning roster role
  "title":      "Cash open/close/mismatch math",
  "specRefs":   ["spec/rebuild/invariants.md#cash",
                 "spec/rebuild/money-units-rounding.md"],
  "affects": {
    "events":     ["cash_session_opened", "cash_session_closed"],
    "invariants": ["C1", "C2", "C3", "C5"],
    "rules":      []
  },
  "testsFirst": [                          // named, written BEFORE code
    "cash-open-sets-expected",
    "cash-close-mismatch-flagged"
  ],
  "paths":      ["packages/domain/src/cash/**"],  // files this ticket may touch
  "dod":        ["unit", "invariant"],     // ci-contract.md jobs that must pass
  "escalateIf": ["a TODO(spec) blocks", "an invariant needs a new label",
                 "a decisions.md row would have to change"],
  "status":     "todo"                     // todo | in-progress | blocked | in-review | done
}
```

Rules that make the format robust:

- **`testsFirst` is mandatory and non-empty** for any behaviour
  ticket — the Test agent writes these before the Implementation
  agent starts (roadmap §Sequencing principle).
- **`paths` is a claim.** The Orchestrator refuses to run two
  in-flight tickets whose `paths` overlap (see
  [§Coordination](#coordination-and-state)).
- **`dod` lists the exact CI jobs** from
  [`../../spec/rebuild/ci-contract.md`](../../spec/rebuild/ci-contract.md)
  that gate the ticket — no "looks done", only green jobs.
- **`escalateIf`** is the agent's stop list. Hitting any of these
  pauses the ticket and routes to the owner via the Orchestrator
  (never invent the answer).

## Sub-agents — when and how to fan out

A role agent may spawn **sub-agents** for bounded, independent work,
then fold the results back. This is how a milestone gets fast without
losing the safety net.

**Fan out when the work is N independent units:**

- The Test agent authoring the **scenario fixtures** for a milestone
  — one sub-agent per fixture (the 9 gaps in
  [`../../spec/rebuild/scenarios.md`](../../spec/rebuild/scenarios.md)
  §Coverage map are a natural fan-out).
- The Implementation agent filling **independent projection folds**
  or per-rule handlers that do not share state.
- The Security agent generating **one rule-test per role × event-type
  cell**.
- Any **read-only exploration** ("where is X used", "does v1 do Y") —
  parallel probes that return a summary, never an edit.
- Mechanical **multi-file edits** with a single clear rule (rename,
  signature change) once the Reviewer has approved the rule.

**Do not fan out for:**

- Anything that changes a **shared invariant, event schema, or
  `decisions.md` row** — those are serial and single-owner; parallel
  edits race.
- Tasks smaller than the spawn overhead (a one-line fix).
- Anything on the `escalateIf` list — escalate, don't parallelise.

**Fan-out / fan-in protocol:**

1. The parent agent writes a one-paragraph brief per sub-agent with
   **full context** (sub-agents are stateless — assume they know
   nothing).
2. Each sub-agent returns a **diff or a summary**, not a merge — it
   never pushes to the shared branch itself.
3. The parent **integrates**, runs the `dod` jobs locally, and owns
   the single PR. Sub-agent output that fails review is the parent's
   problem to fix or re-spawn.
4. If two sub-agents would touch the same file, that is a planning
   error — split the task differently so each sub-agent owns disjoint
   `paths`.

## Coordination and state

| Concern | Mechanism |
|---|---|
| **Backlog / board** | One GitHub Issue per task ticket; a Project board column per `status`. The Orchestrator owns the board. |
| **Handoff artifact** | The **PR** — one ticket, one branch, one PR. A stage hands to the next by passing CI and Reviewer, not by chat. |
| **Agent memory** | A shared **session-store** (decisions, conventions, per-ticket status) so a restarted agent rehydrates. |
| **Collision avoidance** | The ticket's **`paths` claim**. The Orchestrator never runs two in-flight tickets with overlapping `paths`; overlapping work is serialised or re-split. |
| **Merge gate** | The **Reviewer** is the only agent that merges. Ties between agents are the Reviewer's call, recorded in the merge commit (roster §Workflow). |
| **Convention drift** | Every spec/plan edit adds a dated `## Recent changes` entry; the M0.8 recent-changes CI check enforces it. |

## Parallelization model

The hard dependency is **serial**:

```
event schemas  →  projections  →  application services  →  UI
   (M0/M2)          (M2)              (M1/M4)              (M6+)
```

Within a stage, independent units run **in parallel**:

| Stage | Parallel units (fan out) | Serial / single-owner |
|---|---|---|
| Domain math (M1) | cash / stock / outstanding / period math modules | the shared invariant runner + label set |
| Event schemas (M0/M2) | one schema per event type | the common envelope + result-code enum |
| Projections (M2) | one `apply` fold per projection | the projection interface |
| Suspicion (M5) | one positive+negative fixture per rule | the engine's dispatch + `shopProfile` thresholds |
| UI (M6–M10) | one page per agent | the shared shell, router, design primitives |

The Orchestrator reads this table to decide what to fan out and what
to keep single-threaded.

## The orchestrated milestone loop

For any milestone **M-N**:

1. **Plan** — Orchestrator opens the tickets and the dependency graph.
2. **Spec** — Spec agent resolves any `TODO(spec)` for M-N (or
   escalates to the owner). No code starts on an ambiguous spec.
3. **Test (fan-out)** — Test agent spawns a sub-agent per fixture /
   per invariant and lands the **failing** tests first.
4. **Implement** — Implementation agent makes them pass with the
   smallest coherent change, fanning out only on disjoint `paths`.
5. **Harden (parallel)** — Performance, QA, and Security run
   concurrently against the green build (perf budgets, Playwright
   flows, rule/role-matrix tests).
6. **Gate** — Reviewer checks spec-fidelity, layering, and the `dod`
   jobs, then merges or bounces.
7. **Close** — Orchestrator writes the release note and, at a real
   release, walks [`release-health-gates.md`](./release-health-gates.md).

A change is mergeable when every role says yes **or** the Reviewer
records an explicit override with rationale (roster §Workflow).

## Human-in-the-loop seams

Agents are autonomous **inside** a ticket; the owner is pulled in only
at these seams, and the Orchestrator **batches** them:

- A `TODO(spec)` with no safe default (master-prompt rule: stop, ask).
- A change that would touch a **frozen `decisions.md` row** (requires
  a `superseded` entry, never a silent flip).
- An **invariant or scope conflict** between two agents the Reviewer
  cannot resolve from the spec.
- A **Reviewer override** of another agent.
- **Milestone sign-off** — always for M3 (auth), M11 (real printer),
  and M12 (cutover); a quick ack for the rest.

## Where the agents run (recommended default)

This resolves the `TODO(plan)` in
[`agent-roster.md`](./agent-roster.md) §Where the agents live. Treat
it like a `decisions.md` recommendation — adopt it as the default,
record a `superseded` note if you change it.

**Recommended:** Copilot CLI.

- One **Orchestrator** session + one session per role, all sharing
  the **session-store** for memory and status.
- Role agents spawn **sub-agents via the Task tool** for the fan-out
  units above.
- **GitHub Issues + PRs** are the board and the handoff artifact.
- **Scheduled prompts** drive the recurring cadence — the M5
  reconciliation sweep, the QA smoke pass, the nightly CI summary.

**Lighter alternative** (solo owner, early milestones): the owner
plays **Orchestrator + Reviewer**; Test / Implementation / QA /
Security / Performance are agents. The loop and the task format are
unchanged — only the head-count shrinks.

Whichever host: **keep the role separation and the task format.**
Collapsing the roles back into one agent is the failure mode the
whole rebuild is built to avoid.

## Recent changes

- _2026-06-16_ · File created. Adds the orchestration layer the
  roster implied but never specified: the Orchestrator role, the
  task-envelope format (one ticket = one branch = one PR), the
  sub-agent fan-out / fan-in protocol, the coordination + `paths`
  collision rule, the parallelization dependency model, the
  orchestrated milestone loop, the human-in-the-loop seams, and a
  recommended host that resolves the roster's `TODO(plan)`.
