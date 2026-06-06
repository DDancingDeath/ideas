# Personal Agent Companion

> A personal iOS app — Teams-shaped but scoped to just you and your agents — that receives push notifications from a mixed set of AI agents and lets you chat back to approve, deny, or send new prompts. A unified backend normalises events from many agent sources into one conversation model.

## Problem

I run agents across multiple disconnected surfaces — Copilot CLI sessions on my dev box, GitHub Copilot coding agents on PRs, custom Foundry / Semantic Kernel prototypes, ADO pipelines, Watson / Kusto alerts. Each has its own notification channel, its own UI, and its own reply path. When I'm at the desktop the cognitive cost of context-switching across them is real; when I'm away from the desktop they're effectively offline to me.

Teams *almost* solves it — chat + push + actionable cards — but it's built for human conversations and routes everything through tenant policy. For *agents talking to me*, where I'm both ends of the loop, Teams is too heavy and too noisy.

The pain in one sentence: **agents already produce structured events, but there is no one place I can read, approve, and steer them from my phone.**

## Target users

- **Primary**: just me. Single user, personal Microsoft work account.
- **Secondary**: none (anti-secondary, in fact — see non-goals).
- **Anti-users**: anyone wanting to share with a team, deploy via Intune, or use this as a Teams replacement. Multi-tenant adds 10× complexity for zero personal benefit.

## What success looks like

- An agent event becomes a phone notification in **under 5 seconds** end-to-end (nominal conditions).
- I can approve / deny / reply from the phone and the originating agent picks up the response within its own polling interval (≤30 s for the CLI relay, ≤10 s for backend-pushed adapters).
- One unified thread list per agent task, regardless of source — no source-specific UI on the phone.
- All of this runs on **Microsoft credits** (no paid services beyond the existing Apple Developer Program seat).

## Constraints

- **Develop on Windows**, no Mac available. iOS builds happen in the cloud via EAS Build.
- **Single Apple Developer seat** (personal $99/yr; no enterprise distribution channel).
- **No SDL / MSRC / Intune posture** — personal prototype, sideloaded via TestFlight. No production Microsoft secrets in the app.
- **Cost budget**: fits inside MSDN / VS Enterprise Azure credits.
- **Push payloads carry summaries only** — no sensitive content (PII, ticket details, kernel cab content) leaves the backend in a push notification.

## Non-goals

- Multi-user / org rollout.
- Android (Expo gets it almost free later — deferred to a Phase 4 decision).
- Microsoft Store / App Store submission.
- File attachments, image rendering, voice notes (v1).
- Offline composition queue (online-only reply in v1).
- Full SDL / CyberEO compliance posture.
- Replacing any human-to-human surface (Teams, Outlook, Slack).

## Inspiration / prior art

- **Microsoft Teams** — the chat-shaped notification + threaded conversation pattern.
- **Push notifications on iOS 16.4+** — including web push, which makes the PWA path tempting (rejected: native gives better action buttons and APNs reliability).
- **Slack bot interactions** — actionable buttons in messages route back to the bot.
- **Tailscale / Ngrok-style outbound-initiated tunnels** — the model the local relay copies for on-box agents behind NAT.

## Open questions

- [ ] Backend stack: .NET 9 vs Node/TS vs Python. **Working default: .NET 9** (matches MS tooling); revisit at M1 kickoff.
- [ ] First non-CLI adapter: GitHub Copilot coding agent webhook vs ADO pipelines vs generic JSON POST. **Working default: GitHub Copilot agent.**
- [ ] Backend host: dev tunnels (free, ephemeral) vs Azure Container Apps (durable). **Working default: tunnels for M1–M2, Container Apps from M3.**
- [ ] Conversation persistence: SQLite-on-pod vs Cosmos DB. **Working default: SQLite for M1–M2, Cosmos from M3.**
- [ ] Do I have a paid Apple Developer Program seat? Required for TestFlight.
