# prompt-optimizer

> An agent that makes me better at using AI — by watching how I prompt
> and either coaching me, rewriting prompts in flight, or suggesting
> better patterns based on my own past sessions.

- **Status:** early-stage idea capture. Multiple interpretations on
  the table; pick one before building.
- **Audience:** me. Could generalize, but MVP is single-user.

---

## The idea

I use AI a lot — Copilot CLI, Cursor, Claude, web ChatGPT, internal
Copilot. Quality varies wildly with prompt quality, model choice, and
whether I attached the right context. I rarely notice when I'm leaving
performance on the table.

The agent could take any of three shapes — **need to pick one**:

1. **Pre-prompt rewriter.** Sits between me and the LLM. Takes my draft
   prompt, rewrites it for clarity / context / constraints, shows me
   the diff, sends the rewrite (or my edited version) on.
2. **Session-replay coach.** Reads my AI session history (Copilot CLI
   `session_store`, Cursor logs, web ChatGPT export) once a day and
   surfaces patterns: "you asked the same thing 3 ways yesterday —
   here's a prompt that would have worked first time."
3. **Real-time coach.** A toolbar / TUI sidekick that watches my
   active session and flags issues mid-stream: "you didn't attach the
   file you're asking about", "the model you picked can't do this —
   switch to X", "this prompt is ambiguous — clarify Y".

Deeper detail: [`idea.md`](./idea.md).

---

## How it might work (pre-prompt rewriter shape, as the default sketch)

```
Me ──draft prompt──▶ Optimizer agent ──rewritten prompt──▶ chosen LLM
                          │
                          ├── checks: does this prompt have a goal?
                          │   constraints? success criteria? context
                          │   attached? right model for the job?
                          │
                          └── learns from my edits + outcome ratings
                              (did I keep the rewrite? did the response
                              actually solve my task?)
```

Could plug in as:

- A CLI alias / wrapper for `copilot`, `claude`, `cursor`.
- An MCP server my IDE calls before sending.
- A clipboard watcher (paste a prompt → it suggests a rewrite first).

---

## Reading order

1. [`idea.md`](./idea.md) — what we want, who for, success criteria.
2. [`spec/README.md`](./spec/README.md) — placeholder.
3. [`plan/README.md`](./plan/README.md) — status + open questions.
4. [`prompts/build-from-spec.md`](./prompts/build-from-spec.md) — paste-
   ready, but only after the shape decision is made.

## Open decisions

- [ ] **Shape**: pre-prompt rewriter vs session-replay coach vs
      real-time coach. Pick one for MVP.
- [ ] **Surface**: CLI wrapper, MCP server, browser extension,
      clipboard watcher?
- [ ] **Learning loop**: how does the optimizer get feedback on whether
      a rewrite was good? Manual thumbs / outcome inference?
- [ ] **Models we target**: all LLMs uniformly, or per-model coaching
      (e.g. "Claude prefers X, GPT-5 prefers Y")?

## Recent changes

- _2026-05-20_ · Idea captured. No code.
