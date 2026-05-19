# Plan — ado-bugfixer

## Status

**Early-stage idea capture.** No code, no allow-list, no choice on
whether to reuse Copilot Coding Agent.

## Next steps

1. **Audit internal alternatives.** Watson bug-fixer, ADO-Automation,
   Copilot for ADO, area-specific bot accounts. Confirm this project
   is the personal-scope-shaped gap, not a duplicate.
2. **Pick the MVP area path.** One. Pick something I own and where the
   bug volume is moderate.
3. **Resolve open decisions** (see `../README.md`).
4. **Walking skeleton**: pull bugs from one query, classify into
   {dupe, user error, real bug, won't fix}, print results to CLI.
   No PR drafting, no comments.
5. **Add dupe-detection.** Pair with existing-bug search. Measure
   precision against my manual labels for a week.
6. **Add root-cause note generation** for "real bug" items — post as
   a draft I review before sending.
7. **Add PR drafting** (via Copilot Coding Agent if available, else
   direct). Run expert-review skills on every draft.
8. **Promote to bot-runs-overnight only after** trust is earned.

## Risks

- **False dupes** are very annoying and erode trust fast. Set the
  precision bar high; bias toward "I'm not sure" over a wrong
  classification.
- **Sensitive bugs** — skip + alert me; never surface content.
- **Spam on bug comments** — strict "do not comment more than once
  per N days per bug" guardrail.
- **Duplicating org tools** — audit before building.
- **Trust drift** — if the agent quietly degrades, I won't notice
  until I've merged a bad PR. Telemetry on acceptance rate is a
  must.

## Known issues

(none yet — no code)
