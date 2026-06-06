# Idea — reflective-friend

> **Personalised AI Companion as a Virtual Friend and Reflective Guide.**
> A continuous, always-on AI personality that listens through my day
> (with my explicit consent), helps me reflect at night, keeps the long
> thread of who I am over weeks and months, and — when a real
> conversation needs a fair third party who actually remembers what was
> said — can be that.

## One-liner

A stable, long-running AI companion that combines **passive ambient
listening** (opt-in, evidence-backed, never an arbiter) with **active
reflection** (daily check-ins, monthly growth summaries) and
**rehearsal practice** (try a difficult conversation before having it),
so the same memory thread runs across years of personal development.

## Problem

I want two things from AI today that I can't get from one product:

- A **journaling / reflection partner** that doesn't need me to sit
  down and write — that observes my day, prompts me at night ("how
  was today, what could you have done better?"), and over months
  notices the patterns I'm too close to see.
- A **fair witness** to real conversations — so when my wife and I
  disagree about what we agreed on three weeks ago, there's a
  source of truth that isn't either of our memories. Not a judge,
  not an arbiter — a calm "here's what was actually said, on this
  date, with audio backup if you want it."

Today these split across at least four products: Reflectly / Day One
for journaling, Replika / Pi for companionship, Otter / Granola for
meeting transcripts, and nothing at all for the family-dispute case.
None of them share memory across these surfaces.

The unlock is **one continuous memory thread, one personality, one
trust contract** — used both reflectively (at night, alone) and
practically (in the moment, with consent from everyone in the room).

## Goal

Build a mobile (and possibly wearable-augmented) AI companion that:

- Runs **continuously, opt-in, with full user control** — privacy is
  the product, not a feature flag.
- Acts as a **steady, guiding friend** — same name, same voice, same
  tone, year after year.
- **Listens passively** when explicitly enabled, **transcribes locally
  first**, and stores memories in a time-indexed, evidence-backed
  store.
- **Recalls accurately** with citation — every "you said X" is backed
  by a transcript snippet (and optionally the audio).
- **Reflects with the user nightly** — short prompts; structured
  observations; never preachy.
- **Summarises monthly growth** — patterns in stress, communication,
  habits, conflict, mood.
- Helps the user **rehearse** difficult conversations before having
  them.
- **Never pretends to be a therapist.** Escalates to real help when
  the conversation indicates serious distress.

## Target users

- **Primary**: me. Working adults who want a long-term reflective
  practice they don't have to sit down for.
- **Secondary**: anyone who's tried (and abandoned) a journaling
  app — most people, statistically.
- **Anti-users**: people looking for a chatbot to talk to as a
  substitute for human connection (Replika audience). The
  personality is *reflective coach*, not *replacement friend*.
- **Observed-but-not-users**: family members who happen to be in
  rooms where I have listening on. Their consent is a first-class
  design problem.

## Key features

### 1. Always-on, opt-in passive listening
- App runs continuously on the phone (and optionally a wearable),
  listening only when explicitly enabled and when consent is
  established for the room.
- **No recording without a visible "I'm listening" indicator** —
  on screen, on a wearable LED, audibly on request.
- Single tap / wake word / hardware button to **pause for the next
  hour / until tomorrow / forever in this location**.
- Listening *off by default* on first install; turned on
  deliberately, scope-by-scope.

### 2. Virtual friend in real conversations
- "Hey friend, what did we agree about [X] in May?" → the AI
  retrieves the relevant transcript snippet and replays it, or
  reads it back verbatim.
- "Hey friend, what do you think?" mid-disagreement → the AI gives
  a calm, balanced perspective grounded in the actual transcript,
  **never inventing words anyone said**.
- The AI is a **witness, not an arbiter** — its job is to surface
  evidence, not deliver verdicts.

### 3. Daily reflection & feedback
- End-of-day prompt: "How was your day? What's one thing you'd do
  differently?"
- AI surfaces what it observed: how I handled stress; whether I
  followed up on yesterday's intention; moments worth celebrating;
  moments worth re-examining.
- Tone is **gentle, non-judgmental, paediatrician-style**, not
  fitness-app streak-shaming.

### 4. Monthly progress tracking
- AI maintains a rolling summary of the user's themes — recurring
  stressors, communication patterns, habits forming or breaking,
  long-running goals.
- Monthly check-in: "Here's where you grew, here's where you
  slipped, here's a small experiment for next month."
- The user can ask "show me everything we've talked about regarding
  [career / health / [relationship] / [goal]]" — natural-language
  query over the memory thread.

### 5. Personalised practice & skill development
- "I have a hard conversation with [X] tomorrow — can we rehearse?"
  The AI plays the other side based on what it knows of that
  person from past conversations.
- Feedback after: "you defaulted to defending; try acknowledging
  first."
- Skill modules: difficult feedback, boundary-setting, apologies,
  active listening.

### 6. Privacy & customisation
- **Local-first by default**: audio never leaves the device unless
  the user explicitly turns on cloud features.
- **Per-data-class opt-in**: transcribed memories may sync to
  cloud for backup; raw audio never does (unless the user wants
  it for verifiable evidence).
- **Personality knobs**: tone (warm / dry / direct), nudge
  frequency, voice, name.
- **Full data export and full account delete** are first-class.
- **Visible memory editor**: the user can see what the AI thinks
  it remembers and correct or delete entries.

### 7. Modular extensibility
- Phase 1: reflection + memory recall + nightly check-in (no
  always-on listening yet; manual voice notes only).
- Phase 2: opt-in passive listening + in-conversation recall.
- Phase 3: rehearsal practice.
- Phase 4: integrations (mood tracking, journaling export,
  calendar context, family-shared moments).

## What success looks like

- I open the app, or it pings me, **once a day for thirty days
  straight** without it feeling like a chore.
- After three months, I can ask "what have I been working on this
  quarter?" and the answer is more accurate than my own recall.
- After a real family disagreement, I (and the other person)
  trust the AI's recall enough to consult it, and it actually
  resolves the dispute rather than inflaming it.
- The AI **never** invents a memory in a moment that matters —
  zero hallucinated quotes in evidence-mode is the bar.
- I never feel surveilled — the "listening on" state is always
  obvious and easy to revoke.

## Constraints

- **Cross-platform** — iOS and Android. iOS background-mic limits
  are the binding constraint.
- **Local-first** — audio and transcripts default to on-device,
  encrypted. Cloud sync is opt-in per data class.
- **Evidence-backed memory** — every recall surfaces the source
  snippet; the AI never claims a memory it can't cite.
- **Consent-first** — listening defaults to off; family-member
  consent is a real flow, not a checkbox in T&Cs.
- **Recording-law compliance** — India + at least one US state +
  EU rules need to be designed in, not retrofitted.
- **Modular** — phase 1 (reflection + manual notes) ships first;
  passive listening is gated until trust foundations are solid.

## Non-goals

- A **therapist**. The app reflects and surfaces patterns; it does
  not diagnose, treat, or replace mental-health care.
  Serious-distress signals must escalate to real help.
- A **replacement for human friendship**. The personality is
  reflective coach, not substitute relationship. No
  parasocial-relationship-engineered loops, no "I missed you"
  guilt prompts.
- A **judge / arbiter**. In family disputes, the AI gives
  evidence; it does not declare winners.
- A **general chatbot**. Memory is grounded in the user's life;
  the AI doesn't have generic opinions on the news.
- A **surveillance tool for the family**. If anyone in the room
  hasn't consented, listening is off — full stop.
- A **meeting transcriber** (Otter / Granola / Fireflies). Those
  are work tools; this is a life tool. Different consent model,
  different memory horizon.

## Technical approach

- **Cross-platform mobile** (Flutter or React Native — open
  decision, shared with sibling projects).
- **Audio capture**:
  - Phone-only mode using OS background-mic APIs (iOS limits
    are the bottleneck).
  - Optional wearable companion (BLE necklace / pendant /
    earbud), bypassing the phone-background problem at the
    cost of a hardware bet.
- **Transcription**: on-device Whisper (privacy default); cloud
  Whisper / Speech API opt-in for better accuracy.
- **Memory store**: time-indexed, embedded transcripts, vector
  index for natural-language recall. On-device SQLite + a vector
  index (sqlite-vec, FAISS-on-device, or similar).
- **LLM for reflection and recall**: bounded RAG over the memory
  store. Provider open — Azure OpenAI / OpenAI / Anthropic /
  on-device (Apple Foundation Models, Gemini Nano).
- **Personality layer**: a stable system prompt, the user's
  preferred name / tone, persisted user-specific tuning that
  outlives any single model.
- **Encryption**: encrypted at rest on device; user-controlled
  key for any cloud sync.
- **Audit log**: every "listening on" event is logged and visible
  to the user; every recall is traceable to a transcript snippet.

## Inspiration / prior art

- **Replika / Pi (Inflection)** — companion chatbots; parasocial
  framing; no real-life listening.
- **Reflectly / Stoic / Daylio / Day One** — reflective journaling;
  manual entry, no ambient layer.
- **Woebot / Wysa** — CBT-style mental-wellness bots; therapeutic
  framing.
- **Otter / Granola / Fireflies** — meeting transcription;
  work-context, not life-context.
- **Apple Recall** (visual) — always-on capture, OS-level privacy
  model worth studying.
- **Bee AI / Friend / Tab / Humane Pin / Rabbit R1** — always-on
  wearable companions; notable mixed reception. Worth a thorough
  audit of what failed and why.
- **`notes-reminders` (sibling project)** — voice-first
  topic-organised knowledge app; active capture, not passive.
- **`parenting-companion` (sibling project)** — could compose:
  reflective-friend observes my parenting moments, parenting-
  companion turns them into milestone notes.

The white space is **active reflection + evidence-backed witness
+ long memory thread, all in one place**. Replika has the
personality; Otter has the transcripts; Reflectly has the
reflective prompts; none of them combine.

## Success criteria — what the user should never have to do

- Open a journaling app and stare at a blank page.
- Wonder whether the AI is currently recording.
- Take the AI's word that "you said X" without seeing the actual
  source.
- Re-tell the AI who they are every conversation.
- Forget when they last enabled listening, or in what location.

## Open questions

- [ ] **Platform** — Flutter or React Native? (Shared with sibling
      projects.)
- [ ] **Phone-only vs phone + wearable** — biggest product-shape
      decision. iOS background-mic limits force the answer.
- [ ] **On-device vs cloud transcription** — Whisper-on-device
      default; cloud opt-in?
- [ ] **LLM provider** — Azure OpenAI / OpenAI / Anthropic /
      on-device? Personality persistence across model migrations
      is a real engineering problem.
- [ ] **Recording-law model** — one-party vs two-party consent
      varies by jurisdiction. Default to most-restrictive
      (two-party)?
- [ ] **Family-member consent flow** — how does someone else in
      the room consent? Spoken consent? Visible wearable
      indicator? Per-location opt-out?
- [ ] **Memory-accuracy guardrails** — every recall cites a
      transcript snippet. What happens when the AI is asked
      something it didn't hear? ("I don't have a memory of that"
      vs. "I think you may have said…")
- [ ] **Mental-health escalation** — what triggers a "you should
      talk to someone" prompt? What's the regulatory line?
- [ ] **Parasocial-risk guardrails** — what behaviours are
      explicitly *not* allowed (e.g., "I missed you" framing,
      streaks, FOMO nudges)?
- [ ] **Personality persistence engineering** — how does the same
      "friend" survive across model upgrades / replacements?
- [ ] **Composition with `notes-reminders`** — separate apps with
      a shared memory store, or one app with two modes?
- [ ] **Composition with `parenting-companion`** — should
      parenting moments observed here flow into the
      parenting-companion log?
- [ ] **Data export, deletion, and "forget this moment"** — the
      UX for memory management is as important as the memory
      itself.
- [ ] **Hardware bet** — is a wearable a v2 thing, or is it the
      only way to make v1 actually work?
