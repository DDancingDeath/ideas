# Functional spec — Cross-Device Personal Agent

This is the **source of truth for what to build**. An agent reading only this
folder should be able to produce a working application.

## Reading order

1. This file (overview + tech stack + the internal command / event schema).
2. *(future)* `page-specs/` — per-screen specs in numeric order.
3. *(future)* `adapters-design.md` — adapter contract and per-source notes.
4. *(future)* `device-agent-design.md` — device-agent capability model and pairing flow.

## Overview

**What it does** — A personal iOS app, a cloud control plane, and a device agent on each dev machine. The phone sends commands → control plane routes → device agent executes → result returns to the phone. The same plumbing carries unsolicited events from agents and devices back to the phone as notifications. Every interaction shows up as a Teams-style thread, one per ongoing task or device session.

**Who it's for** — A single user (the author). Microsoft personal work account, sideloaded via TestFlight.

**Primary user journeys**

1. *I send a command from the phone.* Thread view → tap "send command" → pick device → either pick from a typed-action menu (Phase 1) or speak / type natural language (Phase 3). Command flows over WebSocket → control plane validates auth & resolves target device → routes to device agent → executes → result returned to the thread within seconds. A status pill shows pending → done / failed.
2. *I receive a notification.* An agent on any source (or a device agent reporting a finished long-running task) emits an event → backend stores it, decides to push → APNs notification on the phone with title, source, action hints → tap to deep-link into the thread.
3. *I tap a one-shot action.* The thread view shows action buttons (Approve / Deny / Re-run / Cancel) rendered from the event's `actions[]`. Tapping dispatches a reply through the originating adapter; thread state updates live over the WebSocket.
4. *I reply / chat in free-text.* Compose box at the bottom of the thread. Text routes to the originating adapter or, if the thread is device-scoped, parses into a command (Phase 3+).
5. *I scroll history.* Thread list grouped by source / device, sorted by latest activity, with unread badges. Pull-to-refresh.

## Tech stack

- **Frontend**: React Native + Expo SDK (TypeScript); EAS Build for cloud iOS builds; MSAL React Native for Entra auth; Expo Notifications for APNs; React Query for cache; React Navigation; a minimal UI library (Tamagui or NativeBase — *suggested*).
- **Cloud control plane**: *(suggested)* .NET 9 ASP.NET Core minimal API + SignalR; Entity Framework Core over SQLite (Phase 1) → Cosmos DB (Phase 2+). Open to Node / TS or Python — the adapter shape, device-agent protocol, and command / event schema are the real contract.
- **Device agent**: a small long-running daemon on each dev machine. Outbound-only WebSocket to the control plane (no inbound ports). Capability-based action set: `launch-app`, `open-url`, `open-file`, `run-script` (from a curated directory), `query-status`. Same language as backend by default so we can share schema.
- **Auth**: Microsoft Entra ID for the user. Phone uses MSAL; backend validates bearer tokens against the same app registration. Device agent authenticates with a long-lived **device-registration token** issued by the control plane after a one-time pairing flow (phone shows a 6-digit code, device agent posts it).
- **Hosting**: dev tunnels for Phase 1; Azure Container Apps from Phase 2 (Bicep / `azd` template under `/infra` once code starts).
- **Mobile build**: EAS Build (cloud); EAS Submit for TestFlight delivery.

Negotiable: every line above except the auth provider (Entra) and the internal schema below.

## Data model (high level)

