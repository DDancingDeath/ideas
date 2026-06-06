# Build prompt — Track P (Phone)

You are **one of three parallel agents** building the Remote App Launcher v0
spike. You own **only** the iPhone app (`pa-phone/`). Two sibling agents are
simultaneously building `pa-backend/` and `pa-agent/`. You DO NOT touch their
folders. You DO NOT edit `docs/contracts.md` — escalate per the contract-change
protocol if it's wrong.

## Context loading (in order)

1. `README.md` at the build-repo root — architecture, three components, links.
2. `docs/contracts.md` — **the contract you build to.** Pin the TypeScript
   types, the request/response shapes for POST `/commands` and GET
   `/commands/{id}`, the env vars, the auth header.
3. (Optional) `..\..\ideas\projects\apps\remote-app-launcher\spec\README.md`
   "Phone app" section for the screen mock and behaviour list.

## Branch

You work on `track/phone`. The orchestrator already created it. Your edits
stay inside `pa-phone/`. You **MUST NOT** touch anything outside that folder.

## What to build

An Expo (React Native + TypeScript) app that runs in Expo Go on iPhone — no
native modules. One screen.

- Reads `EXPO_PUBLIC_PA_BACKEND_URL` and `EXPO_PUBLIC_PA_SECRET` from
  `process.env` at module load (Expo bakes them into the bundle at start).
- UI layout: device label, app-name `TextInput`, `Launch` `Pressable`, divider,
  "Last result" line. Mock in `docs/contracts.md` / the spec.
- On `Launch` tap:
  1. Trim `appName`; reject empty (show `"Enter an app name"`).
  2. Set `sending=true`; set `lastResult="Sending…"`.
  3. `POST /commands` with body `{deviceId:"my-dev-box", kind:"launch-app", args:{appName}}`.
     Auth header.
  4. Capture `commandId`.
  5. Loop `i = 0..60`: `await sleep(500); GET /commands/{commandId}`. Break
     when `status !== "pending"`.
  6. Set `lastResult` to `"✅ <result.message> at <HH:MM:SS>"` (or `"❌ ..."` on
     `failed`, or `"⌛ Timed out after 30s"` on loop exhaustion).
  7. Set `sending=false`.
- Disable `Launch` while `sending`.
- Plain RN components — no Tamagui, no NativeWind, no extra UI libs in v0.

## Concrete steps

1. `npx create-expo-app pa-phone --template blank-typescript`.
2. Replace `App.tsx` with the single-screen UI.
3. Add a tiny `api.ts` exporting `submitCommand(appName)` and
   `pollCommand(commandId)` typed against the interfaces in
   `docs/contracts.md`.
4. Read env vars via `process.env.EXPO_PUBLIC_PA_BACKEND_URL` etc. Fail
   loudly on the screen if either is missing (red banner).
5. Add `jest` (Expo's `jest-expo` preset). Write the tests below.
6. Run `npx expo start --tunnel` and scan with iPhone Expo Go to eyeball
   the layout. Set `EXPO_PUBLIC_PA_BACKEND_URL` to a placeholder
   (`http://localhost:5099`) for screenshot purposes — full integration
   happens at M-integration.

## Mock backend for local development

The real backend is being built in parallel by Track B. You DO NOT depend
on it. Mock `fetch` in your unit tests. For a one-off interactive sanity
check, write a 30-LoC stub in `pa-phone/dev-mock/dev-mock.mjs` (Node):

```js
// dev-mock.mjs — a tiny http server that accepts POST /commands and
// returns a pending Command, then GET /commands/{id} returns "done" after
// the first 2 polls. Listens on http://localhost:5099/. Auth header check.
// Full implementation is your responsibility.
```

Run with `node pa-phone/dev-mock/dev-mock.mjs` while you `npx expo start`.

## Local acceptance gate (must pass before opening PR)

`npm test` MUST be green with three scenarios using `jest.fn()` to mock `fetch`:

1. **Happy path**: tap `Launch` with `appName="notepad"`. After 2 polls the
   mock returns `status:"done"`. Verify `lastResult` displays `"✅ Launched notepad..."` and the button is re-enabled.
2. **Server rejects (400)**: mock returns 400 on POST `/commands`. Verify
   `lastResult` shows `"❌ <error>"` and the button is re-enabled.
3. **Polling timeout**: mock returns `status:"pending"` for all 60 polls.
   Verify `lastResult` shows `"⌛ Timed out after 30s"` and the button is
   re-enabled.

Plus a screenshot of the Expo Go screen (with placeholder backend URL) in
the PR description.

## Out of scope for this track

- Anything in `pa-backend/` or `pa-agent/`. The mock is yours; you can't
  use Track B's real backend for your acceptance gate.
- Editing `docs/contracts.md`, root `README.md`, or root `.gitignore`.
- iOS push notifications (APNs) — that needs EAS Build + TestFlight. v1.
- Device picker — `deviceId` is hardcoded `"my-dev-box"`. v1.
- Login / sign-in flow — shared secret is in env. v1.
- Multiple screens, navigation, persistence of past results.

## Quality bar

- `pa-phone/README.md` documents: how to set both env vars, how to run
  in Expo Go, how to run tests, how to run against `dev-mock.mjs`.
- No ESLint errors with the default `expo` config.
- No `any` types in your `api.ts`. Use the `Command` interface from
  `docs/contracts.md`.

## When complete

1. Push `track/phone`.
2. Open PR `track/phone` → `main` titled `Track P: phone`.
3. Paste the green `npm test` output and an Expo Go screenshot into the
   PR description.
4. Stop. Do not merge. The orchestrator merges during M-integration.

If you hit a contract bug: STOP. Emit a `CONTRACT_CHANGE` note. Do not work
around it.
