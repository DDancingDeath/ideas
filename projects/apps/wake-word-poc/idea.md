# Wake-word detection POC

> An Android proof-of-concept that validates a wake-word detection pipeline end-to-end before investing in full voice features: say a hot phrase like "Hey Laddu" and the app increments a counter, vibrates, shows a toast and a 3-second on-screen confirmation, and speaks a fixed Text-to-Speech reply ("Hey Hitesh"), with a 5-second cooldown to avoid double-triggering. No cloud and no speech-to-text yet, just a verifiable wake-word to response loop.

## Problem

The aadhat-management voice-billing idea includes an in-app wake-word option, but always-listening wake-word detection on Android is the risky, unproven part. The rest of the billing flow should not depend on guesswork about microphone behavior, latency, battery, or whether a custom phrase like `Hey Laddu` can trigger reliably on-device.

This POC cuts the problem down to one loop: listen continuously, detect the wake word, run a fixed local response, then resume listening. There is no speech-to-text and no command understanding — just enough to prove whether the wake-word pipeline is viable before building product features on top of it.

## Target users

- **Primary**: me — Hitesh. This is a personal engineering spike and upstream proof for the in-app wake-word path in aadhat-management voice billing.
- **Secondary**: none yet.
- **Anti-users**: anyone wanting a full production voice assistant, speech-to-text, command handling, cloud automation, or multi-user voice UX. This is a single-loop spike, not a general assistant.

## What success looks like

- Saying `Hey Laddu` triggers exactly one accepted detection after the engine callback fires.
- The app vibrates, shows toast text `Wake word detected!`, shows `✓ Wake word detected` on screen for 3 seconds, and speaks `Hey Hitesh`.
- Detection → vibration / toast / TTS feels immediate; target is under roughly 500 ms from end-of-keyword to vibration, with TTS starting right after.
- A second utterance within 5 seconds is ignored — the app keeps listening, but does not repeat TTS or UI actions during cooldown.
- A second utterance after cooldown triggers again and increments the running detection counter.
- The loop runs fully on-device and offline; microphone audio never leaves the device.

## Constraints

- Android only for this POC.
- Must run on-device and offline at runtime — no network calls for recognition or response.
- Free / no paid cloud dependency.
- Privacy baseline: microphone audio is processed locally, never transmitted, and never written to disk.
- Use Android `TextToSpeech` for the fixed response; the MVP reply is `Hey Hitesh`.
- The wake-word engine remains `TODO(spec)` until chosen from the named candidates.

## Non-goals

- Speech-to-text or transcription beyond wake-word detection.
- Command or intent understanding.
- Any action beyond the fixed local response.
- Cloud services, accounts, analytics, backend storage, or hosting.
- Multiple wake words or personalized per-keyword responses in the MVP.
- iOS.

## Inspiration / prior art

- **Picovoice Porcupine** — on-device wake-word engine with custom keyword support and a free personal tier; already named as a candidate in the aadhat-management voice-billing spec.
- **OS wake words** like "Hey Google" and "Alexa" — the UX model is familiar: a short phrase wakes a local response loop.
- **aadhat-management `voice-billing-v2.md` §B, in-app wake-word** — this POC is the upstream spike for that option.

## Open questions

- [ ] Which wake-word engine — Porcupine / Vosk / TensorFlow Lite keyword model / Android `SpeechRecognizer`?
- [ ] Always-on foreground service vs foreground-only listening?
- [ ] Persist the detection counter / timestamp across restarts?
- [ ] Custom `Hey Laddu` keyword training — who produces the keyword model file?
- [ ] Minimum / target Android SDK and the physical test device.
