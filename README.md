# ideas

Personal knowledge base for ideas, specs, and plans — **structured so an AI
coding agent can read one folder and build the application from it**.

Owner: [@DDancingDeath](https://github.com/DDancingDeath)
Visibility: private.

---

## What lives here

Each idea becomes a self-contained folder under [`projects/`](./projects),
grouped by kind:

- **[`projects/apps/`](./projects/apps)** — real products (in production
  or a working POC).
- **[`projects/agents/`](./projects/agents)** — AI agent ideas (personal
  utilities, team-facing teammates, intern-project pitches).

One folder = one product / experiment / utility.

```
projects/<kind>/<slug>/
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

## Adding new things

Three one-liners. See [`CONVENTIONS.md`](./CONVENTIONS.md) for the full
contract and [`tools/README.md`](./tools/README.md) for prerequisites.

```powershell
# 1. Add a new idea (a new folder in this repo)
.\tools\add-idea.ps1 -Slug my-new-idea -Kind agents `
                     -Title "My new idea" -Pitch "One paragraph."

# 2. Add a new skill (new GitHub repo, or PR to internal ADO)
.\tools\add-skill.ps1 -Slug my-skill -Target github

# 3. Add a new agent
.\tools\add-agent.ps1 -Slug my-agent -Target github
```

Each script scaffolds from [`_templates/`](./_templates), commits with
the `Co-authored-by: Copilot` trailer, and pushes. Use `-NoPush` /
`-NoCommit` to inspect before publishing.

---

## How an agent should use this repo

1. Read [`AGENTS.md`](./AGENTS.md).
2. Read the project's `README.md` (it points to the canonical spec + plan).
3. If a `prompts/build-from-spec.md` exists, follow it.
4. When unsure, prefer `spec/` over `plan/` (spec is the source of truth for
   *what to build*; plan is for *order and status*).

---

## Projects

Grouped by kind. **Complexity** is a rough build-effort estimate:

| Level | Meaning |
| --- | --- |
| Low | Spike or single-purpose tool; days, one platform, few integrations. |
| Medium | A focused product or agent; weeks, a few integrations. |
| High | Multiple subsystems, external data or AI pipelines, or notable privacy/safety work; months. |
| Very high | Multi-platform or multi-component system with sensitive data, regulation or long-horizon roadmap; many months. |

**Agent-doable** is a rough estimate of the share of the effort (design, code, tests, docs) a coding agent can complete independently, with the human limited to decisions, review, accounts/devices, real-world data, and legal or safety sign-off. Treat it as an indicative figure, not a commitment.

### Apps — real products

| Slug | Complexity | Agent-doable | One-liner | Status |
| --- | --- | --- | --- | --- |
| [aadhat-management](./projects/apps/aadhat-management) | Medium | ~70% | Hindi/English wholesale-retail business management app (Firebase + Capacitor). | In production; spec frozen, security hardening pending. |
| [cross-device-personal-agent](./projects/apps/cross-device-personal-agent) | Very high | ~55% | iOS app + cloud control plane + device agents on each of my dev boxes — run commands on my machines from the phone (Phase 1), receive notifications from agents (Phase 2), drive it in natural language (Phase 3), chain into multi-agent workflows (Phase 4). | Idea — design captured (rescoped 2026-06-06 from notification inbox to cross-device personal agent; folder renamed from `agent-companion`); no prototype yet. |
| [remote-app-launcher](./projects/apps/remote-app-launcher) | Low | ~90% | Weekend spike of [cross-device-personal-agent](./projects/apps/cross-device-personal-agent): type `notepad` on the phone → notepad opens on the dev box. One command kind, one device, shared-secret auth, in-memory storage, Expo Go. ~500 LoC, ≤12 h build target. Designed for a parallel 3-agent build (backend/agent/phone) with a frozen contracts file and per-track prompts; sequential single-agent fallback also documented. | Idea — fully designed, code not started; ready to build. |
| [identityposc](./projects/apps/identityposc) | High | ~50% | POC for shop-floor ambient identity from CCTV (camera + mic) — learns who people are by overhearing how they're addressed. | POC complete (F1 80 % on Tears of Steel, recall 100 %); next phase is production hardening. |
| [learning-companion](./projects/apps/learning-companion) | Very high | ~55% | Child-centered, curriculum-aware learning companion with adaptive teaching, independent mastery and retention checks, deadline-aware replanning, and evidence-based parent insights. | Idea/specification capture; full design, phased roadmap and build brief imported; launch scope, stack and progression criteria remain open. |
| [life-os](./projects/apps/life-os) | Very high | ~50% | Umbrella personal life hub: each life area is a box (Finance, Health, Career & Learning, Family, Notes & reminders, Reflection) behind one contract, and one Ask box answers any question across all boxes with deterministic, traceable calculations; local-first, free hosting (home server over a private network now, offline engines + end-to-end encrypted sync next). Boxes draw on [personal-ai-cfo](./projects/apps/personal-ai-cfo), [parenting-companion](./projects/apps/parenting-companion), [notes-reminders](./projects/apps/notes-reminders), [reflective-friend](./projects/apps/reflective-friend). | Idea + spec captured 2026-10-22 (box contract, Ask answer contract, privacy and no-defaults rules); in build in a separate private repo; app name, AI provider, iOS and desktop shell undecided. |
| [notes-reminders](./projects/apps/notes-reminders) | Medium | ~70% | Voice-first AI memory & knowledge app — speak naturally; embeddings route the note to the right topic (or create a new one), each topic keeps its own summary, timeline, open actions, related topics. No folders, no tags, no filing. | Idea pivot 2026-06-06 from type-classifier to topic-organised; mobile platform + embedding store undecided. |
| [parenting-companion](./projects/apps/parenting-companion) | High | ~60% | AI-driven parenting & child-growth companion — age-aware nutrition/habit/education guidance, growth tracking against WHO/IAP curves, vaccination reminders, plus long-term financial planning tied to education goals (Indian fee context + inflation). | Early-stage idea capture; platform (Flutter vs RN), AI provider, and Indian-fee dataset all undecided. |
| [personal-ai-cfo](./projects/apps/personal-ai-cfo) | Very high | ~45% | Personal financial intelligence app: unified net-worth/cash-flow view, deterministic projections, goal and life-event scenarios, and trustworthy prioritized recommendations; read-only and privacy-first. | Early-stage idea capture; full product spec imported; data sources, V1 scope and regulatory posture remain open. |
| [ai-work-companion](./projects/apps/ai-work-companion) | High | ~60% | Local-first personal AI work intelligence & learning assistant: learns from the AI work you record, recommends better models/agents/tools/techniques grounded in evidence, and builds a work-driven learning path. | Early-stage idea capture; full product spec imported; integrations, discovery sources and local/cloud boundary remain open. |
| [reflective-friend](./projects/apps/reflective-friend) | Very high | ~40% | Always-on personal AI as a reflective guide and fair witness — passive ambient listening (opt-in, evidence-backed, never an arbiter), nightly reflection prompts, monthly growth summaries, in-conversation transcript recall, rehearsal practice. Same memory thread across years. | Early-stage idea capture; capture model (phone-only vs phone + wearable), LLM provider, recording-law model, and consent UX all undecided. Reflection-only v0 ships before any passive listening. |
| [wake-word-poc](./projects/apps/wake-word-poc) | Low | ~85% | Android POC that validates a wake-word pipeline end-to-end — say *"Hey Laddu"* and the app vibrates, shows a toast + 3 s on-screen confirmation, and speaks a fixed Text-to-Speech reply (*"Hey Hitesh"*), with a 5 s cooldown. Fully on-device / offline; no speech-to-text. Upstream spike for the aadhat-management in-app wake-word. | Idea — spec authored 2026-06-20 (Detection Behavior, TTS, cooldown, expected flow); wake-word engine (Porcupine / Vosk / TFLite / `SpeechRecognizer`) undecided for production (Porcupine planned); **POC built 2026-06-20** → [wake-word-poc-app](https://github.com/DDancingDeath/wake-word-poc-app) (Manual + SpeechRecognizer detectors, Porcupine stub; core unit-tested). |

### Agents — AI agent ideas

| Slug | Complexity | Agent-doable | One-liner | Status |
| --- | --- | --- | --- | --- |
| [winui-expert-teammate](./projects/agents/winui-expert-teammate) | High | ~50% | An AI teammate for the WinUI team — one brain, many surfaces (Teams, Outlook, GitHub/ADO, Agency); identity, memory, proactive behaviour layered onto existing WinUI agents. | Pitched as intern project; phased delivery plan ready. |
| [inbox-triage](./projects/agents/inbox-triage) | Medium | ~65% | Personal AI that watches my mail, Teams, PRs, and bugs and tells me what's worth doing today (Microsoft-internal). | Early-stage idea capture; open decisions on surface + runtime. |
| [prompt-optimizer](./projects/agents/prompt-optimizer) | Medium | ~70% | An agent that makes me better at using AI — by rewriting prompts in flight, replaying my sessions, or coaching me in real time. | Early-stage idea capture; three competing shapes on the table. |
| [ado-bugfixer](./projects/agents/ado-bugfixer) | High | ~65% | Agency-mode agent that walks my ADO bug list and proposes fixes — draft PRs, root-cause notes, dupe calls. Personal-scope. | Early-stage idea capture; needs area allow-list + audit of existing internal tools. |
| [agent-guidelines-hub](./projects/agents/agent-guidelines-hub) | Low | ~90% | A single source of truth for my cross-project agent guidelines that propagates by default into every repo I own, so any agent starting work already follows my rules without me pasting them in each time. | Idea — captured 2026-06-20 (problem, design sketch, open decisions); no build yet, parked to work on later. |
