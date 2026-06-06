# Build prompt — notes-reminders

> ⚠️ **Do not hand to an agent yet.** Resolve platform + embedding model
> + vector-store decisions in [`../README.md`](../README.md) first. See
> the project plan in [`../plan/README.md`](../plan/README.md).

---

You are building **notes-reminders**, an AI-powered voice memory and
knowledge assistant. Read `../README.md` and `../idea.md` for the full
vision. Generate code in a separate directory / repo (not in this
`projects/` folder).

## Walking skeleton (v0)

The first deliverable is a **mobile-first app** that proves the capture
flow is friction-free. No AI yet.

1. Tap-to-record on the home surface.
2. Speech-to-text using the platform-native API (iOS Speech / Android
   SpeechRecognizer) or Whisper on-device — whichever is faster on the
   target device.
3. Save the raw transcript to local SQLite with timestamp.
4. Show all captures as a chronological list.
5. Background upload / retry if the user is offline at capture time.

No topic detection, no embeddings, no routing, no summarisation in v0.

## Quality bar (v0)

- **Capture latency**: tap → recording starts in < 1 s.
- **Transcript appears within 3 s** of speech ending.
- **Offline capture** works; sync resumes when connected.
- **App cold-start** to recording-ready in < 2 s.

## After v0

Only after v0 ships and feels right do these layers go in (one PR per
layer, behind a feature flag):

1. Embedding pipeline (per note, debounced).
2. Topic objects with manual grouping UI.
3. Automatic topic routing (cosine + threshold + LLM boundary confirm).
4. Topic memory (summary + action items, regenerated on update).
5. Natural-language retrieval.
6. Daily digest.
7. Agent mode (draft a response from topic memory).

## Do NOT

- Add wake-word support in v1.
- Send raw audio to any cloud service unless the platform-native STT
  already does (in which case follow the platform's user-consent flow).
- Auto-embed captures against a cross-tenant embedding service before
  the tenant boundary decision is made.
- Build a manual folder / tag system as a "backup" for when AI routing
  is wrong — this is the **opposite** of the project's thesis. Solve
  it with merge / move UX and routing-confidence indicators instead.
- Compete with Teams for meeting recording. Read its outputs if useful.
