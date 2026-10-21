# Build prompt — Life OS — personal life hub

Paste this prompt to a coding agent (Copilot CLI, Cursor, Claude Code, etc.)
to generate the application from this spec.

---

You are building **Life OS — personal life hub**. Everything you need is in
this folder and the box ideas it links to.

**Context loading order:**

1. Read `../idea.md` end-to-end. Internalize the owner, the privacy
   constraints and the success criteria.
2. Read `../spec/README.md` end-to-end: box contract, Ask answer contract,
   privacy rules, no-defaults rule, configuration table.
3. Read the Finance box spec linked from `../spec/README.md`; build Finance,
   Health and Career & Learning as `live` boxes and Family, Notes & reminders,
   Reflection as `coming_soon`.
4. Skim `../plan/README.md` for milestone order and known issues — do NOT
   reintroduce them.

**Output:**

- Generate the application in a **separate repository**. Do not modify any
  files in this repo.
- Deterministic calculations live in versioned engines with JSON Schemas and
  unit tests; the UI and Ask only select, arrange and phrase engine outputs.
- Every tool result carries `inputs_sha256` and `engine_version`.
- A missing input is reported as `needs_input`, never defaulted.
- Repo init with `.gitignore` (personal data folder ignored), `README.md`
  linking back to this spec folder, build/run commands, tests.
- Use sample data only; never commit personal figures.
- Stop and ask if any spec point is ambiguous. Do not invent behaviour.

**Quality bar:**

- Runs on first try; README has install + run in ≤3 commands.
- The worked example in `../spec/README.md` passes as an automated test.
- No TODOs in committed code — implement, or open an issue and reference it.

**Out of scope (don't do unless asked):**

- Public hosting
- External AI providers (keep `ask.provider` = `none`)
- Production secrets
