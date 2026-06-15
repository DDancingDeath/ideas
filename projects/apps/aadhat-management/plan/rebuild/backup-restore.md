# Backup and restore — rebuild

> What the system backs up, how often, who can restore, and
> the monthly drill that proves restore actually works. The
> operational complement to
> [`../../spec/rebuild/data-governance.md`](../../spec/rebuild/data-governance.md)
> §Retention and
> [`../../spec/rebuild/failure-modes.md`](../../spec/rebuild/failure-modes.md).
>
> Lives in `plan/` because backup cadence, who runs the drill,
> and the contact tree are operational opinion — not contracts.

## What is backed up

| Data | Backup type | Frequency | Retention |
|---|---|---|---|
| Firestore — event ledger | Firebase scheduled export | Daily | 90 days rolling + monthly snapshot kept for 12 months |
| Firestore — projections | Skipped (reproducible from events) | — | — |
| Firestore — shop profile, users | Same export, separate collection | Daily | 90 days |
| Firebase Storage (photos, when added post-v2.0) | Scheduled export | Daily | 90 days |
| Auth users | Firebase Auth export | Weekly | 90 days |
| Firestore rules + Functions source | Git tag per release | Per release | Forever |
| Schema validators (per `schemaVersion`) | Git + npm package versioned | Per change | Forever |
| Owner's export drive (CSV of bills, audit, reports) | Manual monthly | Monthly | Forever |

Projections are **not** backed up. They are reproducible from
the event ledger by definition (per
[`../../spec/rebuild/projections.md`](../../spec/rebuild/projections.md));
backing them up would create a second source of truth that
could disagree with the events — exactly the failure mode the
architecture exists to prevent.

## Where backups live

- **Primary**: Firebase / Google Cloud Storage in the same
  project's `aadhat-backups-${env}` bucket. Object versioning
  on; lifecycle policy enforces retention.
- **Secondary**: owner's personal cloud drive (Google Drive
  account configured on the owner's phone), refreshed monthly
  from the manual export.
- **Tertiary** (recommended, optional): a USB drive at the
  shop, refreshed monthly when the owner runs the monthly
  procedure.

A backup that lives only in the same Firebase project is not
a backup. The off-account drive copy is mandatory.

## Who can restore

- **Owner only.** Restore touches business truth; staff and
  brother have no restore permission.
- **Engineer** assists; the owner approves the action.
- Restore is itself an event: `system.restored` is appended to
  the audit log with the backup source, the operator, and the
  reason.

## Restore scenarios

Three different shapes of "restore". Use the matching one.

### S1. Bad deploy — code rollback

- **Trigger**: a release ships a bug; data is not corrupted.
- **Action**: redeploy the previous tag's artefacts per
  [`operations-runbook.md`](./operations-runbook.md) §Rollback.
  No data restore needed.
- **Constraint**: if the bad release bumped `schemaVersion`,
  do not roll back code — hotfix forward.

### S2. Bad data — selective restore

- **Trigger**: an event was appended with wrong data (e.g. a
  buggy migration); the wrong data is small and bounded.
- **Action**: do **not** restore Firestore. Instead, append
  compensating events (correction / void) per the existing
  event model. The audit trail shows both.
- **Constraint**: never `DELETE` events from Firestore to
  "fix" a bug. The history is part of the contract.

### S3. Catastrophic loss — full restore

- **Trigger**: the entire Firestore project is lost / wiped /
  corrupted (a rare event; would require simultaneous Firebase
  failure plus loss of secondary copies — but planned for).
- **Action**:
  1. Owner authorises restore.
  2. Engineer provisions a fresh Firebase project named
     `aadhat-${env}-restored-${date}`.
  3. Restore from the most recent Firebase export plus any
     daily/weekly increments to the disaster point.
  4. Replay the secondary drive copy of CSV exports for the
     **gap window** (the period between the last successful
     export and the disaster), as `system.restored-from-csv`
     events with `reason = catastrophic-restore-gap`.
  5. Run §Verification before pointing devices at the new
     project.
  6. Update `shopProfile.firebaseProjectId` in the app build;
     release as a hotfix; devices reconnect.

