# Build prompt — Life OS — personal life hub

Paste this prompt to a coding agent (Copilot CLI, Cursor, Claude Code, etc.)
to generate the application from this spec.

---

You are building **Life OS — personal life hub**. Everything you need is in
this folder and the Finance idea it links to.

**Context loading order:**

1. Read `../idea.md` end-to-end: north star, owner, privacy constraints,
   success criteria.
2. Read `../spec/README.md`, then every spec file in the reading order it sets
   (architecture, apps and modes, context policy, glossary, configuration, box
   contract, Ask, cross-cutting, privacy & security, encryption & sync, life
   graph, nudges, identity vault, `boxes/`, worked example).
3. Read the Finance engine spec linked from `../spec/boxes/finance.md`.
4. Skim `../plan/README.md` for milestone order and known issues — do NOT
   reintroduce them. Build milestone by milestone.

**Output:**

- Generate the application in a **separate repository**. Do not modify any
  files in this repo.
- Deterministic calculations live in versioned engines with JSON Schemas and
  unit tests; the UI and Ask only select, arrange and phrase engine outputs.
- Every tool result carries `inputs_sha256` and `engine_version`.
- A missing input is reported as `needs_input`, never defaulted; every
  `required — no default` key in `../spec/configuration.md` starts unset.
- Repo init with `.gitignore` (personal data folder ignored), `README.md`
  linking back to this spec folder, build/run commands, tests.
- Use sample data only; never commit personal figures, names or documents.
- Where the spec has a `TODO(spec)`, implement its stated default and keep it
  easy to change. Stop and ask for anything else that is ambiguous.

**Quality bar:**

- Runs on first try; README has install + run in ≤ 3 commands.
- The worked example in `../spec/worked-example.md` passes as an automated test.
- The accessibility baseline in `../spec/cross-cutting.md` passes on desktop
  and phone widths.
- No TODOs in committed code — implement, or open an issue and reference it.

**Out of scope (don't do unless asked):**

- Public hosting or public network exposure
- External AI providers (keep `ask.provider` = `none`)
- Production secrets
