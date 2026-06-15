# Release health gates — rebuild

> The pre-release checklist. Every checkbox here must be green
> before code is promoted to production. Half of this is "CI is
> green" (which is automatic); the other half is human eyes on
> a printer, a real Android phone, and the day's flag queue.
> This file is the **single page** the release engineer reads
> before pushing the button.

## Why this doc exists

[`spec/rebuild/ci-contract.md`](../../spec/rebuild/ci-contract.md)
says what CI runs. [`spec/rebuild/platform-test-matrix.md`](../../spec/rebuild/platform-test-matrix.md)
says where each test runs and which manual gates exist.
[`operations-runbook.md`](./operations-runbook.md) §Release
process walks through the human steps. This file is the **gate
list itself** — the binary checklist that decides go / no-go.

The principle:

> A release without every gate green is not "almost ready". It
> is rolled back, fixed, and re-gated. There is no exception
> path, no override, no "ship Friday and fix Monday". The shop
> runs production money; the bar for promotion is non-
> negotiable.

## When this checklist applies

| Release type | Use this checklist? |
|---|:-:|
| Hot-fix patch (single-file fix, no schema change) | ✅ — subset per [§Hot-fix subset](#hot-fix-subset) |
| Minor release | ✅ — full |
| Schema bump (event-schema version up) | ✅ — full + migration gates |
| Domain bump (domain version up) | ✅ — full + brother + owner sign-off |

There is no release type that skips this list.

## The gates

### 1. CI green on every required job

Per [`spec/rebuild/ci-contract.md`](../../spec/rebuild/ci-contract.md):

- [ ] `lint`
- [ ] `typecheck`
- [ ] `unit` (coverage threshold)
- [ ] `scenario`
- [ ] `invariant`
- [ ] `security`
- [ ] `integration`
- [ ] `playwright`
- [ ] `visual`
- [ ] `perf` (no regression > 10% vs baseline)
- [ ] `rules`
- [ ] `docs` (link-check + dated `Recent changes` entry on every modified spec file)

A `ci` row that is green only after a re-run **without a code
change** does not count. Per CI contract §Forbidden in CI, that
is a flake; the test or the system must be fixed before the
gate is considered green.

### 2. Platform matrix green

Per [`spec/rebuild/platform-test-matrix.md`](../../spec/rebuild/platform-test-matrix.md)
§Release gate matrix, for the release type at hand:

- [ ] P1 / P2 / P3 / P8 all green per the release-type column
- [ ] iOS gates (P6 / P7) — only if release type is v2.1+; otherwise n/a

### 3. Printer smoke green

Per [`spec/rebuild/printer-compatibility.md`](../../spec/rebuild/printer-compatibility.md)
§Required tests `production-printer-smoke` and the platform
test matrix gate `G-PRINT-PROD`:

- [ ] Real reference Android phone paired with real production
      printer
- [ ] Created a retail bill, printed once, payload matches the
      bill event
- [ ] Photo of the printout attached to the release record
- [ ] Reprint produces a second printout with the same content
- [ ] Double-tap on Print produces **one** printout

Required if any of `apps/web/src/print/**`,
`packages/domain/print/**`, the printer driver, or the bill
renderer was modified; recommended every release regardless.

### 4. Offline / reconnect smoke green

Per [`spec/rebuild/offline-sync.md`](../../spec/rebuild/offline-sync.md)
required scenarios, and gate `G-OFFLINE-RECON`:

- [ ] Created 5 bills offline on the real phone
- [ ] Reconnected
- [ ] Verified exactly 5 server bills (no duplicates, no losses)
- [ ] Verified projections (stock, cash, outstanding) match
- [ ] Verified UI badges transitioned `Saved` → `Sync pending`
      → `Synced`
- [ ] Cash close with a `Sync pending` bill: re-open the
      session record after sync; numbers match

Required if any of `apps/web/src/sync/**`,
`apps/web/src/outbox/**`, or the IndexedDB schema was
modified; recommended every release.

### 5. Migration / cutover checks green

Per [`migration-cutover.md`](./migration-cutover.md) §Migration
check commands:

- [ ] `migration check items` — counts and stable-id mapping
      reconcile
- [ ] `migration check parties` — counts and balance sum
      reconcile
- [ ] `migration check stock` — projection sum equals v1
      snapshot sum
- [ ] `migration check outstanding` — projection sum equals v1
      snapshot sum
- [ ] `migration check cash` — projection sum equals v1
      snapshot sum
- [ ] Reconciliation report produced; brother has read it

Required for any schema-bump release; required for the v1 → v2
cutover. Not required for hot-fix patches.

### 6. No unresolved Sev-1 flags

Per [`spec/rebuild/review-queue.md`](../../spec/rebuild/review-queue.md)
and [`spec/rebuild/observability.md`](../../spec/rebuild/observability.md):

- [ ] Review Queue is **clean of Sev-1**. A Sev-1 flag from
      the previous release that has not been resolved is a
      blocker; a known-and-tracked Sev-2 is acceptable with a
      release note.
- [ ] No `sync.permanent-rejection`, `dedup.conflict`,
      `reconciliation.mismatch`, or `R4`-projection-divergence
      flag is open against production data
- [ ] Brother has signed off on any open Sev-2 carried into
      the new release

### 7. Rollback / hotfix path known

Per [`operations-runbook.md`](./operations-runbook.md) §Release
process and §P11 (release rollback):

- [ ] Previous release's artefact is identified and ready
      (binary or build manifest stored)
- [ ] Rollback procedure rehearsed within the last 90 days
      (per the runbook's quarterly drill)
- [ ] The release does **not** include a schema bump (per
      [`spec/rebuild/versioning-compatibility.md`](../../spec/rebuild/versioning-compatibility.md):
      releases containing a schema bump are **not rollback-
      capable**; the recovery path is hotfix-forward)
- [ ] If the release **does** include a schema bump: the
      hotfix-forward plan is written into the release notes
      and the brother has agreed in advance

### 8. Brother sign-off (production release only)

Per [`operations-runbook.md`](./operations-runbook.md) §Release
process and the migration-cutover sign-off pattern:

- [ ] Brother has read the release notes
- [ ] Brother has acknowledged any behaviour change (e.g.
      new badge, changed flow, new permission)
- [ ] Brother has agreed to the release window (low-traffic,
      shop near close, or scheduled with staff)

This gate is **non-bypassable for production releases**. A
release without brother sign-off is not promoted to
production.

### 9. Backup verified within 24 hours

Per [`backup-restore.md`](./backup-restore.md):

- [ ] Most recent automatic backup completed within last 24 h
- [ ] Backup integrity check (`backup verify --latest`) green
- [ ] Off-account drive copy present
- [ ] Most recent monthly restore drill passed

The shop's data is the shop's only history. A release that
goes out without a known-good backup taken first is a
violation of [`backup-restore.md`](./backup-restore.md) and is
a Sev-1 process defect.

### 10. Release notes drafted for the brother

Per [`operations-runbook.md`](./operations-runbook.md):

- [ ] What changed (in plain Hindi / English; not commit
      messages)
- [ ] What to watch in the first 24 h
- [ ] Any new flag types the brother should look for in the
      Review Queue
- [ ] Any new badge or wording on staff screens
- [ ] How to roll back (or, for schema-bump releases, the
      hotfix-forward plan)

## Hot-fix subset

A hot-fix patch (single-file fix, no schema change, no domain
math change) may skip gates that are demonstrably unaffected.
The minimum subset:

- [ ] Gate 1 (CI green) — **always**
- [ ] Gate 2 (platform matrix) — per release-type column
- [ ] Gate 3 (printer smoke) — only if printer code touched
- [ ] Gate 4 (offline / reconnect) — only if sync code touched
- [ ] Gate 6 (no Sev-1 flags) — **always**
- [ ] Gate 7 (rollback path) — **always**
- [ ] Gate 9 (backup verified) — **always**
- [ ] Gate 10 (release notes) — **always**, even if one line

Gates 5 and 8 are explicit "n/a for hot-fix" — but the brother
is still **informed** (gate 10 covers this).

## Sign-off record

Every release promoted to production is stamped with:

| Field | Filled by |
|---|---|
| Release version | release engineer |
| Release type (hot-fix / minor / schema / domain) | release engineer |
| Date and shop-local time | release engineer |
| Gate checklist (all 10) — green tick per gate or "n/a" | release engineer |
| Brother sign-off (gate 8) — explicit ack | brother |
| Release-record manifest path (per [`platform-test-matrix.md`](../../spec/rebuild/platform-test-matrix.md) §Recording test runs) | release engineer |
| Rollback plan summary | release engineer |

This record is the artefact the brother audits when something
goes wrong; it is also the input to the post-release smoke
24 h later (per the runbook).

## What forces a release to roll back

A release that has passed every gate above can still go wrong
in production. The runbook's §P11 rule:

- Sev-1 in production within 1 hour → roll back if rollback-
  capable; hotfix-forward if not
- Sev-1 across multiple shops (post-v2.0 productisation) → roll
  back same hour
- Sev-1 corruption of the event ledger → stop writes
  immediately; engage backup-restore (drill `S3`)

A release that turned out to need a rollback within its first
24 h triggers a **post-mortem entry** in the runbook so the
gate that should have caught it is hardened (e.g. add a missing
real-device test, raise the printer smoke from "if touched" to
"always").

## Open items

- `TODO(plan)` — exact release-record storage location.
  Default: `releases/<version>.json` committed alongside the
  release branch.
- `TODO(plan)` — automated gate-coverage report (does the PR's
  file diff line up with which gates the release engineer
  actually ran?). Default: a small CI assist that flags
  required gates based on touched paths; the human still
  signs off.
- `TODO(plan)` — separate Friday-evening freeze window for
  pre-festival weeks. Default: brother decides per festival
  calendar.

## Recent changes

- _2026-06-16_ · file created. Ten gates (CI green, platform
  matrix, printer smoke, offline / reconnect, migration
  checks, no Sev-1 flags, rollback path, brother sign-off,
  backup verified, release notes); hot-fix subset rule;
  sign-off record fields; rollback-trigger rules cross-
  referenced to operations-runbook §P11.
