# Learning Companion

> A child-centered learning companion that turns a syllabus into an adaptive journey, checks demonstrated understanding and retention, replans after interruptions, and gives parents evidence-based progress and emerging-interest insights.

---

## The idea

Learning Companion is more than a chatbot on a tablet: it manages a child's
learning journey. Covering a chapter is not the same as understanding it, and
understanding it during a lesson is not the same as remembering it later.
The companion connects curriculum outcomes, teaching, assessment and planning
so that its next activity responds to evidence rather than a fixed playlist.

Children are the primary users; parents configure goals, permissions and
availability; content administrators approve curriculum and assessments.
Success means independently demonstrated understanding that survives later
recall, an honest view of deadline feasibility, and curiosity without pressure
to spend more time on screen. See [the idea](./idea.md) for the deeper goals,
first-release non-goals and unresolved questions.

---

## How it works

1. A parent sets up the learner and selects curriculum, language, availability
   and a target date. Approved sources become versioned learning objectives
   with prerequisites and traceable references.
2. A short diagnostic informs a dependency-aware plan. The child learns through
   explanations, stories, puzzles and supported visualizations, then answers
   questions that distinguish assisted success from independent understanding.
3. Durable learning events inform later revision and local or full replanning.
   The parent sees unresolved gaps, progress, uncertainty and useful next steps.
   Longer-term interest observations remain evidence-based and revisable.

The model proposes teaching actions; application services own curriculum,
grading, mastery, schedule and permissions. The [domain contract](./spec/system.md)
defines these boundaries; [architecture proposals](./plan/architecture.md)
explain the supplied modular-monolith recommendation.

---

## What it does today (and what's next)

**Status: idea/specification capture.** This folder contains the supplied
product design, not an application or evidence of educational efficacy.

- Curriculum ingestion, learning objectives and source validation.
- Adaptive teaching, objective-based assessment, revision and recovery.
- Child-friendly interactions, parent visibility, safety and privacy.
- Illustrative API/model contracts, phased roadmap, evaluation strategy and
  staged build instructions.

The [roadmap](./plan/roadmap.md) starts with a small end-to-end learning loop;
broader curriculum, advanced media and longitudinal development come later.
No numerical learning results or validated aptitude claims are supplied.

---

## Tech stack

Client, backend, storage, retrieval, AI provider and deployment selections are
**proposals, not confirmed decisions**. Their alternatives and rationale have
one home in [the architecture plan](./plan/architecture.md).

Durable relational learning data, versioned content, replaceable model
integrations, structured model output and deterministic domain authority are
part of the [build brief](./prompts/build-from-spec.md). Do not interpret the
suggested stack as permission to select technologies silently.

---

## Reading order for an agent

1. [idea.md](./idea.md) — problem, users, goals and non-goals.
2. [spec/README.md](./spec/README.md) — normative reading order, vocabulary,
   configuration and blocking decisions.
3. [plan/README.md](./plan/README.md) — rationale, scope, roadmap, known gaps,
   supplied research and source coverage.
4. [prompts/build-from-spec.md](./prompts/build-from-spec.md) — staged
   implementation brief for a separate application repository.

## Layout

```
learning-companion/
├── README.md           ← (this doc) the narrative entry point
├── idea.md             ← vision in detail
├── spec/               ← functional source of truth
├── plan/               ← roadmap + known issues
├── prompts/            ← ready-to-paste agent prompts
└── assets/             ← mockups, screenshots, diagrams
```

## Recent changes

- _2026-10-11_ · Fidelity pass against supplied source: restored dropped/weakened
  items, resolved proposal-vs-requirement status, recorded source-type decision,
  structural cleanup.
- _2026-10-10_ · Imported the complete supplied Learning Companion design into
  canonical specs, plans and prompts; indexed the idea and separated unverified
  research, implementation proposals and open decisions from product promises.
