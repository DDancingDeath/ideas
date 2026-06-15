# Plan — Rebuild

> **Opinionated.** Specs in [`../../spec/rebuild/`](../../spec/rebuild/)
> stay factual. This folder is where recommendations, judgement calls,
> and "we think you should do X" live.

## Contents

1. [`roadmap.md`](./roadmap.md) — proposed milestone order from M0 to
   v2.0, with rationale for why correctness-critical pieces come
   before screens.
2. [`decisions.md`](./decisions.md) — tracker for the technical and
   product decisions that need to be **frozen before M0**, with the
   agent's recommended defaults (status: `tentative` until the
   owner confirms).
3. [`agent-roster.md`](./agent-roster.md) — the agents we recommend
   the owner stand up, the responsibility each owns, and the
   master prompt each runs with.
4. [`tech-candidates.md`](./tech-candidates.md) — language /
   framework / library candidates with the trade-offs called out;
   the owner picks before M0.
5. [`migration-cutover.md`](./migration-cutover.md) — how the family
   shop moves from v1 to v2: snapshot-import strategy, dual-run
   window, rollback plan, and the mismatch criteria that block
   cutover.
6. [`productize-later.md`](./productize-later.md) — how to extract a
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

- _2026-06-15_ (later same day) · Added `decisions.md` (freeze list
  with agent-recommended defaults) and `migration-cutover.md`
  (snapshot strategy, dual-run window, rollback, brother sign-off).
- _2026-06-15_ · Initial draft of the rebuild plan subtree.
