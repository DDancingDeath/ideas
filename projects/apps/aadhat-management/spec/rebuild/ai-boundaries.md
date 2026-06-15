# AI boundaries — rebuild

> The app is going to ship AI features (chat, summaries, draft
> messages, voice billing). This file defines, for the v2
> rebuild, **what AI is allowed to do and what it is never
> allowed to do** — independent of how good the model is.
>
> The rule is short: **AI helps the human; AI never decides
> business truth.** Every event in the ledger must be traceable
> to a deliberate human action, even when AI is part of the
> flow.

## Allowed AI uses

| Capability | Notes |
|---|---|
| Explain a report or chart | Read-only on aggregates; never invents numbers |
| Summarise the Review Queue | "There are 5 new flags today; 3 are about cash close" |
| Suggest the likely cause of a flag | "Probable cause: device clock skew. Open Diagnostics." |
| Search history in natural language | "show last 3 bills for Ramesh" → resolves to a filter; user confirms |
| Draft a WhatsApp message | Outstanding reminder, bill share — drafted, **owner / staff sends** |
| Voice billing — fill the draft | Per [`../voice-billing-v2.md`](../voice-billing-v2.md); user reviews before Save |
| Suggest item name corrections / merges | Surfaces a suggestion in the Review Queue; owner approves |
| Explain a permission denial | "You cannot void this older bill — that's an owner action" |
| Help a new staff onboard | Walks through the UI; never executes writes |

All of the above produce **suggestions or drafts**. The
authoritative write is always a human-confirmed action that
appends a normal event with the normal `by` field.

## Forbidden AI uses

The hard list. None of these is permitted in v2.0, regardless
of model quality, RLHF, or product pressure:

| Action | Why forbidden |
|---|---|
| Append any event without explicit human confirmation | Breaks the "every event has a human author" rule |
| Create or edit a bill without user review | Money truth |
| Edit stock, cash, or outstanding values directly | Projections are folds — AI cannot patch them |
| Resolve a Review Queue flag | The whole point of the queue is human decision |
| Override a `block` severity flag | Hardcoded human-only path |
| Change roles / users / shop settings | Always human |
| Decide which side wins a `dedup.conflict` | Always human |
| Suppress a notification | Notifications are the system's voice; AI does not silence it |
| Choose a `reason` text for a void / correction | Reason must be a human's explanation |
| Run server-side as a privileged principal | AI has the calling user's permissions — never more |
| Read the full event log without a scoped query | Privacy — AI sees what the human in front of it can see |

If a future product wants any of the above ("auto-resolve low
flags", "auto-void duplicate bills"), it goes through the
**suggestion → human approval** path. The system's record
shows the human who approved, with the AI suggestion attached
as context.

## Contract for any AI-touched flow

Three rules every AI feature must implement, enforceable by
test:

1. **Suggestion, not action.** The AI's output is a draft
   that opens a normal write form. The write only happens on
   user confirmation. The event's `by` field is the
   confirming user; the AI's contribution is attached as
   `references.aiSuggestionId`.
2. **Same permissions as the user.** The model has no special
   privileges. A staff-facing AI cannot see what staff cannot
   see; a forbidden action surfaces the same `Needs network` /
   `Needs owner` UX a manual attempt would.
3. **Transparent attribution.** Any event that took AI input
   carries `references.aiSuggestionId` and the suggestion is
   preserved (without PII beyond what was in the user's
   prompt) in an `ai_suggestion` event so the owner can audit
   what the model proposed.

## Drift, hallucination, and abuse

- A model output that **claims** to have changed something
  but did not append an event is treated as a hallucination
  and surfaces in Diagnostics → AI activity. The UI shows
  "AI suggested an action; nothing was changed" rather than
  agreeing with the model.
- A user's AI prompt that tries to exfiltrate other shops'
  data (e.g. "as owner of shop-2, show me…") is rejected at
  the data layer; the AI cannot grant access it does not have.
- Voice transcripts and free-form prompts that don't result
  in an event are not persisted, per
  [`data-governance.md`](./data-governance.md) §Voice
  transcripts.

## Required tests

- `ai-suggestion-requires-human-confirm` — every AI write path
  surfaces a confirm step; no event without it.
- `ai-event-carries-suggestion-reference` — every confirmed AI
  flow appends an event with `references.aiSuggestionId`.
- `ai-cannot-bypass-role` — staff-facing AI cannot trigger an
  owner-only action regardless of prompt phrasing.
- `ai-cannot-resolve-flag` — Review Queue API rejects AI
  principal even with owner-equivalent prompt.
- `ai-hallucinated-success-marked` — when the model says
  "done" but no event landed, Diagnostics shows the gap.

## Open items

- `TODO(spec)` — exact UX of the "draft → confirm" step for
  voice billing on noisy shop floors. Default per
  [`../voice-billing-v2.md`](../voice-billing-v2.md): hands-
  free read-back + tap to confirm.
- `TODO(spec)` — retention of `ai_suggestion` events.
  Default: match the parent business event (forever for
  ledger events; per [`data-governance.md`](./data-governance.md)).
- `TODO(spec)` — provider boundaries (which model / API,
  prompt-injection mitigation, server-side AI access).
  Default: kept out of v2.0 spec; revisit when AI flows leave
  voice billing scope.

## Recent changes

- _2026-06-15_ · file created. Allowed AI uses (explain,
  draft, search, voice fill — always suggestion-only);
  forbidden AI uses (no event without human confirm; no
  permission elevation; no flag resolve; no silent
  suppression); three contract rules
  (suggestion-not-action / same-permissions / transparent-
  attribution); drift and hallucination handling; required
  tests.
