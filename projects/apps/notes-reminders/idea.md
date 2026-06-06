# Idea — notes-reminders

> **AI-Powered Voice Memory & Knowledge Assistant** — a voice-first app
> that quietly builds a self-organising personal knowledge base out of
> everything I say to it.

## One-liner

Speak naturally; the app transcribes, finds the right topic via vector
search, and appends — or creates a new topic if nothing fits. Each topic
maintains its own summary, timeline, open actions, and links to related
topics. Retrieval is natural-language.

## Problem

I capture ideas, meeting feedback, design thoughts, action items, and
personal reminders throughout the day. Current note-taking apps either
create too many disconnected notes or require manual organisation. Over
time, information becomes fragmented and hard to retrieve.

Specifically:

- **Capture cost is too high.** Opening OneNote / Todo / Outlook to
  write two sentences breaks flow.
- **Voice notes are easy to create but die on the shelf** — not
  searchable, not summarised, not surfaced when relevant.
- **Manual filing is a tax I won't pay.** Tagging, choosing notebooks,
  picking folders — every one of these is a friction point that ends
  with me not capturing.
- **Existing AI capture tools (AudioPen, Otter) produce a flat list of
  transcripts**, not an evolving knowledge base.

## Goal

Build a voice-first AI assistant that acts as a personal knowledge base.
I should be able to speak naturally, and the system should automatically
determine whether the information belongs to an existing topic/project
or should create a new one.

## Target users

- **Primary**: me. Personal use across work (design reviews, decisions,
  feedback to absorb) and personal life (family tasks, side businesses,
  health, home improvements).
- **Anti-users**: anyone whose capture friction is already low, or who
  prefers explicit hierarchical organisation (Obsidian / Logseq users).

## User experience

1. Open the app **or** send a voice note through Teams / WhatsApp / etc.
2. Tap-and-talk; speak the note.
3. The AI automatically:
   - Transcribes the audio.
   - Understands the content.
   - Finds the most relevant existing topic.
   - Appends the note if it belongs there.
   - Creates a new topic if no suitable match exists.
4. I never manually organise notes.

### Worked examples

**Voice Note 1**
> *"Manoj asked about IME support in TableView. We should add
> globalization requirements."*

→ AI creates `TableView Design Review`:
- Manoj asked about IME support.
- Add globalization requirements.

**Voice Note 2**
> *"Godly thinks the ADR wording implies per-cell effects are not
> possible. Update the ADR wording."*

→ AI recognises same project; appends to `TableView Design Review`:
- Manoj asked about IME support.
- Add globalization requirements.
- ADR wording should clarify that per-cell effects are possible but
  have a performance cost.

**Voice Note 3**
> *"Need to buy shoes for Laddu."*

→ AI creates `Family / Personal Tasks`:
- Buy shoes for Laddu.

## Core features

### Voice capture
- One-tap recording.
- Mobile-first experience.
- Background upload (capture must succeed even on poor connectivity).

### Automatic topic detection
- Embeddings + vector search to compare new notes against existing
  topics.
- Confidence-based routing — append above threshold, new topic below.
- LLM names new topics and seeds their summary.

### Topic memory
Each topic maintains:
- **Summary** (kept current by AI as new notes land).
- **Timeline** of notes, with timestamps and original transcripts.
- **Open action items** (extracted automatically, checkable).
- **Related topics** (embedding-cosine links).

Examples of topics I'd expect to emerge:
- TableView Design Review
- Family Business
- Laddu (kid)
- Career Growth
- Health
- Home Improvements
- Mahua side business

### AI summarisation
Automatically maintained per topic:
- Current summary.
- Key decisions.
- Outstanding actions.
- Important references (people, links, file names).

### Retrieval
Natural-language search across the entire knowledge base:
- *"What are the open issues for TableView?"*
- *"Show everything I've said about the Mahua business."*
- *"Summarize all notes from last week."*

## Advanced features

### Daily digest
End-of-day push notification:
> You added 14 notes today.
>
> Main topics:
> - TableView Design Review
> - Family Business
> - Personal Tasks
>
> New action items:
> - Respond to IME review comment
> - Call Mahua supplier
> - Buy shoes for Laddu

### Cross-topic linking
Detect relationships across topics:
> "This discussion about grouped collections is related to the
>  ShapedCollectionView design."

### Agent mode
Use accumulated topic knowledge to draft outputs:
> *"Draft a response to Manoj's comment."*
>
> The agent pulls everything in `TableView Design Review` about IME
> and globalization and produces a reply I can copy into Teams.

## What success looks like

