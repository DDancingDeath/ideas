# Cross-Device Personal Agent

> A personal iOS app + cloud control plane + a small device agent on each of my dev boxes that lets me **run commands on, and receive notifications from, all of my development machines and AI agents — from my phone, in natural language**. The phone is the head; the backend is the brain; the device agents are the hands. Starts as a plain "remote command runner" MVP and grows into a Scout/Clawpilot-style personal assistant that spans every machine I work on.

- Live code repo: not yet — design captured here, prototype not started
- Status: **idea** — design captured, ready for a Phase 1 spike (see `plan/README.md`)

---

## The idea

I work across multiple dev machines and step away from them constantly. Today I have **no simple way to interact with my active work environment from my phone using natural language** — to check if a build is still running, open a notebook I was reading yesterday, kick off a script, query "is anything stuck?", or get notified the second a long-running task finishes. Each agent / build / pipeline already knows how to notify *something*, but the surfaces are scattered across Teams, email, IDE popups, and ad-hoc webhooks. From the phone, they're effectively invisible.

I want one personal agent that bridges my phone and my machines — bidirectional. From the phone:

> "Open my TableView design notebook."
> "Is my build still running?"
> "Notify me when the build finishes."
> "Show me the latest test results."
> "Open Teams and jump to the design review thread."

The agent figures out the right machine, executes the action there, and reports back. Notifications flow the other direction on the same plumbing — when something interesting happens on a machine, it shows up as a Teams-style chat bubble on the phone with action buttons.

**Anti-users / non-goals**: not multi-tenant, not for shipping to anyone else, not a Teams replacement. No file attachments / voice notes in v1. Android deferred. No SDL / MSRC / Intune posture — personal prototype, sideloaded via TestFlight. **Capability-based device agent, not a remote shell** — no arbitrary RCE from the phone.

---

## How it works

Three pieces. The phone calls the backend; the backend routes to the right device agent; the device agent executes locally and reports back. The same pipe carries inbound agent events the other way.

```
┌─────────────────┐     APNs / WS       ┌──────────────────────────┐
│   iOS app       │ ◀────────────────── │                          │
│   (Expo / RN)   │ ──── REST / WS ───▶ │                          │
└─────────────────┘                     │                          │     ┌───────────────────┐
                                        │   Cloud control plane    │     │ Dev box 1         │
┌─────────────────┐                     │   • Entra auth           │ ◀─▶ │ ├─ device agent   │
│ AI agent sources│ ── webhook ───────▶ │   • Adapter registry     │     │ ├─ Copilot CLI    │
│  (GH Copilot,   │                     │   • Device registry      │     │ └─ apps, files,   │
│   custom, ADO,  │                     │   • Conversation store   │     │    curated scripts│
│   Watson)       │                     │   • Push dispatcher      │     └───────────────────┘
└─────────────────┘                     │   • Command router       │     ┌───────────────────┐
                                        └──────────────────────────┘     │ Dev box 2 …       │
                                                                         └───────────────────┘
```

1. The **iOS app** (React Native + Expo, Entra-signed-in) shows a Teams-style thread list — one thread per ongoing task or device session. Compose box at the bottom; action buttons render from the event's `actions[]`.
2. The **cloud control plane** authenticates the user, holds the device & adapter registries, persists conversations, dispatches push (APNs via Expo Push), and routes commands to the right device agent.
3. A small **device agent** runs as a daemon on every machine I care about. It opens an **outbound** long-poll / WebSocket to the control plane (no inbound ports, works behind corp NAT), executes approved actions (launch app, open URL, open file, run a curated script, query status), and pushes back results plus any unsolicited events (build finished, test failed, agent asks a question).
4. **AI agent sources** that don't run on my own machines (GitHub Copilot coding agent, ADO pipelines, custom Foundry / SK things) post events directly to the control plane via per-source adapters.

Every interaction — outbound command result or inbound agent notification — normalises into one internal schema, so the phone treats every conversation as the same shape.

---

## What it does today (and what's next)

Status: **design captured, no prototype yet**.

The journey is staged into four phases. Each is independently shippable; later phases assume earlier ones.

- **Phase 1 (MVP): Remote command runner.** Phone sends explicit commands (`open OneNote`, `run script X`, `query status`) → control plane → device agent → executes → result returns to the phone. Proves end-to-end communication. *No AI, no inbound agent notifications yet.*
- **Phase 2: Notifications.** Agents and devices push events upward; the control plane fans out to APNs; the phone shows them as Teams-style chat bubbles with action buttons.
- **Phase 3: AI layer (NL → action).** Natural-language commands ("open the notebook I was on yesterday", "is my build still running?") get parsed into structured commands by a server-side LLM.
- **Phase 4: Multi-agent workflows.** Chains and standing rules ("when the build completes, run the tests and summarise"; "every morning summarise unread mail + pending PRs").

Headline capabilities planned for **Phase 1**:

- iOS app signs in (Entra), lists registered devices, sends a typed command.
- Device agent installed on at least one Windows dev box; can launch apps, open files / URLs, run a small allow-listed script set, and report machine status.
- Command executes within a few seconds of phone tap; result returns to the thread.

Out of scope today (deferred): file attachments / voice notes / image previews / Android / offline send-queue / multi-user / App Store submission / SDL posture / arbitrary remote shell.

---

## Tech stack

- **Frontend (mobile)**: React Native + Expo SDK (TypeScript); EAS Build for cloud iOS builds; MSAL React Native for Entra; Expo Notifications for APNs.
- **Cloud control plane**: not finalised — leading candidates are .NET 9 ASP.NET Core minimal API + SignalR, Node / TS + Fastify + `ws`, or Python FastAPI. **Decision deferred to Phase 1 kickoff** (working default: .NET 9).
- **Device agent**: a small long-running daemon on each dev machine. Same language as the backend by default (so we can share the schema package). Targets Windows first; macOS / Linux later. Outbound-only WebSocket; capability-based action set.
- **Conversation / device store**: SQLite for Phase 1; Cosmos DB if/when the backend moves to Azure Container Apps in Phase 2.
- **Push**: Expo Push Notification Service.
- **Auth**: Microsoft Entra ID (single user). Phone uses MSAL; backend validates bearer tokens against the same app registration. Device agent authenticates with a long-lived **device-registration token** issued by the control plane after a one-time pairing flow (phone shows a 6-digit code, device agent posts it).
- **Hosting**: dev tunnels for Phase 1; Azure Container Apps from Phase 2.

The contract that matters is the internal command / event schema (in `spec/`); everything else is negotiable.

---

## Reading order for an agent

1. `idea.md` — vision and constraints in detail.
2. `spec/README.md` — functional spec, data model, and the internal command / event schema (the part that matters most).
3. `plan/README.md` — phases, current status, decision log.
4. `prompts/build-from-spec.md` — paste to a coding agent to build the application.

## Layout

```
cross-device-personal-agent/
├── README.md
├── idea.md
├── spec/
├── plan/
├── prompts/
└── assets/
```

## Recent changes

- _2026-06-06_ · initial scaffold (under prior slug `agent-companion`)
- _2026-06-06_ · rescoped from "passive notification inbox" to full "cross-device personal agent" (bidirectional command execution + notifications + device agents); folder renamed `agent-companion` → `cross-device-personal-agent`
