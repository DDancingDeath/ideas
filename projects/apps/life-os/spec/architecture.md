# Architecture — Life OS

Life OS is **one brain with many apps**: one identity, one Knowledge Core of
shared facts, one shared intelligence layer, many apps for life areas, and a
coordinator on top. This file defines the layers, components and invariants.
How apps receive context: [context-policy.md](context-policy.md). Apps,
sources, Me, modes and configuration: [apps-and-modes.md](apps-and-modes.md).
Terms: [glossary.md](glossary.md).

## Layers

```
 Personal assistant (Ask, from the coordinator or inside any app)
 ┌──────────────────────────────────────────────────────────────────────┐
 │ 5 Coordinator   Today · nudges · life brief                          │
 │ 4 Apps          life areas (+ Me)  — own experience, scoped Ask      │
 │ 3 Intelligence  context under policies · box engines (deterministic) │
 │ 2 Knowledge Core  shared facts, provenance, review states            │
 │ 1 Sources       connectors → drafts → review queues                  │
 └──────────────────────────────────────────────────────────────────────┘
   cross-cutting: identity & access · notifications · configuration · sync
```

| # | Layer | Promises |
| --- | --- | --- |
| 1 | Sources | A source document or message enters once (identified by its SHA-256) and is read into drafts; nothing changes until the owner applies a draft (or an auto-apply the owner turned on applies it). |
| 2 | Knowledge Core | The single canonical home of every shared fact, independent of every app. |
| 3 | Intelligence | Retrieves the context a request needs under the requesting app's [context policy](context-policy.md); applies cross-domain constraints; separates facts from uncertainty; every number comes from a box calculation. |
| 4 | Apps | Each life area is its own experience (own entry point, screens, workflows, preferences, scoped Ask) over the same core. |
| 5 | Coordinator | Weighs all life areas for *Today* and *Your week*, shows trade-offs, never decides or writes without the owner's confirmation. |

## Components

