# Build plan — Life OS — personal life hub

The plan answers **what to do next and in what order**, not what to build.
For "what to build", see [`../spec/`](../spec/README.md).

## Current status

A build exists in
[`DDancingDeath/personal-ai-cfo`](https://github.com/DDancingDeath/personal-ai-cfo)
(private; started as the Finance box and grew into the hub). That repository
owns code, issues, milestones, ADRs and live status — its pinned roadmap issue
is the pick-order view. This folder stays the idea of record.

## Roadmap

Milestones, each shippable on its own.

- **M1 — Finance foundation**: deterministic projection engine, net worth,
  cash flow, loans, dashboard, analytics, planning, bank-statement import.
- **M2 — Life OS hub**: box contract, household profile, home, Ask across
  boxes, Health and Career & Learning boxes.
- **M3a — Home server**: run on the owner's own PC, reachable only over a
  private network from phone and PC; sign-in, sessions, installable website,
  scheduled backups. Exit: works on phone and PC privately; a backup has been
  restored once.
- **M3b — Offline + encrypted sync**: engines run on-device in the browser,
  on-device storage, end-to-end encryption design (key derivation, recovery
  key, threat model), a ciphertext-only free-tier relay, sync protocol with
  conflict copies, static website. Exit: every page works with no server;
  results match server mode; a new device restores identical documents; the
  relay holds no plaintext; daily use stays in free quotas.
- **M3c — Native apps**: desktop shell decision, desktop installer, Android
  app, iOS decision and app.
- **M4 — Your data & personalisation**: real data replaces every illustrative
  assumption; AI provider, app name and whose-learning decisions taken.
- **Later**: Family, Notes & reminders and Reflection boxes; statement
  imports (EPF passbook, payslips, mutual-fund statements, NPS); statutory
  EPF/NPS and tax-regime rules; scanned-report extraction; reminders and
  notifications across boxes.

## Backlog (unordered)

- Reminders across boxes (needs notifications on each platform).
- Annualising yearly / irregular payments in spending.
- Evenly spaced chart ticks supplied by the engines.

## Known issues / debt

- Concurrent edits from two tabs or devices must not silently overwrite each
  other — reject stale saves; sync must keep conflict copies.
- Health text and multi-band reference ranges need explicit judging rules.

## Decision log

- 2026-10-22 · Hosting: home server on the owner's PC over a private network
  now, then on-device engines + end-to-end encrypted sync through a
  ciphertext-only free-tier relay · Free, private, works offline; classic cloud
  backend would see plaintext · Considered: cloud backend, hosted database,
  device-only with no sync.
- 2026-10-22 · Every number from deterministic, versioned calculations; AI may
  only phrase or plan, and any unverified number in AI text discards that text
  · Traceability and trust · Considered: AI-computed answers.
- 2026-10-22 · No defaults for missing inputs · A silently defaulted input
  produces a confident wrong answer · Considered: sensible defaults with a
  warning.
