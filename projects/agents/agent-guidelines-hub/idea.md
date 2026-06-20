# Agent guidelines hub

> A single source of truth for my cross-project agent guidelines (how I want every AI agent to work) that propagates by default into every repo I own, so any agent starting work in any project already knows and follows my rules without me pasting them in each time.

## Problem

I run many repos under [DDancingDeath](https://github.com/DDancingDeath) and
drive almost all the work through AI agents. Every agent, in every repo,
needs the same baseline guidance — how to work, my quality bar, my
conventions, the do-not-reintroduce list. Right now that guidance is:

- pasted by hand into each session, or
- captured per-repo in `.github/copilot-instructions.md` / `AGENTS.md` that I
  author and keep in sync repo-by-repo, or
- only in my head / this session's memory.

So it's tedious, it drifts (repo A has the latest rules, repo B is stale),
and a brand-new agent in a brand-new repo starts blind. I want to write the
rules **once** and have every agent, everywhere, follow them by default.

## Target users

- **Primary**: me, across all my GitHub projects.
- **Secondary**: collaborators and cloud/coding agents working in those
  repos — they inherit the rules for free because the instruction file ships
  inside the repo.
- **Anti-users**: throwaway/scratch repos where the sync overhead isn't
  worth it; anyone already covered by an org-level instruction system.

## What success looks like

- A fresh agent in any of my repos follows my baseline rules on **turn 1**,
  with zero manual pasting.
- I change a rule in **one** place and every repo reflects it (via a sync
  run / auto-PR) within minutes — no manual tour of N repos.
- Each repo can still layer project-specific rules on top of the shared
  baseline without forking it.
- Measurable: onboarding a new repo's agent drops from "paste the guideline +
  hope" to "clone and go".

## Constraints

- **Must travel with the repo, not the machine.** I explicitly rejected the
  local `~/.copilot/copilot-instructions.md` option — the rules have to apply
  to cloud agents, other machines, and collaborators, which means they live
  in the repo.
- **Format is dictated by the consuming tool.** GitHub Copilot auto-loads
  `.github/copilot-instructions.md` (and path-scoped
  `.github/instructions/*.instructions.md`); the cross-tool convention is
  `AGENTS.md`. The hub emits those — it does not invent a new format.
- No secrets in any propagated file.
- Keep it cheap — a small script + the `gh` CLI, not a service.

## Non-goals

- Not a local-only setting (see constraint above).
- Not a new agent runtime or model — it rides on the instruction file the
  agent already loads.
- Not a prompt rewriter / model router — that's
  [`prompt-optimizer`](../prompt-optimizer).
- Not a memory system — Copilot "memory" is adjacent but separate; this is
  about static, version-controlled rules.

## Inspiration / prior art

- **GitHub Copilot repository custom instructions** —
  `.github/copilot-instructions.md`, auto-loaded per repo. The distribution
  *target*.
- **Path-specific instructions** — `.github/instructions/*.instructions.md`
  with `applyTo` globs.
- **`AGENTS.md`** — the emerging cross-tool agent-orientation convention
  (already used in `bahi` and this repo).
- **Global `~/.copilot/copilot-instructions.md`** — the local-machine
  equivalent I deliberately *don't* want.
- **Cursor `.cursorrules` / other editor rule files** — same idea, per-repo.
- **Org-level / enterprise custom instructions** — if/when GitHub exposes
  org-scoped Copilot instructions, that could replace the sync step.

## Open questions

- [ ] **Where does the canonical source live** — a dedicated
      `agent-guidelines` repo, a folder in this `ideas` repo, or org-level
      settings?
- [ ] **Propagation mechanism** — a script I run on demand, a scheduled
      GitHub Action that opens a sync PR per repo, or a git submodule each
      repo vendors in?
- [ ] **Layering / merge** — the consuming tools just concatenate the file,
      so the sync must inline `global + overlay + repo-local`. How do I mark
      the managed region so per-repo edits aren't clobbered (e.g.
      `BEGIN/END managed` markers)?
- [ ] **Which rules are truly global** vs project-specific? (Global: commit
      identity, orchestration preference, oracle testing bar, no-secrets,
      docs↔code sync. Project-specific: build/test commands, invariants,
      stack traps.)
- [ ] **One file or both?** Emit `.github/copilot-instructions.md`,
      `AGENTS.md`, or both — and keep them consistent.
- [ ] **Genuine gap vs Clawpilot / org tooling** — Clawpilot Skills are
      teach-once-run-forever for *behaviours*, not repo-resident *rule files*;
      confirm no existing org feature already does cross-repo instruction sync
      before building.

