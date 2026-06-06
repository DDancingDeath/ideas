# Contracts — Remote App Launcher

This file is the **frozen wire contract** that pins the three components together.
Every parallel agent (backend, device agent, phone) builds against this.

Drift between this file and the language-level types in any one component is a
**contract bug** — escalate to the orchestrator per `../plan/orchestration.md`. No
agent edits this file unilaterally.

The prose version of the same contract lives in `./README.md`. This file is the
copy-paste-ready, type-level distillation.

## Versioning

- Contract version: **v0.1.0**.
- Any breaking change (renamed field, changed type, changed status code) bumps
  the **minor** version and triggers a re-sync across all three components.
- Any additive non-breaking change (new optional field, new error message)
  bumps the **patch** version; existing components keep working.

## Wire-level summary

| Endpoint | Method | Caller | Headers | Status |
| --- | --- | --- | --- | --- |
| `/commands` | POST | phone | `X-Personal-Agent-Key`, `Content-Type: application/json` | 200 / 400 / 401 |
| `/commands/{id}` | GET | phone | `X-Personal-Agent-Key` | 200 / 401 / 404 |
| `/commands?deviceId=&since=` | GET | agent | `X-Personal-Agent-Key` | 200 / 401 (long-poll up to 30 s) |
| `/commands/{id}/result` | POST | agent | `X-Personal-Agent-Key`, `Content-Type: application/json` | 204 / 401 / 404 |

All bodies are `application/json` and use UTF-8. Timestamps are RFC 3339 in UTC
with a trailing `Z`. Field naming is `camelCase` on the wire.

## Canonical types — C# (backend + device agent)

```csharp
using System.Text.Json;

public record Command(
    string CommandId,                  // ULID, 26 chars, monotonic by time
    string DeviceId,                   // "my-dev-box" in v0
    string Kind,                       // "launch-app" — only value in v0
    JsonElement Args,                  // { "appName": "notepad" }
    string Status,                     // "pending" | "running" | "done" | "failed"
    JsonElement? Result,               // null until terminal; then { pid?, message }
    DateTimeOffset CreatedAt,
    DateTimeOffset? CompletedAt
);

public record CommandSubmitRequest(
    string DeviceId,
    string Kind,
    JsonElement Args
);

public record CommandResultRequest(
    string Status,                     // "done" | "failed"
    JsonElement Result                 // { pid?, message }
);

public record PendingCommandsResponse(
    Command[] Commands,
    string Watermark                   // highest CommandId in Commands; or input `since` if empty
);
```

## Canonical types — TypeScript (phone)

```ts
export type CommandStatus = 'pending' | 'running' | 'done' | 'failed';
export type CommandKind = 'launch-app';

export interface Command {
  commandId: string;            // ULID, 26 chars
  deviceId: string;
  kind: CommandKind;
  args: { appName: string };    // v0: only launch-app args
  status: CommandStatus;
  result: { pid?: number; message: string } | null;
  createdAt: string;            // ISO 8601 UTC
  completedAt: string | null;
}

export interface CommandSubmitRequest {
  deviceId: string;
  kind: CommandKind;
  args: { appName: string };
}
```

## Endpoint contracts (request/response examples)

### POST /commands

Request:

```json
{
  "deviceId": "my-dev-box",
  "kind": "launch-app",
  "args": { "appName": "notepad" }
}
```

Response 200:

```json
{
  "commandId": "01HV1AXKPGQK3W4MN7Z2YJ8T6B",
  "deviceId": "my-dev-box",
  "kind": "launch-app",
  "args": { "appName": "notepad" },
  "status": "pending",
  "result": null,
  "createdAt": "2026-06-07T08:30:00Z",
  "completedAt": null
}
```

Errors:

- 400 if `deviceId` empty, `kind != "launch-app"`, or `args.appName` empty.
- 401 if header missing or mismatched.

### GET /commands/{commandId}

Response 200: full `Command` JSON.
Response 404 if unknown id.
Response 401 if header missing or mismatched.

### GET /commands?deviceId=&since=

- Returns immediately if any commands for `deviceId` exist with `commandId > since`.
- Otherwise blocks up to **30 s** for the next command, then returns empty.
- `since` is optional on first call. Agent must dedup by `commandId` in-process.

Response 200:

```json
{
  "commands": [
    {
      "commandId": "01HV1AXKPGQK3W4MN7Z2YJ8T6B",
      "deviceId": "my-dev-box",
      "kind": "launch-app",
      "args": { "appName": "notepad" },
      "status": "pending",
      "result": null,
      "createdAt": "2026-06-07T08:30:00Z",
      "completedAt": null
    }
  ],
  "watermark": "01HV1AXKPGQK3W4MN7Z2YJ8T6B"
}
```

Empty (long-poll timeout):

```json
{ "commands": [], "watermark": "01HV1AXKPGQK3W4MN7Z2YJ8T6B" }
```

(`watermark` echoes the input `since` if no commands were returned.)

### POST /commands/{commandId}/result

Success:

```json
{
  "status": "done",
  "result": { "pid": 12345, "message": "Launched notepad (PID 12345)" }
}
```

Failure:

```json
{
  "status": "failed",
  "result": { "message": "Unknown app: spotify. Known apps: notepad, calc, code, onenote, edge" }
}
```

Response 204. Response 404 if unknown id.

## Auth header

```
X-Personal-Agent-Key: <64-char lowercase hex string>
```

Sourced from the env var `PA_SECRET` (backend, agent) or `EXPO_PUBLIC_PA_SECRET`
(phone). Backend compares string-equal; mismatch → 401.

## Agent CLI

```
pa-agent.exe \
  --device-id my-dev-box \
  --backend https://pa-xyz.devtunnels.ms \
  --apps-config .\apps.json
```

`PA_SECRET` from env var.

## `apps.json` schema

```json
{
  "apps": [
    { "name": "notepad", "executable": "notepad.exe" },
    { "name": "calc",    "executable": "calc.exe" }
  ]
}
```

`name` is case-insensitive matching. `executable` is either a bare name (PATH
lookup) or an absolute path.

## Phone env vars

- `EXPO_PUBLIC_PA_BACKEND_URL` — full backend URL, e.g. `https://pa-xyz.devtunnels.ms`.
- `EXPO_PUBLIC_PA_SECRET` — same secret as backend/agent. Baked into the Expo
  bundle; explicitly insecure beyond a personal-network demo.

## Latency expectations (for test acceptance)

- POST /commands → response: < 50 ms p50.
- Agent long-poll wakeup from a fresh POST: < 100 ms p50.
- Phone tap → result visible on phone: < 5 s p50 (wifi), < 8 s p95 (cellular).

## What this contract intentionally does NOT define

- Retry, idempotency, replay semantics across backend restarts.
- Multiple devices, device registration, device picker.
- Command kinds other than `launch-app`.
- WebSocket / SignalR push.
- Notifications agent → phone.

All deferred to v1 (Phase 1 of [cross-device-personal-agent](../../cross-device-personal-agent)).
