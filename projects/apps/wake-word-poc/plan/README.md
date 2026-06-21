# Build plan — Wake-word detection POC

The plan answers **what to do next and in what order**, not what to build.
For "what to build", see `../spec/`.

## Current status

POC built. The Android app ([DDancingDeath/wake-word-poc-app](https://github.com/DDancingDeath/wake-word-poc-app)) implements the full response loop (M1 + M2): counter, timestamp, vibrate, toast, 3 s indicator, TTS `Hey Hitesh`, and the 5 s cooldown, behind an engine-agnostic `WakeWordDetector`. Shipped detectors are Manual (default) and SpeechRecognizer (free, real); Porcupine remains the production engine to wire (M3).

## Roadmap

- **M0 — Spike**: integrate the chosen wake-word engine; fire a detection callback on the keyword and log it. This proves detection works at all before polishing UI or TTS.
- **M1 — Walking skeleton**: on detection, increment the counter, save the timestamp, vibrate, show toast text `Wake word detected!`, and show the on-screen `✓ Wake word detected` indicator for 3 seconds.
- **M2 — MVP**: add Android `TextToSpeech` speaking `Hey Hitesh` with `TextToSpeech.QUEUE_FLUSH`, English (India) plus device-default fallback, and the 5 s cooldown. The full Expected Flow works end-to-end.
- **M3 — Beyond MVP**: custom `Hey Laddu` keyword; multiple keywords plus personalized responses (`Hey Aadhat` → `Ready`, `Hey Jeepee` → `Yes Hitesh?`); optional always-on foreground service plus persisted counter.

## Backlog (unordered)

- Persist counter / timestamp across restarts.
- Add status-bar notification for the foreground service if always-on background listening is chosen.
- Battery tuning for always-on listening.
- Accessibility polish on the visual indicator.
- Pick min / target Android SDK and a physical test device.

## Known issues / debt

- SpeechRecognizer detector is POC-grade — continuous recognition is battery-heavy and is not a true always-on hotword engine; production needs Porcupine. Config-change/rotation resets the in-session counter (acceptable per spec; persistence is an open question).
- Spec wording mismatch: Detection Behavior says toast plus in-app indicator, while Expected Flow says "shows notification". MVP treats these as the same toast + in-app indicator, not a status-bar notification. `TODO(spec)`: confirm whether a persistent Android status-bar notification is also required, especially if the always-on foreground service path is chosen.

## Decision log

Append-only. Each entry: date · decision · rationale · alternatives considered.

- 2026-06-20 · Scope the MVP to a single fixed `Hey Hitesh` response and defer speech-to-text plus personalization · Rationale: verify the wake-word pipeline cheaply end-to-end before building command or billing behavior on top of it · Considered: jumping straight to multi-keyword / personalized responses.
- 2026-06-20 · Leave the wake-word engine undecided, with Porcupine the leading candidate · Rationale: the spec is engine-agnostic after the detection callback, so the choice can be made at build time; Porcupine is already named in the aadhat-management voice-billing spec and supports custom on-device keywords · Considered: committing to Android `SpeechRecognizer`, rejected for now because it is not a true always-on wake-word engine.
- 2026-06-20 · Build the POC with an engine-agnostic `WakeWordDetector`, a Manual (keyless) default detector, and a free, real `SpeechRecognizer` detector; ship Porcupine as a documented stub · Rationale: delivers a fully working, testable response loop today with no paid key or custom keyword model, while keeping the production engine swap-in trivial · Considered: blocking the build on a Porcupine access key + a custom `Hey Laddu.ppn` model (deferred to production).
- 2026-06-21 · Implement background "always-on" listening as a microphone-typed foreground service with an ongoing notification (an Android requirement to hold the mic in the background), running the SpeechRecognizer detector · Rationale: detection continues with the app closed, which the foreground-only design could not do · Note: SpeechRecognizer in the background is battery-heavy and can be OS-throttled — Porcupine remains the production engine for reliable low-power always-on. This resolves the "always-on foreground service vs foreground-only" open question.
- 2026-06-21 · Use Picovoice Porcupine (on-device hotword, free tier) as the engine for reliable always-on, with SpeechRecognizer kept only as a keyless fallback; the AccessKey is injected via the gitignored local.properties → BuildConfig · Rationale: SpeechRecognizer cannot do reliable, low-power background listening — exactly what "always-on" needs — while Porcupine is purpose-built for it · Considered: SpeechRecognizer-only (rejected: battery + reliability), Vosk (heavier, larger model).
