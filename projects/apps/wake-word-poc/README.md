# Wake-word detection POC

> An Android proof-of-concept that validates a wake-word detection pipeline end-to-end before investing in full voice features: say a hot phrase like "Hey Laddu" and the app increments a counter, vibrates, shows a toast and a 3-second on-screen confirmation, and speaks a fixed Text-to-Speech reply ("Hey Hitesh"), with a 5-second cooldown to avoid double-triggering. No cloud and no speech-to-text yet, just a verifiable wake-word to response loop.

---

## The idea

I want to build voice features like in-app wake-word billing, but the risky part is not the billing flow — it is whether an Android app can reliably stay in a listen → detect → respond loop without cloud speech recognition. Before investing in full voice UX, this POC proves the smallest useful loop: hear a personal wake word such as `Hey Laddu`, run a fixed local response, and return to listening.

The target user is me — Hitesh. This is a personal engineering spike upstream of the in-app wake-word option in `projects/apps/aadhat-management/spec/voice-billing-v2.md` (§ "B. In-app wake-word"). Success is concrete: saying the wake word triggers vibration plus spoken `Hey Hitesh` within roughly 500 ms of detection; a second utterance within 5 s is ignored; the detection counter reflects the running total; and the whole thing works offline on-device.

Non-goals are deliberately sharp: no speech-to-text, no command or intent understanding, no cloud, no accounts, no analytics, no multiple keywords for the MVP, and no iOS.

---

## How it works

The app listens through the Android microphone and passes audio to a wake-word engine. That engine is still `TODO(spec)` — Porcupine, Vosk, a TensorFlow Lite keyword model, and Android `SpeechRecognizer` are the named candidates. Everything after the engine's detection callback is already specified and engine-agnostic.

```text
microphone — listening continuously (never stops)
   │
   ▼
wake-word engine (TBD)
   │ detection
   ▼
within 5 s cooldown? ──yes──▶ ignore: no counter, no UI, no TTS
   │ no
   ▼
accepted detection:
   ├─ increment detection counter
   ├─ save timestamp
   ├─ vibrate briefly
   ├─ show toast: Wake word detected!
   ├─ show indicator: ✓ Wake word detected (3 s)
   ├─ speak via Android TextToSpeech: Hey Hitesh
   └─ start 5 s cooldown (engine keeps listening)
```

This README stays conceptual. The exact detection behavior, Text-to-Speech contract, cooldown, permissions, and open questions live in `spec/`.

---

## What it does today (and what's next)

Status: **POC implemented.** The Android app lives in its own repo:
[`DDancingDeath/wake-word-poc-app`](https://github.com/DDancingDeath/wake-word-poc-app)
— this repo stays docs-only.

The functional spec is complete for the MVP loop: Detection Behavior, Android Text-to-Speech requirements, 5 s cooldown, expected flow, data model, permissions, offline/privacy baseline, and future per-keyword responses are captured.

**Built:** the full response routine (counter, timestamp, vibrate, toast, 3 s indicator, TTS `Hey Hitesh`) and the 5 s cooldown, behind an engine-agnostic `WakeWordDetector`. Shipped detectors: **Manual** (default, keyless test trigger) and **SpeechRecognizer** (free, real spoken-phrase); **Porcupine** is a documented production stub. The pure-Kotlin core (counter + cooldown state machine, phrase matcher) is unit-tested.

Next: wire Porcupine with a custom `Hey Laddu` keyword for production-grade always-on detection; optional persistence + foreground service (see open questions).

---

## Tech stack

- **Mobile:** Android, native.
- **Language:** Kotlin suggested; not yet a hard spec requirement.
- **Text-to-Speech:** Android `TextToSpeech` is part of the contract; response is `Hey Hitesh` using `TextToSpeech.QUEUE_FLUSH`, locale English (India) with device-default fallback.
- **Wake-word engine:** `TODO(spec)` — candidates are Picovoice Porcupine, Vosk, TensorFlow Lite keyword model, or Android `SpeechRecognizer`.
- **Runtime boundary:** fully on-device and offline.
- **Backend / auth / hosting:** none.

---

## Reading order for an agent

1. `idea.md` — vision only (subset of the section above; deeper detail).
2. `spec/` — source of truth for **what to build**. Start at
   `spec/README.md` (it sets the reading order).
3. `plan/` — status, known issues, next steps. **Do not reintroduce**
   anything listed under known issues.
4. `prompts/build-from-spec.md` — paste this to a coding agent to build /
   rebuild the application.

## Layout

```
<slug>/
├── README.md           ← (this doc) the narrative entry point
├── idea.md             ← vision in detail
├── spec/               ← functional source of truth
├── plan/               ← roadmap + known issues
├── prompts/            ← ready-to-paste agent prompts
└── assets/             ← mockups, screenshots, diagrams
```

## Recent changes

- _2026-06-21_ · **Reliable always-on via Porcupine.** Integrated Picovoice Porcupine (on-device hotword engine) as the always-on engine — auto-selected when a free AccessKey is configured, with the SpeechRecognizer kept as a keyless fallback; hardened `WakeWordService` (partial wake-lock, notification Stop action, FGS-permission guards, main-thread callback). Added a usage guide ([USAGE.md](https://github.com/DDancingDeath/wake-word-poc-app/blob/main/USAGE.md)).
- _2026-06-21_ · **Always-on (background) listening** added via a microphone foreground service (`WakeWordService`) + ongoing notification; the *Simulate wake word* button now triggers directly; added Robolectric + detector tests (24 pass). APK refreshed at the [v1.0.0-poc release](https://github.com/DDancingDeath/wake-word-poc-app/releases/tag/v1.0.0-poc).
- _2026-06-20_ · **Debug APK built & released** — `gradlew :app:assembleDebug` green (AGP 8.7.2 / Android SDK 35 / JDK 17) and all 18 unit tests pass; downloadable APK at the [v1.0.0-poc release](https://github.com/DDancingDeath/wake-word-poc-app/releases/tag/v1.0.0-poc).
- _2026-06-20_ · **Built the POC** — Android (Kotlin) app implementing the full Detection Behavior + 5 s cooldown, with Manual and SpeechRecognizer detectors and a documented Porcupine stub; pure-Kotlin core unit-tested. Code: [DDancingDeath/wake-word-poc-app](https://github.com/DDancingDeath/wake-word-poc-app).
- _2026-06-20_ · Spec authored — Detection Behavior, Text-to-Speech requirements, 5 s cooldown, expected flow; future per-keyword responses noted; wake-word engine left open.
- _2026-06-20_ · initial scaffold
