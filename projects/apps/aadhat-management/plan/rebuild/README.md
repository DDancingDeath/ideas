# Plan — Rebuild

> **Opinionated.** Specs in [`../../spec/rebuild/`](../../spec/rebuild/)
> stay factual. This folder is where recommendations, judgement calls,
> and "we think you should do X" live.

## Contents

0. [`getting-started.md`](./getting-started.md) — **start here.** The
   Day-0 sequencer: readiness gate, prerequisites checklist, and the
   first five steps (confirm the freeze → create the repo → run M0 →
   pass exit criteria → stand up the agents for M1).
1. [`roadmap.md`](./roadmap.md) — proposed milestone order from M0 to
   v2.0, with rationale for why correctness-critical pieces come
   before screens.
2. [`decisions.md`](./decisions.md) — tracker for the technical and
   product decisions that needed to be **frozen before M0**. Rows
   1–10 are now `confirmed` (frozen 2026-06-15); a milestone-scoped
   open-questions table (M3–M11) carries the rest.
3. [`agent-roster.md`](./agent-roster.md) — the agents we recommend
   the owner stand up, the responsibility each owns, and the
   master prompt each runs with.
4. [`tech-candidates.md`](./tech-candidates.md) — language /
   framework / library candidates with the trade-offs called out;
   the headline stack (SvelteKit / Firebase / pnpm) is already
   frozen in `decisions.md` rows 1–3.
5. [`migration-cutover.md`](./migration-cutover.md) — how the family
   shop moves from v1 to v2: snapshot-import strategy, dual-run
   window, rollback plan, and the mismatch criteria that block
   cutover.
6. [`operations-runbook.md`](./operations-runbook.md) — daily /
   weekly / monthly procedures for brother and owner; twelve
   failure procedures (P1–P12) matched to the spec's failure-mode
   catalogue; release process with rollback rules; escalation
   table and contact list template; required quarterly drills.
7. [`backup-restore.md`](./backup-restore.md) — what is backed up
   (events, rules, validators; never projections); where backups
   live (primary Firebase, mandatory off-account drive); three
   restore scenarios with verification checklist; the monthly
   restore drill that turns "we have backups" into "we know they
   work".
8. [`productize-later.md`](./productize-later.md) — how to extract a
   reusable product after shop-1 stabilizes, without restarting.
9. [`release-health-gates.md`](./release-health-gates.md) — the
   10-gate pre-release checklist (CI green, platform matrix
   green, printer smoke, offline / reconnect smoke, migration
   checks, no Sev-1 flags, rollback path known, brother
   sign-off, backup verified, release notes drafted); hot-fix
   subset; sign-off record; rollback-trigger rules.

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

- _2026-06-16_ (later) · Added [`getting-started.md`](./getting-started.md)
  — the Day-0 sequencer (readiness gate + prerequisites + the first
  five steps) — and listed it as item 0 / "start here". Refreshed
  the `decisions.md` and `tech-candidates.md` descriptions to say
  the freeze rows are `confirmed` (they were described as
  `tentative` / "owner picks before M0", which was stale).
- _2026-06-16_ · Added `release-health-gates.md` — the 10-gate
  pre-release checklist (CI green; platform matrix green;
  printer smoke; offline / reconnect smoke; migration checks;
  no Sev-1 flags; rollback path known; brother sign-off;
  backup verified; release notes drafted) with hot-fix subset,
  sign-off record fields, and rollback-trigger rules. Pairs
  with the new spec docs `platform-compatibility.md`,
  `printer-compatibility.md`, `platform-test-matrix.md`,
  `money-units-rounding.md`, `time-clock.md`, and
  `concurrency.md`.
- _2026-06-15_ (later same day) · Added `operations-runbook.md`
  (steady-state checklists + 12 failure procedures matched to
  `spec/rebuild/failure-modes.md` + release / rollback rules
  + escalation table) and `backup-restore.md` (what / where /
  who can restore + monthly drill that turns backups into
  proof). These pair with the new `spec/rebuild/` operational
  contracts (`offline-sync.md`, `failure-modes.md`,
  `versioning-compatibility.md`, `observability.md`,
  `data-governance.md`, `ergonomics.md`, `ai-boundaries.md`,
  `data-placement.md`).
- _2026-06-15_ (later same day) · Added `decisions.md` (freeze list
  with agent-recommended defaults) and `migration-cutover.md`
  (snapshot strategy, dual-run window, rollback, brother sign-off).
- _2026-06-15_ · Initial draft of the rebuild plan subtree.
