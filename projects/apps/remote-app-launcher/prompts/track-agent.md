# Build prompt — Track A (Device Agent)

You are **one of three parallel agents** building the Remote App Launcher v0
spike. You own **only** the Windows device agent (`pa-agent/`). Two sibling
agents are simultaneously building `pa-backend/` and `pa-phone/`. You DO NOT
touch their folders. You DO NOT edit `docs/contracts.md` — escalate per the
contract-change protocol if it's wrong.

## Context loading (in order)

1. `README.md` at the build-repo root — architecture, three components, links.
2. `docs/contracts.md` — **the contract you build to.** Pin the agent CLI,
   the `apps.json` schema, the long-poll behaviour, the result POST shapes.
3. (Optional) `..\..\ideas\projects\apps\remote-app-launcher\spec\README.md`
   for the prose version (especially the "Device-agent CLI" and behaviour
   sections).

## Branch

You work on `track/agent`. The orchestrator already created it. Your edits
stay inside `pa-agent/` and `pa-agent.Tests/`. You **MUST NOT** touch anything
outside those two folders.

## What to build

A .NET 9 console application that:

- Parses CLI flags: `--device-id`, `--backend`, `--apps-config`. Reads
  `PA_SECRET` from env var (never CLI — keeps it out of process listings).
- Loads `apps.json` at startup. Validates every `executable` path/PATH lookup,
  warning-and-continuing on misses.
- Long-poll loop against `GET /commands?deviceId=&since=`. Tracks `since`
  in memory. Dedupes by `commandId` via an in-process `HashSet`.
- On `launch-app`: lookup app (case-insensitive `name` match) → `Process.Start`
  (no shell, no args in v0) → capture `Process.Id` → POST result with
  `{status:"done", result:{pid, message}}`.
- On any other `kind`: POST `{status:"failed", result:{message:"v0 only supports launch-app"}}`.
- On unknown app: POST `{status:"failed", result:{message:"Unknown app: <name>. Known apps: ..."}}`.
- On `Process.Start` exception: POST `{status:"failed", result:{message:<exception>}}`.
- On HTTP exception talking to the backend: log, sleep 5 s, retry. Never crash.

## Concrete steps

1. `cd pa-agent && dotnet new console -n PaAgent`.
2. Add NuGets: `System.CommandLine` (CLI parsing) or a 20-LoC manual parser —
   your call.
3. Implement startup: parse CLI, load `apps.json`, validate executables,
   log a 1-line summary.
4. Implement the long-poll loop with `HttpClient` (set `Timeout` to 35 s
   so a 30 s long-poll doesn't trip it).
5. Implement command dispatch (the four cases above).
6. Implement the retry-on-HTTP-error path.
7. `cd .. && dotnet new xunit -n PaAgent.Tests`, reference `PaAgent`.
8. Write the test scenarios from "Local acceptance gate" below.
9. Run `dotnet test` until green.
10. Run the manual scenario against `pa-agent.dev-mock/` (see below) — paste
    log output into the PR.

## Mock backend for local development

The real backend is being built in parallel by Track B. You DO NOT depend
on it. Build a tiny stub in `pa-agent.dev-mock/dev-mock.ps1` (in your
folder, so it ships with your branch):

```powershell
# dev-mock.ps1 — a 50-LoC HttpListener stub for offline agent testing.
# Returns a single hardcoded launch-app command on the first long-poll,
# accepts the result POST, then returns empty on subsequent polls.
# Listens on http://localhost:5099/ ; secret = $env:PA_SECRET.
# Full implementation is your responsibility.
```

Test scenario against the mock:

```powershell
$env:PA_SECRET = "<some hex>"
Start-Process powershell -ArgumentList "-File pa-agent.dev-mock\dev-mock.ps1"
cd pa-agent
dotnet run -- --device-id my-dev-box --backend http://localhost:5099 --apps-config .\apps.json
# Expect: notepad opens on dev box; agent logs a successful result POST; agent then long-polls quietly.
```

## Local acceptance gate (must pass before opening PR)

`dotnet test` MUST be green with these scenarios. Use an `HttpMessageHandler`
mock or `WireMockServer` so tests are deterministic:

1. **Happy `launch-app`**: long-poll returns one notepad command → agent
   `Process.Start(notepad.exe)` → agent POSTs `{status:"done", result:{pid:<int>, message:contains "Launched notepad"}}`. Use a stub `IProcessRunner` so the test doesn't actually open notepad.
2. **Unknown app**: long-poll returns `{appName:"spotify"}` (not in `apps.json`)
   → agent POSTs `{status:"failed", result:{message:contains "Unknown app: spotify"}}`. No process started.
3. **Unknown kind**: long-poll returns `{kind:"open-url"}` → agent POSTs
   `{status:"failed", result:{message:contains "v0 only supports launch-app"}}`.
4. **Backend unreachable**: HttpClient throws → agent logs error, waits, retries
   (verify by inspecting the mock's call count after 6 s).
5. **Dedup**: long-poll returns the same `commandId` twice in two consecutive
   polls → agent calls `Process.Start` exactly once.

Plus the manual `pa-agent.dev-mock` scenario log in the PR description.

## Out of scope for this track

- Anything in `pa-backend/` or `pa-phone/`. The dev-mock is yours; you can't
  use Track B's real backend for your acceptance gate.
- Editing `docs/contracts.md`, root `README.md`, or root `.gitignore`.
- Hot-reload of `apps.json`. (v1.)
- Bash / Linux version. (v1.)
- Killing previously-launched processes, sanity-checking the process is still
  alive after launch. (v1.)
- Multi-device routing — `deviceId` is taken from CLI; if the backend sends
  commands for a different `deviceId` they would never arrive (backend filters).

## Quality bar

- `pa-agent/README.md` documents: how to set `PA_SECRET`, the three CLI flags,
  an example `apps.json`, how to run, how to run tests, how to run against
  the dev-mock.
- Log lines are consistent: `[YYYY-MM-DDTHH:MM:SSZ] LEVEL message`. No
  un-prefixed prints. Never log the secret.
- Exit code 0 on graceful shutdown (Ctrl+C), non-zero on fatal startup error
  (missing `PA_SECRET`, invalid `apps.json`).

## When complete

1. Push `track/agent`.
2. Open PR `track/agent` → `main` titled `Track A: device agent`.
3. Paste the green `dotnet test` output and the dev-mock run log into the
   PR description.
4. Stop. Do not merge. The orchestrator merges during M-integration.

If you hit a contract bug: STOP. Emit a `CONTRACT_CHANGE` note. Do not work
around it.
