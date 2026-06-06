# Plan — notes-reminders

## Status

**Early-stage idea capture.** No code. Project pivoted 2026-06-06 from a
type-classifier (note/todo/reminder routing) to a **topic-organised
knowledge base** delivered as a **mobile-first app**. No chosen
platform, no chosen embedding model, no chosen vector store yet.

## Next steps

1. **Audit nearby commercial tools.** `mem.ai`, `Reflect`, `Saner.ai`,
   `Granola`, `Saner`. Confirm the voice-first + topic-memory shape
   isn't already shipped well enough to use off the shelf.
2. **Pick the platform.** React Native (one codebase) vs mobile-first
   PWA (web reach, slower mic) vs native iOS (best mic latency, slowest
   to iterate).
3. **Pick the embedding model + vector store.** Local-first
   (sentence-transformers + sqlite-vec) vs hosted (OpenAI embeddings +
   pgvector / Qdrant).
4. **Walking skeleton (v0)**: app with tap-to-record, on-device or
   platform-native STT, save raw transcript to local SQLite. No topic
   detection yet. Just a chronological list. *Goal: prove the capture
   flow is friction-free.*
5. **Add embedding pipeline.** Generate an embedding per note; show
   top-3 cosine-nearest existing notes alongside each new capture, so I
   can eyeball whether the embedding signal is strong enough to drive
   topic routing.
6. **Add topic objects.** First version: each existing "cluster" of
   notes (by manual grouping or k-means on embeddings) becomes a topic.
   Add `topic_id` foreign key to notes. UI shows notes grouped by topic.
7. **Add automatic topic routing.** New note → embed → cosine vs each
   topic's centroid → append if above threshold, else create new topic
   with LLM-generated title + summary.
8. **Add topic memory.** LLM pass per topic after each new note:
   regenerate summary, extract action items.
9. **Add retrieval.** Natural-language query → RAG over topics.
10. **Add daily digest.** Schedule end-of-day rollup; deliver in-app
    push first, Clawpilot Workflow for Teams DM later.
11. **Add agent mode.** Per-topic "draft a response" / "summarise for
    sharing" actions.

## Risks

- **Topic-routing accuracy below ~80 % is demoralising.** If new notes
  keep landing in the wrong topic, I'll stop trusting the system. Need
  an easy "move this note to another topic" gesture from day 1, and
  the boundary-zone LLM confirmation in place before launching.
- **Topic proliferation.** If every off-topic remark creates a new
  topic, the knowledge base degenerates into a flat list. Need merge
  UX and a periodic "topics you haven't touched in 90 days" cleanup.
- **Capture latency** still kills the habit. Background upload + retry
  is mandatory.
- **STT accuracy on noisy mics** — Whisper tiny is poor; balance
  model size vs speed vs device support.
- **Privacy** — work-tenant captures shouldn't get embedded against
  personal-cloud OpenAI by accident. Tenant boundary needs to be
  decided early; can't be retrofitted.
- **mem.ai / Reflect may already do this.** Audit before building.

## Known issues

(none yet — no code)
