# AI Assistant — Design (Phase 4c)

> **v1 scope.** This document records the shipped v1 AI Assistant design. If it disagrees with `spec/rebuild/`, `spec/rebuild/` wins.
>
> **Status:** Phase 4c implementation reference. Original path: `docs/CHAT_DESIGN.md`. Closes **WALK-1** and **WALK-1b**.

## 1. Goals

The chat tab had undefined globals (`askChatbot()`, `sendChatMessageFromTab()`). The v1 assistant must:

1. Work: quick replies produce escaped replies.
2. Use `AppState`: `stock`, `purchaseHistory`, `salesHistory`, `retailSalesHistory`, `expensesHistory`, `items`.
3. Stay private by default: deterministic local answers first; LLM only via Firebase Function fallback.
4. Render safely: escape every transcript value.
5. Stay cheap: call LLM only when deterministic routing returns `unknown`, with Function budget caps.

## 2. Architecture

```text
user text
  → ChatManager.ask(text)              www/js/modules/chat.js
  → IntentRouter.classify(t)           intent-router.js; pure regex/keyword
  → if known: AppStateQueries.run(intent, params, AppState)
  → if unknown: ChatLLM.fallback(text, ctx) via functions/chat-llm
  → ChatManager.render(reply)          escapes every value
```

| Layer | Rule |
|---|---|
| Intent router | Pure: string in, object out; no DOM/AppState. |
| Query layer | Pure data: receives `AppState`; no globals. |
| Orchestrator | Only DOM-touching layer; escaping boundary. |
| LLM fallback | Last resort; redacted shape summary only unless future per-message consent exists. |

## 3. Supported intents (v1)

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

| Intent | Extraction |
|---|---|
| `stock_item` | `stock of <item>` / `<item> stock` / `how much <item>`; match `AppState.items[*].name` and `hindiName` case-insensitive substring. |
| `outstanding_party` | `<party> owe` / `owe <party>` / `does <party>`; match union of `customerName` across histories. |
| `nav` | `stock→stock`, `bills/billing→billing`, `reports→reports`, `outstanding/dues→outstanding`, `settings→settings`, `expenses→miscellaneous`, `cash→cash-management`, `finance→finance`, `items→items`, `users→users`, `admin→admin`. |

### Period extraction

For `*_period`, extract `today`, `week`, `month`, `year`, or `all`; default `month`. Convert to `since` with the app's existing date-window logic.

## 4. Output shape

```js
{
  summary: string,        // 1-2 sentence headline (escaped on render)
  table?: Array<Array<string>>,
  navTab?: string,
  empty?: boolean
}
```

The orchestrator escapes every value with `Helpers.escapeHtml` before transcript insertion. No unescaped user-derived `innerHTML`.

## 5. Module layout

```text
www/js/modules/
  chat.js                    — ChatManager orchestrator
  chat/
    intent-router.js         — IntentRouter pure classifier
    appstate-queries.js      — AppStateQueries pure data layer

www/templates/
  chat.html                  — quick replies call app.chat.ask(...)

www/js/__tests__/
  chat-intent-router.test.js — intent table
  chat-queries.test.js       — AppState fixtures
  chat-render.test.js        — XSS escaping, navTab plumbing

functions/
  chat-llm.js                — POST endpoint; Functions config API key; rate-limited; budget-capped; called only for intent==='unknown'
```

## 6. Phase 4c breakdown

| Step | Todo               | Deliverable                                                                            |
|------|--------------------|----------------------------------------------------------------------------------------|
| 4c-1 | `p4-chat-design`   | This document                                                                          |
| 4c-2 | `p4-chat-router`   | `intent-router.js` + Jest suite (no DOM, no `AppState`)                                |
| 4c-3 | `p4-chat-queries`  | `appstate-queries.js` + Jest suite (fixture `AppState`, no DOM)                        |
| 4c-4 | `p4-chat-ui`       | `chat.js` + updated `chat.html` + render test                                          |
| 4c-5 | `p4-chat-llm`      | `functions/chat-llm.js` + client `ChatLLM` wrapper. Optional — disabled until deployed |

Each step is one tested commit and leaves the suite green.

