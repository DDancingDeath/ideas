# Reading tracks

Two audiences read this project. Either may read the other's track — nothing
is hidden, and every doc cross-links — but neither *needs* to.

| Track | Files | Lines | Roughly |
| --- | ---: | ---: | --- |
| **Human** — what the app promises, what was decided, what gets built next | 8 | **1 565** | 45–60 min, or 25 min if you skip the README changelog |
| **Agent** — everything needed to implement | 87 | 16 049 | not meant to be read linearly |

## Human track

Read in this order. It is enough to hold an opinion about the product
without reading a single payload schema.

| # | File | Lines | What you get |
|---|---|---:|---|
| 1 | [`README.md`](./README.md) | 470 | The narrative entry point: problem, how it works, what it does today, what v2 changes, tech stack, known issues. **The last 148 lines are the project changelog — skip on a first read.** |
| 2 | [`idea.md`](./idea.md) | 72 | The vision in detail: who it is for, success criteria, non-goals |
| 3 | [`spec/rebuild/README.md`](./spec/rebuild/README.md) | 102 | The index — all 36 v2 docs in four groups, one line each on what it settles |
| 4 | [`spec/rebuild/worked-example.md`](./spec/rebuild/worked-example.md) | 284 | One retail bill traced end to end. **Read this if you read only one file** — it makes the other 35 click |
| 5 | [`spec/rebuild/scope-boundaries.md`](./spec/rebuild/scope-boundaries.md) | 172 | Core vs configurable vs shop-custom vs explicitly out |
| 6 | [`spec/rebuild/invariants.md`](./spec/rebuild/invariants.md) | 183 | The business laws. The `Constitution` section at the top is eight plain-language rules — that alone is worth the read |
| 7 | [`plan/rebuild/decisions.md`](./plan/rebuild/decisions.md) | 90 | Every frozen decision, with rationale and date. What is settled and what is deferred |
| 8 | [`plan/rebuild/roadmap.md`](./plan/rebuild/roadmap.md) | 192 | Milestones M0–M12 and the order of work |

**Shortest useful path (≈390 lines):** #3 the index → #4 the worked example
→ the `Constitution` table at the top of #6.

## Agent track

Everything, including the human track. Enter at
[`spec/rebuild/README.md`](./spec/rebuild/README.md) and follow its order —
it is built to be read straight through by a machine.

| Area | Files | Lines | Contains |
| --- | ---: | ---: | --- |
| `spec/rebuild/` | 37 | 7 362 | The v2 source of truth: event schemas, projections, invariants, permissions, concurrency, offline sync, printing, budgets, CI contract, fixtures |
| `spec/page-specs/` | 18 | 1 907 | The v1 behavioural reference — one contract per screen. Authoritative for "does v2 still do this?" |
| `spec/` (v1 designs) | 5 | 1 297 | Firestore rules design, voice billing v2, chat design, capabilities inventory, mobile enhancements. Each is banner-marked **v1**; where they disagree with `spec/rebuild/`, `spec/rebuild/` wins |
| `plan/` | 21 | 4 197 | Opinionated: roadmap, decisions, agent roster and orchestration, migration/cutover, runbook, release gates, known v1 defects |
| `prompts/` | 3 | 666 | Paste-ready build prompts (M0 foundation, v2 milestones, v1 rebuild) |

Two entry points worth knowing:

- [`spec/rebuild/configuration.md`](./spec/rebuild/configuration.md) — the
  single home for every threshold, timeout, limit and default. Other docs
  name a key; only this one carries its value.
- [`prompts/rebuild-m0-foundation.md`](./prompts/rebuild-m0-foundation.md) —
  where an implementing agent actually starts.

## Not in either track

[`archive/spec-file-changelogs.md`](./archive/spec-file-changelogs.md) — 673
lines of per-file changelog removed from the spec on 2026-09-12 and kept for
history. Nobody needs to read it.
