# Personal Agent v0 — Launch-App Spike

> Weekend spike to prove the wire of the [cross-device personal agent](../cross-device-personal-agent) works end-to-end: type `notepad` on the phone, notepad opens on a named Windows dev box. One command kind (`launch-app`), one device, one app allow-list config file. Shared-secret auth, in-memory storage, HTTP long-poll, Expo Go. ~500 LoC across phone + cloud backend + device agent. If it lives, graduates into Phase 1 of [cross-device-personal-agent](../cross-device-personal-agent).

- Live code repo: not yet — to be created at `github.com/DDancingDeath/personal-agent-v0` when build starts
- Status: **idea — fully designed, ready to build** (see `plan/README.md` for the task-level checklist)
- Lineage: this is the v0 spike of [cross-device-personal-agent](../cross-device-personal-agent). If v0 lives, it folds back as the foundation of that project's Phase 1.

---

## The idea

I have a much larger personal-agent design captured in [cross-device-personal-agent](../cross-device-personal-agent) — bidirectional commands and notifications across all my dev machines, eventual NL parsing, multi-agent workflows. That's *months* of work and a lot of design decisions still to validate.

Before sinking that time in, I want to prove the **simplest possible** end-to-end loop works: phone → cloud → device-agent → "an app opened on my dev box". Nothing else. No Entra. No persistent storage. No notifications back from agents. No NL. No multi-device routing. No threads, no chat UI, no action buttons. Just one screen on the phone with one text box and one button.

**The demo:** open the app on my phone, see *"Device: my-dev-box. App: [    ] [Launch]"*. Type `notepad`, tap **Launch**. Within ~3 seconds, notepad opens on the dev box and the phone shows *"✅ Launched notepad (PID 12345)"*. Type `calc`, tap Launch — calculator opens. Type `spotify` — phone shows *"❌ Unknown app: spotify. Known apps: notepad, calc, code, onenote, edge."*

If that works reliably from cellular (not just on my home wifi) for two weeks, it's the foundation for the real thing. If it doesn't, it's two days lost — not two months.

**Anti-goals for v0** — anything beyond `launch-app`; multi-device routing; auth beyond a single shared secret; persistent storage; APNs / push of any kind; free-text chat / threads; AI / NL parsing; action buttons; multi-agent workflows; offline support; production iOS distribution (Expo Go only); App Store / TestFlight; SDL posture; macOS / Linux / Android.

---

## How it works (3 components, 3 endpoints, 1 command kind)

```
┌────────────────┐                ┌────────────────────┐                ┌──────────────────────┐
│  iOS phone     │                │  pa-backend        │                │  pa-agent            │
│  (Expo Go)     │                │  (.NET 9 minimal   │                │  (.NET 9 console     │
│                │ ── POST /cmds ─▶│   API on tunnel)   │                │   on dev box)        │
│  "App: [____]" │ ◀ GET /cmds/id │   in-memory store  │ ◀── long-poll ─│   apps.json          │
│  [Launch]      │                │   shared-secret    │ ── command ───▶│   Process.Start()    │
│                │                │   auth in header   │ ◀── result ────│                      │
└────────────────┘                └────────────────────┘                └──────────────────────┘
        │                                                                          │
        │                    ─── tunnel (VS dev tunnels) ───                       │
        └──────────────────────────────────────────────────────────────────────────┘
```

1. **`pa-phone`** (React Native + Expo, runs in Expo Go on iPhone) — one screen. Hardcoded `deviceId = "my-dev-box"`, free-text `appName`, **Launch** button. On tap: POST to `/commands`, then poll `GET /commands/{id}` every 500 ms until status leaves `pending`. Show the result.
2. **`pa-backend`** (.NET 9 ASP.NET Core minimal API) — three endpoints, in-memory `Dictionary<string, Command>`, single shared-secret auth middleware. Exposed to the internet via VS dev tunnels.
3. **`pa-agent`** (.NET 9 console app on the Windows dev box) — runs as a console process. Long-polls `GET /commands?deviceId=my-dev-box&since=…` (30 s cycle). When it gets a `launch-app` command, looks up `appName` in `apps.json`, runs `Process.Start(exe)`, POSTs the result to `/commands/{id}/result`.

That's the whole system. ~150 LoC of backend, ~150 LoC of agent, ~150 LoC of phone, ~50 LoC of shared DTOs and config.

---

## What it does today (and what's next)

Status: **design complete, code not started.** Every API endpoint, every JSON shape, every config file, every command-line flag, every build task is specified in `spec/` and `plan/`.

Headline capabilities (the entire v0 surface):

- Phone: pick one (hardcoded) device, type an app name, tap Launch, see result within seconds.
- Backend: accept commands, store in memory, hand them out to the device agent, store results, expose status by id.
- Device agent: poll for commands, launch one of the apps in its `apps.json`, report PID + message back.

Out of scope today (everything else): notifications upward, persistent storage, multiple devices, multiple command kinds beyond `launch-app`, auth beyond a shared secret, App Store / TestFlight, native iOS modules, Android, NL, threads, chat, AI, workflows.

---

## Tech stack (concrete, no decisions left to make)

- **Phone**: React Native + Expo SDK (TypeScript). Runs in **Expo Go** during v0 (no native modules required → no EAS Build, no TestFlight). One screen, no navigation, plain `fetch()` calls.
- **Cloud backend**: .NET 9 ASP.NET Core minimal API, single `Program.cs` file. In-memory `Dictionary<string, Command>` keyed by command id. Single auth middleware that checks `X-Personal-Agent-Key` against an env-var-supplied secret.
- **Device agent**: .NET 9 console application, single `Program.cs`. Loads `apps.json` at startup, long-polls the backend in a `while(true)`, runs `Process.Start(exe)` on each command, POSTs result.
- **Auth**: single 32-byte random shared secret. Same value on phone (`.env` baked into Expo Go) + backend (env var) + device agent (env var or CLI flag). **Explicitly insecure beyond a personal-network demo**; v1 replaces with Entra ID.
- **Hosting**: backend runs on the dev box; exposed via **Visual Studio dev tunnels** for reachability from cellular. No cloud account needed for v0.
- **Storage**: in-memory. Commands lost on backend restart. Acceptable because v0 commands are ephemeral by definition (user is watching for the result).
- **Wire format**: JSON only. No protobuf, no MsgPack.
- **Transport**: HTTP long-poll on the agent side; short-poll (500 ms) on the phone side. No WebSocket / SignalR in v0.

The full schemas for all 3 endpoints + the `Command` data shape + the `apps.json` config shape are in `spec/README.md`.

---

## Reading order for an agent

1. `idea.md` — vision, success criteria, anti-goals, open questions.
2. `spec/README.md` — every API endpoint, every JSON shape, every config file, every CLI flag. **Source of truth for what to build.**
3. `plan/README.md` — task-level breakdown (M0 → M4), tools, acceptance criteria, decision log.
4. `prompts/build-from-spec.md` — paste to a coding agent to bootstrap the three repos.

## Layout

```
personal-agent-v0/
├── README.md         ← this doc
├── idea.md           ← vision + constraints
├── spec/             ← functional spec (APIs, schemas, config)
├── plan/             ← task list, tools, acceptance, decisions
├── prompts/          ← ready-to-paste agent prompt
└── assets/           ← (empty for now)
```

## Recent changes

- _2026-06-07_ · initial scaffold + full v0 design captured
