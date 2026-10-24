# Life OS — personal life hub

> **A personal chief of staff that knows the owner's whole life from the
> owner's own records.** One private app for an individual and their household
> where each life area is a box — Finance, Health, Career & Learning, Family,
> Notes & reminders, Reflection, Documents, Conversations — and one Ask box
> answers any question by looking across all the boxes, with deterministic,
> traceable calculations behind every number. Local-first and free to host: a
> home server reached over a private network, and the same engines offline on
> every device with end-to-end encrypted sync.

- **Build repo:** [`DDancingDeath/personal-ai-cfo`](https://github.com/DDancingDeath/personal-ai-cfo)
  (private) — owns code, issues, milestones and ADRs. This folder stays the
  idea of record.
- **Working title:** Life OS (final name open).

---

## The idea

Life admin is scattered across bank apps, PDF lab reports, folders of
documents, chats and memory, yet the questions that matter cross all of them.
Life OS absorbs what the owner already has, turns it into connected facts that
each cite their source, puts each life area in a **box** behind one contract,
and answers questions through one **Ask** box with numbers you can trace to
their inputs. It also nudges before things matter — an FD maturing, a passport
expiring, a statement that didn't arrive. Details: [`idea.md`](./idea.md).

Target users: one individual (the owner) and their household. Not for
advisers, shared use, work data, or anyone wanting the app to move money or
diagnose.

Success: cross-area questions answered in seconds with every number
traceable; missing inputs asked for, never defaulted; works offline; zero
running cost; no readable personal data off the owner's devices.

Non-goals: write access to accounts, diagnosis, multi-user, social features,
call recording.

---

## How it works

```
 Home (Your week · top priorities · coming up)        Ask (one question box)
            │                                              │ route → run tools → compose
            ▼                                              ▼
 ┌────────┬────────┬─────────┬────────┬─────────┬────────────┬───────────┬──────────────┐
 │Finance │ Health │ Career &│ Family │ Notes & │ Reflection │ Documents │ Conversations│  ← boxes: one contract
 │        │        │ Learning│        │reminders│            │           │              │
 └────────┴────────┴─────────┴────────┴─────────┴────────────┴───────────┴──────────────┘
            ▼                      ▲ drafts → review queues → owner applies
   Life graph: facts with provenance (source document + page)
            ▼
   Deterministic, versioned engines (inputs_sha256 + engine_version on every result)
```

Each box implements the same contract (manifest, glance, facts, tools,
recommendations, missing, reminders); Home, nudges and Ask use nothing else.
Sources (folders, statements, mail, chat exports) only ever produce **drafts**
that the owner reviews. Ask is deterministic routing plus deterministic
composition; an AI provider, if enabled, may only phrase or plan and is
checked against the tool outputs.

**One brain, many apps.** One identity and one Knowledge Core hold every
shared fact (people, accounts, dates, goals…) once, with its source and review
state. Apps are life areas (Finance, Health, Career & Learning, Family, Notes
& reminders, Reflection), each usable on its own; sources (folders /
documents, chats, email, statements, prices) feed them through review; *Me*
holds about me, the household and the identity vault. An app asks for only
the context its policy allows, and every grant is recorded. Life OS sits on
top as the coordinator: *Today*, with trade-offs, never deciding silently.
Details: [`spec/architecture.md`](./spec/architecture.md).

Two modes run the same UI and engines: a **home server** on the owner's PC
(loopback only, published on the private network, password sign-in) and a
**website / installed app** running the engines in the browser. Anything that
leaves a device is end-to-end encrypted; relays see ciphertext only.

---

## What it does today (and what's next)

Status: in build (live status in the build repo).

Built: Finance (net worth, cash flow, loans, projections, goals, ranked
recommendations, statement and document imports, live prices, read-only
mailbox and SMS drafts with a review queue), Health (report upload, review,
judging only against the lab's printed ranges or owner targets, OCR as draft),
Career & Learning, Family (ages, stages, milestones, vaccinations, education
goal links), Notes & reminders (repeat rules, cross-box feed, calendar feed),
Reflection (private journal, aggregates only to Ask); Ask across boxes with
thread context and the weekly life brief; home-server mode; website mode with
encrypted backup and sync.

Next: owner setup and real data (M3a/M4), cloud relay and website deploy
(M3b), native apps (M3c), then the chief-of-staff milestone — Documents box,
life graph, identity vault, proactive nudges, spending insights and tax report
(M5) — and Conversations (M6). See [`plan/README.md`](./plan/README.md).

---

## Tech stack

Negotiable for a rebuild. Part of the contract: the box contract, the Ask
answer contract, deterministic engines with JSON Schemas, `inputs_sha256` +
`engine_version` on every result, the privacy and encryption rules, and the
data-document versioning. Suggested stack: [`spec/README.md`](./spec/README.md#tech-stack-suggested-not-mandatory).

---

## Related ideas

Finance → [personal-ai-cfo](../personal-ai-cfo/) · Family →
[parenting-companion](../parenting-companion/) · Notes & reminders →
[notes-reminders](../notes-reminders/) · Reflection →
[reflective-friend](../reflective-friend/) · child learning →
[learning-companion](../learning-companion/).

## Reading order for an agent

1. `idea.md` — north star, users, constraints, open questions.
2. `spec/README.md` — source of truth for **what to build**; sets the reading
   order of the other spec files.
3. `plan/README.md` — milestones, known issues, decision log. **Do not
   reintroduce** known issues.
4. `prompts/build-from-spec.md` — paste this to a coding agent.

## Layout

```
life-os/
├── README.md           ← (this doc) the narrative entry point
├── idea.md             ← vision in detail
├── spec/               ← functional source of truth (README, glossary, configuration,
│                         contracts, cross-cutting, privacy, encryption, boxes/)
├── plan/               ← roadmap, known issues, decision log
├── prompts/            ← ready-to-paste agent prompts
└── assets/             ← mockups, screenshots, diagrams
```

## Recent changes

- _2026-10-22_ · initial scaffold; idea, spec (box contract, Ask answer contract, privacy rules, no-defaults rule, glossary, configuration), plan and build prompt captured
- _2026-10-22_ · north star (personal chief of staff, six pillars) added to idea and spec
- _2026-10-22_ · spec split into focused files: glossary, single configuration registry (incl. crypto parameters), box contract, Ask contract (aspects, suggestions, caveats, needs_input, thread context, life brief, refusal scope, safety invariants, AI provider rules), cross-cutting rules (dates/time zone, no defaults, samples, versioned saves, backups, accessibility), privacy & security (home-server access, sessions and scopes), encryption & sync
- _2026-10-22_ · per-box specs: Finance (live data, review queue, auto-apply, freshness, document and statement imports, FD maturity, spending insights, tax report), Health, Career & Learning, Family (birth date from a birth certificate), Notes & reminders, Reflection, Documents, Conversations
- _2026-10-22_ · added life graph, nudges catalogue and identity vault; worked example of a career-break question across five boxes
- _2026-10-22_ · hosting decision (home server now, encrypted sync next) stated as fact; open questions now: life graph, proactive engine, AI provider, app name, whose learning, cloud relay, iOS, desktop shell, Conversations phone access, commitment detection, Telegram
- _2026-10-22_ · plan: current status, milestones M1–M6 with status, known issues, decision log (hosting, encryption, no Account Aggregator for individuals, no scraping, price sources, work data and call audio out of scope)
- _2026-10-25_ · one brain, many apps: new spec files `architecture.md` (layers, components, Knowledge Core with shared entity types and review states, invariants, Today coordinator), `context-policy.md` (policy document, levels, sensitivity classes, retrieval rules, default grants) and `apps-and-modes.md` (apps vs sources vs Me, standalone/connected, platform vs personal configuration); box contract gains `kind` and `shared`; Documents and Conversations become sources; life-graph storage question closed; plan M7 and two decisions
