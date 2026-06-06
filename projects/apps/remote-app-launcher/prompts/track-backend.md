# Build prompt — Track B (Backend)

You are **one of three parallel agents** building the Remote App Launcher v0
spike. You own **only** the backend (`pa-backend/`). Two sibling agents are
simultaneously building `pa-agent/` and `pa-phone/`. You DO NOT touch their
folders. You DO NOT edit `docs/contracts.md` — escalate per the contract-change
protocol if it's wrong.

## Context loading (in order)

1. `README.md` at the build-repo root — architecture, three components, links.
2. `docs/contracts.md` — **the contract you build to.** Pin every JSON shape,
   every header, every status code against this. If something is wrong or
   missing, STOP and emit a `CONTRACT_CHANGE` note (see
   `..\..\ideas\projects\apps\remote-app-launcher\plan\orchestration.md`).
3. (Optional) `..\..\ideas\projects\apps\remote-app-launcher\spec\README.md`
   for the prose version of the contract.

## Branch

You work on `track/backend`. The orchestrator already created it. Your edits
stay inside `pa-backend/` and `pa-backend.Tests/`. You **MUST NOT** touch
anything outside those two folders.

## What to build

A .NET 9 ASP.NET Core minimal API (single `Program.cs` plus a couple of
records) implementing the four endpoints in `docs/contracts.md`:

- `POST /commands`
- `GET /commands/{commandId}`
- `GET /commands?deviceId={id}&since={id?}` (30 s long-poll)
- `POST /commands/{commandId}/result`

**Auth**: `X-Personal-Agent-Key` header compared string-equal against
`PA_SECRET` env var. Reject 401 on miss/mismatch on every endpoint.

**Storage**: `ConcurrentDictionary<string, Command>` keyed by `commandId` plus
a `ConcurrentDictionary<string, Channel<Command>>` keyed by `deviceId` for the
long-poll wakeup. No persistence.

**ID gen**: ULIDs via the `Cysharp.Ulid` NuGet package.

**Logging**: log every request as `method path status durationMs commandId?`.
NEVER log the `X-Personal-Agent-Key` value.

## Concrete steps

1. `cd pa-backend && dotnet new web -n PaBackend`.
2. Add `Cysharp.Ulid` NuGet.
3. Implement the four endpoints + auth middleware in `Program.cs`.
4. Read `PA_SECRET` from `Environment.GetEnvironmentVariable`. Fail fast on
   startup if missing.
5. `cd .. && dotnet new xunit -n PaBackend.Tests`, reference `PaBackend`, add
   `Microsoft.AspNetCore.Mvc.Testing` NuGet.
6. Write the test scenarios from "Local acceptance gate" below.
7. Run `dotnet test` until green.
8. Run the manual curl scenario; paste the transcript into the PR.

## Local acceptance gate (must pass before opening PR)

`dotnet test` MUST be green with these four scenarios using
`WebApplicationFactory<Program>`:

1. **Happy path**:
   - POST `/commands` with a `launch-app` command → 200, returns a Command with `status="pending"`.
   - In parallel, GET `/commands?deviceId=my-dev-box` returns the command within 200 ms.
   - POST `/commands/{id}/result` with `{status:"done", result:{pid:1234,message:"..."}}` → 204.
   - GET `/commands/{id}` returns the command with `status="done"`.
2. **Auth failure**: any of the four endpoints without `X-Personal-Agent-Key` → 401.
3. **Long-poll timeout**: GET `/commands?deviceId=my-dev-box` with no pending
   commands returns `{commands:[], watermark:""}` after ~30 s. (Use a short
   timeout override in test config to keep the test under 2 s.)
4. **Validation**: POST `/commands` with `kind:"open-url"` → 400.

Plus the manual curl transcript from the M1 section of `..\..\ideas\projects\apps\remote-app-launcher\plan\README.md`, in your PR description.

## Out of scope for this track

- Anything in `pa-agent/` or `pa-phone/`.
- Editing `docs/contracts.md`, root `README.md`, or root `.gitignore`.
- Adding a database. In-memory only.
- Adding Entra / OAuth / JWT. Shared secret only.
- Adding rate limiting, request validation middleware beyond the four checks
  above, OpenAPI/Swagger. (All v1.)

## Quality bar

- Code compiles + runs on first try.
- `pa-backend/README.md` documents: how to set `PA_SECRET`, how to run, how to
  run tests, the four curl commands.
- No TODOs in committed code. If a contract point is ambiguous, STOP and
  escalate — do not invent behavior.

## When complete

1. Push `track/backend`.
2. Open PR `track/backend` → `main` titled `Track B: backend`.
3. Paste the green `dotnet test` output and the 4-step curl transcript into the
   PR description.
4. Stop. Do not merge. The orchestrator merges during M-integration.

If you hit a contract bug: STOP. Emit a `CONTRACT_CHANGE` note. Do not work
around it.
