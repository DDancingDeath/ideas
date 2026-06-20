# Functional spec — Wake-word detection POC

This is the **source of truth for what to build**. An agent reading only this
folder should be able to produce a working application. The POC is small enough
that the whole spec lives in this single file — there is no `page-specs/` yet.

## Reading order

1. This file (the complete functional spec).
2. `../plan/README.md` — milestones, decision log, known issues (order + status,
   not "what to build").

## Overview

- **What it does.** An Android app that continuously listens for a spoken wake
  word (e.g. *"Hey Laddu"*) and, the moment it hears it, runs a fixed local
  response routine — increment a counter, save a timestamp, vibrate, show a
  toast and an on-screen confirmation, then speak a fixed Text-to-Speech reply
  (*"Hey Hitesh"*) — and returns to listening. It deliberately stops at
  wake-word detection: there is **no** speech-to-text and **no** command
  understanding. The point is to prove the *always-listening → detect → respond*
  loop end-to-end, fully on-device.
- **Who it's for.** Me (Hitesh) — a personal engineering spike. It is the
  upstream proof for the in-app wake-word option described in
  [`../../aadhat-management/spec/voice-billing-v2.md`](../../aadhat-management/spec/voice-billing-v2.md)
  (§ "B. In-app wake-word").
- **Primary user journeys.**
  - Cold start → grant microphone permission → the app begins listening.
  - Say *"Hey Laddu"* → device vibrates, a toast and an on-screen
    *"✓ Wake word detected"* appear, and the app speaks *"Hey Hitesh"*.
  - Say it again within 5 s → ignored (cooldown); the app keeps listening.
  - Say it again after the cooldown → it triggers once more; the detection
    counter reflects the running total.

## Tech stack (suggested, not mandatory)

- **Platform:** Android, native. **Language:** Kotlin _(suggested)_.
- **Text-to-Speech:** Android's built-in `android.speech.tts.TextToSpeech`
  — **this is part of the contract**, not negotiable (see below).
- **Wake-word engine:** `TODO(spec)` — **undecided, and the central build
  decision.** Candidates: Picovoice **Porcupine** (custom *"Hey Laddu"* keyword,
  on-device, free personal tier — already named as a candidate in the
  aadhat-management voice-billing spec), **Vosk** (offline), a **TensorFlow Lite**
  custom keyword model, or Android **`SpeechRecognizer`** (not a true always-on
  wake-word — battery and UX caveats). Everything in *Detection Behavior* below
  is engine-agnostic: it specifies what happens **after** the engine's
  detection callback fires.
- **Backend / data:** none. Fully on-device, offline.
- **Auth:** none.
- **Hosting:** none — local APK / sideload.

## Detection Behavior

When the wake word is detected:

1. Increment detection counter.
2. Save detection timestamp.
3. Vibrate device briefly.
4. Display toast:

```text
Wake word detected!
```

5. Show visual indicator on screen:

```text
✓ Wake word detected
```

for 3 seconds.

6. Use Android Text-to-Speech (TTS) to respond:

```text
Hey Hitesh
```

### Text-to-Speech Requirements

* Use Android's built-in TextToSpeech API.
* Initialize TTS when the app starts or when listening begins.
* Speak immediately after wake-word detection.
* Queue mode:

```kotlin
TextToSpeech.QUEUE_FLUSH
```

* Language:

```text
English (India)
```

with fallback to the device default language.

### Cooldown

To prevent repeated triggering:

* After a successful detection, ignore additional detections for 5 seconds.
* During cooldown, continue listening but do not trigger TTS or UI actions.

### Expected Flow

```text
User: "Hey Laddu"

App:
  Vibrates
  Shows notification
  Speaks:
  "Hey Hitesh"

App resumes listening
```

> **Spec note — flagged wording mismatch.** Step 4 specifies a **Toast**
> (*"Wake word detected!"*) plus a 3-second on-screen indicator
> (*"✓ Wake word detected"*); the *Expected Flow* summarises this as *"Shows
> notification"*. For the MVP these are the **same** user-visible confirmation
> (toast + in-app indicator), **not** an Android status-bar Notification.
> `TODO(spec)`: confirm whether a persistent status-bar notification is *also*
> wanted (it likely is, if an always-on foreground listening service is chosen
> — Android requires an ongoing notification for foreground services).

## Future — personalized responses (NOT in the MVP)

Later, the response can vary per wake word, e.g.:

```text
User: "Hey Laddu"
App: "Hey Hitesh"

User: "Hey Aadhat"
App: "Ready"

User: "Hey Jeepee"
App: "Yes Hitesh?"
```

The MVP ships a **single fixed response** (*"Hey Hitesh"*). A fixed reply is
enough to verify the wake-word pipeline end-to-end without adding speech
recognition yet. Multiple keywords and per-keyword replies are a later
milestone — see [`../plan/README.md`](../plan/README.md).

## Data model (high level)

- **DetectionState** (in-app) — `detectionCount: Int` (incremented once per
  *accepted* detection), `lastDetectionAt: Long` (epoch millis),
  `cooldownUntil: Long` (epoch millis; detections before this are ignored).
- Nothing else is modelled, and **nothing leaves the device**.
- `TODO(spec)`: does `detectionCount` / `lastDetectionAt` **persist across app
  restarts** (e.g. `SharedPreferences` / DataStore) or reset each session? The
  MVP may keep them in memory for the session unless persistence is requested.

## Non-functional requirements

- **Performance.** Detection → vibrate/toast/TTS should feel immediate; target
  under ~500 ms from end-of-keyword to vibration, with TTS starting right after.
- **Offline.** 100% offline at runtime — no network calls. Engine model and TTS
  voice run on-device. `TODO(spec)`: the *English (India)* TTS voice may require
  a one-time on-device voice-data download.
- **Always-listening.** The app listens continuously while active. `TODO(spec)`:
  foreground-only (listen while the screen is on the app) **or** a foreground
  service that survives backgrounding? This drives battery cost, the Android
  background-mic policy, and whether an ongoing notification is required.
- **Permissions.** `RECORD_AUDIO` (microphone) and `VIBRATE`. Add
  `FOREGROUND_SERVICE` / `POST_NOTIFICATIONS` only if the always-on service
  option is chosen.
- **Accessibility.** The on-screen *"✓ Wake word detected"* indicator must not be
  the only feedback (vibration + TTS already cover non-visual users); ensure it
  has adequate contrast and is announced to screen readers.
- **i18n / l10n.** Wake word and response are fixed English strings for the MVP;
  TTS locale is *English (India)* with device-default fallback.
- **Security / privacy baseline.** Audio is processed **on-device only**, never
  written to disk and never transmitted. State this prominently in the app — an
  always-listening microphone is sensitive.

## Out of scope

- Speech-to-text / transcription of anything beyond the wake word.
- Any command or intent understanding, or actions beyond the fixed response.
- Cloud services, accounts, analytics.
- Multiple simultaneous wake words and personalized per-keyword responses
  (a future milestone, not the MVP).
- iOS.

## Open questions — `TODO(spec)`

- [ ] Which wake-word engine — Porcupine / Vosk / TFLite / `SpeechRecognizer`?
- [ ] Always-on foreground service vs foreground-only listening?
- [ ] Persist the detection counter / timestamp across restarts?
- [ ] Toast-only, or also a status-bar notification?
- [ ] Custom keyword training for *"Hey Laddu"* (e.g. the Porcupine console) —
      who produces the keyword model file?
- [ ] Minimum / target Android SDK and the physical test device.

