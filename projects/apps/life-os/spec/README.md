# Functional spec — Life OS — personal life hub

This is the **source of truth for what to build**. An agent reading only this
folder (plus the linked box ideas) should be able to produce a working
application.

> Written to the crispness contract in [`AGENTS.md`](../../../../AGENTS.md).
> The project README holds the single changelog.

## Reading order

1. This file — overview, glossary, box contract, Ask contract, privacy rules,
   configuration.
2. Box detail, where a box has its own idea: Finance →
   [personal-ai-cfo spec](../../personal-ai-cfo/spec/product-spec.md); Family →
   [parenting-companion spec](../../parenting-companion/spec/README.md);
   Notes & reminders → [notes-reminders spec](../../notes-reminders/spec/README.md);
   Reflection → [reflective-friend spec](../../reflective-friend/spec/README.md).
   Where a box spec conflicts with this file on the hub, box or Ask contract,
   this file wins.

## Overview

- **What it does.** A private hub for one household. Each life area is a
  **box**. The **home** shows every box's glance and the top priorities across
  all boxes. The **Ask** box takes a free-text question, routes it to the
  calculations of every relevant box, runs them, and composes one answer in
  which every number is traceable.
- **Who it's for.** One **owner** (the individual) and the people in their
  household profile. Only the owner signs in.
- **Primary user journeys.**
  1. Owner opens the home, sees each box's glance and *Top priorities across
     your life*, follows the first one.
  2. Owner asks *"Can I afford a car for ₹15 lakh next year?"* → answer with
     the affordability result, the aspects considered per box, suggestions,
     caveats and follow-ups; any missing input is asked for inline.
  3. Owner uploads a lab report in Health, reviews the extracted values,
     saves; Health's glance and facts update; Ask can now use them.
  4. Owner edits the household profile; every box that depends on it
     (dependents, ages) recomputes.
  5. Owner opens the app with the network off and gets the same results.

## Boxes

