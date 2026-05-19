# Spec — notes-reminders

> **Placeholder.** Spec deferred until the tenant and capture-surface
> decisions are made.

## What the spec will need to cover

1. **Capture pipeline** — hotkey / push-to-talk binding, recording
   length cap, end-of-utterance detection.
2. **STT** — Whisper model choice (tiny/base/small for speed vs
   accuracy), on-device only.
3. **Classifier** — LLM prompt for {note, todo, reminder, meeting
   outcome, question, idea, decision}. Few-shot examples per class.
4. **Output adapters** — one per destination: OneNote section, Outlook
   reminder, Microsoft To Do task, local SQLite "notes" table.
5. **Surface** — morning brief format, on-demand search UI, weekly
   review format.
6. **Search** — FTS5 across all captures + LLM-assisted natural-
   language query rewrite.
7. **Tenant + privacy** — explicit destination per tenant; capture
   never crosses tenant boundary.
8. **Auto-route confidence floor** — items below floor go to an
   "unrouted" bucket I clean up daily.

## Out of scope

- Meeting recording itself.
- Full PKM features (graph, backlinks, etc.).
- Calendar scheduling.
- Multi-user sharing.
