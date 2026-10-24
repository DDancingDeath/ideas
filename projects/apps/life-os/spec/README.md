# Functional spec — Life OS — personal life hub

This folder is the **source of truth for what to build**. An agent reading only
this folder (plus the Finance spec it links to) should be able to produce a
working application.

> Written to the crispness contract in [`AGENTS.md`](../../../../AGENTS.md).
> The project README holds the single changelog.

## North star

**A personal chief of staff that knows the owner's whole life from the owner's
own records.**

| # | Pillar | The system promises | Specified in |
| --- | --- | --- | --- |
| 1 | Absorbs what the owner already has | Document folders re-scanned on the owner's schedule; bank and investment statements; read-only email; tax documents (ITR, Form 16, AIS); medical reports; certificates; personal chat exports | [Documents](boxes/documents.md), [Finance](boxes/finance.md), [Health](boxes/health.md), [Conversations](boxes/conversations.md) |
| 2 | Understands them as connected facts | Every shared fact lives once in the **Knowledge Core** (the life graph made canonical: people, accounts, assets, policies, documents, dates, events, goals, commitments) and cites its source document and page | [Architecture](architecture.md), [Life graph](life-graph.md) |
| 3 | Reasons across life areas | Any question is routed to the calculations of every relevant box and answered as one | [Ask](ask.md) |
| 4 | Nudges before it matters | FD maturity, policy and passport expiry, missing expected statements, retests due, birthdays, tax savings, spending drift | [Nudges](nudges.md) |
| 5 | Answers with evidence | Every number comes from a calculation; every fact names its source; identifiers are masked until revealed after re-authentication | [Ask](ask.md), [Identity vault](identity-vault.md) |
| 6 | Stays the owner's | Local-first, end-to-end encrypted, no change without the owner's confirmation, identifiers never sent to an AI provider | [Privacy & security](privacy-security.md), [Encryption & sync](encryption-sync.md) |

## Reading order

1. This file — north star, overview, boxes, NFRs, open questions.
2. [`architecture.md`](architecture.md) — one brain, many apps: layers, components, Knowledge Core, invariants, the coordinator; then [`apps-and-modes.md`](apps-and-modes.md) (apps, sources, Me, modes, configuration layers) and [`context-policy.md`](context-policy.md) (what each app may see).
3. [`glossary.md`](glossary.md) — every term, state and scale. Check it before inventing a word.
4. [`configuration.md`](configuration.md) — every constant and setting (single home).
5. [`box-contract.md`](box-contract.md) — what every box provides.
6. [`ask.md`](ask.md) — the Ask answer contract.
7. [`cross-cutting.md`](cross-cutting.md) — dates, no-defaults, samples, saves, backups, accessibility.
8. [`privacy-security.md`](privacy-security.md) and [`encryption-sync.md`](encryption-sync.md).
9. [`life-graph.md`](life-graph.md), [`nudges.md`](nudges.md), [`identity-vault.md`](identity-vault.md).
10. Box specs in [`boxes/`](boxes/): [finance](boxes/finance.md) (plus the
    [personal-ai-cfo spec](../../personal-ai-cfo/spec/README.md) for the finance
    engine), [health](boxes/health.md), [career & learning](boxes/career-learning.md),
    [family](boxes/family.md), [notes & reminders](boxes/notes-reminders.md),
    [reflection](boxes/reflection.md), [documents](boxes/documents.md),
    [conversations](boxes/conversations.md).
11. [`worked-example.md`](worked-example.md) — one Ask answer end to end.

Where a linked idea (parenting-companion, notes-reminders, reflective-friend)
conflicts with this folder on the hub, box or Ask contract, this folder wins.

## Overview

- **What it does.** A private hub for one household: one brain, many apps
  ([architecture.md](architecture.md)). Each life area is an **app**; each
  connector is a **source**; identity and profile is **Me**
  ([apps-and-modes.md](apps-and-modes.md)). **Home** shows every app's glance,
  the sources' status, *Your week* (the life brief) and *Top priorities across
  your life*. **Ask** takes a free-text question, routes
  it to the calculations of every relevant box, runs them and composes one
  answer in which every number is traceable.
