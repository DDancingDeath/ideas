# Spec — notes-reminders

> **Placeholder.** Spec deferred until the platform (React Native /
> PWA / native iOS), embedding model, and vector-store decisions are
> made — see open questions in [`../README.md`](../README.md) and
> [`../idea.md`](../idea.md).

## What the spec will need to cover

### Capture pipeline
1. **Recording** — tap-to-record on the app's home surface; backgrounded
   recording so a brief app-switch doesn't kill the capture; offline
   queue with retry.
2. **Inbound surfaces beyond the app** — Teams chat-bot, WhatsApp
   forward, email-in alias, browser-extension hotkey. One of these is
   v1; the rest follow.
3. **Speech-to-text** — Whisper.cpp on-device for offline + privacy,
   native iOS Speech / Android SpeechRecognizer as the platform-native
   path, Azure Speech as a cloud fallback for unsupported devices.

### Topic detection & routing
4. **Embeddings** — model choice (on-device sentence-transformers vs
   hosted OpenAI / Azure OpenAI); chunk size; representation per topic
   (centroid vs k-rep vs rolling summary embedding).
5. **Vector store** — schema, index choice (HNSW / IVF / brute force),
   sync strategy if local-first.
6. **Topic match** — similarity threshold, tie-breaking, the "boundary
   zone" where an LLM confirms the top-K candidate.
7. **New-topic creation** — LLM prompt for title + seed summary;
   guardrails against duplicate topics (post-hoc merge UX).

### Topic memory
8. **Summary maintenance** — debounced LLM pass after each new note;
   structured output for { summary, key decisions, open action items,
   important references }.
9. **Action-item extraction** — schema; resolution UX (check off, snooze,
   convert to reminder); whether to surface across topics or per-topic.
10. **Cross-topic linking** — cosine between topic embeddings;
    threshold; "related topics" UI.
11. **Topic merge / split / rename** — manual override flow when AI
    routing is wrong; what happens to embeddings on merge.

### Retrieval
12. **Natural-language query** — RAG over the topic store: embed query,
    pull top-K topics, feed the topic summaries + relevant notes to the
    answering LLM.
13. **Within-topic search** — FTS over notes inside a topic.
14. **Agent mode** — prompt template that pulls a topic's full memory
    into the drafting context.

### Surfaces
15. **Daily digest** — schedule, format, delivery channel (in-app push,
    Teams DM via Clawpilot, email).
16. **Inbox / Unsorted** — what happens to below-threshold captures or
    ones where no topic exists yet.
17. **Topic browsing UI** — list, search, drill in to timeline + summary.

### Privacy & tenant
18. **Tenant boundary** — single personal knowledge base, or split
    work / personal with explicit promotion?
19. **On-device vs cloud** — capture stays on-device until embedding;
    explicit allowlist for what crosses the boundary.
20. **Audit log** — what the AI did with each capture, viewable per note.

## Out of scope

- Meeting recording itself (Teams handles this; agent can ingest
  outputs).
- Full PKM features (manual graph, backlinks, daily-notes templates).
- Calendar / scheduling — action items live inside topic memory.
- Multi-user sharing — single-user first.
- General-purpose chat — retrieval is bounded to my knowledge base.
