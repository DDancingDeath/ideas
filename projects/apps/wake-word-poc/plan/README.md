# Build plan — Wake-word detection POC

The plan answers **what to do next and in what order**, not what to build.
For "what to build", see `../spec/`.

## Current status

Design only. The functional spec is complete for the fixed wake-word response loop — Detection Behavior, Android Text-to-Speech requirements, cooldown, expected flow, non-goals, and open questions are captured. There is no application code yet, and the wake-word engine decision is still pending.

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

- None yet — new project, no code.
- Spec wording mismatch: Detection Behavior says toast plus in-app indicator, while Expected Flow says "shows notification". MVP treats these as the same toast + in-app indicator, not a status-bar notification. `TODO(spec)`: confirm whether a persistent Android status-bar notification is also required, especially if the always-on foreground service path is chosen.

## Decision log

Append-only. Each entry: date · decision · rationale · alternatives considered.

- 2026-06-20 · Scope the MVP to a single fixed `Hey Hitesh` response and defer speech-to-text plus personalization · Rationale: verify the wake-word pipeline cheaply end-to-end before building command or billing behavior on top of it · Considered: jumping straight to multi-keyword / personalized responses.
- 2026-06-20 · Leave the wake-word engine undecided, with Porcupine the leading candidate · Rationale: the spec is engine-agnostic after the detection callback, so the choice can be made at build time; Porcupine is already named in the aadhat-management voice-billing spec and supports custom on-device keywords · Considered: committing to Android `SpeechRecognizer`, rejected for now because it is not a true always-on wake-word engine.
