# Idea — ado-bugfixer

## One-liner

An autonomous agent that walks my ADO bug list, classifies each item,
and either proposes a fix (draft PR / root-cause note) or recommends a
disposition (dupe / user-error / won't-fix) — for my review.

## Problem

Bugs land in my queue faster than I can triage them. Most need 5-15
minutes of investigation to know what they really are. That cost adds
up to hours per week of "first-pass triage" before I do any actual
fixing. Existing reactive tools help once I'm *in* a bug — but nothing
walks the backlog autonomously and pre-digests it for me.

## Target users

- **Primary**: me, on my personal ADO queries / area paths.
- **Secondary**: any engineer with a backlog larger than their
  attention.
- **Anti-users**: anyone whose bugs are too sensitive for an agent to
  read (some areas of Windows / Defender / etc.). Area allow-list
  required.

## What success looks like

- **Pre-triage in my morning queue** — top-10 bugs each have a
  classification + suggested action when I sit down.
- **At least 1 draft PR / week** the agent opens that I merge with
  minor edits or no edits.
- **Zero auto-merges, zero auto-closes** — the agent is advisory and
  authoring; I'm the gatekeeper.
- **Dupe-detection precision ≥ 90 %**. False dupes are annoying and
  noisy; the agent should be conservative.
- **Patterns absorbed** — after a month, the agent's draft fixes
  reflect "how we actually fix this kind of thing in this area".

## Constraints

- **Area allow-list** — agent only runs on areas I explicitly enable.
- **Read-only by default**; PR drafting and bug-commenting require
  explicit consent per action class.
- **Honours sensitivity** — some bugs are flagged sensitive; agent
  skips them silently and tells me it skipped.
- **Internal LLM only** — corp code stays in corp services.
- **No org-wide automation** — this is a personal-scope agent.

## Non-goals

- Auto-merging PRs.
- Auto-closing bugs.
- Replacing the existing internal bug-fixer / Copilot for ADO tools
  (those are org-scoped — this is personal-scoped).
- Becoming a bot account that posts to bugs on its own — at least not
  until trust is earned (out of MVP).
- Building a SaaS.

## Inspiration / prior art

- **Watson bug-fixer** — patterns mined from accepted fixes; closest
  internal cousin. Useful as a corpus, not a replacement.
- **Copilot Coding Agent** — actually drafts the PRs; this project
  could reuse it for the authoring step.
- **ADO-Automation bot** — does triage and routing org-wide; different
  scope.
- The expert-review skills (memory-safety, concurrency, error-handling,
  performance, etc.) — should be invoked on every draft PR before
  surfacing it to me.

## Open questions

- [ ] Start area? Suggest one area path to MVP on.
- [ ] Use Copilot Coding Agent for the actual PR draft, or do it
      directly?
- [ ] Cadence: daily batch, on-new-bug, on-demand?
- [ ] Should this share a brain with `winui-expert-teammate` (if the
      area is WinUI) or stay separate?
- [ ] Sensitivity / area-allow-list governance — how does it get
      enforced and audited?
