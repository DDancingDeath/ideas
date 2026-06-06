# notes-reminders

> A voice-first **app** that turns spontaneous thoughts into a self-organising
> personal knowledge base. Speak; the system transcribes, finds the right
> topic, appends — or creates a new topic if nothing fits. No folders,
> no tagging, no choosing where it goes.

- **Status:** idea capture. Pivoted 2026-06-06 from a *type-classifier*
  (note/todo/reminder) to a *topic-organised knowledge base* (TableView
  Design Review, Family/Personal Tasks, Mahua Business, …). To be built
  as a **mobile-first app**.
- **Audience:** me. Personal use across work and personal life.
- **Working title:** `notes-reminders` (folder name preserved for stable
  links). Likely product name candidates: *Memory*, *Threads*, *Topic*.

---

## The idea

I capture ideas, design feedback, meeting takeaways, action items, and
personal reminders all day long. Existing note apps either create a swamp
of disconnected notes or demand that I file each one manually. Over time
information fragments and becomes unfindable.

The app should let me **speak naturally** and then:

1. **Transcribe** the audio.
2. **Understand** what the note is about.
3. **Find** the most relevant existing topic — using embeddings, not folders.
4. **Append** the note there, or **create** a new topic if nothing fits.
5. **Maintain** each topic as a living document: summary, timeline of notes,
   open actions, related topics.
6. **Surface** information back through natural-language search, daily
   digest, and an agent that can draft responses using a topic's accumulated
   context.

I should never have to create folders, choose a notebook, tag notes, or
decide where information belongs.

Deeper detail: [`idea.md`](./idea.md).

---

## Example

> 🎙️ *"Manoj asked about IME support in TableView. We should add
>     globalization requirements."*

→ **Topic created:** `TableView Design Review`
> - Manoj asked about IME support.
> - Add globalization requirements.

> 🎙️ *"Godly thinks the ADR wording implies per-cell effects are not
>     possible. Update the ADR wording."*

→ Recognised as same project; appended to `TableView Design Review`:
> - ADR wording should clarify that per-cell effects are possible but
>   have a performance cost.

> 🎙️ *"Need to buy shoes for Laddu."*

→ **Topic created:** `Family / Personal Tasks`
> - Buy shoes for Laddu.

---

## How it might work

```
   capture (in-app mic, Teams / WhatsApp share, text fallback)
            │
            ▼
     Speech-to-text  (Whisper on-device on mobile; Azure Speech fallback)
            │
            ▼
   Embed the note  (sentence-transformers / OpenAI embeddings)
            │
            ▼
   Vector search across existing topic embeddings
            │
       ┌────┴────┐
       ▼         ▼
   match found   no match above threshold
       │              │
       ▼              ▼
   append to     create new topic
   topic         (LLM-generated title + summary seed)
       │              │
       └──────┬───────┘
              ▼
       Topic memory updated
       (summary, timeline, open actions, related topics)
              │
              ▼
   Retrieval surfaces:
     - in-app chat   ("what's open on TableView?")
     - daily digest  ("you added 14 notes today, here's the rollup")
     - agent mode    ("draft a reply to Manoj's IME comment")
```

The original capture-and-route pipeline (note vs todo vs reminder) is
**replaced**, not extended: open action items now live inside each topic's
memory, not in a separate todo destination.

---

## Reading order

1. [`idea.md`](./idea.md) — full vision, examples, success criteria.
2. [`spec/README.md`](./spec/README.md) — what the spec will need to cover.
3. [`plan/README.md`](./plan/README.md) — status + walking skeleton.
4. [`prompts/build-from-spec.md`](./prompts/build-from-spec.md) — hand to
   an agent only after the platform + embedding-store decisions are made.

---

## Open decisions

- [ ] **App platform** — React Native (one codebase iOS + Android), or
      mobile-first PWA, or native iOS first? Mic latency and Share-sheet
      integration (for Teams / WhatsApp re-shares) are the tie-breakers.
- [ ] **Embedding model** — on-device (sentence-transformers MiniLM) vs
      hosted (OpenAI `text-embedding-3-small`, Azure OpenAI)? Affects
      privacy boundary, cost, and offline behaviour.
- [ ] **Vector store** — local SQLite + sqlite-vec (per-device), Pinecone
      / Qdrant / pgvector (hosted), or hybrid (local first, sync later)?
- [ ] **Topic-match threshold** — single similarity cutoff, or
      LLM-confirms-top-K? Below-threshold notes go to *Unsorted* or
      trigger a new topic?
- [ ] **Privacy / tenant** — work captures stay in corp services, personal
      stays local? Or one personal knowledge base with explicit
      "share to work" gestures? (Was unresolved in the type-classifier
      version too.)
- [ ] **Capture surfaces beyond the app** — Teams chat-bot, WhatsApp
      forward, email-in alias, browser extension? Which is v1?
- [ ] **Clawpilot composition** — Clawpilot Workflows are still the
      cleanest way to schedule the daily digest. Generate the digest in
      the app and *forward* via Clawpilot, or skip Clawpilot entirely?
- [ ] **Wake-word** — still a v2 question; push-to-talk in v1.
- [ ] **Action-item extraction** — separate LLM pass per topic, or
      structured output from the topic-summary pass?
- [ ] **Cross-topic linking** — auto-detect via embedding cosine between
      *topics* (not notes), surface as "related topics" in the UI.

---

## Recent changes

- _2026-06-06_ · **Pivot.** Reframed from a type-classifier (route to
  OneNote / Outlook / Todo) to a **topic-organised knowledge base** with
  embedding-driven routing, topic memory (summary + timeline + open
  actions), cross-topic linking, daily digest, and agent mode. Decision:
  build as a mobile-first **app**. See [`idea.md`](./idea.md).
- _2026-05-20_ · Noted **Clawpilot** (Microsoft-internal) as the likely
  substrate for reminders + scheduled briefs. Still useful for the daily
  digest under the new framing.
- _2026-05-20_ · Idea captured. No code.
