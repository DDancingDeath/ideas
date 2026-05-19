# Spec — agent-prompt-optimizer

> **Placeholder.** Spec deferred until the shape decision is made
> (pre-prompt rewriter / session-replay coach / real-time coach).

## What the spec will need to cover

1. **Capture surface** — how prompts and responses are observed.
   Wrapper CLI? MCP server? IDE extension? Clipboard watcher?
   Per-tool adapter?
2. **Optimizer model** — the LLM that rewrites / coaches. Single model
   or per-target-LLM choice?
3. **Prompt-quality rubric** — explicit checklist the optimizer runs
   against every input (goal stated? constraints? context attached?
   success criteria? right model?).
4. **Rewrite UX** — diff format, accept/edit/reject keys, latency
   budget, opt-out hotkey.
5. **Learning loop** — how the optimizer improves over time. Outcome
   capture, manual ratings, what's logged.
6. **Privacy** — same data-boundary rules as the underlying LLM. No
   silently uploading corp data.
7. **Multi-tool integration** — list of supported tools (Copilot CLI,
   Cursor, internal Copilot, web ChatGPT) with adapter strategy for
   each.

## Out of scope

- Replacing or routing between LLMs.
- Training a custom model.
- Building a template library.