- **Capture latency**: tap-to-recording in under 1 second; transcript
  visible within 3 seconds of speech ending.
- **Topic-routing accuracy**: ≥ 80 % of captures land in the right
  topic (or correctly create a new one) without me reassigning.
- **Recall via natural-language search**: I can retrieve anything I
  captured by what I roughly remember.
- **Zero manual filing**: no folders, no tags, no notebook picking.
- **Daily digest is useful enough that I read it.** If I dismiss it
  unread for a week, the format is wrong.

## Constraints

- **Capture latency** must stay sub-second to recording. Anything
  slower kills the habit.
- **Speech-to-text** should run on-device on mobile when possible
  (Whisper.cpp / native iOS Speech / Android SpeechRecognizer); cloud
  STT (Azure Speech) is acceptable as a fallback or when on-device
  isn't available.
- **Privacy boundary** matches the tenant: work captures stay in
  corp-approved services if I'm in work-tenant mode; personal stays
  in my personal cloud / on-device.
- **Offline capture** must work — embeddings and routing can sync when
  back online.

## Non-goals

- A full PKM (personal knowledge management) tool — Obsidian / Logseq
  exist; this is the opposite philosophy (no manual structure).
- A meeting-recording tool — Teams already does this; the agent can
  read the output, not compete.
- A calendar / scheduling tool. Open action items live inside topics;
  they don't go on the calendar.
- Multi-user / shared notes. Single-user first.
- A general chat assistant. Retrieval is **over my knowledge base**,
  not the world.

## Technical approach

1. **Speech-to-text** — Whisper (on-device or hosted) or Azure Speech.
2. **Embeddings** — generate for every note (and a rollup embedding
   per topic).
3. **Vector database** — store topic embeddings + note embeddings.
   Candidates: SQLite + sqlite-vec (local-first), Pinecone / Qdrant /
   pgvector (hosted).
4. **Topic match** — cosine similarity between new-note embedding and
   each topic's representative embedding(s). Above threshold → append;
   below → new topic. Tunable, possibly LLM-confirmed for the boundary
   zone.
5. **Summary maintenance** — LLM pass per topic after each new note (or
   debounced) regenerates summary + extracts action items in structured
   output.
6. **Chat interface** — RAG over the topic store for natural-language
   queries and agent-mode drafting.

## Inspiration / prior art

- **AudioPen / Otter** — voice-first capture and clean transcripts, but
  flat list, no topic memory, no auto-organisation.
- **Apple / Google Reminders** — fast capture, no understanding.
- **Microsoft To Do + OneNote** — destination systems; lack the
  capture-and-route front end.
- **Copilot for M365** — overlaps in retrieval; not voice-first capture,
  not topic-organised over time.
- **Clawpilot** _(Microsoft-internal, `aka.ms/clawpilot-request`)_ —
  Workflows are clean for the *scheduled daily digest* side. Still
  applicable under the new framing for the evening rollup; not needed
  for the capture-and-organise core.
- **mem.ai / Reflect** — closest commercial cousin (AI-organised note
  graph). Worth a focused audit before building.

## Success criteria — what the user should never have to do

- Create folders.
- Choose a notebook.
- Tag notes.
- Decide where information belongs.

The system should continuously organise knowledge, maintain context, and
make information easy to retrieve through natural language.

## Open questions

- [ ] **App platform** — React Native, mobile-first PWA, or native iOS
      first?
- [ ] **Embedding model** — on-device vs hosted? Affects privacy,
      cost, offline.
- [ ] **Vector store** — local-first (sqlite-vec), hosted (Pinecone /
      Qdrant / pgvector), or hybrid?
- [ ] **Topic-match threshold** — single cosine cutoff, or LLM
      confirms top-K?
- [ ] **Tenant boundary** — single personal knowledge base, or split
      work / personal with an explicit "promote to work" gesture?
- [ ] **Capture surfaces beyond the app** — Teams chat-bot, WhatsApp
      forward, email-in alias, browser extension? Which is v1?
- [ ] **Daily digest delivery** — in-app push, Teams DM via Clawpilot
      Workflow, or email?
- [ ] **Action-item extraction** — separate LLM pass per topic, or
      structured output from the topic-summary pass?
- [ ] **Cross-topic linking** — embedding cosine between *topic*
      embeddings? UI: "you might also care about…"
- [ ] **Audit `mem.ai` / `Reflect` / `Saner.ai`** before building —
      is one of them already close enough?
- [ ] **Composition with `inbox-triage`** — should triaged emails feed
      into topic memory as captures?
