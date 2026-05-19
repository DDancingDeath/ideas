# Copilot instructions for this repository

This is a **docs + specs repository**, not a codebase. Read
[`AGENTS.md`](../AGENTS.md) in the repo root before doing anything else.

Key rules:

- Treat each `projects/<slug>/` folder as a self-contained idea.
- The canonical spec lives in `projects/<slug>/spec/`. Plans and known issues
  live in `projects/<slug>/plan/`.
- Never invent specs. If something is unclear, ask the user or note it as
  `TODO(spec)` in a draft block — don't silently fill the gap.
- When the user asks you to build an application from a project, generate
  code in a *separate* directory or repo. This repo stays docs-only.
- Mockups, screenshots, and diagrams go under `projects/<slug>/assets/`.
- No secrets in any file. Redact if found.

Templates for new ideas: `_templates/`.
