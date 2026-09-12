# Functional spec — <Project name>

This is the **source of truth for what to build**. An agent reading only this
folder should be able to produce a working application.

> Write to the crispness contract in [`AGENTS.md`](../AGENTS.md): one fact one
> home, never cite a value you did not define, one vocabulary per concept,
> examples must obey their own invariants, normative content only, tables over
> prose. No `## Recent changes` block in this file — the project README holds
> the single changelog.

## Reading order

1. This file (overview).
2. `capabilities.md` — feature inventory.
3. `page-specs/` — one file per screen/route, in numeric order.
4. Any `*-design.md` files — cross-cutting design (data model, rules, etc.).

## Overview

- **What it does** (1 paragraph).
- **Who it's for**.
- **Primary user journeys** (3-5 bullet flows).

## Tech stack (suggested, not mandatory)

- Frontend:
- Backend / data:
- Auth:
- Hosting:
- Mobile (if any):

State the stack so the agent doesn't have to guess. Mark anything negotiable
with `(suggested)`.

## Glossary and vocabulary

Define every domain term, severity scale, and state machine **once**, here or
in a linked file. One name per concept — a second name for the same thing is a
spec bug. Agents grep this before inventing a term.

- **<Term>** — definition.
- **Severity scale** — the single scale used everywhere (runtime flags, CI
  gates, release blockers). Do not let a second scale appear in `plan/`.

## Constants and configuration (single home)

**Every** threshold, timeout, limit, retry count and tunable lives in this one
table. Other documents reference a key; they never restate its value.

| Key | Scope | Type / unit | Default | Editable by | Used by |
| --- | ----- | ----------- | ------- | ----------- | ------- |
|     |       |             | or `required — no default` | | |

Naming: one unit suffix vocabulary (`Paise`, `Grams`, `Seconds`, `Minutes`,
`Days`), consistent camelCase, plural namespaces.

## Data model (high level)

Per-entity bullets. Detail goes in `*-design.md`.

- **<Entity>** — fields, who can read/write, lifecycle.

## Non-functional requirements

- Performance:
- Offline support:
- Accessibility:
- i18n / l10n:
- Security baseline:

## Worked example

One end-to-end trace: input → events → state → what the user sees. It must
obey every invariant and formula above — recompute the arithmetic before
committing, because this is the section implementers copy from.

## Open questions

Each entry states the question, the milestone it blocks, and a recommended
default so work can proceed:

- `TODO(spec, blocks: M<N>)` — <question>? **Default:** <recommendation>.

When a decision is confirmed in `plan/`, delete the entry here in the same
commit and assert the decision as fact.

## Out of scope

What the spec deliberately doesn't cover (yet).
