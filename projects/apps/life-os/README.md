# Life OS — personal life hub

> One private app for an individual and their household where each life area is a box — Finance, Health, Career & Learning, Family, Notes & reminders, Reflection — and one Ask box answers any question by looking across all the boxes, with deterministic, traceable calculations behind every number. Local-first and free to host: a home server reached over a private network now; offline engines on every device with end-to-end encrypted sync next.

- **Build repo:** [`DDancingDeath/personal-ai-cfo`](https://github.com/DDancingDeath/personal-ai-cfo)
  (private) — owns code, issues, milestones and ADRs. This folder stays the
  idea of record. Captured from [personal-ai-cfo#43](https://github.com/DDancingDeath/personal-ai-cfo/issues/43).
- **Working title:** Life OS (final name open).

---

## The idea

Life admin is scattered across bank apps, PDF lab reports, notes and memory,
yet the questions that matter cross all of them. Life OS puts each area in a
**box** behind one contract, and one **Ask** box that routes a question to the
right calculations in every box and answers with numbers you can trace to
their inputs. Details: [`idea.md`](./idea.md).

Target users: one individual (the owner) and their household. Not for
advisers, shared use, or anyone wanting the app to move money or diagnose.

Success: cross-area questions answered in seconds with every number traceable;
missing inputs asked for, never defaulted; works offline; zero running cost;
no readable personal data off the owner's devices.

Non-goals: write access to accounts, diagnosis, multi-user, social features.

---

## How it works

```
 Home (glances + top priorities)     Ask (one question box)
            │                                │ route → run tools → compose
            ▼                                ▼
   ┌────────┬────────┬─────────┬────────┬────────┬────────────┐
   │Finance │ Health │ Career &│ Family │ Notes &│ Reflection │  ← boxes: manifest, glance,
   │        │        │ Learning│        │reminders│           │    facts, tools, recs, missing
   └────────┴────────┴─────────┴────────┴────────┴────────────┘
            ▼
   Deterministic, versioned engines (inputs_sha256 + engine_version on every result)
```

Each box implements the same six-member contract; the hub and Ask use nothing
else. Ask is deterministic routing + deterministic composition; an AI
provider, if ever enabled, may only phrase or plan and is checked against the
tool outputs.

---

## What it does today (and what's next)

Status: in build (see the build repo for live status).

Milestones: M1 Finance foundation → M2 Life OS hub → M3a home server → M3b
offline + encrypted sync → M3c native apps → M4 your data & personalisation.
See [`plan/README.md`](./plan/README.md).

---

## Tech stack

Negotiable for a rebuild. Part of the contract: the box contract, the Ask
answer contract, deterministic engines with JSON Schemas, `inputs_sha256` +
`engine_version` on every result, and the privacy rules in
[`spec/README.md`](./spec/README.md).

---

## Related ideas

Finance → [personal-ai-cfo](../personal-ai-cfo/) · Family →
[parenting-companion](../parenting-companion/) · Notes & reminders →
[notes-reminders](../notes-reminders/) · Reflection →
[reflective-friend](../reflective-friend/) · child learning →
[learning-companion](../learning-companion/).

## Reading order for an agent

1. `idea.md` — vision, users, constraints, open questions.
2. `spec/README.md` — source of truth for **what to build**; links to the
   box specs.
3. `plan/README.md` — milestones, known issues, decision log. **Do not
   reintroduce** known issues.
4. `prompts/build-from-spec.md` — paste this to a coding agent.

## Layout

```
life-os/
├── README.md           ← (this doc) the narrative entry point
├── idea.md             ← vision in detail
├── spec/               ← functional source of truth
├── plan/               ← roadmap + known issues
├── prompts/            ← ready-to-paste agent prompts
└── assets/             ← mockups, screenshots, diagrams
```

## Recent changes

- _2026-10-22_ · initial scaffold; idea, spec (box contract, Ask answer contract, privacy rules, no-defaults rule, glossary, configuration), plan and build prompt captured
