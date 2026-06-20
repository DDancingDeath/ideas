# Build prompt — Wake-word detection POC

Paste this prompt to a coding agent (Copilot CLI, Cursor, Claude Code, etc.)
to generate the application from this spec.

---

You are building **Wake-word detection POC**: an **Android (Kotlin)** app that proves an always-listening → wake-word detected → fixed local response → resume listening loop.

Everything you need is in this folder, but the application must be generated in a **separate directory or repo** such as `wake-word-poc-app/`. Never create application code inside this docs/specs repository. The generated repo's `README.md` must link back to this spec folder.

**Context loading order:**

1. Read `../idea.md` end-to-end. Internalize the user, constraints, non-goals, and success criteria.
2. Read `../spec/README.md` end-to-end. This is the full functional spec and the source of truth for what to build.
3. Skim `../plan/` for roadmap, decisions, and known issues — do NOT reintroduce them.
4. Look at `../assets/` for mocks if any exist. If a mock contradicts the text spec, prefer the mock and flag the contradiction in your output.

**Output:**

- Generate the Android app in a **new directory** (`wake-word-poc-app/`, `../../../wake-word-poc-app/`, or a separate repo). Do not modify any files in this docs repo.
- Produce a clean, runnable scaffold:
  - Repo init with `.gitignore`, `README.md` linking back to this spec folder.
  - Build/run commands documented.
  - At least one happy-path test or instrumentation strategy for the detection callback / cooldown logic.
- Use Android native + Kotlin unless the user explicitly overrides.
- Stop and ask if any spec point is ambiguous. Do not invent behavior.

**Hard requirements from the spec — implement exactly:**

- Request and use `RECORD_AUDIO` and `VIBRATE` permissions.
- When the wake word is detected:
  1. Increment the detection counter.
  2. Save the detection timestamp.
  3. Vibrate briefly.
  4. Display toast text:

     ```text
     Wake word detected!
     ```

  5. Show this on-screen indicator for 3 seconds:

     ```text
     ✓ Wake word detected
     ```

  6. Use Android `TextToSpeech` to speak:

     ```text
     Hey Hitesh
     ```

- Use Android's built-in `TextToSpeech` API.
- Speak with:

  ```kotlin
  TextToSpeech.QUEUE_FLUSH
  ```

- Use locale English (India), with fallback to the device default language.
- After a successful detection, enforce a 5 s cooldown: keep listening, but ignore detections during cooldown and do not trigger TTS or UI actions.
- Keep runtime fully on-device and offline.

**Wake-word engine decision:**

The wake-word engine is an open decision in the spec (`TODO(spec)`). Do **not** silently pick or bake in one.

- First confirm the choice with the user.
- If no engine is confirmed, do **not** implement a real engine. Instead, define a small engine-agnostic detection interface (e.g. a `WakeWordDetector` that emits a detection callback) and wire it to a **deterministic fake / test trigger** (a debug button or test hook) so the full response routine and 5 s cooldown can be built and tested now. Keep the real engine behind that interface for when the decision is made.
- Named candidates for later: Picovoice Porcupine (leading — on-device, supports a custom `Hey Laddu` keyword model), Vosk, a TensorFlow Lite keyword model, or Android `SpeechRecognizer` (note: `SpeechRecognizer` is not a true always-on wake-word engine).

**Quality bar:**

- Code compiles / runs on first try.
- README has install + run in ≤3 commands and links back to this spec folder.
- The detection callback path is testable without speaking into a microphone.
- Cooldown behavior is covered by a deterministic test or clearly documented manual verification.
- No secrets, API keys, analytics, cloud calls, or paid-service assumptions.
- No TODOs in committed code unless they map directly to `TODO(spec)` open questions and are also documented in the generated README.

**Out of scope (don't do unless asked):**

- Speech-to-text / transcription.
- Command or intent understanding.
- Cloud services, accounts, analytics, backend storage, or network recognition.
- Multiple keywords / personalized responses for the MVP.
- iOS.
- Hosting setup.
- CI/CD pipelines.
- Production secrets.
