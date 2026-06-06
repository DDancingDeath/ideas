# Personal Agent Companion

> A personal iOS app — Teams-shaped but scoped to **just you and your agents** — that receives push notifications from a mixed set of AI agents (Copilot CLI sessions, GitHub Copilot coding agents, custom Foundry / Semantic Kernel agents, ADO / build hooks) and lets you chat back from your phone to approve, deny, or send new prompts. A unified backend normalises events from each source into one conversation thread per agent task, so heterogeneous agents look like one coherent inbox.

- Live code repo: not yet — design captured here, prototype not started
- Status: **idea** — design captured, ready for a v1 spike (see `plan/README.md`)

---

## The idea

I have agents in too many places — Copilot CLI sessions running on my dev box, GitHub Copilot coding agents on PRs, custom Foundry / Semantic Kernel things I'm prototyping, ADO pipeline hooks. Each one already knows how to notify *something* (a webhook, an email, a SignalR endpoint), but I have to babysit them all from the desktop. When I'm away from the laptop they're effectively offline to me — and even when I'm at the laptop, the surfaces are scattered.

**The novel mechanism:** every agent event normalises into *one* internal schema (`source`, `threadKey`, `kind`, `title`, `body`, `actions[]`), and the phone treats a "thread" as one agent task. A Copilot CLI run that asks *"approve this `rm -rf`?"* shows up as the same Teams-style chat bubble as a GitHub Copilot agent saying *"this PR is ready — merge?"*. I tap a button, the backend routes the reply back through the right adapter, and the agent on the other end picks up the answer. The phone is just the head; the **backend is the brain**.

**Anti-users / non-goals**: not multi-tenant, not for shipping to anyone else, not a Teams replacement. No file attachments, no voice notes, no offline composition queue in v1. Android is deferred (Expo gets it almost free later). No SDL / MSRC / Intune posture — this is a personal prototype that I sideload via TestFlight.

---

## How it works

Three pieces. Agents push events into the backend; the backend dispatches APNs; the phone reads and replies over a WebSocket.

```
┌────────────────┐    webhook/REST    ┌──────────────────────────┐
│ GitHub Copilot │ ─────────────────▶ │                          │
│  coding agent  │                    │                          │
└────────────────┘                    │                          │
┌────────────────┐    HTTP POST       │   Unified Agent Hub      │   APNs   ┌─────────┐
│ Local relay on │ ─────────────────▶ │  (backend: .NET / Node / │ ───────▶ │  iOS    │
│  dev box       │ ◀── long-poll ──── │   Python — TBD)          │          │  app    │
│  (Copilot CLI) │                    │   ├── Adapter registry   │ ◀── WS ─ │ (Expo)  │
└────────────────┘                    │   ├── Conversation store │          └─────────┘
┌────────────────┐    webhook         │   ├── Push dispatcher    │
│ ADO / Watson / │ ─────────────────▶ │   └── Entra auth         │
│  custom hooks  │                    └──────────────────────────┘
└────────────────┘
```

1. Each agent source has a small **adapter** in the backend that translates inbound events into the internal schema and translates outbound replies back into the agent's native protocol (HTTP call, queue message, long-poll response, etc.).
2. The backend persists conversations, dispatches push via APNs (through Expo Push Notification Service for the prototype), and serves the iOS app over a WebSocket for live thread updates.
3. The iOS app (React Native + Expo) signs in with Microsoft Entra ID, registers its Expo push token, shows a Teams-style thread list and chat view, and renders action buttons (Approve / Deny / Re-run / Cancel) from each event's payload.

For agents that run on my own machines (Copilot CLI sessions), a tiny **local relay** runs as a daemon, posts outbound events to the backend, and receives reply commands back over a long-poll / WebSocket — so I don't need to expose an inbound port on the dev box.

---

## What it does today (and what's next)

Status: **design captured, no prototype yet**.

Headline capabilities (planned for v1):

- Receive APNs push within a few seconds of an agent event, with title / source / action hints in the payload.
- Conversation list grouped by source, with unread badges.
- Thread view with chat bubbles + inline action buttons.
- Free-text reply routed back through the originating adapter.
- v1 adapters: **Copilot CLI** (via local relay) + **one webhook source** (default: GitHub Copilot coding agent).

Out of scope today (deferred):

- File attachments, image rendering, voice notes.
- Offline composition queue (online-only reply in v1).
- Android, Microsoft Store / App Store submission, multi-user or org rollout.

---

## Tech stack

- **Frontend (mobile)**: React Native + Expo SDK (TypeScript); EAS Build for cloud iOS builds; MSAL React Native for Entra auth; Expo Notifications for APNs registration.
- **Backend**: not finalised — leading candidates are .NET 9 ASP.NET Core minimal API + SignalR, Node / TS with Fastify + `ws`, or Python FastAPI. **Decision deferred to M1 kickoff.**
- **Conversation store**: SQLite for the local-dev phase; Cosmos DB if/when the backend moves to Azure Container Apps in M3.
- **Push**: Expo Push Notification Service (frees us from APNs cert juggling). Migrate to Azure Notification Hubs only if Expo Push hits a limit.
- **Auth**: Microsoft Entra ID (single user, personal work account). Phone uses MSAL; backend validates bearer tokens against the same app registration.
- **Hosting**: dev tunnels for M1–M2; Azure Container Apps from M3.

The contract that matters is the internal event schema (in `spec/`); everything else is negotiable.

---

## Reading order for an agent

1. `idea.md` — vision and constraints in detail.
2. `spec/README.md` — functional spec, data model, and the internal event schema (the part that matters most).
3. `plan/README.md` — phases, current status, decision log.
4. `prompts/build-from-spec.md` — paste to a coding agent to build the application.

## Layout

```
agent-companion/
├── README.md
├── idea.md
├── spec/
├── plan/
├── prompts/
└── assets/
```

## Recent changes

- _2026-06-06_ · initial scaffold + first-pass content from session plan
