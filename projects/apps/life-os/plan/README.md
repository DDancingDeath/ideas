# Build plan — Life OS — personal life hub

The plan answers **what to do next and in what order**, not what to build.
For "what to build", see [`../spec/`](../spec/README.md).

## Current status

A build exists in the private repository
[`DDancingDeath/personal-ai-cfo`](https://github.com/DDancingDeath/personal-ai-cfo)
(started as the Finance box, grew into the hub). It owns code, issues,
milestones, ADRs and live status; its pinned roadmap issue
[#45](https://github.com/DDancingDeath/personal-ai-cfo/issues/45) is the pick
order. As of 2026-10-22: M1 and M2 done; all six original boxes live (Finance,
Health, Career & Learning, Family, Notes & reminders, Reflection); Ask across
boxes with an evaluation set, thread context and the life brief; home-server
mode with sign-in and encrypted scheduled backups (code done, owner setup
pending); website mode with engines in the browser, end-to-end encrypted
backup and sync with conflict copies (cloud relay project and deploy pending);
live finance data (prices, read-only mailbox, SMS paste) done; QA pass done
except one item. Not started: Documents box, life graph, identity vault,
proactive engine, spending insights, tax report, Conversations.

## Roadmap

Milestones mirror the build repo's; M5 and M6 are this idea's next steps and
are not yet on the build roadmap.

| Milestone | Scope | Status (2026-10-22) |
| --- | --- | --- |
| M1 — Finance foundation | Deterministic finance engine, net worth, cash flow, loans, dashboard, analytics, planning, statement import | Done |
| M2 — Life OS hub | Box contract, household profile, Home, Ask across boxes, Health and Career & Learning; Ask evaluation set, thread context, life brief | Done |
| M3a — Home server | Loopback server on the owner's PC over a private network; sign-in, sessions, installable app, encrypted scheduled backups, reminders while the app is open | Code done; waiting on the owner's PC + private-network setup and data move |
| M3b — Offline + encrypted sync | Engines in the browser, browser storage, E2E encryption, sync with conflict copies, home-server relay, cloud relay adapter, static website | Mostly done; cloud relay project, deploy and manual phone + PC drill left |
| QA — Review & polish | Every page on desktop and phone against the accessibility baseline | Done except consistent form fields and empty states |
| M3c — Native apps | Desktop shell decision, desktop installer, Android app, iOS decision | Not started; waiting on decisions and build tools |
| M4 — Your data & personalisation | Real data replaces illustrative assumptions; live finance data; AI provider, app name, whose-learning and Account Aggregator decisions | Live data done; owner data entry and decisions open |
| M5 — Chief of staff | Documents box, life graph, identity vault, proactive engine (nudges incl. FD maturity, document expiry, expected documents, birthdays from certificates), spending insights, tax report | Not started; build issues [#90](https://github.com/DDancingDeath/personal-ai-cfo/issues/90) (Documents), [#91](https://github.com/DDancingDeath/personal-ai-cfo/issues/91) (life graph), [#92](https://github.com/DDancingDeath/personal-ai-cfo/issues/92) (proactive engine), [#31](https://github.com/DDancingDeath/personal-ai-cfo/issues/31) (statutory rules + tax) |
| M6 — Conversations | Personal chat exports, phone metadata (needs the Android app), people graph, relationship nudges, commitment drafts, work bridge entries | Not started; build issue [#93](https://github.com/DDancingDeath/personal-ai-cfo/issues/93) |
| Later | Background push when the app is closed; Telegram own-account (if ever) | Open |

## Backlog (unordered)

- Background push for reminders when the app is closed (non-personal payload).
- Statutory EPF/NPS contribution and withdrawal rules.
- A "remember this device" key for the vault; padding of sync blobs.
- Rules-emulator tests for the cloud relay's access rules.

## Known issues / debt

Do not reintroduce. Build-repo issue numbers for reference.

- Website-mode copy inside some boxes still says "on this computer" (#86).
- Form fields and empty states differ between boxes (#87).
- Fixed, keep fixed: Home date from UTC instead of the local date (#72); the
  same priorities listed twice on Home (#88); two tabs overwriting each other
  (#37); unreadable EPF passbook rows treated as zero (#66); sync cursor
  advanced before a successful apply (#63); relay index lost under concurrent
  writes (#62); server log inside the data folder (#64); sync token usable as
  an app session (#67); one oversized cloud-relay request aborting a whole sync
  (#65).

## Decision log

Append-only. Each entry: date · decision · rationale · alternatives considered.

- 2026-10-22 · Every number from deterministic, versioned calculations; AI may
  only phrase or plan, and any unverified number in AI text discards that text
  · Traceability and trust · Considered: AI-computed answers.
- 2026-10-22 · No defaults for missing inputs · A silently defaulted input
  produces a confident wrong answer · Considered: sensible defaults with a
  warning.
- 2026-10-22 · Hosting: home server on the owner's personal PC over a private
  network now (D), then engines on each device + end-to-end encrypted sync
  through a ciphertext-only free-tier relay (C) · Free, private, works offline;
  a cloud backend would hold plaintext health and money data and cost money ·
  Considered: local only (no phone access), own cloud drive (clumsy conflicts;
  kept as a backup target), paid cloud backend (cost, privacy, regulatory
  duties). Build-repo ADR-001.
- 2026-10-22 · Public internet exposure of the home server is never used; the
  server binds loopback only · Smallest attack surface · Considered: a public
  tunnel with login.
- 2026-10-22 · E2E encryption: one random data key wrapped by a PBKDF2-derived
  passphrase key and a printed recovery key; AES-256-GCM; one format in every
  language · PBKDF2 is native in browsers and Python; the iteration count is
  recorded per keyring so it can rise · Considered: Argon2id (needs extra
  WebAssembly in the page). Build-repo ADR-002.
- 2026-10-22 · Sync conflicts: later write stays, the other becomes a conflict
  copy for the owner to resolve · Never silent loss · Considered: plain
  last-writer-wins, field-level merge.
- 2026-10-22 · Bank data through Account Aggregator is not available to an
  individual's own app (only regulated Financial Information Users); use
  statements, alert messages and public prices · Regulatory fact · Open: a
  regulated partner (build #71).
- 2026-10-22 · No scraping and no portal credential storage (bank, EPFO) ·
  Breaks site terms, breaks silently on redesigns, holds the most dangerous
  secret · Considered: screen-scraping connectors.
- 2026-10-22 · Indian share prices from bhavcopy files the owner downloads;
  foreign share prices entered by the owner; FX from ECB reference rates;
  MF/NPS NAVs fetched once a day · Exchange terms forbid automated downloads;
  broker APIs (e.g. Kite Connect) are paid; no free key-less US price source
  allows automated use; FBIL rates are licensed · Considered: broker API,
  unofficial price endpoints.
- 2026-10-22 · Read-only mailbox access with the owner's own OAuth client; the
  product ships no client id and runs no server of its own · Privacy ·
  Considered: a shared app registration.
- 2026-10-22 · North star: a personal chief of staff from the owner's own
  records (absorb, connect with provenance, reason across areas, nudge, answer
  with evidence, stay the owner's) · Owner's long-term vision · —
- 2026-10-22 · Work data (employer mail, chats, Teams, work agents) is out of
  scope; only owner-authored work bridge entries · Corporate confidential data
  stays in sanctioned work tools · Considered: importing work chats.
- 2026-10-22 · Never record call audio; only the owner's own voice notes ·
  Consent and legal risk · Considered: call recording.
