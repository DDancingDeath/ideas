# AI Assistant — Design (Phase 4c)

> **Status:** Draft for Phase 4c implementation. Lives in `docs/CHAT_DESIGN.md`.
> Closes review item **WALK-1** (chat is non-functional) and **WALK-1b**
> (chat must be data-aware, not generic LLM-only).

## 1. Goals

The current chat tab is wired up to two undefined globals (`askChatbot()`,
`sendChatMessageFromTab()`) and so every quick-reply button throws
`ReferenceError`. We need a real assistant that:

1. **Actually works** — clicking a button produces a useful, escaped reply.
2. **Knows the user's data** — answers come from `AppState`
   (`stock`, `purchaseHistory`, `salesHistory`, `retailSalesHistory`,
   `expensesHistory`, `items`), not from a generic LLM that has never
   seen these numbers.
3. **Is private by default** — no business data leaves the device for
   the common questions. The LLM is a *fallback* path, not the primary
   one, and must be invoked through a Firebase Function so the API key
   never ships to clients.
4. **Is safe to render** — every value rendered into the chat transcript
   is HTML-escaped (we just finished an XSS sweep — Section 8).
5. **Stays cheap** — the LLM only runs when the deterministic path
   fails to find an intent. With a sensible monthly budget cap on the
   Function, the LLM is essentially free for everyday use.

## 2. Architecture

```
                            user types in box
                                    │
                                    ▼
                     ┌─────────────────────────────┐
                     │  ChatManager.ask(text)      │  www/js/modules/chat.js
                     └──────────────┬──────────────┘
                                    │
                                    ▼
                     ┌─────────────────────────────┐
                     │  IntentRouter.classify(t)   │  intent-router.js
                     │  → { intent, params }       │  (pure, regex/keyword)
                     └──────────────┬──────────────┘
                                    │
                  ┌─────────────────┴──────────────────┐
        intent != 'unknown'                  intent == 'unknown'
                  │                                    │
                  ▼                                    ▼
   ┌──────────────────────────┐    ┌──────────────────────────────┐
   │ AppStateQueries.run(     │    │ ChatLLM.fallback(text, ctx)  │
   │   intent, params,        │    │ → POST functions/chat-llm    │
   │   AppState               │    │   (Firebase Function holds   │
   │ ) → { summary, table,    │    │    the API key)              │
   │       navTab? }          │    │ → { summary }                │
   └─────────────┬────────────┘    └──────────────┬───────────────┘
                 │                                │
                 └────────────┬───────────────────┘
                              ▼
                ┌─────────────────────────────┐
                │  ChatManager.render(reply)  │
                │  (HTML-escapes everything)  │
                └─────────────────────────────┘
```

Key properties:

* The intent router is **pure** (no `AppState`, no DOM). All test inputs
  are strings, all outputs are objects. Easy to unit-test.
* The query layer is **pure-data** (takes `AppState` as an argument,
  never reads it from globals). Easy to unit-test against fixtures.
* The orchestrator (`chat.js`) is the *only* layer allowed to touch the
  DOM. It does the escaping at the rendering boundary.
* The LLM fallback is **last resort**. Its prompt only includes a
  redacted "shape summary" (item count, sale-count-today, etc.) — never
  raw customer names or rupee amounts unless the user explicitly
  consents per-message in a future iteration.

## 3. Supported intents (v1)

The router returns one of the following intents. Each is implemented
as a regex/keyword matcher in `intent-router.js` and a corresponding
query function in `appstate-queries.js`.

| # | Intent              | Sample utterances                                                                | Output                                                       |
|---|---------------------|----------------------------------------------------------------------------------|--------------------------------------------------------------|
| 1 | `stock_all`         | "show stock", "what's in stock", "inventory"                                     | Top-N items with quantities + low-stock flags                |
| 2 | `stock_item`        | "stock of rice", "how much wheat do I have", "rice stock"                        | Single-item quantity + last-known rate                       |
| 3 | `sales_today`       | "today's sales", "total sales today", "what did I sell today"                    | Count + sum of today's wholesale + retail sales              |
| 4 | `sales_period`      | "sales this week", "sales this month", "sales last month"                        | Count + sum + top customer over the period                   |
| 5 | `purchases_today`   | "today's purchases", "what did I buy today"                                      | Count + sum of today's purchases                             |
| 6 | `purchases_period`  | "purchases this week", "purchases this month"                                    | Count + sum + top supplier over the period                   |
| 7 | `outstanding_top`   | "who owes me the most", "biggest dues", "top outstanding"                        | Top-5 outstanding parties (sale dues + purchase dues split)  |
| 8 | `outstanding_party` | "how much does Ramesh owe", "what do I owe Sharma"                               | All open dues for a named party                              |
| 9 | `expenses_today`    | "today's expenses", "spending today"                                             | Count + sum of today's `expensesHistory`                     |
| 10 | `expenses_period`  | "expenses this month", "spending this week"                                      | Count + sum + top category                                   |
| 11 | `profit_period`    | "profit this month", "how much did I make this week"                             | Sales − purchases − expenses for the period                  |
| 12 | `nav`              | "open stock", "go to reports", "show me the bills tab"                           | Calls `app.nav.showTab(...)` and returns "Opening …"         |
| 13 | `help`             | "help", "what can you do", "?"                                                   | Lists supported intents (the table above, condensed)         |
| 14 | `unknown`          | anything that doesn't match                                                      | Triggers LLM fallback (Phase 4c-5) or canned "I don't know"  |

