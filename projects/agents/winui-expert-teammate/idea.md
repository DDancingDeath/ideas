# Idea — winui-expert-teammate

> This file preserves the original pitch close to verbatim. The
> narrative README and the spec/plan synthesize and structure it; this
> file is the source of truth for the *intent*.

---

## An AI teammate for WinUI, not just a tool

The WinUI Expert is a single agent with one brain — and many surfaces.
It has a real identity in Teams (chat 1:1, @mention in channels), in
Outlook (add it to mail threads like any recipient), in GitHub/ADO
(review and comment on PRs and issues, assign bugs and PRs to it), and
as an agent in Agency. Wherever you add it, it's the same teammate with
the same persistent memory and context — a discussion in a Teams
channel informs a PR review the next day; a decision in an email
thread shows up when someone asks the same question in chat a month
later.

Most importantly, you can give it work like any other team member —
assign it a bug, add it as a reviewer on a PR, or just say "@WinUIBot,
investigate this and post back here". It acknowledges, gives an ETA,
does the work, and posts the result on the same surface where you
assigned it.

It carries persistent memory of the team's past — PR discussions,
design decisions, bugs, KT recordings, OneNote, mail threads — and
keeps learning from every new conversation, review, and commit.

## What it does

- **Q&A** — answers architecture, API, and "how do I…" questions with
  citations, on whichever surface you ask.
- **Accepts assigned tasks** — assign it a bug in ADO, add it as a PR
  reviewer in GitHub, or hand it work in chat ("investigate this
  crash", "summarize the shadows discussions from the last two
  weeks", "draft release notes for this week's changes", "triage
  today's new bugs in the Lifted XAML area"). It acknowledges, gives
  an ETA, posts progress, and marks the task done with results.
- **PR review** — posts architect-level comments on regression risk,
  API design, perf, a11y; can be requested as a reviewer.
- **Issue investigation** — given a bug, drafts a root-cause
  hypothesis with relevant code and prior fixes.
- **Mail-thread participation** — add it to an Outlook thread; it
  reads the context, answers questions, summarizes, and remembers the
  decision afterwards.
- **Proactive notifications** — pings the right channel (or replies on
  the right thread) when its rules fire (regression on main,
  deprecated API in a PR, KIR cleanup overdue, new bug in an owned
  area).
- **Status & accountability** — has a visible work queue, posts
  daily/weekly summaries of what it picked up, what it shipped, what's
  blocked — like any team member in standup.
- **PR drafting & QA assist (stretch)** — opens draft fixes for well-
  scoped issues, scaffolds tests, flags coverage gaps.

## Why it matters

Tribal WinUI knowledge is locked in a few experts and scattered
across mail, Teams, docs, recordings, and PRs. The Expert bot makes
that knowledge available 24/7 on every surface the team already uses,
gets stronger over time, and turns reactive Q&A into proactive
guidance — onboarding faster, catching regressions earlier, and
freeing senior engineers from repetitive review and triage.

## Why it's a great intern project

Phased delivery (identity + Q&A → review → notifications →
investigation → mail/Agency surfaces → authoring) so v1 ships value
early. Real users from day 1. Builds on existing internal skills
(WinUI Expert KB, expert reviewer, regression reviewer) — interns
extend proven pieces rather than start from zero.

## How is this different from the WinUI agents we already have?

We already have **winui-expert** (10 MB+ static KB, Q&A, debug,
regression investigation, PR review), **WinUI Code Review** (183-rule
PR reviewer), and **winui-regression-reviewer** (regression risk on
PRs). They're powerful, but they're CLI/IDE tools you summon —
siloed, per-user, with snapshot knowledge.

**The framing: don't rebuild the brain — build the body and the
heartbeat.** The existing agents are the brain. The intern project is
the delivery layer that turns three CLI-summoned experts into one
always-on teammate with identity, presence, memory, and proactive
behavior across every surface the team already uses.
