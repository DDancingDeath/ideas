# Page spec: AI Assistant (`chat`)

## Purpose
A natural-language layer over the user's data. The user types ("how much
rice do I have?", "who owes me the most?", "today's net?"). The assistant
parses intent, queries `AppState`, and replies in the same language as
the question. Fallback to LLM only when intent routing can't match.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `chat` | `www/templates/chat.html` | `www/js/modules/chat.js` |

## Who can use it
Any authenticated user.

## What the user sees
1. **Chat transcript** (assistant messages, user messages).
2. **Quick-question buttons** ("Today's totals", "Who owes me?", etc.).
3. **Input box + Send button**.

## What the user can do
| Action | Effect | Writes to |
|---|---|---|
| Send message | Routes via intent matcher → AppState query → reply | — (read-only) |
| Click quick button | Same as sending its text | — |

## Calculations / formulas

The assistant is a thin router on top of the same formulas already
defined in the other page specs. It does **not** re-implement math.

### Intent routing
Keyword/regex match → handler. Examples:
| User input matches | Handler | Returns |
|---|---|---|
| `today` / `आज` | `todayTotals()` | numbers from `01-day.md` |
| `owes` / `due` / `उधार` | `outstanding()` | numbers from `08-due.md` |
| `stock of X` / `कितना X है` | `stockOf(item)` | number from `07-stock.md` |
| `profit` / `मुनाफा` | `profit(period)` | number from `11-analytics.md` |
| `cash` / `नकद` | `cashPosition()` | numbers from `09-finance.md` |

### LLM fallback
If no intent matches:
1. Build a compact context blob (today's totals + outstanding total +
   top 5 items by stock — **not** raw bills).
2. Send `{ system: rules, context, userMessage }` to the configured LLM.
3. Display the response.

LLM endpoint URL + key live in Firebase Functions config; the client
calls a Function (no key in client code).

## Data sources
- All AppState collections (read-only).
- LLM endpoint via Firebase Function (fallback only).

## Must NOT do
- **Must NOT make any Firestore write.** This page is read-only by
  contract.
- Must not send full bill data to the LLM — only the summarized numbers
  needed to answer. Privacy.
- Must not log API keys to console or any error message.
- Inline `onclick` handlers must use `window.app.chat.X` — not just
  `app.chat.X` — to survive the firebaseConfig `let app` shadow that
  was fixed in STG-WALK-5.
- Must not block the UI while waiting for the LLM — show a typing
  indicator and let the user cancel.

## Known issues
- ~~Send button broken via `app` shadow — fixed (STG-WALK-5).~~
- ~~Generic "let LLM ramble" version — replaced with intent router +
  AppState query + LLM fallback (see `docs/CHAT_DESIGN.md`).~~

## Example bug reports → what to change
- "I asked 'who owes me the most?' and it gave a generic answer" →
  intent router didn't match. Add a regex/keyword case for "owes" /
  "उधार" in `chat.js` `routeIntent()`.
- "It said the wrong stock for rice" → router matched, but the stock
  formula in `07-stock.md` (triple-key lookup) wasn't applied. Use
  the same helper, not a new one.