| Component | Responsible for | Never |
| --- | --- | --- |
| Identity & Access | The owner's identity, sign-in, sessions and scopes, re-authentication for Reveal, vault keys ([privacy-security.md](privacy-security.md), [encryption-sync.md](encryption-sync.md)) | Accepts a sync session as an app session |
| Knowledge Core | Shared facts with provenance and review state, conflicts, link decisions, history; the core API | Holds an identity value (only its masked reference), note text, journal text or message text |
| Data ingestion | Sources, schedules, de-duplication by SHA-256, extraction to drafts, sync status, review queues | Applies a draft without the owner (except auto-apply the owner turned on; never for identity facts) |
| Intelligence | Context retrieval under policies, Ask routing and composition, assumptions, clarification, audit of context grants | Computes a number; returns context a policy does not grant |
| Box engines | Deterministic, versioned calculations and the box's domain records | Holds the only copy of a shared fact; produces a balance, diagnosis or date not derived from the owner's data |
| App shells | An app's entry point, screens, workflows, preferences, scoped Ask, links into other apps | Reads another box's data documents |
| Coordinator | *Today*, nudges ([nudges.md](nudges.md)), the life brief ([ask.md § Life brief](ask.md#life-brief)), ranking, trade-offs | Writes or schedules anything without confirmation |
| Notifications | Reminders feed, calendar feed, notifications | Puts a personal value in a notification or the calendar feed |

## Knowledge Core

The Knowledge Core is the life graph ([life-graph.md](life-graph.md)) made
canonical: the graph's entities, observations, links and rules G1–G6 are the
core's content; boxes no longer keep their own copy of a shared fact.

### Shared entity types (canonical in the core)

| Type | Examples |
| --- | --- |
| Person | Owner, household members, confirmed contacts |
| Household | The owner's household and its members |
| Organisation | Employer, bank, insurer, lab, school |
| Account | Bank account, deposit, investment account, loan account, card |
| Asset | Holding, property, deposit |
| Liability | Loan, card due |
| Policy | Life, health or other insurance policy |
| Document | A source document's identity (type, dates, about whom); never its file |
| Identity fact reference | Masked value and vault reference only; the value stays in the [identity vault](identity-vault.md) |
| Event | Birthday, maturity, expiry, renewal, appointment, retest, review, any dated fact |
| Goal | A goal with its target date and the people it is for |
| Commitment | A promise with a due date, from a source or the owner |
| Note metadata | Title, topic, tags, dates, links; never the note's text |

### Domain records (stay in their box)

| Box | Domain records |
| --- | --- |
| `finance` | Transactions, statements, balances over time, loan schedules, projections, tax computations |
| `health` | Reviewed reports, result tables, reference ranges, trends |
| `career` | Skill levels, learning sessions, path scores, learning plan |
| `family` | Milestone log, vaccination doses, life-stage catalogue |
| `notes` | Note text, reminder repeat state |
| `reflection` | Journal entries, reviews |
| `documents` | Library index, extracted text, classification |
| `conversations` | Messages (encrypted), per-source retention |

A domain record refers to shared facts by their core id; it never copies a
shared fact's value.

### Review states

Every fact in the core has exactly one review state.

| State | Meaning | May be a calculation input |
| --- | --- | --- |
| `owner_entered` | Typed or chosen by the owner | yes |
| `verified` | Read from a source and confirmed by the owner (applied draft) | yes |
| `draft` | Read from a source, awaiting review ([glossary § Draft](glossary.md#hub-and-boxes)) | no |
| `ai_interpretation` | Proposed by an AI provider | no; always labelled, never shown as a fact |

### Core API

| Operation | Rule |
| --- | --- |
| Read: get, query by type and attributes, neighbours, timeline, history | Returns facts with provenance and review state; reads by an app pass through its [context policy](context-policy.md) |
| Write: propose, apply, reject, retract | Versioned ([cross-cutting.md § Versioned saves](cross-cutting.md#versioned-saves-and-conflicts)); every write appended to the core's history with who and when |
| Link decisions: merge, split, not-the-same, link | As life-graph rule G2; kept in the core's history |

Core data are ordinary data documents: atomic, versioned, backed up and synced
end-to-end encrypted like every other data document.

## Invariants

| # | Invariant |
| --- | --- |
| A1 | No box holds the only copy of a shared fact. |
| A2 | A box reads and writes shared facts only through the core API, and never reads another box's data documents. |
| A3 | A source document enters once; every box that needs its values receives them as drafts from that one entry. |
| A4 | Every fact has provenance and a review state; `draft` and `ai_interpretation` facts are never calculation inputs. |
| A5 | No app has to understand the owner's whole life: it asks the intelligence layer for context, which applies the app's context policy, returns the minimum necessary and records the grant. |
| A6 | Every number in an answer comes from a deterministic box calculation. |
| A7 | The platform, not an app, is responsible for identity, provenance, permissions and consistency. |
| A8 | Installing or enabling another app connects it to the same identity and core with no migration ([apps-and-modes.md § Modes](apps-and-modes.md#modes)). |

## Coordinator: Today

| Rule |
| --- |
| *Today* lists, grouped by app: nudges and reminders that are overdue or due on Today, and the top recommendations — each with its evidence and a link. |
| Order within and across groups is the [priority order](box-contract.md#priority-order). |
| Two items **compete** when they refer to the same shared fact (e.g. one deposit offered to a goal and to a loan prepayment) or fall on the same date for the same person. Competing items are shown together as a trade-off: each option, what it affects in each life area, and its evidence. |
| *Today* offers options, never a decision; any write goes through the item's own confirmation. |
| Ask "What should I prioritise today?" answers with *Today*; "why is this first?" names the ranking keys that placed it. |
| The coordinator reads context through its own [context policy](context-policy.md#default-grants). |
