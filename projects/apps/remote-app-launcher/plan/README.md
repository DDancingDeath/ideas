# Build plan — Remote App Launcher

The plan answers **what to do next and in what order**. For "what to build",
see `../spec/`. For "how to coordinate multiple agents", see
`./orchestration.md`. For "what each worker agent is told", see
`../prompts/track-*.md`.

## Current status

**Idea — design complete, code not started.** The spec is final and the
contract is frozen in `../spec/contracts.md`. Ready for a parallel-agent
build.

LoC budget: ≤ 1000 total across the three components. Build effort budget:
≤ 12 h of focused work.

## Build modes

The three components only meet through the API contract, which means the
build can collapse from five sequential milestones into **one setup → three
parallel tracks → one integration → one finalization**.

| Mode | Who runs it | Wall-clock | Trade-off |
| --- | --- | --- | --- |
| **Parallel (recommended)** | 1 orchestrator + 3 worker agents | ~7 h | Needs an orchestrator-capable model; produces cleaner per-component PRs. |
| **Sequential (fallback)** | 1 agent end-to-end | ~10 h | Simpler dispatch; same total work; serial wall-clock. Prompt: `../prompts/build-from-spec.md`. |

The rest of this document describes the parallel build. The sequential
fallback follows the same M0/M-integration/M-final bookends, just with M1+M2+M3
done back-to-back by one agent instead of in parallel.

## Tools / prerequisites

