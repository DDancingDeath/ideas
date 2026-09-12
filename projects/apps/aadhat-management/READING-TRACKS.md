# Reading tracks

Three audiences read this project, and they are asking different questions.
Read your own track. Everything cross-links, so read another's whenever you
need to — nothing here is hidden.

| Track | Who | Files | Lines |
| --- | --- | ---: | ---: |
| **Owner** | Deciding what to build, what it must catch, who may do what | 8 | **1 526** |
| **Engineer** | Judging whether the design is correct | 5 | **911** |
| **Agent** | Implementing it | 88 | 16 145 |

**In ten minutes** (~390 lines), read the index
[`spec/rebuild/README.md`](./spec/rebuild/README.md), then
[`worked-example.md`](./spec/rebuild/worked-example.md) — one bill traced
end to end — then the `Constitution` table at the top of
[`invariants.md`](./spec/rebuild/invariants.md). That is enough to follow any
other conversation about this project.

## Owner track — 1 526 lines

What the app promises the shop, and what it refuses to let happen. Skip the
last 148 lines of the README (the changelog) and this is ~1 380.

| # | File | Lines | The question it answers |
|---|---|---:|---|
| 1 | [`README.md`](./README.md) | 480 | What is this, how does it work, what does it do today, what changes in v2 |
| 2 | [`idea.md`](./idea.md) | 72 | Who it is for, what counts as success, what it deliberately is not |
| 3 | [`spec/rebuild/scope-boundaries.md`](./spec/rebuild/scope-boundaries.md) | 172 | What is in v2.0, what is configurable, what is explicitly out |
| 4 | [`spec/rebuild/suspicion-engine.md`](./spec/rebuild/suspicion-engine.md) | 152 | **What the app catches when something goes wrong** — wrong price, impossible stock, duplicate bill, cash that does not add up. The reason the rebuild exists |
| 5 | [`spec/rebuild/role-permission-matrix.md`](./spec/rebuild/role-permission-matrix.md) | 199 | Who may do what. Staff vs manager vs owner, and what a staff member can never do even with the API |
| 6 | [`spec/rebuild/analytics.md`](./spec/rebuild/analytics.md) | 169 | What the app will tell you: margins, dead stock, who owes you, peak hours |
| 7 | [`plan/rebuild/decisions.md`](./plan/rebuild/decisions.md) | 90 | Every decision already frozen, with its reason and date |
| 8 | [`plan/rebuild/roadmap.md`](./plan/rebuild/roadmap.md) | 192 | Milestones M0–M12 and the order of work |

## Engineer track — 911 lines

Whether the design holds up. Assumes you do not care about shop workflow.

| # | File | Lines | The question it answers |
|---|---|---:|---|
| 1 | [`spec/rebuild/README.md`](./spec/rebuild/README.md) | 102 | The map — 37 docs, one line each on what each one settles |
| 2 | [`spec/rebuild/worked-example.md`](./spec/rebuild/worked-example.md) | 284 | One retail bill through every layer: UI intent → service → event → projection → print → audit → test |
| 3 | [`spec/rebuild/invariants.md`](./spec/rebuild/invariants.md) | 183 | The business laws and how each is enforced. Start at the `Constitution` table |
| 4 | [`spec/rebuild/architecture.md`](./spec/rebuild/architecture.md) | 219 | Layering, and why the UI is never allowed to own business truth |
| 5 | [`spec/rebuild/event-ledger.md`](./spec/rebuild/event-ledger.md) | 123 | Why everything is an append-only event and everything else is derived |

## Stretch — read when the question comes up

Not part of either track. Each is self-contained; go to the one that matches
your question rather than reading them in order.

| File | Lines | Read it when |
|---|---:|---|
| [`review-queue.md`](./spec/rebuild/review-queue.md) | 120 | "Where do the flags actually land, and who clears them?" |
| [`failure-modes.md`](./spec/rebuild/failure-modes.md) | 212 | "What happens when the phone dies mid-bill / Firebase is down / the clock is wrong?" |
| [`ergonomics.md`](./spec/rebuild/ergonomics.md) | 217 | "Can it actually be used one-handed, in sunlight, in Hindi?" |
| [`data-governance.md`](./spec/rebuild/data-governance.md) | 269 | "Who owns the data, what is kept, what can never be deleted?" |
| [`observability.md`](./spec/rebuild/observability.md) | 203 | "When something breaks, how would we even know?" |

## Agent track — everything

Enter at [`spec/rebuild/README.md`](./spec/rebuild/README.md) and follow its
order; it is built to be read straight through by a machine.

| Area | Files | Lines | Contains |
| --- | ---: | ---: | --- |
| `spec/rebuild/` | 37 | 7 362 | The v2 source of truth: event schemas, projections, invariants, permissions, concurrency, offline sync, printing, budgets, CI contract, fixtures |
| `spec/page-specs/` | 18 | 1 907 | The v1 behavioural reference — one contract per screen. Authoritative for "does v2 still do this?" |
| `spec/` (v1 designs) | 5 | 1 297 | Firestore rules design, voice billing v2, chat design, capabilities, mobile enhancements. Each is banner-marked **v1**; where they disagree with `spec/rebuild/`, `spec/rebuild/` wins |
| `plan/` | 21 | 4 197 | Opinionated: roadmap, decisions, agent roster and orchestration, migration/cutover, runbook, release gates, known v1 defects |
| `prompts/` | 3 | 666 | Paste-ready build prompts (M0 foundation, v2 milestones, v1 rebuild) |

Two entry points worth knowing:

- [`spec/rebuild/configuration.md`](./spec/rebuild/configuration.md) — the
  single home for every threshold, timeout, limit and default. Other docs
  name a key; only this one carries its value.
- [`prompts/rebuild-m0-foundation.md`](./prompts/rebuild-m0-foundation.md) —
  where an implementing agent actually starts.

## Not in any track

[`archive/spec-file-changelogs.md`](./archive/spec-file-changelogs.md) — 673
lines of per-file changelog removed from the spec on 2026-09-12 and kept for
history. Nobody needs to read it.
