# Functional spec — Personal Agent v0 (Launch-App Spike)

This is the **source of truth for what to build**. An agent reading only this
folder should be able to produce a working application.

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

## Data model (high level)

Per-entity bullets. Detail goes in `*-design.md`.

- **<Entity>** — fields, who can read/write, lifecycle.

## Non-functional requirements

- Performance:
- Offline support:
- Accessibility:
- i18n / l10n:
- Security baseline:

## Out of scope

What the spec deliberately doesn't cover (yet).

