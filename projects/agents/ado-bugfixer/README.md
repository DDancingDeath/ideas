# ado-bugfixer

> An agency-mode agent that walks the ADO bug list (mine or my area's)
> and proposes fixes — draft PRs, root-cause notes, or "this is a
> dupe of bug N" calls.

- **Status:** early-stage idea capture. No code.
- **Audience:** me, internal to Microsoft. Could generalize to a team
  later.

---

## The idea

ADO accumulates bugs faster than I can act on them. Most need 10
minutes of investigation to know what they really are — dupe? user
error? real bug, easy fix? real bug, deep fix? — and the cost of doing
that for every new item is too high. An autonomous agent can do that
first pass for me.

The agent should:

1. **Pull bugs** matching a query (assigned to me / cc'd / area path /
   tag).
2. **Read each bug** — repro steps, attachments, linked PRs, comment
   history.
3. **Classify** — dupe (link the original), user error (suggest reply),
   real bug, won't fix (with reason).
4. **For real bugs in a known area**: hypothesize root cause, find the
   relevant code, and either:
   - Draft a fix PR (small, well-scoped) for me to review and merge.
   - Or post a root-cause note to the bug with a pointer to the file
     and a one-paragraph plan.
5. **Never auto-close, never auto-merge.** I'm the gatekeeper on every
   action.

Conceptually adjacent to existing internal tools (Watson bug-fixer,
ADO-Automation bot, Copilot for ADO). This project is **personal-scope**
— my queries, my repos, my style — not an org-wide replacement for those.

Deeper detail: [`idea.md`](./idea.md).

---

## How it might work

```
ADO query  ──▶  Bug puller  ──▶  Local SQLite (bug + comments + linked PRs)
                                       │
                                       ▼
                              Classifier (LLM)
                                       │
                       ┌───────────────┼───────────────┐
                       ▼               ▼               ▼
                     dupe?          user error?     real bug?
                       │               │               │
              link & comment      draft reply    investigate
                                                       │
                                                       ▼
                                              ┌────────────────┐
                                              │ small + clear? │
                                              ├────────────────┤
                                              │ yes → draft PR │
                                              │ no  → RC note  │
                                              └────────┬───────┘
                                                       ▼
                                              My review queue
                                              (CLI / TUI / Teams card)
```

Reuses internal Microsoft expert-review skills where relevant (memory-
safety review, error-handling review, etc.) so the draft PRs are
already pattern-checked.

---

## Reading order

1. [`idea.md`](./idea.md) — vision.
2. [`spec/README.md`](./spec/README.md) — placeholder.
3. [`plan/README.md`](./plan/README.md) — status + open questions.
4. [`prompts/build-from-spec.md`](./prompts/build-from-spec.md) — only
   after the area / repo scope is decided.

## Open decisions

- [ ] **Area scope**: which ADO area paths / repos is this allowed to
      touch in MVP? Suggest one area to start.
- [ ] **Coding agent**: reuse Copilot Coding Agent for the actual PR
      drafting, or have this agent do it directly?
- [ ] **Comment voice**: how chatty on the bug? A 1-line note + link, a
      paragraph, or a full RC writeup?
- [ ] **Triage cadence**: daily batch run, on-new-bug, on-demand only?
- [ ] **Tribal-knowledge layer**: how does this agent learn the team's
      "we usually fix this kind of thing this way" patterns? Pair with
      the `winui-expert-teammate` brain?

## Recent changes

- _2026-05-20_ · Idea captured. No code.
