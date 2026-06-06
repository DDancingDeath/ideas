# Build plan — Personal Agent Companion

The plan answers **what to do next and in what order**, not what to build.
For "what to build", see `../spec/`.

## Current status

**Idea** — design captured; no code yet. Open decisions enumerated in `../idea.md` ("Open questions"). Ready for a v1 spike once the backend-stack and first-non-CLI-adapter decisions are made (both have working defaults).

## Roadmap

Milestones, not tasks. Each milestone should be shippable on its own.

- **M0 — Decisions & scaffolding** — confirm the assumption table in `../idea.md`; create repo layout (`/app` Expo project, `/backend`, `/relay`, `/infra`); stand up empty Expo project on Windows; verify EAS Build smoke build to a TestFlight slot.
- **M1 — One-way notifications** — Entra app registration; backend skeleton (auth + thread + event tables + Expo Push dispatcher); iOS app signs in, registers push token, shows thread list + thread view (read-only). *Demo path: `curl` a fake event into the backend → notification on phone → thread updates.*
- **M2 — Two-way chat & first real adapter** — WebSocket (SignalR or `ws`) for live thread updates; reply box posts back; action buttons render from `actions[]`. Ship **Copilot CLI local relay** (outbound HTTP + long-poll/WS).
- **M3 — Second adapter + Azure hosting** — add GitHub Copilot coding agent webhook adapter. Move backend to Azure Container Apps with `azd up`; secrets to Key Vault; deep-linking from push to thread; unread badges; basic error states.
- **M4 — Hardening (optional)** — dedup / retry on push failures; App Insights dashboards (events/sec, push latency, adapter errors); per-adapter rate limiting. Decide whether to add Android.

## Backlog (unordered)

- Push payload signing (so the phone can verify origin before showing).
- Per-thread mute / notification preferences.
- Snooze button on action prompts.
- Adapter for ADO pipelines (build green / red, approval gates).
- Adapter for Watson / Kusto alerts (read-only, threshold-based).
- Quick-actions on lock-screen (notification actions, no thread-open required).
- Web companion (for desktop parity without a Mac).

## Known issues / debt

None yet — no code.

## Decision log

Append-only. Each entry: date · decision · rationale · alternatives considered.

- _2026-06-06_ · React Native + Expo + EAS Build chosen as the mobile stack · No Mac available; EAS Build provides cloud iOS builds; Expo Push handles APNs token registration without cert juggling · Considered: PWA on Azure Static Web Apps (lighter but worse action-button UX), .NET MAUI / Flutter (both still need a Mac for iOS).
- _2026-06-06_ · Backend stack deferred to M1 kickoff · Need to validate library support for SignalR-equivalent + Entra in each candidate · Considered: .NET 9 (working default), Node / TS, Python.
- _2026-06-06_ · First non-CLI adapter deferred to M3 · Need to inspect what events each candidate emits before committing · Considered: GitHub Copilot agent (working default), ADO pipelines, generic JSON webhook.
