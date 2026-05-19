# ideas

Personal knowledge base for ideas, specs, and plans — **structured so an AI
coding agent can read one folder and build the application from it**.

Owner: [@DDancingDeath](https://github.com/DDancingDeath)
Visibility: private.

---

## What lives here

Each idea becomes a self-contained folder under [`projects/`](./projects). One
folder = one product / experiment / utility.

```
projects/<slug>/
├── README.md         ← entry point. Read this first.
├── idea.md           ← the why: problem, users, north star
├── spec/             ← the what: functional spec, page specs, data design
├── plan/             ← the how: roadmap, review notes, promotion
├── prompts/          ← ready-to-paste agent prompts ("build this for me")
└── assets/           ← mockups, screenshots, diagrams
```

Reusable scaffolding:

- [`_templates/`](./_templates) — start a new idea from a template
- [`AGENTS.md`](./AGENTS.md) — orientation for AI agents
- [`.github/copilot-instructions.md`](./.github/copilot-instructions.md) —
  picked up by GitHub Copilot CLI / coding agent

---

## How to add a new idea

```bash
slug=my-new-idea
cp -r _templates projects/$slug
mv projects/$slug/idea.md projects/$slug/idea.md     # fill in the blanks
# write a project README that points to the idea + spec entry points
```

Then iterate: idea → spec → mocks in `assets/` → plan → prompt → build.

---

## How an agent should use this repo

1. Read [`AGENTS.md`](./AGENTS.md).
2. Read the project's `README.md` (it points to the canonical spec + plan).
3. If a `prompts/build-from-spec.md` exists, follow it.
4. When unsure, prefer `spec/` over `plan/` (spec is the source of truth for
   *what to build*; plan is for *order and status*).

---

## Projects

| Slug | One-liner | Status |
| --- | --- | --- |
| [aadhat-management](./projects/aadhat-management) | Hindi/English wholesale-retail business management app (Firebase + Capacitor). | In production; spec frozen, refactor pending. |