### Parameter extraction

For `stock_item`, `outstanding_party`, `nav` we extract a parameter
slot from the utterance:

* `stock_item` — match `stock of <item>` / `<item> stock` / `how much <item>` and look up against `AppState.items[*].name` (case-insensitive substring); also match against `hindiName` so "गेहूं" works.
* `outstanding_party` — match `<party> owe` / `owe <party>` / `does <party>`; look up against the union of `customerName` across all histories.
* `nav` — map keyword → tab id: `stock→stock`, `bills/billing→billing`, `reports→reports`, `outstanding/dues→outstanding`, `settings→settings`, `expenses→miscellaneous`, `cash→cash-management`, `finance→finance`, `items→items`, `users→users`, `admin→admin`.

### Period extraction

For `*_period` intents we extract one of `today`, `week`, `month`,
`year`, `all` from the utterance (default `month` if ambiguous). Maps
to a `since` timestamp via the same logic the rest of the app uses.

## 4. Output shape

All query functions return:

```js
{
  summary: string,        // 1-2 sentence headline (will be escaped on render)
  table?: Array<Array<string>>,  // optional rows for tabular display
  navTab?: string,        // optional: tab id to also navigate to
  empty?: boolean         // true if there were no results to show
}
```

The orchestrator HTML-escapes every value via `Helpers.escapeHtml`
before injecting into the transcript. No `innerHTML` of user-derived
data without escaping. (The `XSS-1`/`XSS-2` patches we just shipped
have hardened `escapeHtml` to handle `null`/`undefined`/non-strings.)

## 5. Module layout

```
www/js/modules/
  chat.js                    — ChatManager (the orchestrator)
  chat/
    intent-router.js         — IntentRouter (pure)
    appstate-queries.js      — AppStateQueries (pure)

www/templates/
  chat.html                  — UI; quick-reply buttons call app.chat.ask(...)

www/js/__tests__/
  chat-intent-router.test.js — exhaustive intent table
  chat-queries.test.js       — fixture-based query tests
  chat-render.test.js        — XSS escaping, navTab plumbing

functions/                   — Firebase Functions (LLM fallback only)
  chat-llm.js                — POST endpoint; reads OPENAI_API_KEY from
                                Functions config; rate-limited;
                                budget-capped; only invoked from
                                ChatManager when intent==='unknown'
```

## 6. Phase 4c breakdown

| Step | Todo               | Deliverable                                                                            |
|------|--------------------|----------------------------------------------------------------------------------------|
| 4c-1 | `p4-chat-design`   | This document                                                                          |
| 4c-2 | `p4-chat-router`   | `intent-router.js` + Jest suite (no DOM, no `AppState`)                                |
| 4c-3 | `p4-chat-queries`  | `appstate-queries.js` + Jest suite (fixture `AppState`, no DOM)                        |
| 4c-4 | `p4-chat-ui`       | `chat.js` + updated `chat.html` + render test                                          |
| 4c-5 | `p4-chat-llm`      | `functions/chat-llm.js` + client `ChatLLM` wrapper. Optional — disabled until deployed |

Each step is a separate commit, each with its own tests, each leaving
the suite green.

## 7. LLM fallback (Phase 4c-5) — **shipped** (commit CHAT-LLM-1)

The deferred LLM fallback is now landed. Two files implement it:

* `functions/chat-llm.js` — **deployment artefact**, not yet deployed.
  Owner runs `firebase deploy --only functions:chatLlmFallback` once
  they've installed deps, set `chatllm.openai_key` (or
  `chatllm.gemini_key` / `chatllm.anthropic_key`) and chosen caps via
  `firebase functions:config:set`. Until deployed, the client wrapper
  detects the absence and silently skips the LLM call (see
  `functionsAvailable()` in the wrapper).

