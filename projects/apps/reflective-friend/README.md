# reflective-friend

> An always-on personal AI that acts like a steady, trusted friend —
> sits quietly through my day (with explicit consent), helps me reflect
> at night ("how was today — what could I have done better?"), keeps the
> long thread of who I am over weeks and months, and — when a real
> conversation goes sideways — can step in as a fair third party who
> actually remembers what was said.

- **Status:** idea capture. No code.
- **Audience:** me first; one person per device. Family members are
  *observed* (with consent) but not *users*.
- **Working title:** `reflective-friend`. Product-name candidates:
  *Mira*, *Echo*, *Saathi*, *Witness*, *Steady*.

---

## The idea

Two things I want from an AI that are hard to find in any one product
today:

1. **A reflective guide.** Something that, at the end of a day, can
   ask me *"how did you handle that argument with X?", "where did
   you lose your temper?", "what did you do well?"* — and at the end
   of a month can show me the **pattern** I'm too close to see.
2. **A fair third party in actual conversations.** When my wife and
   I disagree about what we'd agreed on three weeks ago, I want to
   be able to ask the AI — calmly — *"what did we actually say?"*
   and get an answer that's grounded in **what it heard**, not
   what either of us now remembers.

The first half is reflective journaling on autopilot. The second half
is the harder, riskier, more original idea — and it only works if the
AI is **always-on, listening with consent, and trusted to be accurate
about what it heard**. Hallucinating "you said X" in a family dispute
would destroy the product (and the family) in one shot. So the design
constraint is: **memory must be evidence-backed, citable, and
overridable**; the AI is a witness, not an arbiter.

Deeper detail: [`idea.md`](./idea.md).

---

## How it might work

```
   day-long ambient audio (opt-in, local, encrypted)
            │
            ▼
   ┌──────────────────────────────────────────────────────────┐
   │  Transcripts → embeddings → time-indexed memory store     │
   │  (on-device first; cloud sync opt-in per data class)      │
   └──────────────────────────────────────────────────────────┘
            │
   ┌────────┼─────────────┬──────────────────┬──────────────┐
   ▼        ▼             ▼                  ▼              ▼
  Memory  Reflect-with-  In-conversation     Practice /     Monthly
  recall  me (end of     "what did we say"   rehearsal      growth
  ("did   day prompt:    third-party recall  ("how should   summary
  we      "how was       — always with       I respond      ("you
  agree   today?")       quoted evidence     to X?")        improved
  to X    + nudge on                                        on Y, you
  in May  patterns                                          slipped
  ?")                                                       on Z")
```

The reflective side and the witness side share the same memory store —
that's the whole point. The night-time reflection is what makes me
trust the listening; the listening is what makes the reflection
accurate enough to act on.

---

## Reading order

1. [`idea.md`](./idea.md) — full vision, features, risks, prior art,
   open questions.
2. [`spec/README.md`](./spec/README.md) — placeholder spec; what it
   needs to cover (with extra emphasis on consent UX, recording-law
   compliance, and memory-accuracy guardrails).
3. [`plan/README.md`](./plan/README.md) — walking-skeleton-first
   roadmap; what to build first (and what to refuse to ship until
   the trust foundations are solid).
4. [`prompts/build-from-spec.md`](./prompts/build-from-spec.md) —
   gated build prompt; do not hand to an agent until the platform,
   on-device-LLM, and consent UX are decided.

---

## Open decisions

- [ ] **Always-on listening on phones is hard.** iOS aggressively
      kills background mic access; Android is more permissive but
      battery-hostile. Phone-only? Phone + dedicated wearable
      (necklace / pendant, like Bee AI / Friend / Tab)? Phone +
      AirPods? *This is the single most product-shaping decision.*
- [ ] **Recording-law compliance.** One-party vs two-party consent
      varies by country and state. India needs its own answer.
      Family-member consent flow must exist before any real
      recording happens.
- [ ] **On-device vs cloud transcription.** Whisper-on-device
      (privacy) vs cloud (accuracy + cost). Probably on-device
      first, cloud opt-in for "I want better summaries".
- [ ] **AI provider for reflection and recall** — Azure OpenAI,
      OpenAI, Anthropic, or a self-hosted on-device model
      (Apple Foundation Models, Gemini Nano)? The "friend"
      personality consistency requires the same model long-term.
- [ ] **Mental-health regulatory boundary.** This is not therapy
      and must not pretend to be. Need a clear "I am not a
      therapist" line and visible escalation to real help when
      reflection touches on serious distress (self-harm, abuse).
- [ ] **Memory-accuracy guarantees.** When the AI says "you said X
      last Tuesday", what backs that? Verbatim transcript snippet?
      Audio playback? Confidence score? **This is the trust
      foundation.**
- [ ] **Family consent UX.** How does the second person in the room
      consent? A spoken "I'm okay with this being on"? Visible
      indicator on a wearable? Off by default in any room until
      everyone present has opted in?
- [ ] **Overlap with `notes-reminders` and `parenting-companion`.**
      Both also do voice capture. `notes-reminders` is **active**
      capture ("I'm telling you something"); this is **passive**
      capture ("you're observing my life"). Probably distinct
      apps, but the memory store could be shared.
- [ ] **Personality persistence.** Same name, same voice, same
      tone across years. Like having one therapist for a decade,
      not a hot-swappable LLM. How is that engineered?
- [ ] **Parasocial-relationship risk.** "Trusted friend" framing
      is loaded post-Replika. The product needs guardrails that
      keep it in *reflective coach* territory, not *substitute for
      human connection* territory.

---

## Recent changes

- _2026-06-06_ · Idea captured. No code.
