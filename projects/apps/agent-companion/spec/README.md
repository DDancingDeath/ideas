# Functional spec — Personal Agent Companion

This is the **source of truth for what to build**. An agent reading only this
folder should be able to produce a working application.

## Reading order

1. This file (overview + tech stack + the internal event schema).
2. *(future)* `page-specs/` — per-screen specs in numeric order.
3. *(future)* `adapters-design.md` — adapter contract and per-source notes.

## Overview

**What it does** — A personal iOS app that receives push notifications from a mixed set of AI agent sources (Copilot CLI, GitHub Copilot, custom AI agents, ADO pipelines) and lets the user chat back from the phone, with each agent task represented as one conversation thread. A unified backend normalises events from each source into a single internal schema, dispatches APNs push, and routes replies back to the originating agent.

**Who it's for** — A single user (the author). Microsoft personal work account, sideloaded via TestFlight.

**Primary user journeys**

1. *Agent calls me.* An agent on any source emits an event → backend stores it, decides whether to push → APNs notification arrives on the phone with title, source, and action hints → tap to deep-link into the thread.
2. *I tap a one-shot action.* The thread view shows action buttons (Approve / Deny / Re-run / Cancel) rendered from the event's `actions[]`. Tapping dispatches a reply back through the adapter; thread state updates live over the WebSocket.
3. *I reply in free-text.* Compose box at the bottom of the thread. Text is sent to the backend, which routes it through the adapter to the agent's native input channel.
4. *I scroll history.* Thread list grouped by source, sorted by latest activity, with unread badges. Pull-to-refresh.

## Tech stack

- **Frontend**: React Native + Expo SDK (TypeScript); EAS Build for cloud iOS builds; MSAL React Native for Entra auth; Expo Notifications for APNs; React Query for cache; React Navigation; a minimal UI library (Tamagui or NativeBase — *suggested*).
- **Backend / data**: *(suggested)* .NET 9 ASP.NET Core minimal API + SignalR; Entity Framework Core over SQLite (M1–M2) → Cosmos DB (M3+). Open to Node / TS or Python — the adapter shape and event schema are the real contract.
- **Auth**: Microsoft Entra ID. Phone uses MSAL; backend validates bearer tokens against the same app registration. No long-lived secrets on the phone.
- **Hosting**: dev tunnels for M1–M2; Azure Container Apps from M3 (Bicep / `azd` template under `/infra` once code starts).
- **Mobile build**: EAS Build (cloud); EAS Submit for TestFlight delivery.

Negotiable: every line above except the auth provider (Entra) and the internal event schema below.

## Data model (high level)

- **User** — `id`, `entraOid`, `displayName`, `expoPushTokens[]`, `createdAt`. Single row in v1; modelled as a table so multi-user isn't a future schema migration.
- **Adapter** — `id`, `source` (`copilot-cli` | `gh-copilot` | `ado` | `custom`), `config` (JSON), `enabled` (bool). Configured server-side.
- **Thread** — `id`, `userId`, `adapterId`, `threadKey` (stable correlation id from the adapter), `title`, `source`, `status` (`open` | `archived`), `unreadCount`, `lastActivityAt`.
- **Event** — `id`, `threadId`, `kind` (`status` | `question` | `approval-request` | `error` | `message`), `title`, `body` (markdown), `actions` (JSON array of `{id, label, style}`), `createdAt`, `externalEventId` (for dedup), `authoredBy` (`agent` | `user`).
- **Delivery** — `id`, `eventId`, `expoPushTicketId`, `status` (`pending` | `sent` | `failed`), `attempts`, `lastError`.

## Internal event schema (the contract)

Every adapter normalises inbound events into this shape; replies flow back through the same channel.

Inbound event (agent → phone):

```json
{
  "eventId": "uuid",
  "source": "copilot-cli | gh-copilot | ado | custom",
  "threadKey": "stable-correlation-id-for-this-task",
  "kind": "status | question | approval-request | error | message",
  "title": "short summary suitable for a push notification (<= 80 chars)",
  "body": "longer markdown body",
  "actions": [
    { "id": "approve", "label": "Approve", "style": "primary" },
    { "id": "deny",    "label": "Deny",    "style": "destructive" }
  ],
  "createdAt": "iso-8601"
}
```

Reply envelope (phone → agent):

```json
{
  "replyId": "uuid",
  "threadKey": "same-as-above",
  "kind": "action | message",
  "actionId": "approve",
  "text": "free-text body when kind=message",
  "createdAt": "iso-8601"
}
```

## Non-functional requirements

- **Latency**: agent event → APNs delivery < 5 s p50.
- **Reliability**: backend can crash-restart without losing already-acknowledged events; push retries are idempotent on the phone (dedup by `eventId`).
- **Security**: Entra-protected APIs; backend secrets in Azure Key Vault; no agent secrets stored on device; push payloads carry summaries only.
- **Offline**: read-only graceful degradation (cached last-seen state); compose disabled when offline (no send queue in v1).
- **Accessibility**: dynamic type, VoiceOver labels on action buttons.
- **i18n / l10n**: English only in v1.

## Out of scope (v1)

- File attachments, image rendering, voice notes.
- Offline composition / send queue.
- Android.
- Multi-user / org features.
- Microsoft Store / App Store submission.
