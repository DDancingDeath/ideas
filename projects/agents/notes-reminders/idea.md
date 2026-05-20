# Idea — notes-reminders

## One-liner

A capture-first agent that takes voice / text / clipboard input,
classifies it into note / todo / reminder / question, routes each to
the right system, and surfaces it back when it's useful.

## Problem

The capture cost for ideas, todos, and reminders is too high. I lose
decisions and tasks because opening OneNote or Todo or Outlook
mid-flow is friction. Voice notes are easy to *create* but die on the
shelf — not searchable, not actionable, not surfaced when needed.

## Target users

- **Primary**: me. Personal use.
- **Anti-users**: anyone whose capture friction is already low.

## What success looks like

- **Capture latency**: from "I want to note this" to "noted" in under
  3 seconds. Hotkey or push-to-talk.
- **Recall**: when something I captured is relevant tomorrow / next
  week, the agent surfaces it without me searching.
- **Auto-route accuracy**: ≥ 80 % of captures land in the right
  destination without me re-classifying.
- **Search**: I can find any past capture by what I roughly remember
  ("that thing about the lock contention idea from last month").

## Constraints

- **Capture latency < 3 s**. Anything slower kills the habit.
- **STT on-device** — Whisper local. No cloud round-trip in the
  capture path.
- **Privacy boundary** matches the tenant: work captures stay in
  corp services if I'm in work-tenant mode; personal stays local or
  in personal cloud.

## Non-goals

- A full PKM (personal knowledge management) tool — Obsidian / Logseq
  exist.
- A meeting-recording tool — Teams already does this; the agent reads
  the output rather than competing.
- A calendar / scheduling tool. Reminders only.
- Multi-user / shared notes.

## Inspiration / prior art

- **Clawpilot** _(Microsoft-internal, `aka.ms/clawpilot-request`)_ —
  Workflows + Skills cover the *reminders / scheduled brief* side
  cleanly (multi-step natural-language prompts on a cron). It does
  **not** do voice-first capture, on-device STT, or auto-classification
  of captures into note/todo/reminder — that's the gap this project
  fills. The reminders layer should likely be a Clawpilot Workflow,
  with the capture-and-classify pipeline as the new piece.
- **AudioPen / Otter** — voice-first capture, but no auto-routing.
- **Apple / Google Reminders** — fast capture, no classification.
- **Microsoft To Do + OneNote** — destination systems; lack the
  capture-and-route front end.
- **Copilot for M365** — overlaps in capture; not push-to-talk and
  not classification-routed.

## Open questions

- [ ] **Can Clawpilot host the reminders + briefing layer?** If yes,
      this project narrows to the capture-and-classify front end only.
- [ ] Tenant — work AAD or personal MSA?
- [ ] Capture surface — desktop hotkey, mobile-first, both?
- [ ] Output systems — Outlook + OneNote, or local store?
- [ ] Wake-word vs push-to-talk?
- [ ] How does this compose with `inbox-triage`? (Reminders
      could surface there.)
