# assistant-inbox-triage

> A personal AI assistant that ingests my Outlook mail, Teams chats and
> mentions, ADO pull requests, and ADO bugs — and tells me what to do
> next, ranked by priority, with a drafted reply or comment ready to go.

- **Status:** early-stage idea capture. No code yet.
- **Audience:** me, internal to Microsoft. Single-user, runs on my work
  device.
- **Owner:** [@DDancingDeath](https://github.com/DDancingDeath)

---

## The idea

The pain: every morning starts with 80 unread Outlook items, 30 Teams
mentions, 12 PRs needing review, and a personal ADO query of bugs that
quietly grew overnight. None of these surfaces talk to each other. The
"what should I do next?" question takes 20 minutes of skimming before I
even start the first thing.

The assistant should:

1. **Pull from all four sources** (mail, Teams, PRs, bugs) on a schedule
   or on demand.
2. **Normalize each item** into a unified "inbox entry" — who, subject,
   age, my role (reviewer / mentioned / assigned), link, raw body.
3. **Rank** by urgency + my responsibility, using both metadata (age,
   sender seniority, due dates, SLA) and content (LLM read of the body).
4. **Suggest the action** for each top item — reply / approve / triage /
   ignore / schedule — and **draft the content** (reply body, PR
   comment, bug-triage note).
5. **Never auto-send.** All drafts land in a review queue I confirm.
6. **Run on my work device** with my AAD identity — no shared service,
   no cloud cache of corp data.

Deeper detail: [`idea.md`](./idea.md).

Anti-users: anyone else (single-tenant, single-user). High-stakes auto-
actions (approving PRs, closing bugs without me) are out of scope.

---

## How it would work

```
┌─────────────────────────────────────────────────────────────────┐
│  Local scheduler (Task Scheduler / Windows service)             │
│  Runs every N minutes during work hours                          │
└──────────────────────────┬──────────────────────────────────────┘
                           ▼
   ┌──────────────────────────────────────────────┐
   │  Source pullers (incremental delta queries)  │
   │  ────────────────────────────────────────    │
   │  Microsoft Graph: /me/messages,              │
   │                   /me/chats/getAllMessages,  │
   │                   /me/teamwork/sentMessages  │
   │  Azure DevOps REST: /git/pullrequests?reviewerId=me,
   │                     WIQL for bugs assigned/cc'd to me
   └──────────────────────────┬───────────────────┘
                              ▼
              ┌───────────────────────────┐
              │  Local SQLite             │
              │  ──────────────────────   │
              │  inbox_entries table:     │
              │  source, source_id, who,  │
              │  subject, body, age,      │
              │  my_role, link, status,   │
              │  rank, draft_reply        │
              └──────────────┬────────────┘
                             ▼
           ┌─────────────────────────────────────┐
           │  Triage pass (Azure OpenAI internal) │
           │  - score urgency (1-5)               │
           │  - classify action                   │
           │  - draft reply / PR comment / note   │
           └─────────────────┬───────────────────┘
                             ▼
   ┌──────────────────────────────────────────────┐
   │  Surface: morning brief + on-demand TUI/web  │
   │  Adaptive Card to a Teams self-chat,         │
   │  CLI digest, or local Electron mini-app      │
   │  TODO(idea): pick one                        │
   └──────────────────────────────────────────────┘
```

**Auth (the hard part).**
AAD app registration in my tenant with the right Graph + ADO scopes,
device-bound token via MSAL Public Client + Windows Credential Manager.
Tokens never leave the box. Conditional Access likely requires the work
device to be Intune-managed — run on the work laptop, not a personal
box.

**LLM.**
Azure OpenAI via an internal-approved endpoint. **No public OpenAI**, no
third-party LLM SaaS. The system prompt loads my role context (team X,
owner of Y) so urgency scoring matches my actual responsibilities.

---

## What it would do at launch (MVP scope)

- One scheduled pull every 15 min during work hours, plus on-demand.
- Top-10 ranked inbox digest, with a one-sentence "why this matters" and
  a draft action for each.
- One-tap confirmation to send the draft (no auto-send).
- Deltas only — no full mailbox/PR list rescans.

**Out of scope for MVP:**
- Auto-sending replies, auto-approving PRs, auto-closing bugs.
- Meeting scheduling.
- Calendar / focus-time integration.
- Document / OneNote ingestion.
- Voice (see `agent-notes-reminders` for that).

---

## Tech stack (suggested)

| Layer | Choice | Notes |
|---|---|---|
| Runtime | Python 3.11 or Node 20 | TODO(idea): pick. Python is simpler for ADO + Graph SDKs. |
| Auth | MSAL (Python or Node) | Public Client flow, device-bound. |
| Mail / Teams | `msgraph-sdk` (Python) or `@microsoft/microsoft-graph-client` | Delta queries mandatory. |
| ADO | `azure-devops` (Python) or `azure-devops-node-api` | PAT for personal use, AAD for prod. |
| LLM | Azure OpenAI via **internal-approved** endpoint | Get the endpoint from internal docs. |
| Storage | SQLite | One file in `%LOCALAPPDATA%`. |
| Secrets | Windows Credential Manager | Never `.env`. |
| Schedule | Task Scheduler | Or a small Windows service. |
| Surface | TODO(idea) — Teams self-chat Adaptive Card vs CLI digest vs Electron tray app |

---

## Reading order

1. [`idea.md`](./idea.md) — problem, users, success.
2. [`spec/README.md`](./spec/README.md) — placeholder, fill in once
   surface and stack are decided.
3. [`plan/README.md`](./plan/README.md) — status + open questions.
4. [`prompts/build-from-spec.md`](./prompts/build-from-spec.md) — only
   safe to hand to an agent once the open questions in `idea.md` are
   resolved.

## Layout

```
assistant-inbox-triage/
├── README.md
├── idea.md
├── spec/README.md
├── plan/README.md
├── prompts/build-from-spec.md
└── assets/
```

## Open decisions (block on the user)

- [ ] **Surface**: Teams self-chat Adaptive Card vs CLI digest vs
      Electron tray app vs all three?
- [ ] **Runtime**: Python or Node?
- [ ] **LLM endpoint**: which internal Azure OpenAI deployment?
- [ ] **Schedule cadence**: every 15 min? On-demand only? Pull during
      focus blocks too or skip them?
- [ ] **Calendar integration in MVP, or later?**
- [ ] **Does this duplicate Copilot for M365 Priority Inbox?** Audit
      before building. Internal hackathon projects may already cover
      ~70%.

## Recent changes

- _2026-05-20_ · Idea captured. No code.
