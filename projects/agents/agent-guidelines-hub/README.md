# Agent guidelines hub

> A single source of truth for my cross-project agent guidelines (how I want every AI agent to work) that propagates by default into every repo I own, so any agent starting work in any project already knows and follows my rules without me pasting them in each time.

- **Status:** idea captured — _we'll work on this later_. No build yet; this
  folder parks the thinking so a future session can pick it up cold.
- **Audience:** me (owner of the
  [DDancingDeath](https://github.com/DDancingDeath) projects). Generalises to
  anyone running many repos with AI agents, but MVP is single-owner.

---

## The idea

I work across many repos — `bahi`, this `ideas` repo, the POC apps, the
agent ideas. I want **every** AI agent that starts work in any of them to
already follow the same baseline rules without me re-typing them:

- **how I want it to work** — prefer orchestration + subagents, decide
  (don't ask) in autopilot, verify before claiming done;
- **my quality bar** — validate every UI value against an **independent
  oracle** recomputed from raw events; structural/trend checks are not
  enough;
- **my conventions** — commit identity, keep docs in sync with code, never
  reintroduce a logged known-bug, no secrets;
- **stack-specific traps** — e.g. in `bahi`: bulk-load via `hydrate()` not
  `appendEvent`; `SyncedStorage.ingest` silently drops invalid events.

Today I paste the same guidance into each project by hand (or it lives only
in my head / this session's memory). That's tedious, it drifts out of sync,
and a brand-new agent in a brand-new repo starts blind.

**The fix:** one canonical "guidelines hub" + a propagation step, so each
repo carries an up-to-date `.github/copilot-instructions.md` (and/or
`AGENTS.md`) that any Copilot agent auto-loads the moment it opens that repo.

- **Primary user:** me, across all my GitHub projects.
- **Secondary:** collaborators / cloud agents on those repos — they inherit
  the rules for free because the file travels with the repo.
- **Anti-users:** throwaway/scratch repos where the sync overhead isn't
  worth it; anyone already covered by an org-level instruction system.

**What success looks like**

- A fresh agent in any of my repos follows my baseline rules on **turn 1**,
  with zero manual pasting.
- I edit the rules in **one** place and every repo reflects the change (via a
  sync run / auto-PR) within minutes — no manual tour of N repos.
- Each repo can still layer project-specific rules on top without forking the
  shared baseline.

**Non-goals**

- Not a local-only machine setting. (I explicitly *don't* want
  `~/.copilot/copilot-instructions.md` — the rules must travel **with the
  repo** so they apply to cloud agents, other machines, and collaborators.)
- Not a new agent runtime — it rides on whatever instruction file the agent
  already auto-loads.
- Not a prompt rewriter / model router — that's
  [`prompt-optimizer`](../prompt-optimizer).

---

## How it might work

```
        guidelines-hub  (canonical source)
        ├── global.md          ← rules true for every repo
        └── overlays/          ← optional per-stack snippets (e.g. ts-monorepo)
                  │
                  │   sync run (script / GitHub Action)
                  ▼
   each repo:  .github/copilot-instructions.md  = global + overlay + repo-local
               AGENTS.md  (optional mirror)
                  │
                  ▼
        any Copilot agent opening the repo auto-loads it on turn 1
```

Three shape questions to settle when we build (details in
[`idea.md`](./idea.md)):

- **Where the canonical source lives** — a dedicated `agent-guidelines`
  repo, a folder in this `ideas` repo, or GitHub org-level custom
  instructions if/when that exists.
- **How it propagates** — a script I run, a scheduled GitHub Action that
  opens a sync PR per repo, or a git submodule each repo vendors in.
- **Layering** — Copilot just concatenates the repo's instruction file (no
  native `include`), so the sync has to **inline** global + per-repo rules
  into the generated file and mark the managed region so local edits aren't
  clobbered.

---

## What it does today (and what's next)

Status: **idea capture only.** Nothing built. The concept and the open
decisions are recorded here and in [`idea.md`](./idea.md) so a future session
can start without re-deriving them.

Next, when we pick this up: settle the three shape questions above, then ship
an MVP that syncs one hand-written `global.md` into 2–3 of my repos.

---

## Tech stack

Undecided (idea stage). Likely a small PowerShell/Node sync script + a GitHub
Action, writing each repo's `.github/copilot-instructions.md` via the `gh`
CLI. The instruction-file **format** is fixed by the consuming tool (GitHub
Copilot's `.github/copilot-instructions.md` / the `AGENTS.md` convention), so
that part is contract, not choice.

---

## Reading order for an agent

1. [`idea.md`](./idea.md) — the vision in detail: problem, users, success
   criteria, prior art, open questions.
2. `spec/README.md` — **placeholder.** No spec yet; write it when we build.
3. `plan/README.md` — current status + decision log.
4. `prompts/build-from-spec.md` — **placeholder.** Fill once the shape is
   decided.

## Layout

```
<slug>/
├── README.md           ← (this doc) the narrative entry point
├── idea.md             ← vision in detail
├── spec/               ← functional source of truth
├── plan/               ← roadmap + known issues
├── prompts/            ← ready-to-paste agent prompts
└── assets/             ← mockups, screenshots, diagrams
```

## Recent changes

- _2026-06-20_ · Idea captured — problem, design sketch, open decisions. No
  code; parked to work on later.