## Verification (always run after any restore)

A restore that hasn't been verified is a restore that hasn't
happened.

| Check | Pass condition |
|---|---|
| Event count matches backup | within 0 events of the export manifest |
| Spot-check 20 most recent bills | exact totals match prior end-of-day reports |
| Today's cash session totals | match owner's pre-disaster mental model and the most recent paper / WhatsApp summary |
| Outstanding totals | match the most recent owner export |
| Reports for the last week | render with non-zero numbers; spot-check three known days |
| Audit log integrity | the most recent 100 events present; `data_exported` events present per the owner's known exports |
| Schema validators | every event's `schemaVersion` has a matching validator |
| Projection rebuild | runs to completion without errors |

A failed check **blocks** going-live on the restored project.
The engineer + owner decide whether to retry the restore, dig
deeper, or escalate to Firebase support.

## Monthly restore drill

This is the most important part of the doc. **A backup that
has never been restored does not exist.**

### When

- First Sunday of each month, after the shop closes.
- Or: any time `obs.restoreDrillIntervalDays` (default 30) has
  elapsed and the app surfaces the in-app reminder per
  [`../../spec/rebuild/observability.md`](../../spec/rebuild/observability.md).

### What

1. Engineer provisions a **drill project**
   `aadhat-drill-${YYYY-MM}` from the latest Firebase export.
2. Run the §Verification checks against the drill project.
3. Point a **non-production phone** at the drill project; run
   the manual smoke test from
   [`../../spec/rebuild/quality-bar.md`](../../spec/rebuild/quality-bar.md):
   create one bill, print, void, cash close.
4. Confirm a known prior bill (chosen by the owner) appears
   correctly.
5. Append a `drill_completed` event in the owner's notebook /
   the operations log; clear the in-app reminder.
6. Delete the drill project to control cost.

### Pass / fail

- **Pass**: all verification checks green, smoke test succeeds,
  reminder cleared.
- **Fail**: investigate immediately. A failed drill is the
  same severity as a real outage — the backup is the only
  defence against the worst-case data loss.

### Tracking

- Each drill produces a short note in the owner's drive:
  date, who ran it, pass / fail, anything anomalous.
- Three consecutive passes → next quarter's cadence can drop
  to once every two months (owner's call).
- Any fail → cadence locks back to monthly until three
  consecutive passes.

## Required tests

The drill itself **is** the test. Additionally, automated
tests in CI assert:

- The scheduled export Cloud Function exists and is wired to
  the daily schedule.
- The export bucket has the correct lifecycle (90-day
  rolling) and object versioning enabled.
- A test fixture for restore replay (`scenarios.md` →
  `catastrophic-restore-gap`) produces an event stream
  byte-identical to a manually constructed reference.
- `data_exported` and `system.restored` events validate
  against their schema validators.
- The in-app reminder fires after `obs.restoreDrillIntervalDays`.

## Open items

- `TODO(plan)` — confirm Firebase project owner email and
  billing contact in
  [`operations-runbook.md`](./operations-runbook.md) Contact
  list; restore depends on the engineer having the right
  Firebase permissions.
- `TODO(plan)` — pick the off-account drive provider for the
  monthly CSV copy (Google Drive on the owner's personal
  account is the default; alternatives = OneDrive, iCloud).
- `TODO(plan)` — decide whether to provision the drill project
  in the same GCP organisation or a separate sandbox org.
  Default: separate sandbox to ensure billing isolation.

## Recent changes

- _2026-06-15_ · file created. What is backed up (events,
  rules, validators; **not** projections); where backups live
  (primary Firebase, mandatory off-account drive, optional
  USB); owner-only restore with `system.restored` audit
  event; three restore scenarios (code rollback, selective
  correction events, catastrophic full restore); mandatory
  verification checklist; monthly drill with pass/fail
  tracking and cadence adjustment.
