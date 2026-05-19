# Plan — agent-prompt-optimizer

## Status

**Early-stage idea capture.** Three competing shapes on the table; no
shape chosen yet; no code.

## Next steps

1. **Pick a shape** (see `../README.md` → "Open decisions"). Without
   this choice, every downstream design call is blocked.
2. **Pick a capture surface** that matches the shape — wrapper CLI for
   pre-prompt rewriter, log scraper for session-replay coach, IDE
   extension for real-time coach.
3. **Define the prompt-quality rubric.** This is the real IP — what
   does a "good" prompt look like for the LLMs I actually use?
4. **Walking skeleton**: rewrite my prompt before sending, show me the
   diff, let me accept or edit. No learning yet.
5. **Outcome capture** — start logging whether rewrites helped.
6. **Tune the rubric** based on real data.

## Risks

- **Latency** — anything > 500 ms on a pre-prompt path will get
  disabled inside a day.
- **Privacy boundaries** — if I use this on internal-Copilot prompts,
  the optimizer must call an internal LLM endpoint, not public OpenAI.
- **Over-coaching** — too many nudges = I disable it. The bar for
  surfacing a rewrite has to be high.

## Known issues

(none yet — no code)
