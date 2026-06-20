# Build plan — Agent guidelines hub

The plan answers **what to do next and in what order**, not what to build.
For "what to build", see `../spec/`.

## Current status

Idea captured, parked to work on later. No spec, no code. The problem,
design sketch, and open decisions live in [`../README.md`](../README.md) and
[`../idea.md`](../idea.md).

## Roadmap

- **M0 — Decide the shape**: where the canonical source lives, how it
  propagates, how layering/merge works (see `idea.md` open questions).
- **M1 — Walking skeleton**: one hand-written `global.md` synced into 2–3 of
  my repos' `.github/copilot-instructions.md` via a script.
- **M2 — MVP**: per-repo overlay + managed-region markers so local edits
  survive; a scheduled sync (Action) that opens a PR per repo on change.
- **M3 — Coverage**: roll out to all main DDancingDeath repos; optional
  `AGENTS.md` mirror.

## Backlog (unordered)

- Inventory the rules worth centralising (pull from `bahi`'s
  `.github/copilot-instructions.md` + this repo's `AGENTS.md`).
- Separate the canonical global rule set from per-project overrides.
- Dry-run / diff mode before writing to any repo.

## Known issues / debt

- None yet (no code).

## Decision log

- 2026-06-20 · Rules must live **in the repo**, not in a machine-local
  `~/.copilot/copilot-instructions.md` · so cloud agents, other machines, and
  collaborators inherit them · Considered: machine-global file (rejected by
  owner).

