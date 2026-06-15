# Plan — Rebuild

> **Opinionated.** Specs in [`../../spec/rebuild/`](../../spec/rebuild/)
> stay factual. This folder is where recommendations, judgement calls,
> and "we think you should do X" live.

## Contents

1. [`roadmap.md`](./roadmap.md) — proposed milestone order from M0 to
   v2.0, with rationale for why correctness-critical pieces come
   before screens.
2. [`agent-roster.md`](./agent-roster.md) — the agents we recommend
   the owner stand up, the responsibility each owns, and the
   master prompt each runs with.
3. [`tech-candidates.md`](./tech-candidates.md) — language /
   framework / library candidates with the trade-offs called out;
   the owner picks before M0.
4. [`productize-later.md`](./productize-later.md) — how to extract a
   reusable product after shop-1 stabilizes, without restarting.

## Relationship to the existing `plan/` files

The other files in [`../`](../) (`review-issues.md`,
`promotion.md`, `staging-smoke-checklist.md`,
`legacy-agents-orientation.md`, `setup/`) describe the **live v1
app's** operational backlog and runbooks. They stay relevant during
the rebuild because:

- The shop keeps running on v1 until v2 is ready to take over.
- `review-issues.md` is also the "do not reintroduce" list for the
  rebuild.
- `setup/` contains hardware notes (printer, Firebase, environment)
  that v2 will also need.

## Recent changes

- _2026-06-15_ · Initial draft of the rebuild plan subtree.
