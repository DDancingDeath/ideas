# Build prompt — agent-prompt-optimizer

> ⚠️ **Do not hand this to an agent yet.** Pick a shape first (see
> `../README.md` → "Open decisions").

---

You are building **agent-prompt-optimizer**. Read `../README.md` and
`../idea.md` first. The shape decision is the gating choice — do not
start coding until the user has answered:

1. Pre-prompt rewriter / session-replay coach / real-time coach — which?
2. Capture surface (CLI wrapper / MCP server / IDE extension / log
   scraper / clipboard watcher)?
3. Optimizer LLM (must match the user's data-boundary needs — corp
   prompts need internal endpoint).

Once those are answered, design a walking skeleton in a **separate
directory or repo** (do not modify this `projects/` folder). Code in
the chosen language, with the chosen capture surface, doing exactly
one thing: rewrite a single prompt and show the diff. No learning loop
yet. Iterate from there.

Quality bar:

- Latency < 500 ms on the active path (pre-prompt rewriter only).
- One keystroke to opt out / disable.
- Honours the data boundary of the underlying LLM (internal in,
  internal out).
- No silent uploads of prompts anywhere.

Do NOT:

- Train a custom model.
- Build a template / prompt library.
- Auto-route between LLMs without consent.
- Push corp-data prompts to public LLM endpoints.