- **Who it's for.** One **owner** and the people in the owner's household
  profile. Only the owner signs in.
- **Primary user journeys.**
  1. Owner opens Home, sees *Your week* and the top priorities, follows the first.
  2. Owner asks *"Can I afford a car for ₹15 lakh next year?"* → affordability
     result, aspects considered per box, suggestions, caveats and follow-ups;
     a missing input is asked for inline.
  3. Owner points the Folders / Documents source at a folder; a new mutual-fund statement
     and a lab report appear as drafts in Finance's and Health's review queues;
     the owner reviews and applies them.
  4. Owner gets a nudge that an FD matures in the "coming up" window and that
     an expected monthly statement has not arrived.
  5. Owner opens the app with the network off and gets the same results.

## Boxes

| Box id | Kind | Name | Holds | Spec |
| --- | --- | --- | --- | --- |
| `finance` | app | Finance | Accounts, holdings, loans, income, spending, goals, assumptions, tax documents | [boxes/finance.md](boxes/finance.md) |
| `health` | app | Health | Reviewed lab reports, settings, targets, check-up plan | [boxes/health.md](boxes/health.md) |
| `career` | app | Career & Learning | Role history, skills, role profiles, learning resources and plan | [boxes/career-learning.md](boxes/career-learning.md) |
| `family` | app | Family | People from the household profile, events, milestones, vaccinations, education-goal links | [boxes/family.md](boxes/family.md) |
| `notes` | app | Notes & reminders | Notes, reminders, topics | [boxes/notes-reminders.md](boxes/notes-reminders.md) |
| `reflection` | app | Reflection (Journal) | Journal entries, reviews | [boxes/reflection.md](boxes/reflection.md) |
| `documents` | source | Folders / Documents | Folder sources, the source-document index, classification rules | [boxes/documents.md](boxes/documents.md) |
| `conversations` | source | Chats | Personal chat exports, phone message/call metadata, the owner's voice notes, work bridge entries | [boxes/conversations.md](boxes/conversations.md) |
| `me` | me | Me | About me, the household profile, the identity vault | [apps-and-modes.md](apps-and-modes.md), [identity-vault.md](identity-vault.md) |

The default box order is `ranking.domainOrder` ([configuration](configuration.md)).

## Tech stack (suggested, not mandatory)

| Layer | Suggestion | Contract or negotiable |
| --- | --- | --- |
| Engines | Deterministic, versioned libraries with JSON Schemas (draft 2020-12); decimal arithmetic | Contract: determinism, schemas, `inputs_sha256`, `engine_version` |
| API | One transport-agnostic dispatch function serving every route, reachable over HTTP (home server) or in-process in the browser (website) | Contract: identical answers on both transports |
| Home server | Process on the owner's PC bound to loopback, published only on the owner's private network | Contract: [privacy-security.md](privacy-security.md) |
| Website / installed app | Static files; engines compiled to WebAssembly in a worker; browser database for data documents | Negotiable |
| Sync relay | Ciphertext-only blob store: the owner's home server, or a free-tier cloud store | Contract: [encryption-sync.md](encryption-sync.md) |
| UI | Plain HTML/CSS/ES modules, no third-party scripts or fonts | Contract: no external resources; no money or medical maths in the UI |

## Non-functional requirements

