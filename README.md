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
├── README.md         ← the narrative entry point. Idea first, then
│                       a tour of the detailings, then links into spec/.
├── idea.md           ← the why, in detail: problem, users, north star
├── spec/             ← the what: functional spec, page specs, data design
├── plan/             ← the how: roadmap, review notes, promotion
├── prompts/          ← ready-to-paste agent prompts ("build this for me")
└── assets/           ← mockups, screenshots, diagrams
```

**The project `README.md` is the canonical narrative doc.** Read it
top-to-bottom and you have: the idea, how the system works at a glance,
what it does today, the tech stack, the known issues, and a reading
order pointing into `spec/` and `plan/` for the deep details. New
projects should follow [`_templates/project-readme.md`](./_templates/project-readme.md).

Reusable scaffolding:

- [`_templates/`](./_templates) — start a new idea from a template
- [`AGENTS.md`](./AGENTS.md) — orientation for AI agents
- [`.github/copilot-instructions.md`](./.github/copilot-instructions.md) —
  picked up by GitHub Copilot CLI / coding agent

---

## How to add a new idea

```bash
slug=my-new-idea
mkdir -p projects/$slug/{spec,plan,prompts,assets}
cp _templates/project-readme.md projects/$slug/README.md
cp _templates/idea.md           projects/$slug/idea.md
cp _templates/spec.md           projects/$slug/spec/README.md
cp _templates/plan.md           projects/$slug/plan/README.md
cp _templates/build-prompt.md   projects/$slug/prompts/build-from-spec.md
touch projects/$slug/assets/.gitkeep
```

Then iterate: fill in the README narrative (idea → detailings → links) →
write idea.md → drop mocks in `assets/` → flesh out `spec/` → write the
build prompt.

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
| [aadhat-management](./projects/aadhat-management) | Hindi/English wholesale-retail business management app (Firebase + Capacitor). | In production; spec frozen, security hardening pending. |
| [identityposc](./projects/identityposc) | POC for shop-floor ambient identity from CCTV (camera + mic) — learns who people are by overhearing how they're addressed. | POC complete (F1 80 % on Tears of Steel, recall 100 %); next phase is production hardening. |
| [winui-expert-teammate](./projects/winui-expert-teammate) | An AI teammate for the WinUI team — one brain, many surfaces (Teams, Outlook, GitHub/ADO, Agency); identity, memory, proactive behaviour layered onto existing WinUI agents. | Pitched as intern project; phased delivery plan ready. |
| [assistant-inbox-triage](./projects/assistant-inbox-triage) | Personal AI that watches my mail, Teams, PRs, and bugs and tells me what's worth doing today (Microsoft-internal). | Early-stage idea capture; open decisions on surface + runtime. |
| [agent-prompt-optimizer](./projects/agent-prompt-optimizer) | An agent that makes me better at using AI — by rewriting prompts in flight, replaying my sessions, or coaching me in real time. | Early-stage idea capture; three competing shapes on the table. |
| [agent-ado-bugfixer](./projects/agent-ado-bugfixer) | Agency-mode agent that walks my ADO bug list and proposes fixes — draft PRs, root-cause notes, dupe calls. Personal-scope. | Early-stage idea capture; needs area allow-list + audit of existing internal tools. |
| [agent-notes-reminders](./projects/agent-notes-reminders) | Capture-first agent — voice/text in, auto-classified notes + scheduled reminders out — without me deciding where things go. | Early-stage idea capture; tenant + capture-surface undecided. |
