# Functional spec — Remote App Launcher

This is the **source of truth for what to build**. An agent reading only this
file should be able to produce a working v0.

## Reading order

1. This file (overview, components, APIs, schemas, configs, security).
2. `./contracts.md` — the same API/types pinned in a copy-paste-ready form for
   parallel-agent builds. If this file and `contracts.md` disagree,
   `contracts.md` is authoritative for wire shapes; this file is
   authoritative for behaviour and rationale.

## Overview

Three components:

1. **`pa-phone`** — Expo (React Native + TypeScript) app, runs in **Expo Go** on iPhone.
2. **`pa-backend`** — .NET 10 ASP.NET Core minimal API (single `Program.cs`).
3. **`pa-agent`** — .NET 10 console application, runs on the Windows dev box.

Three endpoints on the backend, one command kind, in-memory storage, shared-secret auth.

## End-to-end flow

```
phone                       backend                          agent
  │                            │                               │
  │── POST /commands ─────────▶│                               │
  │   {deviceId, kind, args}   │  store command (pending)      │
  │◀── 200 {commandId,...} ────│                               │
  │                            │                               │
  │── GET /commands/{id} ─────▶│   (still pending)             │
  │◀── 200 status=pending ─────│                               │
  │                            │                               │
  │                            │◀── GET /commands?deviceId=... │  long-poll
  │                            │── 200 [{commandId,...}] ─────▶│
  │                            │                               │  Process.Start(notepad.exe)
  │                            │                               │
  │                            │◀── POST /commands/{id}/result │
  │                            │     {status:done, result:{...}}│
  │                            │── 204 ─────────────────────▶  │
  │                            │  update command (done)        │
  │── GET /commands/{id} ─────▶│                               │
  │◀── 200 status=done ────────│                               │
  │   show "✅ Launched..."    │                               │
```

Phone poll cadence: every 500 ms after submit, for up to 30 s.
Agent long-poll cadence: backend holds the request open up to 30 s waiting for a new command.

## Auth

Every request to the backend MUST carry the header:

```
X-Personal-Agent-Key: <32-byte hex string>
```

Backend rejects with `401 Unauthorized` if missing or mismatched.

The same secret is configured in all three places via environment variables:

- Backend: `PA_SECRET`
- Agent: `PA_SECRET`
- Phone: baked into the Expo Go bundle via `app.config.ts` reading `process.env.EXPO_PUBLIC_PA_SECRET` (must be prefixed `EXPO_PUBLIC_` for client-side access). Acceptable for v0; explicitly insecure (anyone with the bundle has the secret).

Generate once:

```powershell
[byte[]]$b = New-Object byte[] 32; [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); ($b | ForEach-Object { $_.ToString("x2") }) -join ''
```

Store in `.env` files (gitignored) for the three components.

## Data model

```csharp
public record Command(
    string CommandId,        // ULID, e.g. "01HV1A...":  monotonic-by-time
    string DeviceId,         // "my-dev-box" (hardcoded in v0)
    string Kind,             // "launch-app" (only value in v0)
    JsonElement Args,        // { "appName": "notepad" }
    string Status,           // "pending" | "running" | "done" | "failed"
    JsonElement? Result,     // null until done/failed; then { pid, message } or { message }
    DateTimeOffset CreatedAt,
    DateTimeOffset? CompletedAt
);
```

In-memory storage: `ConcurrentDictionary<string, Command>` keyed by `CommandId`.
Plus a per-device `Channel<Command>` (System.Threading.Channels) so the long-poll endpoint can `await` new commands instead of busy-spinning.

## API

All endpoints accept and return `application/json` unless noted. All require the `X-Personal-Agent-Key` header.

### `POST /commands` — phone submits a command

Request body:

```json
{
  "deviceId": "my-dev-box",
  "kind": "launch-app",
  "args": { "appName": "notepad" }
}
```

Response `200 OK`:

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

Validation:
- `deviceId` non-empty.
- `kind` must equal `"launch-app"` in v0 (others return `400 Bad Request`).
- `args.appName` non-empty.

### `GET /commands/{commandId}` — phone polls for status

Response `200 OK` with the full `Command` object. `404 Not Found` if unknown id.

### `GET /commands?deviceId={id}&since={commandId?}` — agent long-polls for work

- Returns immediately if there are pending commands for `deviceId` with `commandId > since` (`since` may be omitted on first call).
- Otherwise holds the request open up to **30 seconds** waiting for a new command. Returns an empty array on timeout — agent re-polls.
- `since` is the last command id the agent has *already received* (not necessarily completed). The agent keeps it in memory; on agent restart it starts from `null` and may re-receive in-flight commands — the agent must dedup by `commandId` and not relaunch apps it has already launched in this process lifetime.