## 7. LLM fallback (Phase 4c-5) — **shipped** (commit CHAT-LLM-1)

| File | Role |
|---|---|
| `functions/chat-llm.js` | Deployment artefact, not yet deployed. Owner runs `firebase deploy --only functions:chatLlmFallback` after deps, provider key (`chatllm.openai_key` / `chatllm.gemini_key` / `chatllm.anthropic_key`), and caps are configured. |
| `www/js/modules/chat/chat-llm.js` | Client wrapper exporting `ChatLlm.callLlmFallback({ prompt, dataSummary })` and `ChatLlm.buildDataSummary(appState)`. Uses 12-second timeout and returns `null` on no Functions, network down, quota exhausted, provider error, malformed response, or timeout. |

Function requirements:

- AuthN: Firebase Auth `context.auth`.
- AuthZ: `users/{uid}.status === 'approved'`.
- Input limits: ≤500 char prompt, ≤4000 char dataSummary.
- Quotas: per-uid daily and per-project monthly caps via transactions on `chatLlmQuotas/{uid_<uid>_<YYYY-MM-DD>}` and `chatLlmQuotas/{project_<YYYY-MM>}`.
- Providers: OpenAI / Gemini / Anthropic; default OpenAI `gpt-4o-mini`.
- System prompt: shop-only; refuse unrelated requests.
- Quota refund: provider error and overestimate refund.
- Audit: write `chatAuditLogs/{auto}` with caller uid, success flag, prompt length, response length, used tokens, model, latency, and failure reason.
- Data summary: aggregated counts/totals only; never customer names paired with bill amounts.

Unknown intent flow: render user bubble + "🤔 Thinking…"; call `ChatLlm.callLlmFallback()`; on success replace placeholder with escaped LLM text; on `null` replace with `I don't know how to answer that yet. Type **help** for what I can do.`

Tests: `www/js/__tests__/chat-llm.test.js`, 21 assertions for aggregation/truncation, failure degradation, placeholder flow, no-call-on-known-intent, success replacement, canned fallback, and XSS escape.

## 8. Security checklist (from XSS-1 / XSS-2 review)

* [x] Every value rendered into `chatMessages` goes through `Helpers.escapeHtml` (handles `null`/`undefined`/non-strings).
* [x] Quick-reply button labels in `chat.html` are static strings, no template interpolation, so they need no runtime escaping.
* [x] User-typed messages are echoed in the transcript via `escapeHtml`, not raw.
* [x] No `eval`, no `new Function`, no `innerHTML += rawText`.
* [x] No `document.write`.
* [x] Inline `onclick` attributes only call `app.chat.ask(literal)` — never a user-controlled string.

## 9. Open questions (resolved for 4c-2..4c-5)

| Q                                                              | Decision                                                                                                  |
|----------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| Should we support Hindi utterances in the router?              | **Yes for item names** (we already store `hindiName`). Other intents stay English keywords for v1.        |
| What's "today"?                                                | The same date-window helper used elsewhere in the app (start of local day → now).                         |
| What if the user has no data yet?                              | Each query returns `{ empty: true, summary: 'No transactions yet for this period.' }`.                    |
| Where do we keep conversation history?                         | In-memory only for v1 (no Firestore writes — staging is read-only, and prod doesn't need it for v1).      |
| Can a staff user see profit?                                   | Yes in v1 — same role checks the existing reports/finance modules already enforce. Chat is a read-only mirror. **v2 override:** staff cannot access Reports/Analytics/Finance; `spec/rebuild/role-permission-matrix.md` governs. |
| What about voice / speech-to-text?                             | Out of scope for v1. The browser's native dictation works in the input box if the user wants it.          |
| Are there any rate-limits on the deterministic intents?        | No — it's a local computation. Only the LLM fallback path needs limits.                                   |

## 10. Future work (not Phase 4c)

* Conversation memory (multi-turn): "Show stock of rice" → "What about wheat?"
* Rich-card responses (charts, deep-links to specific bills)
* Voice input via Web Speech API (English + Hindi)
* "Suggest" feature: based on AppState, the assistant pro-actively prompts "You haven't recorded today's stock-in yet. Go to Stock?"
* Per-customer chat threads ("ask about Ramesh") with party-scoped query results.
