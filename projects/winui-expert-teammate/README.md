# winui-expert-teammate

> An **AI teammate for WinUI** — not a tool you summon, a presence
> on every surface the team already uses. One brain, many surfaces:
> Teams, Outlook, GitHub, ADO, Agency. Persistent memory across
> conversations, reviews, and commits. Acknowledges work, gives ETAs,
> ships results back on the surface where you assigned it.

- **Status:** pitched as an intern project. Reuses existing WinUI
  agents as the brain; this project is the body + heartbeat.
- **Audience:** the WinUI team (and adjacent teams that interact with
  WinUI).
- **Owner:** _TODO(idea) — intern + sponsor._
- **Why a great intern project:** phased delivery so v1 ships value
  early, real users from day 1, extends proven internal pieces
  instead of starting from zero.

---

## The idea

Tribal WinUI knowledge is locked in a few experts and scattered
across mail, Teams, docs, recordings, and PRs. The team already has
powerful agents — **winui-expert** (10 MB+ static KB, Q&A, debug,
regression investigation, PR review), **WinUI Code Review** (183-rule
PR reviewer), **winui-regression-reviewer** (regression risk on PRs)
— but they're CLI/IDE tools you summon. Siloed. Per-user. Snapshot
knowledge.

> **The framing: don't rebuild the brain — build the body and the
> heartbeat.** The existing agents are the brain. This project is the
> delivery layer that turns three CLI-summoned experts into one
> always-on teammate with identity, presence, memory, and proactive
> behaviour across every surface the team already uses.

The WinUI Expert is a single agent with one brain — and many
surfaces. It has a real identity in **Teams** (chat 1:1, @mention in
channels), in **Outlook** (add it to mail threads like any
recipient), in **GitHub/ADO** (review and comment on PRs and issues,
assign bugs and PRs to it), and as an agent in **Agency**. Wherever
you add it, it's the same teammate with the same persistent memory —
a Teams-channel discussion informs a PR review the next day; a mail
decision shows up when someone asks the same question a month later.

Most importantly, you can **give it work** like any other team
member — assign it a bug, add it as a reviewer on a PR, or just say
*"@WinUIBot, investigate this and post back here"*. It acknowledges,
gives an ETA, does the work, posts the result on the same surface.

Full pitch lives in [`idea.md`](./idea.md) (kept close to the
original wording).

---

## How it works (architecture, one frame)

```
        ┌───────────────────────────────────────────────────────────┐
        │                       SURFACES                            │
        │  Teams ◀──▶  Outlook ◀──▶  GitHub/ADO ◀──▶  Agency  CLI  │
        └──────────────────────────┬────────────────────────────────┘
                                   │ identity + presence + work intake
                                   ▼
                       ┌───────────────────────────┐
                       │      ROUTER / IDENTITY    │
                       │  one persona, many APIs   │
                       │  parses @mentions, assigns│
                       │  acks + ETAs + status     │
                       └────────────┬──────────────┘
                                    │
                                    ▼
                       ┌───────────────────────────┐
                       │      WORK QUEUE           │
                       │  visible, prioritised,    │
                       │  per-task lifecycle:      │
                       │  ack → plan → progress    │
                       │  → result → wrap-up       │
                       └────────────┬──────────────┘
                                    │
                                    ▼
                       ┌───────────────────────────┐
                       │   PERSISTENT MEMORY       │
                       │  PRs, decisions, KT recs, │
                       │  OneNote, mail threads,   │
                       │  past Q&A; grows daily    │
                       └────────────┬──────────────┘
                                    │
                                    ▼
       ┌─────────────────────────── BRAIN ──────────────────────────┐
       │   winui-expert (KB)   │   WinUI Code Review   │  winui-    │
       │   Q&A, debug, regr    │   183-rule reviewer   │  regression│
       └───────────────────────┴───────────────────────┴────────────┘
                                    │
                                    ▼
                       ┌───────────────────────────┐
                       │    PROACTIVE RULES        │
                       │  regression on main,      │
                       │  deprecated API in PR,    │
                       │  KIR cleanup overdue,     │
                       │  new bug in owned area    │
                       └───────────────────────────┘
```

The "brain" boxes already exist. This project builds everything
above and around them.

---

## What it does

- **Q&A** — answers architecture, API, and "how do I…" questions with
  citations, on whichever surface you ask.
