# Remote App Launcher

> The smallest end-to-end loop that proves the [cross-device personal agent](../cross-device-personal-agent) concept works in real life. *Type `notepad` on the phone, notepad opens on the dev box.* Nothing else.

## Problem

I have a much larger design captured in [cross-device-personal-agent](../cross-device-personal-agent) — bidirectional commands and notifications, NL parsing, multi-agent workflows. That's months of work and many design decisions that are *cheap on paper* and *expensive once built*.

Two specific risks worry me, neither of which I can resolve on paper:

1. **Network plumbing.** Will the outbound-only device-agent → cloud → phone loop actually be reliable enough end-to-end (cellular included) to feel responsive? Long-poll vs WebSocket, tunnel choice, latency in practice — these all need to be felt, not modelled.
2. **Cost of friction.** A "personal" app that needs Apple Developer Program enrolment, EAS Build, TestFlight invitations, Entra app registration, Azure Container Apps deployment, and Cosmos DB provisioning *before* the first line of business code runs is dead-on-arrival. Will the cheapest possible path (Expo Go + shared secret + dev tunnels + in-memory store) actually carry weight for a demo? If not — what breaks first?

Both risks are answered by building the smallest possible thing that touches every layer, and using it for two weeks.

## Target users

- **Primary**: just me. Single user. One iPhone, one Windows dev box.
- **Anti-users**: anyone else. Don't share the URL. Don't share the secret. Don't deploy this for anyone.

## What success looks like

v0 is "done" when **all** of the following hold for two weeks of daily use:

- Tap **Launch** on the phone with `notepad` typed → notepad is visible on the dev box → phone shows ✅ result. **End-to-end latency < 5 s p50**, including the 500 ms phone-poll cadence.
- This works from cellular (not just home wifi).
- Backend can restart without me reconfiguring the phone (the tunnel URL persists, or I just retype it).
- Device agent can crash-restart and self-recover (long-poll resumes).
- Total code: **≤ 1000 LoC** across all three components.
- Total build effort: **≤ 12 hours** of focused weekend time.
- I can extend the app allow-list (`apps.json`) by editing a file and restarting the agent.

If any of these fail, the parent project's design assumptions (long-poll viability, shared-secret-then-Entra migration path, capability-based action set) need revisiting before Phase 1.

## Constraints

- **Develop on Windows** (no Mac). Phone runs **Expo Go** in v0 — no native modules, no EAS Build, no TestFlight enrolment.
- **No Azure account** spent in v0. Everything runs on the dev box; backend exposed via VS dev tunnels (free).
- **No Apple Developer Program** seat needed in v0. Expo Go is enough for a single-screen plain-HTTP app.
- **Single shared secret** for auth across all three components. Document its insecurity loudly.
- **In-memory storage** only. Commands lost on backend restart. Acceptable — v0 commands are ephemeral.
- **One device** ("my-dev-box"), **one user**, **one secret**. Hardcoded.
- **One command kind** (`launch-app`). Anything else returns "not implemented".
- **App allow-list lives in a config file** (`apps.json`), not a UI. Edit and restart the agent.

## Non-goals (the long list)

- Entra ID auth. (v1.)
- APNs / push notifications of any kind. (v1.)
- WebSocket / SignalR. (v1.)
- Persistent storage. (v1.)
- Multiple devices. (v1.)
- Multiple command kinds (`open-url`, `open-file`, `run-script`, `query-status`). (v1.)
- Notifications back from agents (the inbound half of the parent design). (v1.)
- Free-text chat / threads. (v1.)
- AI / natural-language parsing. (v3.)
- Multi-agent workflows. (v4.)
- Offline send queue. (Never — v1+ is online-only too.)
- iOS production distribution (App Store / TestFlight). (v1+ once we add native modules for APNs.)
- macOS / Linux device agent. (v1+, on demand.)
- Android phone. (v1+ Expo gets it almost free.)
- Per-device UI in the phone. (v1.)
- Pairing flow / device registration. (v1.)
- Per-thread mute / preferences. (v1.)
- App Insights / metrics / dashboards. (v1.)
- Rate limiting. (v1+, only if needed.)

## Inspiration / prior art

- **Visual Studio dev tunnels** — the moment they shipped, the "free tunnel to your laptop" problem went from "ngrok subscription" to "click a button". v0 leans on this hard.
- **Expo Go** — proves you can run a non-trivial RN app on iPhone without ever touching Apple's signing flow. v0 leans on this hard too.
- **iOS Shortcuts** — proof that "do a thing on a device, from elsewhere" is a habit-forming primitive.
- **Tailscale SSH** — outbound-initiated agent on a target machine, controlled remotely. Same connection pattern (just SSH instead of long-poll JSON).

## Open questions

- [ ] **Tunnel choice.** VS dev tunnels (default) vs Cloudflare Tunnel vs ngrok free. Decide at M0; tunnel URL will be hardcoded into the Expo Go bundle for the duration of v0.
- [ ] **Phone polling cadence.** 500 ms (snappy, more battery) vs 1 s (gentler) vs server-sent-events (fancier). Default: 500 ms short-poll for 30 s, then give up.
- [ ] **Backend listening port + tunnel URL stability.** VS dev tunnels give a stable subdomain on Azure account. Confirm.
- [ ] **Expo Go reachability across cellular.** Expo Go fetches the JS bundle from the Expo dev server. Will the dev server be reachable from cellular, or do I need to use `--tunnel` mode for `expo start` too? Default: try `--tunnel` mode for Expo dev server.
- [ ] **App allow-list scope.** Start with: notepad, calc, code, onenote, edge. Add more after first demo if any obvious miss.
