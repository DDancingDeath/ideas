# Build prompt — reflective-friend

> ⚠️ **Do not hand to an agent yet.** This project has a higher trust
> bar than every other app in this repo. Resolve platform (Flutter vs.
> React Native), capture model (phone-only vs. phone + wearable), LLM
> provider, personality-persistence design, and the consent /
> recording-law model in [`../README.md`](../README.md) first. See the
> project plan in [`../plan/README.md`](../plan/README.md).

---

You are building **reflective-friend**, a personal AI companion that
combines passive ambient listening (opt-in, evidence-backed) with
active reflection (daily check-ins, monthly growth summaries) and
rehearsal practice. Read `../README.md` and `../idea.md` for the full
vision. Generate code in a **separate directory / repo** (not in this
`projects/` folder).

## Walking skeleton (v0)

The first deliverable is a **reflection-only** app — **no passive
listening yet**. The point is to prove the personality, the memory
recall, the evidence-backed citations, and the reflective UX all work
before we ever turn the mic on continuously.

1. Onboarding: user picks the AI's name, tone, voice, evening
   reflection time.
2. Manual voice-note capture: tap-to-talk; on-device Whisper
   transcription; stored in time-indexed memory.
3. Nightly reflection prompt at the user's chosen evening time:
   "How was today? One thing you'd do differently? One thing you
   did well?" The AI surfaces 2-3 observations from today's notes
   with citations.
4. Natural-language recall: "what did I say about X last week?" →
   AI returns transcript snippets with timestamps.
5. Personality layer: stable system prompt; same name and tone
   across sessions; persisted user-specific tuning.
6. Memory editor: user can browse what the AI thinks it remembers;
   correct mishears; delete entries.
7. Encrypted on-device SQLite + a vector index for recall.

## Quality bar (v0)

- **Personality consistency**: across 50 conversations spread over
  a week, the AI's name, tone, and conversational style are
  indistinguishable from the first session.
- **Recall accuracy**: 0 hallucinated quotes in 100 recall
  prompts. Missing-memory case ("I don't have that") fires
  cleanly.
- **Reflection prompt latency**: prompt appears within 1 minute
  of the user's chosen time; observations render in under 3
  seconds.
- **Onboarding**: complete in under 90 seconds.
- **Offline-first**: every v0 surface (notes, reflection, recall)
  works with airplane mode on.

## After v0

Each layer ships behind a feature flag, in this order. Do not
re-order; the trust foundations must precede passive capture.

1. Monthly growth summary; theme / topic extraction; rolling
   summaries.
2. Rehearsal mode (no passive listening yet); skill modules
   (feedback, boundaries, apologies, active listening).
3. Full data export + full delete + per-period selective delete +
   per-person redaction.
4. **Phase 2 begins here**: opt-in passive listening, single
   user only. Per-location consent; visible listening indicator
   always on; full audit log of listening sessions; one-tap
   pause-until-X.
5. Family-member consent flow — second person consents verbally
   or via a visible wearable indicator; revocation; per-room
   defaults.
6. In-conversation witness mode: "what did we agree about X?" →
   verbatim transcript snippet with playback. Strictly no
   paraphrase in family-dispute contexts.
7. Disagreement mode: "what do you think?" → calm,
   transcript-grounded perspective; explicit refusal to declare
   winners.
8. Optional cloud sync for transcripts (opt-in per data class).
   Audio never syncs unless the user wants it as verifiable
   evidence.
9. Optional wearable integration (Bee AI / Friend / Tab /
   AirPods). Design only first; live integration after.
10. Persona regression tests gating any LLM provider / model
    upgrade.

## Do NOT

- Implement passive listening in v0. The reflection-only surfaces
  must earn user trust before the mic is ever on continuously.
- Paraphrase in evidence-mode. When the user asks "what did I /
  we say about X?", return the transcript snippet, verbatim. If
  there's no matching memory, say so clearly — never invent.
- Use streak / gamification / engagement-loop mechanics. No "I
  missed you", no FOMO nudges, no daily-streak counters.
- Behave as a therapist or use diagnosis / treatment language.
  Reflection responses must include a standing
  not-a-therapist line when the conversation touches on serious
  distress; escalation to real help is a first-class response.
- Listen without a visible indicator. The "I am listening now"
  state must be obvious on screen (and on the wearable, if
  present) at all times.
- Listen in any location until the user has opted in for that
  location.
- Listen to a second person without their consent. The
  family-member consent flow is a real product feature; do not
  skip it.
- Default to cloud transcription. On-device Whisper first; cloud
  is opt-in per session.
- Cross-contaminate the memory store with the sibling apps
  (`notes-reminders`, `parenting-companion`) without an explicit
  shared-memory architectural decision.
- Build new hardware. If wearable capture is needed, integrate
  with existing third-party devices.
- Send transcripts, audio, or reflection content to any
  third-party analytics service.
