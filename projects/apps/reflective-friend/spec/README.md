# Spec — reflective-friend

> **Placeholder.** Spec deferred until the platform (Flutter vs.
> React Native), capture model (phone-only vs. phone + wearable),
> LLM provider, and consent / recording-law model are decided —
> see open questions in [`../README.md`](../README.md) and
> [`../idea.md`](../idea.md).
>
> This project has a higher trust bar than the other apps in this
> repo: it captures audio of the user and the people around them.
> The spec must treat **consent UX, evidence-backed recall,
> recording-law compliance, and parasocial-risk guardrails** as
> first-class requirements, not afterthoughts.

## What the spec will need to cover

### Identity, personality, and persistence
1. **Profile schema** — user name, preferred AI name, voice,
   conversational tone, nudge frequency.
2. **Personality layer** — stable system prompt + user-specific
   tuning that survives LLM provider / model changes. The "same
   friend" guarantee.
3. **Persona consistency tests** — automated checks that the AI
   responds in-character before any model upgrade is rolled out.

### Consent and recording-law compliance
4. **Listening-state machine** — explicit states (off, listening,
   paused-until-X, off-in-this-location); single-tap transitions;
   visible indicator always.
5. **Per-room / per-location consent** — listening is off by
   default in any new location until the user opts in here.
6. **Family-member consent flow** — how a second person consents
   (spoken consent recorded as evidence; wearable LED visible;
   verbal "I'm okay with this on"); revocation path.
7. **Jurisdiction model** — one-party vs. two-party consent
   defaults per country / state; default to most-restrictive when
   location is unknown.
8. **Audit log** — every listening session is logged with
   start/stop time, location, and consenting parties; visible to
   the user; exportable.

### Audio capture and transcription
9. **Capture surfaces** — phone background mic (iOS / Android
   limits documented); optional BLE wearable; AirPods integration.
10. **On-device transcription** — Whisper on-device for default
    privacy; sample-rate, model size, battery budget.
11. **Optional cloud transcription** — opt-in per session, with a
    visible "this is cloud-transcribed" badge on every resulting
    memory.
12. **Wake words / hot phrases** — "Hey [name]" patterns; per-user
    customisable; tested for accidental triggers.
13. **Battery and storage budget** — explicit targets; degraded
    modes when battery is low.

### Memory store
14. **Transcript schema** — time, location, participants,
    confidence, source (phone / wearable / cloud-transcribed),
    raw audio reference (optional).
15. **Embedding index** — sentence-level embeddings; vector
    search for natural-language recall.
16. **Theme / topic extraction** — recurring people, places,
    goals; user-visible and user-editable.
17. **Memory editor** — the user can browse what the AI thinks
    it remembers; correct misheard words; delete moments
    ("forget this hour"); redact people or topics.
18. **Cloud sync** — opt-in per data class. Default: transcripts
    may sync; raw audio never does unless the user wants
    verifiable evidence.

### Reflection and recall
19. **Nightly prompt** — short, structured: "how was today?",
    "one thing you'd do differently?", "one thing you did well?";
    AI surfaces 2-3 observations from the day with citations.
20. **Monthly summary** — recurring themes, growth, slips,
    suggested experiments; based on aggregated weekly summaries.
21. **Evidence-backed recall** — every "you said X" surfaces a
    transcript snippet and (optionally) the audio. The AI
    refuses to invent quotes; missing memory is a "I don't have
    that" response.
22. **Confidence levels** — recall responses are tagged as
    *verbatim*, *paraphrase*, or *inferred*; the user always
    knows which.

### In-conversation third-party mode
23. **Witness mode invocation** — "hey [name], what did we agree
    about X?"; the AI replies with the transcript snippet, never
    a paraphrase, in front of everyone present.
24. **Disagreement mode** — "what do you think?" → calm
    perspective grounded in observed transcript; explicit refusal
    to declare a winner.
25. **In-room consent gating** — witness / disagreement responses
    only fire if everyone present has consented to listening for
    the time window being recalled.

### Rehearsal and practice
26. **Rehearsal mode** — user describes a conversation they want
    to practise; AI plays the other side based on what it knows
    of that person.
27. **Feedback** — post-rehearsal, AI surfaces communication
    patterns the user could refine.
28. **Skill modules** — feedback, boundary-setting, apologies,
    active listening; each module a structured workflow.

### Safety and escalation
29. **Mental-health escalation triggers** — specific signals
    (self-harm, abuse, sustained severe distress) prompt the AI
    to surface real-help resources; logged separately.
30. **Therapeutic-boundary copy** — the AI's reflection responses
    include a standing reminder that it is not a therapist;
    explicit disclaimer when reflection touches on serious
    distress.
31. **Parasocial-risk guardrails** — explicit list of behaviours
    the AI must not exhibit: no "I missed you", no streak
    shaming, no FOMO nudges, no manufactured emotional
    dependency.

### Privacy and data control
32. **On-device encrypted storage** — canonical store.
33. **User-controlled keys** for any cloud sync.
34. **Full export** — all transcripts, memories, audio (if
    stored), reflections, in machine-readable form.
35. **Full delete** — full account delete; "forget this period"
    selective delete; "forget this person" cross-cutting delete.
36. **No third-party analytics** in v1.

### Notifications
37. **Channels** — APNs (iOS) / FCM (Android); local fallbacks.
38. **Quiet hours** — respect device DND; reflection prompt
    timed to evening user setting (default 9pm).
39. **Cadence ceilings** — hard maximum reflection / nudge count
    per day to prevent engagement-loop dynamics.

## Out of scope

- A diagnostic or treatment tool for any mental-health condition.
- A judge / arbiter in family disputes — strictly a witness.
- Meeting transcription as a work tool (Otter / Granola /
  Fireflies do this).
- Group chat with multiple users sharing a single AI.
- Multi-user accounts on one device.
- Public sharing of reflections, social features, comments,
  feeds.
- Streaks / gamification / engagement-loop mechanics.
- General-purpose chatbot — the AI's knowledge is grounded in the
  user's life, not the internet.
- Hardware manufacture — if a wearable is chosen, integrate with
  third-party hardware (Bee AI / Friend / Tab / AirPods) rather
  than build new hardware in-house.
- Telemedicine integrations.
