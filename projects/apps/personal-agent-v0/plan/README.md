# Build plan — Personal Agent v0

The plan answers **what to do next and in what order**. For "what to build", see `../spec/`.

## Current status

**Idea — design complete, code not started.** Spec is final; no open design decisions remain (only the tunnel-choice and Expo-Go-cellular open questions in `../idea.md`, both with working defaults). Ready for a weekend build.

Target: **≤ 12 h focused weekend time**, **≤ 1000 LoC**.

## Tools / prerequisites

- Windows 11 dev box.
- iPhone with [Expo Go](https://apps.apple.com/app/expo-go/id982107779) installed.
- .NET 9 SDK ([download](https://dotnet.microsoft.com/download)).
- Node 20+ and `npm`.
- `expo` and `eas` CLIs (`npm install -g expo eas-cli` — `eas` not strictly needed for v0 but install it anyway).
- VS dev tunnels CLI (`winget install Microsoft.devtunnel`).
- Git, VS Code (or whatever).
- An iCloud-signed Apple ID on the phone (just for Expo Go install — no Apple Developer Program seat needed).

Generate the shared secret once and store in three `.env` files (gitignored):

```powershell
$secret = [byte[]]::new(32); [System.Security.Cryptography.RandomNumberGenerator]::Fill($secret); $hex = -join ($secret | ForEach-Object { $_.ToString("x2") }); $hex | Set-Clipboard
```

Paste into:
- `pa-backend/.env`: `PA_SECRET=...`
- `pa-agent/.env`: `PA_SECRET=...`  (or pass via env var directly when launching)
- `pa-phone/.env`: `EXPO_PUBLIC_PA_SECRET=...` and `EXPO_PUBLIC_PA_BACKEND_URL=https://...devtunnels.ms`

## Roadmap (sub-milestones within v0)

### M0 — Repos & skeleton (~1 h)

- [ ] Create GitHub repo `DDancingDeath/personal-agent-v0` (private) with three top-level folders: `pa-phone/`, `pa-backend/`, `pa-agent/`. Add a root README that links back to this idea folder.
- [ ] `cd pa-backend && dotnet new web -n PaBackend && cd ..` — verify `dotnet run` starts on `http://localhost:5099`.
- [ ] `cd pa-agent && dotnet new console -n PaAgent && cd ..` — verify `dotnet run` prints `Hello, World!`.
- [ ] `npx create-expo-app pa-phone --template blank-typescript` — verify `npx expo start` shows a QR; scan it; Expo Go opens.
- [ ] Add `.env`, `bin/`, `obj/`, `node_modules/`, `.expo/` to root `.gitignore`.
- [ ] Commit.

**Done when**: all three components build and run their template "hello" state.

### M1 — Backend (~2 h)

- [ ] In `PaBackend/Program.cs`: add the three endpoints from `../spec/README.md` and the auth middleware. In-memory `ConcurrentDictionary<string, Command>` + a `ConcurrentDictionary<string, Channel<Command>>` keyed by `deviceId` for the long-poll.
- [ ] Use `Ulid` ([Cysharp.Ulid NuGet](https://www.nuget.org/packages/Ulid)) for `CommandId` so they sort by time.
- [ ] Smoke-test with curl:
  ```powershell
  $env:PA_SECRET = "<hex>"
  dotnet run --project PaBackend
  # in another shell:
  curl -H "X-Personal-Agent-Key: <hex>" -H "Content-Type: application/json" `
       -d '{"deviceId":"my-dev-box","kind":"launch-app","args":{"appName":"notepad"}}' `
       http://localhost:5099/commands
  ```
- [ ] Confirm long-poll works: kick off `GET /commands?deviceId=my-dev-box` in one window, POST a command in another → first request returns within ~100 ms.
- [ ] Commit.

**Done when**: 3 curl commands prove POST → long-poll-GET → result-POST → status-GET cycle works end-to-end.

### M2 — Device agent (~2 h)

- [ ] In `PaAgent/Program.cs`: parse `--device-id`, `--backend`, `--apps-config` flags ([`System.CommandLine`](https://www.nuget.org/packages/System.CommandLine) or a 10-line manual parser).
- [ ] Load `apps.json`; warn-and-continue on missing executables.
- [ ] Long-poll loop with `HttpClient`. Track `since`. Dedup by `commandId` in a `HashSet`.
- [ ] On `launch-app`: lookup → `Process.Start` → POST result with PID.
- [ ] Error handling: backend unreachable → log + sleep 5 s + retry. Unknown kind / unknown app / `Process.Start` exception → POST `failed`.
- [ ] Test against the M1 backend (still on localhost): start agent → from another shell curl-POST a command → notepad launches → curl-GET shows `done` with PID.
- [ ] Commit.

**Done when**: curl-POST `notepad` → notepad opens on dev box → curl-GET shows `done` + PID. Same for `calc`. `spotify` returns `failed` with the known-apps list.

### M3 — Phone (~3 h)

- [ ] Replace `pa-phone/App.tsx` with the single-screen UI from `../spec/README.md`. Plain RN components (no Tamagui in v0 — keep dependency count low).
- [ ] Read `EXPO_PUBLIC_PA_BACKEND_URL` and `EXPO_PUBLIC_PA_SECRET` from `process.env`.
- [ ] Submit-and-poll logic exactly as specified in `../spec/README.md`.
- [ ] `npx expo start --tunnel` — scan QR with iPhone Expo Go.
- [ ] Test on local wifi: backend still on `localhost`, phone on same wifi → tap **Launch** → notepad opens on dev box → ✅ shown on phone.
- [ ] Commit.

**Done when**: phone (on wifi) → backend (localhost) → agent → notepad opens, result returns to phone within seconds.

### M4 — Tunnel + cellular + polish (~2 h)

- [ ] `devtunnel host -p 5099 -a` → note the public URL.
- [ ] Update `pa-phone/.env`: `EXPO_PUBLIC_PA_BACKEND_URL=https://...devtunnels.ms`. Restart `expo start --tunnel`. Reload Expo Go.
- [ ] Turn off phone wifi → repeat the launch test over cellular. Measure latency (phone tap → notepad visible) by stopwatch.
- [ ] Add 3 more apps to `apps.json` (one that I actually want like `oneNote`, plus `code` and `edge` with full paths).
- [ ] Demo it three times in a row, two-week soak from there.
- [ ] Commit.

**Done when**: cellular launch works, p50 < 5 s, the demo has been done 3× without intervention.

## Backlog (unordered, for v0 only)

- [ ] Tiny structured-log helper in each component (timestamp + level + message). Useful for the soak.
- [ ] `GET /healthz` on the backend (returns 200 + last-command timestamp).
- [ ] `--verbose` flag on the agent that logs every poll.
- [ ] Bash equivalent of the agent for Linux dev boxes (post-v0 if needed).

## Known issues / debt

None yet — no code.

Anticipated debt to carry into v1 (and to **call out in the v0 README**):

- Shared-secret-in-bundle is leakage if the phone is lost. Mitigation: v1 migrates to Entra.
- In-memory store loses commands across backend restarts. Mitigation: v1 adds SQLite.
- Single device hardcoded. Mitigation: v1 adds device registration + picker.
- `launch-app` only — no way to know if the app *actually* opened on screen vs `Process.Start` returned a PID but the process exited immediately. v1 adds a sanity check (process still alive after 500 ms).

## Acceptance criteria for "v0 is done"

All must hold:

- [ ] M0 through M4 complete and committed.
- [ ] Total LoC across all three components ≤ 1000 (count with `cloc` or `tokei`).
- [ ] Launch demo (cellular) succeeds 3× in a row.
- [ ] p50 latency from phone tap to app visible ≤ 5 s.
- [ ] After 14 days of daily use, the soak test shows no manual intervention beyond restarting the agent (which can fail for any reason — the test is that *I notice and restart it*, not that it's invulnerable).

If all hold → fold v0's code into Phase 1 of [cross-device-personal-agent](../cross-device-personal-agent).
If any fail → write up the failure in this `plan/README.md`'s Decision log + update the parent project's open questions accordingly.

## Decision log

Append-only. Each entry: date · decision · rationale · alternatives considered.

- _2026-06-07_ · Shared-secret auth (single key in env var) instead of Entra ID · Entra is ≥ 4 h of Azure AD app-reg + MSAL on phone + bearer validation on backend for zero v0 value. The secret is one line in three `.env` files. Migrate at v1 once Phase 1 starts · Considered: Entra (planned for v1), no auth (rejected — backend is tunneled to the public internet).
- _2026-06-07_ · In-memory `ConcurrentDictionary` storage; commands lost on backend restart · v0 commands are ephemeral by definition — the user is watching the phone for the result; nobody replays old commands. A SQLite store is ~50 LoC and would inflate scope · Considered: SQLite (planned for v1), file-on-disk JSON snapshot (rejected — same complexity as SQLite without the query primitives).
- _2026-06-07_ · HTTP long-poll on the agent side, HTTP short-poll on the phone side · Both are < 10 LoC of `await httpClient.GetAsync(...)`. A WebSocket / SignalR setup is ~100 LoC of lifecycle management for no measurable v0 latency win (sub-second was never the v0 target) · Considered: SignalR (planned for v1 when notifications-upward arrive and 30 s long-poll cycles become user-visible).
- _2026-06-07_ · Expo Go (not EAS Build → TestFlight) for the phone in v0 · Avoids the whole Apple Developer Program + EAS Build + TestFlight invitation loop. v0 has no native modules (no APNs, no auth SDK). Plain `fetch()` runs fine in Expo Go · Considered: EAS Build + TestFlight (planned for v1, mandatory once APNs is added).
- _2026-06-07_ · VS dev tunnels for backend reachability from cellular · Free, Microsoft-aligned, no signup beyond the existing work account. Stable subdomain. Outbound from the dev box, so no firewall pain · Considered: ngrok (free tier rotates URL, paid tier ~$10/mo), Cloudflare Tunnel (works but extra setup), Azure Container Apps (full deployment — defeats the point of v0).
- _2026-06-07_ · Backend + device agent both in .NET 9 (minimal API + console) · Single language for server-side components means a shared `Command` record (zero serialisation surprises) and one toolchain to install. C# minimal API is the smallest backend that does this · Considered: Node/TS for both (rejected — more package juggling, no win), Python FastAPI (rejected — packaging story on Windows is worse than `dotnet publish`).
- _2026-06-07_ · `launch-app` is the only command kind in v0 · Adding `open-url` / `open-file` / `run-script` / `query-status` are each independently small, but they expand the *spec*-test surface 5× and aren't needed to answer the v0 questions (latency, reliability, friction). All four are in v1's Phase 1 · Considered: ship all 5 (rejected — spec bloat for no v0-question value).
- _2026-06-07_ · Hardcoded single device `"my-dev-box"` · Adding device registration is ~3 h of UI + state. Pointless when I have one device · Considered: registration flow (planned for v1).
- _2026-06-07_ · App allow-list via `apps.json`, edit-and-restart · No UI to manage; user edits a JSON file. Hot-reload deferred · Considered: `POST /apps` admin endpoint (rejected for v0; admin UI deferred to v1).
- _2026-06-07_ · ULIDs for `CommandId` (via `Cysharp.Ulid`) · Sort-by-time is exactly what `since` filtering needs; ULIDs are 26 chars vs UUIDs' 36 and human-skimmable in logs · Considered: GUID (rejected — no time order), incrementing integer (rejected — global mutable counter across restarts is gross).
