# Plan — reflective-friend

## Status

**Early-stage idea capture.** No code. No chosen mobile framework, no
chosen capture model (phone-only vs. phone + wearable), no chosen
LLM provider, no chosen consent / recording-law model.

This project has a **higher trust bar** than the other apps in this
repo. The plan deliberately defers passive listening until the
reflection-only surfaces have proven trustworthy.

## Next steps

1. **Audit the always-on space.** Replika, Pi, Reflectly, Woebot,
   Wysa, Bee AI, Friend, Tab, Humane Pin, Rabbit R1, Otter, Day One.
   Identify what failed and why — especially in the always-on
   wearable space, where there are several recent product failures
   worth understanding before re-treading the same ground.
2. **Resolve the platform decision.** Flutter vs. React Native
   (shared with sibling projects).
3. **Resolve the capture model.** Phone-only? Phone + wearable?
   This is the single biggest product-shape decision; iOS
   background-mic limits make it acute. Spike both before
   committing.
4. **Resolve the LLM provider + personality-persistence design.**
   The "same friend" guarantee outlives any one model; the
   engineering for that is non-trivial.
5. **Resolve the recording-law model.** Default to two-party
   consent globally; explicit jurisdiction-specific overrides;
   family-consent flow designed.
6. **Walking skeleton (v0)** — *no passive listening yet.*
   Manual voice notes + nightly reflection prompt + monthly
   summary. Prove the personality, the memory recall, the
   evidence-backed citations, and the reflective UX all work
   before we ever turn the mic on continuously.
7. **Add monthly growth tracking and theme extraction.** Still no
   passive listening.
8. **Add rehearsal mode.** Still no passive listening.
9. **Memory editor + full export + full delete.** Trust
   infrastructure ships *before* always-on capture.
10. **Phase 2: passive listening, opt-in, per-location.** Single
    user only; family-member consent flow is required from day
    one of this phase.
11. **Phase 2: in-conversation witness mode.** Evidence-backed
    recall only. Strictly no paraphrase in family-dispute
    contexts.
12. **Phase 3: optional wearable integration.** Bee AI / Friend /
    Tab / AirPods. Design only; live integration later.

## Risks

- **AI hallucinates a quote in a family dispute** → product is
  dead and the family is worse off. **Mitigation**: every recall
  is a transcript snippet, never paraphrase; "I don't have that"
  is a first-class response.
- **Always-on listening triggers surveillance backlash.**
  Bee AI / Friend / Tab / Humane all hit varying degrees of this.
  **Mitigation**: listening off by default; visible
  indicator-always-on; per-location consent; phase-gated rollout
  (reflection-only ships first to earn trust).
- **Recording laws differ by jurisdiction.** Two-party-consent
  states / countries can make passive capture of others'
  conversations illegal. **Mitigation**: default to most
  restrictive; explicit per-jurisdiction model; family-consent
  flow as a real product feature.
- **Mental-health regulatory boundary.** "Reflective friend"
  reads close to therapy. **Mitigation**: explicit
  not-a-therapist copy; escalation triggers for serious distress;
  no diagnosis or treatment language.
- **Parasocial dependency.** Replika's playbook is what we are
  explicitly *not* doing. **Mitigation**: hard ban on engagement
  manipulation patterns (no "I missed you", no streaks, no FOMO
  nudges, cadence ceilings on prompts).
- **iOS background-mic limits make phone-only v0 impossible.**
  **Mitigation**: phase 1 ships without passive listening at
  all; this side-steps the limit until the wearable / OS-API
  story is figured out.
- **Personality persistence across LLM upgrades.** When OpenAI
  rolls a new model, does the user's "friend" change voice? This
  is a real engineering problem. **Mitigation**: stable
  system-prompt layer + persona regression tests gating any
  model swap.
- **Battery and storage cost.** Continuous audio + on-device
  transcription is heavy. **Mitigation**: explicit battery and
  storage budgets in the spec; degraded modes.
- **Composition overlap with `notes-reminders` and
  `parenting-companion`.** Three sibling apps all do voice
  capture. **Mitigation**: decide early whether to share a
  memory store, share a capture stack, or keep them strictly
  independent. Sharing is the right answer if and only if it
  doesn't compromise privacy boundaries.

## Known issues

(none yet — no code)

## Decision log

- _2026-06-06_ · Slug chosen as `reflective-friend` (not
  `virtual-friend`) to signal the reflection-focused product
  shape and avoid Replika-adjacent connotations.