| Area | Requirement |
| --- | --- |
| Determinism | Same inputs → same outputs and `inputs_sha256` on every device and both transports. |
| Offline | Website mode: every box and Ask work with the network off after the first load. Home-server mode: the app shell loads offline and says the server is unreachable. |
| Performance | An Ask answer within `ask.answerLatencySeconds`; every Home API call within `perf.apiCallMs` on the home server. |
| Accessibility | [cross-cutting.md § Accessibility](cross-cutting.md#accessibility-baseline). |
| Language | English UI; Ask routing also understands common Hinglish and common misspellings. |
| Integrity | Every write is schema-validated, atomic and versioned, and keeps a backup ([cross-cutting.md](cross-cutting.md#versioned-saves-and-conflicts)). |
| Cost | Zero running cost: free tiers only, no billing account attached. |

## Open questions

Each blocks the named milestone of [`../plan/README.md`](../plan/README.md).

- `TODO(spec, blocks: M7)` — Are the shared entity types in
  [architecture.md § Shared entity types](architecture.md#shared-entity-types-canonical-in-the-core)
  the complete canonical set for the first Knowledge Core? **Default:** yes,
  exactly that list; every other record stays a domain record.
- `TODO(spec, blocks: M7)` — Context policy defaults per app? **Default:** the
  [default grants](context-policy.md#default-grants); every other cross-domain
  read denied.
- `TODO(spec, blocks: M7)` — Is a professional-profile data export (e.g. a
  professional network's export) a source for Career & Learning? **Default:**
  yes, a source producing drafts into Career & Learning's review, applied by
  the owner.
- `TODO(spec, blocks: Later)` — More than one signing-in user (other
  household members, other people)? **Default:** no — stays out of scope;
  every Knowledge Core write and context audit entry carries the owner's
  identity so a later change needs no migration.
- `TODO(spec, blocks: M5)` — Proactive engine? **Default:** a single rules
  engine over the life graph that emits nudges as reminders or recommendations
  ([nudges.md](nudges.md)).
- `TODO(spec, blocks: M4)` — AI provider for Ask? **Default:** a local model on
  the home-server PC; a cloud provider (Azure OpenAI with the owner's key) only
  as a fallback, with masked facts only and identifiers never sent
  ([ask.md § AI provider](ask.md#ai-provider)). Until decided,
  `ask.provider` stays `none`.
- `TODO(spec, blocks: M4)` — Final app name? **Default:** keep `productName`.
- `TODO(spec, blocks: M4)` — Whose learning does Career & Learning cover?
  **Default:** the owner's learning in Career & Learning; a child's education
  in Family (milestones and education-goal links).
- Finance open questions (Account Aggregator via a regulated partner,
  statutory EPF/NPS rules, regulatory posture) live in the
  [personal-ai-cfo spec](../../personal-ai-cfo/spec/README.md#open-questions).
- `TODO(spec, blocks: M3b)` — Which cloud relay for sync? **Default:** the
  owner's home server as relay until the owner creates a free-tier Firebase
  (Spark) project; then Firebase Auth + Firestore with owner-only rules.
- `TODO(spec, blocks: M3c)` — Native iOS app? **Default:** the installable
  website on iPhone; no native iOS app.
- `TODO(spec, blocks: M3c)` — Desktop shell? **Default:** the installable
  website; a packaged desktop app only for a requirement the website cannot
  meet.
- `TODO(spec, blocks: M3c)` — What may the Android app read from the phone for
  Conversations? **Default:** SMS and call-log metadata only (who, when,
  direction, duration), plus SMS text only from senders matched by Finance
  alert templates; no call audio.
- `TODO(spec, blocks: M6)` — How are commitments detected? **Default:**
  deterministic, owner-editable phrase rules producing draft reminders; an AI
  provider only for sources with `aiConsent` true, still producing drafts.
- `TODO(spec, blocks: Later)` — Telegram own-account import? **Default:** not
  supported; revisit only through an official, read-only API for the owner's
  own account, with the same retention and consent rules as other sources.

## Out of scope

Moving money, trading, filing tax returns or any write access to a financial
account; diagnosis or treatment advice; more than one signing-in user; public
sharing or public network exposure; scraping websites or storing bank or EPFO
portal passwords; work data of any kind (employer mail, work chats, Teams,
work agents' data); recording call audio.