| Box id | Name | Holds | Calculations it must offer | Detailed spec |
| --- | --- | --- | --- | --- |
| `finance` | Finance | Accounts, investments, loans, income, spending, goals, assumptions | Projections, net worth, cash flow, loans, affordability, goal plans, recommendations | [personal-ai-cfo](../../personal-ai-cfo/spec/product-spec.md) |
| `health` | Health | Lab reports (reviewed values with the report's own reference ranges), check-up plan | Latest value vs reference range, trend, due check-ups, follow-up prompts | This file (§Health rules) |
| `career` | Career & Learning | Role history, skills (0–5 scale), target roles, learning resources | Skill gaps, ranked next paths, learning plan | This file |
| `family` | Family | People and relations from the household profile, child milestones, education goals | Dependents, education-goal links to Finance goals | [parenting-companion](../../parenting-companion/spec/README.md) |
| `notes` | Notes & reminders | Notes, reminders | Due reminders | [notes-reminders](../../notes-reminders/spec/README.md) |
| `reflection` | Reflection | Reflection entries | Prompts, summaries | [reflective-friend](../../reflective-friend/spec/README.md) |

A box is either `live` or `coming_soon`. A `coming_soon` box shows on the home
but contributes no facts, tools or recommendations.

## Box contract

Every box provides exactly these six members. The hub and Ask use nothing else.

| Member | Returns | Rules |
| --- | --- | --- |
| `manifest` | `{id, name, icon, tagline, status, order, nav[]}` | `status` ∈ {`live`, `coming_soon`}. |
| `glance` | `{headline {label, value, unit, format}, chip {label, tone}, lines[], missing_count, state, action, source}` | Built only from calculation outputs. `lines` ≤ 2. `format` ∈ {`inr`, `count`, `years`, `date`}. |
| `facts` | List of **facts** | See [Fact](#glossary). |
| `tools` | Map name → **tool** | Each tool has a JSON Schema for its inputs, a description and the document paths it reads. |
| `recommendations` | `[{id, domain, title, why, urgency, category, evidence, next_step, source_calc, rank_in_module}]` | `urgency` and `category` use the scales below. |
| `missing` | `[{id, domain, topic, impact, blocking, href}]` | One entry per data gap that affects a calculation. |

### Tool result

Running a tool with the stored documents plus optional per-answer overrides
returns `{tool, status, result, inputs_sha256, engine_version, needs[], notes[]}`.

| `status` | Meaning | `result` | `needs` |
| --- | --- | --- | --- |
| `ok` | Calculated | Present | Empty |
| `needs_input` | A required input is missing | Absent | Exact input paths + a form spec for each |
| `invalid` | An input failed its schema | Absent | Empty; `notes` names the failing path |
| `not_configured` | The box has no documents yet | Absent | Empty |

Overrides apply to that one run only and are never saved.

## Ask answer contract

An answer is composed **deterministically from tool outputs**. Its fields:

| Field | Content |
| --- | --- |
| `question` | The text as asked |
| `intent` | The routed intent id, or `fallback` |
| `answer_summary` | Sentences; every number in them is copied from a tool output or the question, with a `refs` entry giving its source path |
| `aspects_considered` | One entry per box: `used` / `missing_data` / `not_relevant`, the facts used, and each tool call with `inputs_sha256` and `engine_version` |
| `suggestions` | Ranked across boxes by the [priority order](#priority-order) |
| `caveats` | Unknown amounts shown as bounds, sample or illustrative data used, values used for this answer only |
| `follow_ups` | Suggested next questions |
| `disclaimers` | Per touched box (finance: not investment advice; health: not medical advice; career) |
| `needs` | Inputs to ask for inline when any tool returned `needs_input` |

Rules:

1. Routing is deterministic and inspectable: intents, their phrases and
   weighted keywords, and the tool plan per intent are data, not code.
2. Entities parsed from the question (amounts such as ₹15 lakh / 15L / 2 crore /
   20k, durations, dates, health test names, role names) override tool inputs
   for that answer only.
3. Any number in AI-written text that does not appear in the tool outputs or
   the question discards that text; the deterministic answer is shown with a
   caveat.
4. Every answer is appended to a local history with enough to reproduce it
   (question, intent, tool calls, `inputs_sha256`, engine versions).

### Priority order

*Top priorities across your life* and Ask `suggestions` sort by, in order:

1. `urgency`: `critical` > `high` > `medium` > `low` > `unrated`
2. `category`: `lab_critical` > `protection` > `liquidity` > `health_followup` > `debt` > `data` > `optimisation` > `growth`
3. box order: `ranking.domainOrder`
4. the box's own `rank_in_module`

## Privacy rules

| # | Rule |
| --- | --- |
| P1 | Readable personal data exists only on the owner's devices. Anything that leaves a device is end-to-end encrypted with a key only the owner holds. |
| P2 | Any relay or host stores ciphertext only and is replaceable without data loss. |
| P3 | No analytics, telemetry, third-party scripts or external fonts. |
| P4 | Access from another device requires owner sign-in; the server is reachable only over the owner's private network, never the public internet. |
| P5 | An external AI provider is used only when the owner has turned it on **and** shared every box the answer touches; names, employers, labs and document ids are masked before sending; only the routed intent's facts are sent. |
| P6 | Logs, histories and backups never contain passwords or session tokens. |
| P7 | Health output is factual and non-diagnostic; anything outside a reference range points to a doctor. |
| P8 | The owner can export all data as plain documents and delete it. |

## No-defaults rule

**Missing is never zero.** A calculation never substitutes a value for an
input the owner has not given. It returns `needs_input` with the exact path.
Settings with no agreed value are listed in the configuration table as
`required — no default` and the box reports them as missing until set. Sample
or illustrative data may be used only when labelled *sample* wherever it
appears, and the answer's `caveats` say so.

## Health rules

| Rule | Behaviour |
| --- | --- |
| Reference ranges | Judged only against the range printed on the report; no built-in ranges |
| Unreviewed values | Excluded unless `health.includeUnverified` is true |
| Trend | Shown only with at least `health.trendMinPoints` values; "stable" within `health.stableTolerancePct` |
| Critical flag | A value the lab marks critical gets urgency `critical`, category `lab_critical` |

## Glossary

- **Owner** — the one person who signs in and owns the data.
- **Household profile** — the people in the owner's household: relation
  (`self`, `spouse`, `child`, `parent`, `sibling`, `other`), birth date or
  age-on-a-date, `household_member`, `financially_dependent`, `co_owner`.
  Nothing is inferred.
- **Box** — one life area implementing the box contract.
- **Glance** — a box's tile on the home.
- **Fact** — `{fact_id, domain, statement, value, unit, date, source {box, calculation, engine_version, inputs_sha256, ref}, status, tags}`; a statement backed by a calculation output.
- **Tool** — a deterministic calculation a box exposes to Ask.
- **Engine version** — version string of the calculation code; changes whenever any output can change.
- **`inputs_sha256`** — SHA-256 of the canonical JSON of a calculation's inputs; equal inputs give equal hashes on every device.
- **Intent** — a class of question with a fixed tool plan across boxes.
- **Needs** — the list of missing inputs a tool reports.
- **Urgency** — `critical`, `high`, `medium`, `low`, `unrated`.

## Constants and configuration (single home)

| Key | Scope | Type / unit | Default | Editable by | Used by |
| --- | --- | --- | --- | --- | --- |
| `productName` | app | string | `Life OS` (working title) | build | All UI |
| `ranking.domainOrder` | Ask, home | list of box ids | `health, finance, family, career, notes, reflection` | owner | Priority order |
| `ask.provider` | Ask | `none` \| `local` \| `cloud` | `none` | owner | Ask rule 3, P5 |
| `ask.allowExternal` | Ask | bool | `false` | owner | P5 |
| `health.trendMinPoints` | Health | count | `required — no default` | owner | Health rules |
| `health.stableTolerancePct` | Health | percent | `required — no default` | owner | Health rules |
| `health.includeUnverified` | Health | bool | `required — no default` | owner | Health rules |
| `auth.sessionDays` | sign-in | days (1–365) | `required — no default` | owner | P4 |

## Non-functional requirements

- **Determinism:** same inputs → same outputs and `inputs_sha256` on every device.
- **Offline:** every box and Ask work with the network off once installed.
- **Performance:** an Ask answer within 3 seconds on a mid-range phone.
- **Accessibility:** keyboard-reachable; text alternatives for every chart.
- **Language:** English UI; Ask routing also understands common Hinglish.
- **Integrity:** every write is validated against the box's schema, atomic, and keeps a timestamped backup.

## Worked example

Owner asks *"Can I afford a car for ₹15 lakh next year?"* with Finance, Health
and Career configured and no insurance documents entered.

| Step | Result |
| --- | --- |
| Route | intent `afford_purchase`; entities: amount ₹15,00,000, timing next year |
| Plan | Finance affordability tool (amount and month overridden for this answer); Health and Career facts; Family dependents from the profile |
| Run | Finance `ok`; insurance cover missing → listed in Finance `missing` |
| Compose | `answer_summary` quotes only the affordability output's figures with `refs`; `aspects_considered`: finance `used`, health `used`, career `used`, family `used`; `caveats`: insurance cover unknown; `disclaimers`: finance |

## Open questions

- `TODO(spec, blocks: M4)` — Final app name? **Default:** keep `productName` = `Life OS`.
- `TODO(spec, blocks: M4)` — AI provider for Ask? **Default:** `ask.provider` = `none` (deterministic answers only).
- `TODO(spec, blocks: M3c)` — Native iOS app? **Default:** installable website on iPhone; no native iOS app.
- `TODO(spec, blocks: M3c)` — Desktop shell? **Default:** installable website; packaged desktop app only if the website cannot meet a requirement.
- `TODO(spec, blocks: Later)` — Whose learning plans? **Default:** the owner's in Career & Learning; a child's in Family.

## Out of scope

Write access to any financial account; diagnosis; more than one signing-in
user; public sharing.
