# Cross-Device Personal Agent

> A personal iOS app + cloud control plane + a small device agent on each of my dev machines, that lets me run commands on, and receive notifications from, all my development environments and AI agents — from my phone, in natural language.

## Problem

I work across multiple development machines and step away from them constantly. While away — and often even while at the desk — I have **no simple way to interact with my active work environment from my phone using natural language**.

Concrete missing capabilities, today:

- Check whether a build has completed.
- Open a document or notebook on a specific dev box.
- Start a script remotely.
- Launch an application.
- Get notified the second a long-running task finishes.
- Query the current state of a machine ("is anything stuck?", "what tests failed?").

Each AI agent / build / pipeline already knows how to notify *something* — a webhook, an email, a SignalR endpoint — and each dev machine exposes thousands of ways to do things locally. But from the phone, none of this is reachable. The pain in one sentence: **my machines and agents already produce structured events and accept structured commands, but there is no one place I can read, approve, command, and steer them from my phone.**

Teams *almost* solves the inbound half — chat + push + actionable cards — but it's built for human conversations and routes everything through tenant policy. For *agents talking to me, and me commanding machines*, where I'm both ends of the loop, Teams is too heavy and too noisy.

## Target users

- **Primary**: just me. Single user, personal Microsoft work account.
- **Secondary**: none (anti-secondary, in fact — see non-goals).
- **Anti-users**: anyone wanting to share with a team, deploy via Intune, or use this as a Teams replacement. Multi-tenant adds 10× complexity for zero personal benefit.

## What success looks like

A user (me) can:

- Send a command from the phone and have it execute on any registered dev machine within **a few seconds** end-to-end (nominal conditions).
- Receive notifications when long-running tasks complete, with one tap to open the relevant thread or take an action (approve / deny / re-run / cancel).
- Interact in natural language ("open the notebook I had open yesterday") by Phase 3.
- Manage **multiple devices** through a single personal agent.
- All of this runs on **Microsoft credits** (no paid services beyond the existing Apple Developer Program seat).

Latency targets:

- Phone tap → command starts executing on the dev box: **under 3 s p50.**
- Agent event → APNs delivery on the phone: **under 5 s p50.**

## Constraints

- **Develop on Windows**, no Mac available. iOS builds happen in the cloud via EAS Build.
- **Single Apple Developer seat** (personal $99/yr; no enterprise distribution channel).
- **No SDL / MSRC / Intune posture** — personal prototype, sideloaded via TestFlight. No production Microsoft secrets in the app.
- **Cost budget**: fits inside MSDN / VS Enterprise Azure credits.
- **Device agent runs outbound-only** — no inbound ports on the dev box, no enterprise firewall exceptions, no certificate inventory pain.
- **Push payloads carry summaries only** — no sensitive content leaves the backend in a push notification.
- **Command allow-list, not arbitrary RCE** — the device agent only executes from a vetted set of capabilities (launch app, open URL, open file, run script from a curated script directory, query status). No "exec arbitrary command from phone".

## Non-goals

- Multi-user / org rollout.
- Android in v1 (Expo gets it almost free later — deferred to a Phase 4 decision).
- Microsoft Store / App Store submission.
- File attachments, image rendering, voice notes (v1).
- Offline composition queue (online-only reply / send in v1).
- Full SDL / CyberEO compliance posture.
- Replacing any human-to-human surface (Teams, Outlook, Slack).
- Arbitrary remote shell. The device agent is *capability-based*, not a shell.

## Inspiration / prior art

- **Microsoft Teams** — the chat-shaped notification + threaded conversation pattern.
- **Slack bot interactions** — actionable buttons that route back to the bot.
- **Tailscale / Ngrok-style outbound-initiated tunnels** — the model the device agent copies for on-box agents behind corp NAT.
- **iOS Shortcuts** — proves users (me) like NL-style "do this thing on my device from anywhere".
- **Scout / Clawpilot** — the eventual aspiration: a personal agent that knows enough about all my devices to act on my behalf.

## Open questions

- [ ] Backend stack: .NET 9 vs Node / TS vs Python. **Working default: .NET 9** (matches MS tooling); revisit at Phase 1 kickoff.
- [ ] Device agent language: same as backend (shared schema package) vs a tiny Go binary. **Working default: same as backend.**
- [ ] Backend host: dev tunnels (free, ephemeral) vs Azure Container Apps (durable). **Working default: tunnels for Phase 1, Container Apps from Phase 2.**
- [ ] Conversation persistence: SQLite-on-pod vs Cosmos DB. **Working default: SQLite for Phase 1, Cosmos from Phase 2.**
- [ ] First non-device adapter for Phase 2: GitHub Copilot coding agent webhook vs ADO pipelines vs generic JSON POST. **Working default: GitHub Copilot agent.**
- [ ] AI layer (Phase 3): server-side LLM (Azure OpenAI) vs on-device (Apple Intelligence) for NL → action parsing.
- [ ] Do I have a paid Apple Developer Program seat? Required for TestFlight.
