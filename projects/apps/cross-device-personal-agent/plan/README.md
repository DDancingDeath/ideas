# Build plan — Cross-Device Personal Agent

The plan answers **what to do next and in what order**, not what to build.
For "what to build", see `../spec/`.

## Current status

**Idea** — design captured; no code yet. Open decisions enumerated in `../idea.md` ("Open questions"). Rescoped 2026-06-06 from a passive notification inbox (prior slug `agent-companion`) to a full cross-device personal agent (bidirectional command execution + notifications + device agents). Ready for a Phase 1 spike once the backend-stack and device-agent-language decisions are made (both have working defaults).

## Roadmap

The user-facing journey is staged into four phases. Each phase is independently shippable; later phases assume earlier ones.

- **Phase 1 — Remote command runner (MVP).** Prove end-to-end communication between phone and dev box.
  - Entra app registration.
  - Cloud control plane skeleton (auth + device + thread + command tables).
  - Device agent for Windows: outbound WebSocket to control plane; capability allow-list (`launch-app`, `open-url`, `open-file`, `run-script`, `query-status`); one-time pairing flow.
  - iOS app signs in, lists registered devices, sends a typed command, shows result in the thread.
  - *Demo path: tap "open OneNote" on the phone → OneNote launches on the dev box → "OneNote opened" appears in the thread.*

- **Phase 2 — Notifications.** Devices and AI agents push events upward.
  - WebSocket / SignalR for live thread updates on the phone.
  - APNs dispatch via Expo Push for events that warrant a push (`kind=status` high-priority, `question`, `approval-request`, `error`).
  - First non-device adapter: **GitHub Copilot coding agent** webhook.
  - Move control plane to Azure Container Apps (`azd up`); secrets to Key Vault; deep-linking from push to thread; unread badges; basic error states.
  - *Demo path: a long-running build on the dev box finishes → notification on the phone → tap to see "Build succeeded" with a "Run tests" action button.*

- **Phase 3 — AI layer (NL → action).** Convert natural language into structured commands.
  - Add a server-side NL → command parser (Azure OpenAI or equivalent). Input: utterance + per-device capability list + recent thread context. Output: a `Command` envelope or a clarifying question event.
  - Phone compose box becomes voice-or-text "tell my devices what to do". Suggested commands surface based on context.
  - *Demo path: "open the notebook I had open yesterday" → parser picks the file from device-side recent-files inventory → opens it.*

- **Phase 4 — Multi-agent workflows.** Chains and standing rules.
  - Backend supports a tiny rule DSL: triggers (event matches), conditions, actions (issue another command, send a notification, run a script).
  - *Examples: "when the build completes, run tests and summarise"; "every morning summarise unread mail + pending PRs"; "if any test fails for the third time today, ping me with the stack trace".*
  - Decide whether to add Android.

## Backlog (unordered)

- Push payload signing (so the phone can verify origin before showing).
- Per-thread mute / notification preferences.
- Snooze button on action prompts.
- Adapter for ADO pipelines (build green / red, approval gates).
- Adapter for Watson / Kusto alerts (read-only, threshold-based).
- Quick-actions on lock-screen (notification actions, no thread-open required).
- Web companion (for desktop parity without a Mac).
- Device agent for macOS / Linux.
- Per-device curated script directory UI (manage the `run-script` allow-list from the phone).
- Recent-files / open-windows inventory exposed by the device agent (needed for Phase 3 "the notebook I had open yesterday" parsing).

## Known issues / debt

None yet — no code.

## Decision log

Append-only. Each entry: date · decision · rationale · alternatives considered.

- _2026-06-06_ · React Native + Expo + EAS Build chosen as the mobile stack · No Mac available; EAS Build provides cloud iOS builds; Expo Push handles APNs token registration without cert juggling · Considered: PWA on Azure Static Web Apps (lighter but worse action-button UX), .NET MAUI / Flutter (both still need a Mac for iOS).
- _2026-06-06_ · Backend stack deferred to Phase 1 kickoff · Need to validate library support for SignalR-equivalent + Entra in each candidate · Considered: .NET 9 (working default), Node / TS, Python.
- _2026-06-06_ · First non-device adapter deferred to Phase 2 · Need to inspect what events each candidate emits before committing · Considered: GitHub Copilot agent (working default), ADO pipelines, generic JSON webhook.
- _2026-06-06_ · **Rescoped from "passive notification inbox" to full "cross-device personal agent"** · The mobile inbox is only half the value; the other half is being able to *send* commands to my dev boxes from the phone. Same plumbing (Entra-secured backend + WebSocket fan-out + Teams-style threads) serves both. Phase 1 MVP changed accordingly from "one-way push" to "remote command runner". Folder renamed `agent-companion` → `cross-device-personal-agent` · Considered: keeping inbox + commands as two separate ideas (rejected — they share the entire control-plane surface).
- _2026-06-06_ · Device agent is **capability-based, not a shell** · Allow-list of action kinds (`launch-app`, `open-url`, `open-file`, `run-script` from curated dir, `query-status`). Reasoning: I never want my phone to be "ssh into my dev box" — too much blast radius for a sideloaded personal app · Considered: PowerShell-remoting-style arbitrary command (rejected — security blast radius, IT-policy collision risk).
- _2026-06-06_ · Device agent uses **outbound-only WebSocket** · No inbound ports, works behind corp NAT, no firewall exceptions. Same pattern Tailscale / Ngrok use · Considered: inbound TLS endpoint (rejected — port forwarding pain, certificate inventory, IT collision).
