# notes-reminders

> A capture-first agent for notes and reminders — voice or text in,
> structured notes + scheduled reminders out — without me having to
> decide where things go.

- **Status:** early-stage idea capture. No code.
- **Audience:** me. Personal use. Could be work-tenant or personal-life
  oriented depending on the chosen surface.

---

## The idea

I lose decisions, tasks, and one-off ideas all day because the
capture cost is too high. Opening OneNote / Todo / Outlook to write
two sentences breaks flow. A voice note app captures, but then the
note is dead — not searchable, not actionable, not surfaced when
relevant.

The agent should:

1. **Make capture free.** Hotkey or wake-phrase opens a 5-second voice
   capture; tap-and-talk on mobile; quick-paste on desktop. Whisper
   on-device for STT.
2. **Auto-classify** the capture into one of: note, todo, reminder,
   meeting outcome, question-for-someone, idea, decision.
3. **Auto-route** — todos to my todo system, calendar reminders to
   Outlook, notes to OneNote / a daily journal, questions into a
   "ping these people" list.
4. **Surface back** — daily morning brief of pending reminders, weekly
   review of notes captured, "you said you'd ask X about Y a week ago,
   still want to?"
5. **Stay queryable** — natural-language search across every capture
   ever made.

Deeper detail: [`idea.md`](./idea.md).

---

## How it might work

```
   capture (voice / text / clipboard)
            │
            ▼
     Whisper STT (local)
            │
            ▼
   Auto-classify (LLM)
            │
   ┌────────┼─────────┬──────────┬──────────┐
   ▼        ▼         ▼          ▼          ▼
  note    todo     reminder   meeting    question
   │       │         │          │          │
  store   →todo   →cal/Outlook  →OneNote  →ping list
   │       │         │          │          │
   └───────┴─────────┴──────────┴──────────┘
                     │
                     ▼
              Local SQLite (FTS)
                     │
                     ▼
        Morning brief + on-demand search
```

---

## Reading order

1. [`idea.md`](./idea.md) — vision.
2. [`spec/README.md`](./spec/README.md) — placeholder.
3. [`plan/README.md`](./plan/README.md) — status + open questions.
4. [`prompts/build-from-spec.md`](./prompts/build-from-spec.md) — only
   after the capture-surface and tenant decisions are made.

## Open decisions

- [ ] **Tenant**: work AAD (notes route to corp OneNote / Outlook) or
      personal Microsoft account?
- [ ] **Capture surface**: hotkey desktop only, mobile-first, or
      both?
- [ ] **Output systems**: Outlook + OneNote, or a clean local store
      and skip the Microsoft stack?
- [ ] **Wake-word**: yes (battery + privacy concerns) or push-to-talk
      only?
- [ ] **Existing tools**: is this Copilot for M365 + a hotkey, or
      something genuinely new?

## Recent changes

- _2026-05-20_ · Idea captured. No code.
