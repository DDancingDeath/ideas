# Idea — prompt-optimizer

## One-liner

Make me measurably better at using AI — by either rewriting my prompts
on the fly, coaching me in real time, or reviewing my session history
and showing me what I keep getting wrong.

## Problem

I use AI all day. Prompt quality varies wildly. I waste time:

- Asking the same question three different ways before the model
  gets it.
- Forgetting to attach the file I'm asking about.
- Using the wrong model for the task (cheap fast model for a
  reasoning-heavy job, or vice versa).
- Re-asking questions I already solved in a previous session because
  I can't recall how.
- Not knowing which agent / skill to invoke for a given problem.

No tool I use today nudges me toward better behaviour. I just feel
vaguely slow.

## Target users

- **Primary**: me, with my mixed-AI workflow (Copilot CLI, Cursor,
  internal Copilot, web ChatGPT).
- **Secondary**: any heavy AI user. Generalization is a stretch goal.
- **Anti-users**: anyone whose AI usage is light enough that the
  overhead of the optimizer outweighs the win.

## What success looks like

- Fewer turns per task — measured as "time from first prompt to first
  acceptable answer" dropping by 30 % over a month.
- Fewer obvious mistakes I'd be embarrassed by if a senior engineer
  saw the session log (wrong file context, wrong model, ambiguous
  ask).
- I can explain why my prompt was rewritten — every rewrite shows the
  diff and a one-line reason.
- Opt-out is one keystroke. Never coerces.

## Constraints

- Must not slow me down. Latency budget for any in-flight rewrite:
  < 500 ms.
- Works across my actual tools (CLI, IDE, browser) without me having
  to think about which one I'm in.
- Doesn't send my prompts anywhere I wouldn't already be sending
  them. (If I'm using internal Copilot for corp data, the optimizer
  has to honour the same boundary.)

## Non-goals

- Replacing the LLM. The optimizer is metadata, not the model.
- Auto-routing between models without my consent.
- Training a custom model. Off-the-shelf LLM with a clever system
  prompt is plenty for v1.
- Becoming a prompt library / template system — there are too many.

## Inspiration / prior art

- LangSmith and other observability tools (session replay, but
  passive).
- "Prompt engineering" guides (text, not agentic).
- IDE features like Cursor's `@` mentions that nudge context
  attachment.

## Open questions

- [ ] **Which shape wins**: pre-prompt rewriter, session-replay
      coach, or real-time coach? Could even be all three over time —
      but pick one for MVP.
- [ ] **What's "good"?** How does the optimizer know whether a
      rewrite was actually better? Manual ratings? Outcome inference
      (did I follow up with a thank-you or a "no, you misunderstood")?
- [ ] **Internal vs personal use** — if I want this to work on
      corp-data prompts, it has to use the same internal LLM endpoint
      and the same data boundaries.
- [ ] **Multi-tool capture** — sessions are scattered across CLI logs,
      Cursor history, browser. Is there one ingestion layer or per-tool
      pluggable adapters?
