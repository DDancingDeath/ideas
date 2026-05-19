# AGENTS.md — Orientation for AI agents

You (the agent) are looking at a **specs + plans repository**, not a codebase.
Nothing here gets built or deployed. The goal is for you to be able to take an
idea folder and produce a working application elsewhere.

## Repo shape

```
projects/<slug>/
├── README.md     ← always start here. Tells you which files matter and in what order.
├── idea.md       ← problem, users, success criteria. Read for context.
├── spec/         ← functional source of truth. THE WHAT.
├── plan/         ← roadmap + known issues. THE HOW + ORDER.
├── prompts/      ← curated prompts to hand to a coding agent.
└── assets/       ← images: mockups, screenshots, diagrams.
```

## How to read a project

1. **`projects/<slug>/README.md`** — **the narrative entry point.** It
   opens with the idea, walks you through how the system works, lists
   what it does today, the tech stack, and the known issues, and ends
   with a reading order that points into the rest. If you only read one
   file per project, read this one. New projects follow
   `_templates/project-readme.md`.
2. **`idea.md`** — deeper version of the idea: who is this for, success
   criteria, non-goals, open questions. Don't skip; it changes your
   design choices.
3. **`spec/`** — the canonical spec. If there's a `spec/README.md`, follow its
   reading order. If `spec/page-specs/` exists, read each page spec.
4. **`plan/`** — read `review-issues.md` (known defects, do not reintroduce)
   and any roadmap docs. These constrain priority, not the spec itself.
5. **`prompts/`** — if present, these are pre-written prompts for handing off
   to a code-generating agent. Treat them as the entry point for a "build
   this" job.
6. **`assets/`** — visuals. Use them to disambiguate the spec when text is
   not enough (always prefer image truth over text when they conflict, **but
   flag the conflict to the user**).

## Authoring rules (when modifying this repo)

- **Never delete user-authored content** without confirmation. Move it to a
  `archive/` subfolder inside the project instead.
- **Spec changes need a one-line entry** in the project README under a
  "Recent changes" list with a date.
- **Plans may be opinionated**; specs must stay factual. Don't smuggle
  opinions into `spec/`.
- **Mockups go in `assets/`**, never inline base64. Reference them with
  relative paths: `![Login mock](../assets/login-mock.png)`.
- **No secrets** — API keys, connection strings, internal URLs. If you find
  any, redact and warn.

## When the user says "build the app"

If a `prompts/build-from-spec.md` exists, that is the contract. Follow it.
Otherwise:

1. Confirm the target stack with the user (don't assume).
2. Generate code in a **separate repository or directory**, never in
   `projects/<slug>/`. This repo stays docs-only.
3. Cross-link: in the generated repo's README, link back to the spec folder
   here.

## When the user says "review the spec"

Read the spec end-to-end. Produce findings as a markdown report. Do not
modify spec files unless explicitly asked. If asked to update, preserve the
original wording where possible and call out every behavioral change in a
"Changes" list at the top of the file.
