# Build prompt — Personal Agent v0 (Launch-App Spike)

Paste this prompt to a coding agent (Copilot CLI, Cursor, Claude Code, etc.)
to generate the application from this spec.

---

You are building **Personal Agent v0 (Launch-App Spike)**. Everything you need is in this folder.

**Context loading order:**

1. Read `../idea.md` end-to-end. Internalize the users and success criteria.
2. Read `../spec/` in the order listed in `../spec/README.md` (or alphanumeric
   if no order is given).
3. Skim `../plan/` for known issues — do NOT reintroduce them.
4. Look at `../assets/` for mocks. If a mock contradicts the text spec,
   prefer the mock and flag the contradiction in your output.

**Output:**

- Generate the application in a **new directory** (`../../../<slug>-app/` or
  a separate repo). Do not modify any files in this repo.
- Produce a clean, runnable scaffold:
  - Repo init with `.gitignore`, `README.md` linking back to this spec folder.
  - Build/run commands documented.
  - At least one happy-path test.
- Pick the tech stack listed in `spec/README.md` unless the user overrides.
- Stop and ask if any spec point is ambiguous. Do not invent behavior.

**Quality bar:**

- Code compiles / runs on first try.
- README has install + run in ≤3 commands.
- No TODOs in committed code — either implement, or open an issue and
  reference the issue number.

**Out of scope (don't do unless asked):**

- Hosting setup
- CI/CD pipelines
- Production secrets