- **User** — `id`, `entraOid`, `displayName`, `expoPushTokens[]`, `createdAt`. Single row in v1; modelled as a table so multi-user isn't a future schema migration.
- **Device** — `id`, `userId`, `name` (`dev-laptop`, `home-desktop`, …), `os` (`win` | `mac` | `linux`), `agentVersion`, `lastSeenAt`, `capabilities[]` (`launch-app` | `open-url` | `open-file` | `run-script` | `query-status`), `registrationTokenHash`. Registered via the pairing flow.
- **Adapter** — `id`, `source` (`copilot-cli` | `gh-copilot` | `ado` | `custom`), `config` (JSON), `enabled` (bool). For inbound non-device events.
- **Thread** — `id`, `userId`, `threadKey` (stable correlation id from the device / adapter), `scope` (`device` | `agent`), `targetId` (deviceId or adapterId), `title`, `status` (`open` | `archived`), `unreadCount`, `lastActivityAt`.
- **Event** — `id`, `threadId`, `kind` (`status` | `question` | `approval-request` | `error` | `message` | `command-result`), `title`, `body` (markdown), `actions` (JSON array of `{id, label, style}`), `createdAt`, `externalEventId` (for dedup), `authoredBy` (`agent` | `device` | `user`).
- **Command** — `id`, `threadId`, `deviceId`, `kind` (`launch-app` | `open-url` | `open-file` | `run-script` | `query-status`), `args` (JSON), `status` (`pending` | `running` | `done` | `failed` | `cancelled`), `requestedAt`, `completedAt`, `result` (JSON).
- **Delivery** — `id`, `eventId`, `expoPushTicketId`, `status` (`pending` | `sent` | `failed`), `attempts`, `lastError`.

## Internal command / event schema (the contract)

### Inbound event (agent or device → phone)

```json
{
  "eventId": "uuid",
  "source": "copilot-cli | gh-copilot | ado | custom | device:<deviceId>",
  "threadKey": "stable-correlation-id-for-this-task",
  "kind": "status | question | approval-request | error | message | command-result",
  "title": "short summary suitable for a push notification (<= 80 chars)",
  "body": "longer markdown body",
  "actions": [
    { "id": "approve", "label": "Approve", "style": "primary" },
    { "id": "deny",    "label": "Deny",    "style": "destructive" }
  ],
  "createdAt": "iso-8601"
}
```

### Outbound command (phone → device agent)

```json
{
  "commandId": "uuid",
  "threadId": "uuid-of-thread",
  "deviceId": "uuid-of-target-device",
  "kind": "launch-app | open-url | open-file | run-script | query-status",
  "args": {
    "appName": "OneNote",                     // for launch-app
    "url": "https://...",                     // for open-url
    "path": "C:/notes/TableView.one",         // for open-file
    "scriptId": "build-status",               // for run-script (must be in agent's curated set)
    "scriptArgs": [],                         // for run-script
    "what": "build | tests | disk | all"      // for query-status
  },
  "createdAt": "iso-8601"
}
```

### Reply envelope (phone → agent, for action-button taps)

```json
{
  "replyId": "uuid",
  "threadKey": "same-as-inbound",
  "kind": "action | message",
  "actionId": "approve",
  "text": "free-text body when kind=message",
  "createdAt": "iso-8601"
}
```

### Command result (device agent → phone, expressed as an Event)

A `command-result` event ties back to the originating `commandId` via `externalEventId = commandId`, with `kind=command-result`, a terminal status in the body (`done` | `failed`), and the device's output in `body`.

## Non-functional requirements

- **Latency**: phone tap → command starts on device < 3 s p50; agent event → APNs delivery < 5 s p50.
- **Reliability**: backend can crash-restart without losing already-acknowledged events; push retries are idempotent on the phone (dedup by `eventId`); commands dedup by `commandId`.
- **Security**:
  - Entra-protected APIs; backend secrets in Azure Key Vault; no agent secrets stored on device.
  - Push payloads carry summaries only.
  - Device agent action set is allow-listed; **no arbitrary shell**. `run-script` only invokes scripts from a curated directory the user explicitly populates.
  - Device registration uses a one-time pairing code; long-lived token bound to the device's machine identity.
- **Offline**: read-only graceful degradation on the phone (cached last-seen state); compose disabled when offline. Device agent retries outbound connection with backoff; queued commands time out after 60 s if device is unreachable.
- **Accessibility**: dynamic type, VoiceOver labels on action buttons.
- **i18n / l10n**: English only in v1.

## Out of scope (v1)

- File attachments, image rendering, voice notes.
- Offline composition / send queue.
- Android.
- Multi-user / org features.
- Microsoft Store / App Store submission.
- Arbitrary remote shell / unrestricted RCE.
