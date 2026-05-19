# Spec — winui-expert-teammate

> Functional breakdown of the delivery layer ("body + heartbeat"). The
> brain — winui-expert KB, WinUI Code Review, winui-regression-reviewer
> — is **already built** and is invoked as a downstream service.

## 1. Surfaces

Each surface exposes the same persona with the same memory. Per-surface
adapter responsibilities:

| Surface       | Inbound (work intake)                              | Outbound (response)                            | Identity                |
| ------------- | -------------------------------------------------- | ---------------------------------------------- | ----------------------- |
| Teams         | 1:1 chat, channel @mention, Adaptive-Card buttons  | Reply in same thread/channel, post Card        | Bot Framework app       |
| Outlook       | Added to a mail thread (To/Cc), @mention in body   | Reply-all on thread, summary mail              | Service mailbox (UPN)   |
| GitHub        | PR review request, issue assignment, @mention      | Review comments, line comments, issue comments | GitHub App              |
| ADO           | Bug assignment, PR reviewer add, @mention          | Bug comments, PR comments, work-item updates   | ADO service account     |
| Agency        | Registered as an Agency agent                      | Per-Agency-protocol responses                  | Agency identity         |
| CLI _(opt.)_  | Direct invocation as winui-expert today            | Stdout                                         | Local user              |

Adapters MUST normalise into a single canonical work-intake event so
the router/work-queue is surface-agnostic.

## 2. Identity & router

- **Single persona** "WinUIBot" (name TBD) across all surfaces.
- Per-surface identities federate to one logical agent.
- Router parses @mentions and assignments into work-intake events.
- Router posts acknowledgements with ETAs on the originating surface
  within seconds.
- Router enforces permission model (who can assign work; see "Open
  decisions" in `../README.md`).

## 3. Work queue & accountability

Every accepted task has a lifecycle:

```
intake → ack (with ETA) → plan → progress posts → result → wrap-up
```

- Visible queue (Teams pinned Card OR separate dashboard — open
  decision).
- Per-task status: queued, in-progress, blocked, done, failed.
- Daily and weekly summary posts to a configurable channel: what was
  picked up, what shipped, what's blocked.
- Failed / blocked tasks ping the requester with a reason and a
  proposed next step.

## 4. Persistent memory

The memory layer is the heartbeat. Ingestion sources:

- PR discussions (GitHub + ADO)
- Design decisions captured in OneNote, mail threads
- KT recordings (transcripts)
- Past Q&A exchanges (Teams chat, channel threads)
- Commit messages and PR descriptions
- This bot's own past responses (so it's consistent)

Storage:

- Reuse the existing winui-expert KB pipeline as the static base.
- Add an **incremental layer** for new conversations / reviews /
  commits, refreshed nightly (or near-real-time, open decision).
- All retrieval is citation-first; every answer links back to source.

## 5. Brain (already exists, called as service)

| Capability                     | Provided by                |
| ------------------------------ | -------------------------- |
| Q&A, architecture, debug       | winui-expert (KB + LLM)    |
| PR review (183-rule)           | WinUI Code Review          |
| Regression risk on PRs         | winui-regression-reviewer  |
| Issue investigation            | winui-expert (KB + LLM)    |
| Authoring/fix PRs _(stretch)_  | Copilot Coding Agent       |

The intern project owns the **invocation, routing, and surface**
of these existing capabilities. It does **not** rewrite them.

## 6. Proactive rules engine

Rule examples (each produces a notification to a configured channel
or thread):

- Regression detected on `main` for a WinUI-owned component.
- Deprecated API used in a new PR.
- KIR cleanup overdue (velocity / containment lifecycle).
- New bug filed in an owned area.
- PR open > N days awaiting WinUI expert review.

Rules are config-driven (YAML). Each rule has: condition, target
surface/channel, message template, suppression window.

## 7. Per-phase functional acceptance

See `plan/README.md`. Each phase ships a self-contained slice; this
spec applies cumulatively.

## 8. Cross-cutting requirements

- **Responsible AI** — every outbound message has audit trail.
  Required RAI review before phases 5 (mail) and 6 (authoring).
- **Identity isolation** — bot speaks as itself; never impersonates a
  user.
- **Internal LLM only** — corp code, bug content, mail content stay
  within the internal Azure OpenAI boundary.
- **Citations on every claim** — answers without sources are not
  shipped; the bot says "I don't know" instead.
- **Opt-out** per channel / per repo / per user.
- **Throttling** — Graph throttling and ADO REST throttling must be
  respected; persistent memory ingestion uses delta queries.
- **Audit log** — every action (Q&A, PR comment, mail, proactive
  ping) logged with prompt, retrieval set, response, recipient.

## Out of scope

- Replacing the existing winui-expert / WinUI Code Review / winui-
  regression-reviewer agents.
- Becoming a general-purpose Microsoft bot (this is WinUI-team-
  scoped).
- External-facing bot (this is internal-only).
- Building a new code-authoring engine (reuse Copilot Coding Agent
  for the stretch phase).