* `www/js/modules/chat/chat-llm.js` — **client wrapper**.
  Exports `ChatLlm.callLlmFallback({ prompt, dataSummary })` and
  `ChatLlm.buildDataSummary(appState)`.
  Wraps the Functions invocation in a 12-second timeout, gracefully
  degrades to `null` on any error (no Functions, network down, quota
  exhausted, provider error, malformed response, timeout). The chat
  orchestrator interprets `null` as "fall back to canned reply".

The function's responsibilities:

* AuthN (Firebase Auth context.auth) and AuthZ (`users/{uid}.status === 'approved'`).
* Input validation (≤500 char prompt, ≤4000 char dataSummary).
* Per-uid daily token cap + per-project monthly cap, both enforced via
  Firestore transactions on `chatLlmQuotas/{uid_<uid>_<YYYY-MM-DD>}`
  and `chatLlmQuotas/{project_<YYYY-MM>}`.
* Calls a configured LLM provider (OpenAI / Gemini / Anthropic supported
  out of the box — defaults to OpenAI gpt-4o-mini).
* Wraps the user prompt in a constraining system prompt that limits the
  model to shop-only questions and refuses unrelated requests.
* Refunds the quota on provider error and on overestimate (we always
  reserve more than we'll need, then refund the difference).
* Logs every call to `chatAuditLogs/{auto}` with: caller uid, success
  flag, prompt length, response length, used tokens, model, latency,
  failure reason if any.

The user prompt is **never** passed to the LLM verbatim alongside raw
shop data. `buildDataSummary()` produces an aggregated summary
(item counts, low-stock counts, today/month totals, outstanding party
counts and totals) — never customer names paired with bill amounts.

Behaviour for `intent === 'unknown'` is now:

1. Render the user bubble + a "🤔 Thinking…" placeholder synchronously.
2. Kick off `ChatLlm.callLlmFallback()` (fire-and-forget Promise).
3. When it resolves:
   - Success → replace the placeholder with the LLM's text (escaped
     via `Helpers.escapeHtml` — see §8 below).
   - `null` (any failure) → replace with the canned reply
     "I don't know how to answer that yet. Type **help** for what I
     can do."

Tests: `www/js/__tests__/chat-llm.test.js` — 21 assertions covering
buildDataSummary aggregation correctness + truncation; the wrapper's
graceful degradation across every failure mode; the orchestrator's
sync placeholder, no-call-on-known-intent, replacement-on-success,
canned-fallback-on-absent-Functions, and LLM-output XSS escape.

## 8. Security checklist (from XSS-1 / XSS-2 review)

* [x] Every value rendered into `chatMessages` goes through
  `Helpers.escapeHtml` (handles `null`/`undefined`/non-strings).
* [x] Quick-reply button labels in `chat.html` are static strings, no
  template interpolation, so they need no runtime escaping.
* [x] User-typed messages are echoed in the transcript via
  `escapeHtml`, not raw.
* [x] No `eval`, no `new Function`, no `innerHTML += rawText`.
* [x] No `document.write`.
* [x] Inline `onclick` attributes only call `app.chat.ask(literal)` —
  never a user-controlled string.

## 9. Open questions (resolved here so 4c-2..4c-5 can run unblocked)

| Q                                                              | Decision                                                                                                  |
|----------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| Should we support Hindi utterances in the router?              | **Yes for item names** (we already store `hindiName`). Other intents stay English keywords for v1.        |
| What's "today"?                                                | The same date-window helper used elsewhere in the app (start of local day → now).                         |
| What if the user has no data yet?                              | Each query returns `{ empty: true, summary: 'No transactions yet for this period.' }`.                    |
| Where do we keep conversation history?                         | In-memory only for v1 (no Firestore writes — staging is read-only, and prod doesn't need it for v1).      |
| Can a staff user see profit?                                   | Yes — same role checks the existing reports/finance modules already enforce. Chat is a read-only mirror.  |
| What about voice / speech-to-text?                             | Out of scope for v1. The browser's native dictation works in the input box if the user wants it.          |
| Are there any rate-limits on the deterministic intents?        | No — it's a local computation. Only the LLM fallback path needs limits.                                   |

## 10. Future work (not Phase 4c)

* Conversation memory (multi-turn): "Show stock of rice" → "What about wheat?"
* Rich-card responses (charts, deep-links to specific bills)
* Voice input via Web Speech API (English + Hindi)
* "Suggest" feature: based on AppState, the assistant pro-actively
  prompts "You haven't recorded today's stock-in yet. Go to Stock?"
* Per-customer chat threads ("ask about Ramesh") with party-scoped
  query results.