Response `200 OK`:

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

`watermark` is the highest `commandId` in the returned array, or the input `since` if empty. Agent uses it as the next `since`.

### `POST /commands/{commandId}/result` — agent reports completion

Request body:

```json
{
  "status": "done",
  "result": {
    "pid": 12345,
    "message": "Launched notepad (PID 12345)"
  }
}
```

Or on failure:

```json
{
  "status": "failed",
  "result": {
    "message": "Unknown app: spotify. Known apps: notepad, calc, code, onenote, edge"
  }
}
```

Response `204 No Content`. `404 Not Found` if unknown id. Backend transitions the command to the reported status, sets `completedAt`, persists in the in-memory dictionary.

## Device-agent config

File: `apps.json` next to `pa-agent.exe`. Loaded at startup. Hot-reload deferred to v1.

Schema:

```json
{
  "apps": [
    { "name": "notepad",  "executable": "notepad.exe" },
    { "name": "calc",     "executable": "calc.exe" },
    { "name": "code",     "executable": "C:\\Users\\hik\\AppData\\Local\\Programs\\Microsoft VS Code\\Code.exe" },
    { "name": "onenote",  "executable": "onenote.exe" },
    { "name": "edge",     "executable": "msedge.exe" }
  ]
}
```

Resolution is case-insensitive match on `name`. Executable can be a bare name (PATH lookup) or a full path.

## Device-agent CLI

```
pa-agent.exe \
    --device-id my-dev-box \
    --backend https://pa-xyz.devtunnels.ms \
    --apps-config .\apps.json
```

`PA_SECRET` from env var (not CLI flag — keeps it out of process listings).

Behaviour:
- On startup: load `apps.json`, validate every `executable` (warn on missing, but continue).
- Loop: long-poll `GET /commands?deviceId=...&since=...`.
- On a `launch-app` command: look up app, `Process.Start(executable)` (no shell, no args in v0), capture `Process.Id`, POST result.
- On any other `kind`: POST `failed` with `"v0 only supports launch-app"`.
- On unknown app: POST `failed` with the known-apps list.
- On any `Process.Start` exception: POST `failed` with the exception message.
- On any HTTP exception against the backend: log + sleep 5 s + retry.

## Backend CLI

```
pa-backend.exe \
    --urls http://localhost:5099
```

`PA_SECRET` from env var. Dev tunnel started separately:

```powershell
devtunnel host -p 5099 -a
```

(URL persists for the tunnel's lifetime; tear down with `devtunnel delete`.)

## Phone app

One screen. Layout (Tamagui or plain RN — *suggested*):

```
┌──────────────────────────────┐
│  Remote App Launcher         │
│                              │
│  Device: my-dev-box          │
│                              │
│  App to launch               │
│  ┌────────────────────────┐  │
│  │ notepad                │  │
│  └────────────────────────┘  │
│                              │
│  [        Launch        ]    │
│                              │
│  ──────────────────────────  │
│                              │
│  Last result:                │
│  ✅ Launched notepad         │
│     (PID 12345)              │
│     at 14:32:01              │
└──────────────────────────────┘
```

Config via `EXPO_PUBLIC_PA_BACKEND_URL` and `EXPO_PUBLIC_PA_SECRET` env vars (both baked into the Expo Go bundle).

Behaviour on **Launch** tap:
1. `setSending(true); setLastResult("Sending…")`.
2. `POST /commands` with `{deviceId:"my-dev-box", kind:"launch-app", args:{appName}}`.
3. Receive `commandId`.
4. Loop `i=0..60`: `await sleep(500); GET /commands/{commandId}`. Break when `status !== "pending"`.
5. Set `lastResult` to a formatted line (✅ or ❌ + result.message + local timestamp).
6. `setSending(false)`.

Disable the **Launch** button while `sending`. Trim whitespace from `appName`; reject empty.

## Non-functional requirements

- **Latency**: phone tap → app visible on dev box < 5 s p50 (local wifi); < 8 s p95 (cellular).
- **LoC budget**: ≤ 1000 total across the three components.
- **Build effort**: ≤ 12 h focused weekend.
- **Reliability**: agent and backend can each crash-restart without manual recovery. Commands in-flight at the moment of a backend crash are lost (acceptable).
- **Security**: shared secret in every request. Explicitly documented as insecure beyond a personal-network demo. Backend MUST reject without the header.
- **No logging of secrets**: never log the `X-Personal-Agent-Key` value (in any component).

## Out of scope (everything else)

Every capability listed in [cross-device-personal-agent's `spec/README.md`](../../cross-device-personal-agent/spec/README.md) other than the bare `launch-app` round-trip.