- Windows 11 dev box.
- iPhone with [Expo Go](https://apps.apple.com/app/expo-go/id982107779) installed.
- .NET 10 SDK ([download](https://dotnet.microsoft.com/download)) — target framework `net10.0`. (Plan originally said .NET 9; the Cloud-PC dev box has only .NET 10 SDK installed. If you install .NET 9 SDK side-by-side, either TFM works — the code is identical.)
- Node 20+ and `npm`.
- `expo` and `eas` CLIs (`npm install -g expo eas-cli` — `eas` not strictly needed for v0).
- VS dev tunnels CLI (`winget install Microsoft.devtunnel`).
- Git, VS Code.
- An iCloud-signed Apple ID on the phone (just for Expo Go install — no Apple Developer Program seat needed).

**Dev box environment note** — if your dev box is a Windows 365 Cloud PC (host
name starts with `CPC-`), it sits on a private Azure subnet and a phone on
your home WiFi **cannot reach** its LAN IP. In that case, the phone must hit
the backend via a public VS dev tunnel **from M-integration onward** (not
deferred to M-final). M0 step below installs the tunnel CLI for this reason.

Generate the shared secret once:

```powershell
$secret = [byte[]]::new(32); [System.Security.Cryptography.RandomNumberGenerator]::Fill($secret); $hex = -join ($secret | ForEach-Object { $_.ToString("x2") }); $hex | Set-Clipboard
```

Paste into:
- `pa-backend/.env`: `PA_SECRET=...`
- `pa-agent/.env`: `PA_SECRET=...`
- `pa-phone/.env`: `EXPO_PUBLIC_PA_SECRET=...` and `EXPO_PUBLIC_PA_BACKEND_URL=...`

## Roadmap

```
                       ┌────────────────────────────┐
                       │  M0 — Pre-flight (~1 h)    │
                       │  orchestrator, sequential  │
                       └────────────┬───────────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              ▼                     ▼                     ▼
    ┌──────────────────┐ ┌──────────────────┐  ┌──────────────────┐
    │  Track B         │ │  Track A         │  │  Track P         │
    │  Backend (~2 h)  │ │  Agent (~2 h)    │  │  Phone (~3 h)    │
    │  worker #1       │ │  worker #2       │  │  worker #3       │
    └─────────┬────────┘ └────────┬─────────┘  └────────┬─────────┘
              │                   │                     │
              └─────────────────┬─┴─────────────────────┘
                                ▼
                       ┌────────────────────────────┐
                       │  M-integration (~1 h)      │
                       │  orchestrator, sequential  │
                       └────────────┬───────────────┘
                                    ▼
                       ┌────────────────────────────┐
                       │  M-final (~2 h)            │
                       │  tunnel, cellular, demo    │
                       │  orchestrator, sequential  │
                       └────────────────────────────┘
```

Wall-clock target: **~7 h** (1 + max(2, 2, 3) + 1 + 2).
Total compute: **~9 h** across all agents — same as the sequential build.

### M0 — Pre-flight (~1 h, orchestrator)

The orchestrator (human or a meta-agent) sets up everything the three
parallel tracks need. Nobody else touches the meta-repo during this phase.

- [ ] Create GitHub repo `DDancingDeath/remote-app-launcher` (private) with
      three top-level folders: `pa-phone/`, `pa-backend/`, `pa-agent/`.
- [ ] Add a root `README.md` that links back to this idea folder, names the
      three tracks, and points at `docs/contracts.md` as the source of truth
      for the contract.
- [ ] Add root `.gitignore` covering: `.env`, `bin/`, `obj/`, `node_modules/`,
      `.expo/`, `*.user`.
- [ ] Copy `../spec/contracts.md` into the build repo at `docs/contracts.md`
      and mark it READ-ONLY for worker agents in the root README.
- [ ] Generate the shared secret (snippet above). Write `pa-backend/.env`,
      `pa-agent/.env`, `pa-phone/.env`.
- [ ] Install the VS dev tunnels CLI if not present
      (`winget install Microsoft.devtunnel`) and run `devtunnel user login`
      once. (The tunnel itself starts in M-integration; this step just makes
      sure the CLI is ready and authenticated.)
- [ ] Create three feature branches off `main`: `track/backend`,
      `track/agent`, `track/phone`. Push all three.
- [ ] Commit + push `main`.

**Done when**: three feature branches exist on the remote, contracts are
pinned in the build repo, the secret is in all three `.env` files, the root
README names the three tracks.

### Parallel phase (run concurrently)

Three workers spawn off M0 and run independently. Each worker:

- Reads only `docs/contracts.md` + its own track prompt.
- Implements its component in its own branch (`pa-<component>/`).
- Verifies acceptance using mocks (does not depend on the other two tracks).
- Opens a PR back to `main` when its local acceptance gate passes.

See `./orchestration.md` for two execution modes (three terminals vs. one
Copilot CLI driving three background subagents) and for the contract-change
protocol.

#### Track B — Backend (~2 h, worker #1)

Branch: `track/backend`. Folder: `pa-backend/` (+ `pa-backend.Tests/`).
Prompt: `../prompts/track-backend.md`.

- [ ] `dotnet new web -n PaBackend` in `pa-backend/`. Add `Cysharp.Ulid`.
- [ ] Implement the four endpoints + auth middleware from `docs/contracts.md`.
- [ ] In-memory `ConcurrentDictionary<string, Command>` + per-device
      `Channel<Command>` for the long-poll.
- [ ] `dotnet test` covers happy path, auth failure, long-poll timeout, and
      kind validation (via `WebApplicationFactory<Program>`).
- [ ] Open PR with `dotnet test` output + a 4-step curl transcript in the
      description.

**Local acceptance**: `dotnet test` green; PR description includes the curl
transcript. No dependency on Track A or Track P.

#### Track A — Device agent (~2 h, worker #2)

Branch: `track/agent`. Folder: `pa-agent/` (+ `pa-agent.Tests/` + `pa-agent.dev-mock/`).
Prompt: `../prompts/track-agent.md`.

- [ ] `dotnet new console -n PaAgent` in `pa-agent/`.
- [ ] CLI parsing: `--device-id`, `--backend`, `--apps-config`. `PA_SECRET` from env.
- [ ] Load and validate `apps.json`.
- [ ] Long-poll loop with `HttpClient` (35 s timeout to allow 30 s long-poll).
      Track `since`. Dedup by `commandId`.
- [ ] Command dispatch: `launch-app` → `Process.Start` → POST result.
      Other kinds / unknown app / process exception → POST `failed`.
      HTTP errors → log + sleep 5 s + retry.
- [ ] `dotnet test` with `HttpMessageHandler` mock covers happy launch,
      unknown app, unknown kind, backend unreachable, dedup.
- [ ] Write a 50-LoC PowerShell `pa-agent.dev-mock/dev-mock.ps1` stub so the
      agent can be eyeballed without the real backend.
- [ ] Open PR with `dotnet test` output + dev-mock run log in the description.

**Local acceptance**: `dotnet test` green; PR description includes the
dev-mock log showing notepad actually opening. No dependency on Track B or
Track P.

#### Track P — Phone (~3 h, worker #3)

Branch: `track/phone`. Folder: `pa-phone/`. Prompt: `../prompts/track-phone.md`.

- [ ] `npx create-expo-app pa-phone --template blank-typescript`.
- [ ] Single-screen UI per `docs/contracts.md`. Plain RN components.
- [ ] Read `EXPO_PUBLIC_PA_BACKEND_URL` and `EXPO_PUBLIC_PA_SECRET` at module load.
- [ ] `api.ts` typed against the `Command` interface from `docs/contracts.md`.
- [ ] Submit-and-poll logic (`POST /commands` → loop 60× × 500 ms `GET /commands/{id}`).
- [ ] `npm test` with `jest.fn()`-mocked `fetch` covers happy `done`,
      validation 400, polling timeout.
- [ ] Optional 30-LoC Node `dev-mock.mjs` stub for interactive eyeballing.
- [ ] Open PR with `npm test` output + Expo Go screenshot in the description.

**Local acceptance**: `npm test` green; PR description includes a screenshot.
No dependency on Track B or Track A.

### M-integration (~1 h, orchestrator)

After all three PRs are open and green, the orchestrator stitches them
together.

- [ ] Review each PR's local acceptance evidence. If any track is red,
      kick it back with a targeted follow-up prompt.
- [ ] Diff `docs/contracts.md` (build repo) against `../spec/contracts.md`
      (ideas repo). If they differ: ideas-repo wins. Update build repo + log
      the drift.
- [ ] Merge in order: `track/backend` → `main`, then `track/agent`, then
      `track/phone`. No conflicts expected (each track owns one folder).
- [ ] Start backend (`dotnet run --project PaBackend`) and agent
      (`dotnet run --project PaAgent -- --device-id my-dev-box --backend http://localhost:5099 --apps-config .\apps.json`)
      on the dev box. Both on `localhost:5099`.
- [ ] Start the public tunnel: `devtunnel host -p 5099 -a`. Note the
      `https://...devtunnels.ms` URL. (On a *physical* dev box on your home
      LAN you can instead set `EXPO_PUBLIC_PA_BACKEND_URL=http://<lan-ip>:5099`
      and defer the tunnel to M-final — but Cloud PCs require the tunnel from
      this step onward.)
- [ ] Update `pa-phone/.env`:
      `EXPO_PUBLIC_PA_BACKEND_URL=https://...devtunnels.ms`. Restart
      `npx expo start --tunnel` and reload Expo Go.
- [ ] Tap **Launch** with `notepad` → confirm notepad opens on dev box →
      confirm ✅ on phone within ~1 s (WiFi) or ~3 s (cellular).
- [ ] If broken: bisect by which boundary fails — `curl` the public tunnel URL,
      then check agent's poll log, then check phone's network tab.

**Done when**: real-network end-to-end works from Expo Go to the dev box
(through the tunnel for Cloud-PC dev boxes; directly on the LAN otherwise).

### M-final — Cellular + polish + demo (~2 h, orchestrator)

By this point the tunnel is already up from M-integration; M-final adds the
cellular smoke test, fills out the app catalog, and starts the soak.

- [ ] Turn off phone WiFi → repeat the launch test over cellular. Measure
      latency (phone tap → notepad visible) by stopwatch. Target: < 8 s p95
      (NFR from `../spec/contracts.md`).
- [ ] Add 3 more apps to `apps.json` (`onenote`, `code` with full path,
      `edge`). Re-run the smoke test for each.
- [ ] Demo three times in a row. Start the two-week soak from here.
- [ ] Commit.

**Done when**: cellular launch works, p50 < 5 s, the demo has been done 3×
without intervention.

## Backlog (unordered, for v0 only)

- [ ] Tiny structured-log helper in each component (timestamp + level +
      message). Useful for the soak.
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
- No structured tracing across the three components. Mitigation: v1 adds an
  OpenTelemetry shim so a single `commandId` is the trace correlation key.

## Acceptance criteria for "v0 is done"

All must hold:

- [ ] M0, all three parallel tracks, M-integration, and M-final complete and committed.
- [ ] Total LoC across all three components ≤ 1000 (count with `cloc` or `tokei`).
- [ ] Launch demo (cellular) succeeds 3× in a row.
- [ ] p50 latency from phone tap to app visible ≤ 5 s.
- [ ] After 14 days of daily use, the soak test shows no manual intervention
      beyond restarting the agent (which can fail for any reason — the test
      is that *I notice and restart it*, not that it's invulnerable).

If all hold → fold v0's code into Phase 1 of [cross-device-personal-agent](../../cross-device-personal-agent).
If any fail → write up the failure in this `plan/README.md`'s Decision log
+ update the parent project's open questions accordingly.

## Decision log

Append-only. Each entry: date · decision · rationale · alternatives considered.

- _2026-06-07_ · Shared-secret auth (single key in env var) instead of Entra ID · Entra is ≥ 4 h of Azure AD app-reg + MSAL on phone + bearer validation on backend for zero v0 value. The secret is one line in three `.env` files. Migrate at v1 once Phase 1 starts · Considered: Entra (planned for v1), no auth (rejected — backend is tunneled to the public internet).
- _2026-06-07_ · In-memory `ConcurrentDictionary` storage; commands lost on backend restart · v0 commands are ephemeral by definition — the user is watching the phone for the result; nobody replays old commands. A SQLite store is ~50 LoC and would inflate scope · Considered: SQLite (planned for v1), file-on-disk JSON snapshot (rejected — same complexity as SQLite without the query primitives).
- _2026-06-07_ · HTTP long-poll on the agent side, HTTP short-poll on the phone side · Both are < 10 LoC of `await httpClient.GetAsync(...)`. A WebSocket / SignalR setup is ~100 LoC of lifecycle management for no measurable v0 latency win (sub-second was never the v0 target) · Considered: SignalR (planned for v1 when notifications-upward arrive and 30 s long-poll cycles become user-visible).
- _2026-06-07_ · Expo Go (not EAS Build → TestFlight) for the phone in v0 · Avoids the whole Apple Developer Program + EAS Build + TestFlight invitation loop. v0 has no native modules (no APNs, no auth SDK). Plain `fetch()` runs fine in Expo Go · Considered: EAS Build + TestFlight (planned for v1, mandatory once APNs is added).
- _2026-06-07_ · VS dev tunnels for backend reachability from cellular · Free, Microsoft-aligned, no signup beyond the existing work account. Stable subdomain. Outbound from the dev box, so no firewall pain · Considered: ngrok (free tier rotates URL, paid tier ~$10/mo), Cloudflare Tunnel (works but extra setup), Azure Container Apps (full deployment — defeats the point of v0).
- _2026-06-07_ · Backend + device agent both in .NET 10 (minimal API + console) · Single language for server-side components means a shared `Command` record (zero serialisation surprises) and one toolchain to install. C# minimal API is the smallest backend that does this · Considered: Node/TS for both (rejected — more package juggling, no win), Python FastAPI (rejected — packaging story on Windows is worse than `dotnet publish`).
- _2026-06-07_ · `launch-app` is the only command kind in v0 · Adding `open-url` / `open-file` / `run-script` / `query-status` are each independently small, but they expand the *spec*-test surface 5× and aren't needed to answer the v0 questions (latency, reliability, friction). All four are in v1's Phase 1 · Considered: ship all 5 (rejected — spec bloat for no v0-question value).
- _2026-06-07_ · Hardcoded single device `"my-dev-box"` · Adding device registration is ~3 h of UI + state. Pointless when I have one device · Considered: registration flow (planned for v1).
- _2026-06-07_ · App allow-list via `apps.json`, edit-and-restart · No UI to manage; user edits a JSON file. Hot-reload deferred · Considered: `POST /apps` admin endpoint (rejected for v0; admin UI deferred to v1).
- _2026-06-07_ · ULIDs for `CommandId` (via `Cysharp.Ulid`) · Sort-by-time is exactly what `since` filtering needs; ULIDs are 26 chars vs UUIDs' 36 and human-skimmable in logs · Considered: GUID (rejected — no time order), incrementing integer (rejected — global mutable counter across restarts is gross).
- _2026-06-07_ · **Build plan is parallel-by-default, single-agent is the fallback** · The three components only meet through the API contract — they have zero shared code. Parallel execution compresses 7 h critical-path into 3 h wall-clock at the cost of one orchestrator + a frozen contract artefact. Compute cost is identical (same LoC). The contract is the lock that makes it safe · Considered: pure sequential (rejected — wastes wall-clock when components are independent), 4 parallel tracks splitting backend into "endpoints" + "auth" (rejected — backend is < 200 LoC, splitting adds coordination overhead with negative ROI).
- _2026-06-07_ · **Contract pinned in `spec/contracts.md` (canon) + `docs/contracts.md` (build-repo copy)** · Workers context-load only the build repo, not the ideas repo. Keeps each prompt small enough to fit in a single context window. Drift detection: orchestrator diff-checks the two contract files before M-integration · Considered: git submodule pointing the build repo at the ideas repo (rejected — submodules are friction for every collaborator), single-source-of-truth in build repo (rejected — ideas repo is the planning canon and must survive the build repo being deleted).
- _2026-06-07_ · **Branch-per-track + PR-back-to-main, with strict folder ownership** · Each track edits exactly one folder, so merges are conflict-free by construction. PRs give the orchestrator one obvious review surface per track (the local-acceptance evidence) · Considered: trunk-based with feature flags (rejected — only 3 tracks; branch overhead is negligible), three separate repos (rejected — re-stitching at integration is more work than merging branches; loses cross-component navigation).
- _2026-06-07_ · **Local-acceptance gates per track use mocks, not cross-track dependencies** · Backend tests with `WebApplicationFactory`, agent tests with `HttpMessageHandler` mock + a dev-mock PowerShell stub for eyeballing, phone tests with `jest.fn()`-mocked `fetch` + an optional Node dev-mock. Means each worker can pass-fail without waiting for the others; the integration test happens once, at M-integration, against the real three · Considered: WireMock-backed shared contract testing (rejected — Pact-style consumer-driven contracts are great when the contract evolves; v0's contract is frozen at M0), test against the real backend (rejected — defeats parallelism).
- _2026-06-07_ · **`net10.0` target framework (was `net9.0` in the original plan)** · The Cloud-PC dev box has only .NET 10 SDK installed (`dotnet --list-sdks` → `10.0.204`). Bumping the TFM is one line per `.csproj` and the runtime/library surface used here (minimal API, `ConcurrentDictionary`, `HttpClient`, `Process.Start`) is unchanged · Considered: installing .NET 9 SDK side-by-side (rejected — adds a setup step with zero v0 benefit), targeting `netstandard2.1` (rejected — minimal API is not available there).
- _2026-06-07_ · **Tunnel from M-integration onward (not deferred to M-final), because dev box is a Cloud PC** · Windows 365 Cloud PCs sit on private Azure subnets; phones on the home WiFi cannot reach the Cloud PC's LAN IP (`10.26.2.89` in this case). The "phone on same WiFi → backend LAN IP" path in the original plan implicitly assumed a physical dev box. Fix is small: install `devtunnel` in M0, start it in M-integration. M-final keeps the cellular soak + polish · Considered: ngrok (rejected — same shape, fewer benefits, free tier rotates URL), Cloudflare Tunnel (rejected — extra signup), VPN-the-phone-into-the-Cloud-PC subnet (rejected — way out of scope for v0).