- **Accepts assigned tasks** — assign it a bug in ADO, add it as a PR
  reviewer in GitHub, or hand it work in chat ("investigate this
  crash", "summarize the shadows discussions from the last two
  weeks", "draft release notes for this week's changes", "triage
  today's new bugs in the Lifted XAML area"). It acknowledges, gives
  an ETA, posts progress, marks done with results.
- **PR review** — posts architect-level comments on regression risk,
  API design, perf, a11y; can be requested as a reviewer.
- **Issue investigation** — given a bug, drafts a root-cause
  hypothesis with relevant code and prior fixes.
- **Mail-thread participation** — add it to an Outlook thread; it
  reads context, answers questions, summarizes, remembers the
  decision afterwards.
- **Proactive notifications** — pings the right channel (or replies
  on the right thread) when its rules fire (regression on main,
  deprecated API in a PR, KIR cleanup overdue, new bug in an owned
  area).
- **Status & accountability** — visible work queue, posts daily/
  weekly summaries of what it picked up, shipped, and what's blocked.
  Like any team member in standup.
- **PR drafting & QA assist** _(stretch)_ — opens draft fixes for
  well-scoped issues, scaffolds tests, flags coverage gaps.

---

## Phased delivery

Detailed plan in [`plan/README.md`](./plan/README.md). Headline:

| Phase | Theme                          | Ships                                  |
| ----- | ------------------------------ | -------------------------------------- |
| 1     | **Identity + Q&A** (Teams)     | @WinUIBot in 1:1 + channels, Q&A only  |
| 2     | **PR review** (GitHub/ADO)     | Add-as-reviewer, posts review comments |
| 3     | **Proactive notifications**    | Rules engine, channel pings            |
| 4     | **Investigation + work queue** | Accepts assigned bugs/tasks, ack/ETA   |
| 5     | **Mail + Agency surfaces**     | Outlook participation, Agency agent    |
| 6     | **Authoring** _(stretch)_      | Draft fix PRs, test scaffolds          |

The intern project ships in phase order so v1 has real users from
day 1.

---

## Why it matters

Tribal WinUI knowledge is locked in a few experts and scattered
across mail, Teams, docs, recordings, and PRs. The Expert bot makes
that knowledge available 24/7 on every surface the team already uses,
gets stronger over time, and turns reactive Q&A into proactive
guidance — onboarding faster, catching regressions earlier, and
freeing senior engineers from repetitive review and triage.

---

## How is this different from the WinUI agents we already have?

We already have:

- **winui-expert** — 10 MB+ static KB, Q&A, debug, regression
  investigation, PR review.
- **WinUI Code Review** — 183-rule PR reviewer.
- **winui-regression-reviewer** — regression risk on PRs.

They're powerful, but they're **CLI/IDE tools you summon** —
siloed, per-user, with snapshot knowledge. This project gives them
**identity, presence, memory, and proactive behaviour** across every
surface the team uses. Don't rebuild the brain — build the body and
the heartbeat.

---

## Reading order

1. **This file** — full picture.
2. [`idea.md`](./idea.md) — original pitch (preserve as primary
   source).
3. [`spec/README.md`](./spec/README.md) — system breakdown: surfaces,
   identity, memory, work queue, proactive rules.
4. [`plan/README.md`](./plan/README.md) — phased delivery plan with
   acceptance criteria per phase.
5. [`prompts/build-from-spec.md`](./prompts/build-from-spec.md) —
   intern-onboarding-shaped build prompt.

## Layout

```
projects/winui-expert-teammate/
├── README.md          ← you are here
├── idea.md            ← the original pitch
├── spec/README.md     ← system breakdown
├── plan/README.md     ← phased delivery
├── prompts/
│   └── build-from-spec.md
└── assets/            ← architecture diagrams, mocks (drop here)
```

## Open decisions

- [ ] **Owner / intern sponsor** — who runs this?
- [ ] **Identity** — single bot account `WinUIBot` across all
      surfaces? Or surface-specific identities federating to one
      brain?
- [ ] **Memory store** — what backs persistent memory? Existing
      WinUI KB pipeline + an incremental layer for new
      conversations?
- [ ] **Work queue surface** — separate dashboard, or live in Teams
      as a pinned message / Adaptive Card?
- [ ] **Trust ramp** — which phases require human-in-the-loop sign-
      off on every action vs. fully autonomous?
- [ ] **Permission model** — who can assign work? Anyone in the WinUI
      team? Only specific groups?
- [ ] **Responsible-AI sign-off path** — required before phase 5
      (mail) and phase 6 (authoring).

## Recent changes

- _2026-05-20_ · Pitch captured, phased plan extracted, architecture
  sketch drawn. No code.
