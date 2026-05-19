# Idea — inbox-triage

## One-liner

Personal AI assistant that triages my Microsoft work-day inbox (mail +
Teams + PRs + bugs) into a ranked todo list with drafted actions.

## Problem

I spend 20 minutes every morning skimming four disconnected surfaces
just to decide what to do first:

- **Outlook** — DLs, FYIs, action-requested mails, calendar invites
  needing response.
- **Teams** — direct chats, @mentions in channels, threads I'm tagged
  in but didn't open yet.
- **ADO pull requests** — assigned-as-reviewer queue, drafts of my own
  awaiting status, blocked-by-me on other PRs.
- **ADO bugs** — assigned to me, cc'd, on a personal query, on a sprint
  query.

None of these talks to the others. None of them score "what's actually
important". I rely on memory and gut and lose 20 minutes daily to that
skim.

## Target users

- **Primary**: me. Single-user, single-tenant, runs on my work device.
- **Secondary**: would generalize to anyone on a Microsoft-internal team
  with the same four surfaces — but generalization is explicitly **not
  an MVP goal**.
- **Anti-users**: anyone outside Microsoft (this uses internal-only
  endpoints), and any use case where the assistant takes irreversible
  action (sending, approving, closing) without my confirmation.

## What success looks like

- The 20-minute morning skim becomes a **2-minute review** of a ranked
  list with one-line "why this matters" notes.
- Top-3 items have **drafts ready** I can edit-and-send in one click.
- **Zero auto-sent messages** in the first quarter — every action goes
  through my confirmation.
- Recall: no item I'd have rated "important" gets ranked below an item
  I'd have rated "not important" (measured weekly by me eyeballing the
  list).
- Precision: drafts are useful at least 60 % of the time (I'd send
  them with minor edits, not rewrite from scratch).

## Constraints

- **No corporate data leaves the device.** All LLM calls hit an
  internal-approved Azure OpenAI endpoint.
- **Runs on the work laptop.** Conditional Access + Intune compliance
  effectively require it.
- **No PAT in source.** Tokens live in Windows Credential Manager.
- **Free / internal-tier only** — no extra license cost beyond what
  M365 + ADO already provide.
- **No background polling outside work hours** — respects focus / OOF.

## Non-goals

- Auto-sending, auto-approving, auto-closing.
- Meeting scheduling / calendar coaching.
- Document / OneNote / SharePoint ingestion.
- Multi-user / SaaS variant.
- Mobile app — the surface stays on the work device.
- Voice input (that's `notes-reminders`).

## Inspiration / prior art

- **Copilot for M365 Priority Inbox + Chat** — solves part of #1 (mail
  prioritization) and #2 (Teams summarization). Audit before building.
- **MyHub** — internal portal aggregating PRs, bugs, mails. UI-only;
  doesn't rank or draft.
- Various internal hackathon projects that aggregate ADO + Graph signals.
- Cortex (defunct) and Microsoft Viva Briefing (calendar-focused).

## Open questions

- [ ] Does Copilot for M365 already do enough of this? Audit needed
      before any code.
- [ ] Surface choice: Teams self-chat Adaptive Card vs CLI digest vs
      Electron tray app — see README.
- [ ] Is there an internal MCP server that already exposes Graph + ADO
      with the right auth model?
- [ ] How does this interact with focus time / OOF? Pause during
      focus blocks?
- [ ] PR-review depth: just surface them, or also fetch the diff and
      let the LLM pre-comment?
- [ ] Bug triage: include team-wide queries, or only items where I'm
      assigned/cc'd?
