# Operations runbook — rebuild

> Procedures the human side runs when the system tells them
> something is wrong, plus the steady-state operations the
> owner / brother does on a normal week. The system's
> automated behaviour for each of these conditions is in
> [`../../spec/rebuild/failure-modes.md`](../../spec/rebuild/failure-modes.md);
> this file says **what the human does**.
>
> Lives in `plan/` because runbooks are opinion (who calls
> whom, what wording to use, when to escalate) — not a contract
> the code enforces.

## Audience

- **Brother** monitors the Review Queue, watches notifications,
  and runs first-line procedures.
- **Owner** has admin authority — anything that requires sign-
  off, role change, or settings change is the owner's call.
- **Staff** rarely opens this doc. Their UI surfaces the one
  obvious next step in plain language; the runbook is the
  fallback when the UI's hint is not enough.

Each procedure below is structured the same way:

- **When**: the trigger (push notification, in-app flag, a
  staff complaint).
- **First check**: cheap diagnostic — usually a glance at the
  app's Diagnostics screen.
- **Action**: the steps, in order.
- **Stop / escalate**: when to stop trying and call the owner /
  an engineer.

## Steady-state operations

### Daily — brother (≤ 5 min)

1. Open the Review Queue / the day's flag digest. Resolve any
   **low** / **medium** flags from the previous day — this includes
   any **rate anomaly** a cashier "saved anyway" at the counter
   (`price.unusually-low` / `…-high` / `below-cost`), which the
   daily report lists by severity.
2. Skim Today's cash close summary. If it shows mismatch,
   confirm with staff and resolve or escalate per §Cash close
   mismatch.
3. Check the Diagnostics dot at the top of the app:
   green = healthy, amber = stale data on any device, red =
   active failure.

### Weekly — owner (≤ 30 min)

1. Open Audit log → filter to "owner-relevant" (settings
   changes, voids, corrections, exports). Skim for anything
   unexpected.
2. Open Reports → last week. Compare against feel ("did we
   actually sell that much wholesale?"). Anything off → flag
   for next month's deeper review.
3. Confirm the Backup banner shows "Last backup: < 24 h ago"
   (per [`backup-restore.md`](./backup-restore.md)).
4. Confirm the **restore drill** counter — if the drill is due
   (default monthly), run it per [`backup-restore.md`](./backup-restore.md)
   §Drill.
5. Update app on devices if a new version is released. Use the
   §Release process below.

### Monthly — owner (≤ 1 h)

1. Run the restore drill if not already done.
2. Export bills, audit log, and reports for the month → store
   in the shop's drive backup location.
3. Review the suspicion-engine summary: top flagged staff
   actions, top flagged customers, top flagged items. Re-tune
   `shopProfile` thresholds if the noise/signal ratio is off.
4. Review the user list. Suspend any user who has not signed
   in for > 60 days.

## Failure procedures

Each procedure has a code (P1–P12) that matches a failure mode
in [`../../spec/rebuild/failure-modes.md`](../../spec/rebuild/failure-modes.md)
where applicable.

### P1. Printer not working

- **When**: bill rows show `Print failed`; staff reports the
  printer is dead / blank / out of paper.
- **First check**: check printer power, paper, and BT pairing.
  The app's Diagnostics → Print queue shows last error.
- **Action**:
  1. Power-cycle the printer.
  2. Re-pair via Settings → Bluetooth.
  3. In the app, tap `Retry` on the failed row. The queue
     dedupes; no duplicate sale is created.
  4. If still failing, switch to the backup print path:
     paper-and-pen bill, mark the bill in the app as
     `Manually printed` (an audit-tagged action).
- **Stop / escalate**: if more than 1 hour without working
  print, contact the printer vendor. Continue running the
  shop using the manual path — bills are still saved.

### P2. Sync pending too long

- **When**: notification "Outbox has events older than 30
  min".
- **First check**: Diagnostics → outbox depth and oldest age.
- **Action**:
  1. Confirm the device is online (Diagnostics → network).
  2. Tap `Retry` on a stuck row to nudge the worker.
  3. If still stuck after 5 min, ask staff to fully close and
     reopen the app — outbox is persisted so this is safe.
  4. If outbox depth keeps growing, check Firebase status
     page; if Firebase is down see §P10.
- **Stop / escalate**: if the same items are still pending
  after 24 h, **do not** force-clear them. Contact the
  engineer. The outbox protects business data; clearing it
  loses sales.

### P3. Cash mismatch at close

- **When**: cash close shows a difference between counted
  cash and expected cash.
- **First check**: Diagnostics → outbox. Any unsynced cash-
  affecting events on this device or another device?
- **Action**:
  1. If outbox is non-empty, **wait** for sync to complete
     before closing — the mismatch may disappear.
  2. If still mismatched after sync, ask staff to recount.
  3. If still mismatched, close the session anyway. The
     close event captures the mismatch and `reason` (free
     text). The system raises a `cash.close-mismatch` flag.
  4. Brother / owner reviews the flagged session within 24 h.
     The runbook for the review is §P4.
- **Stop / escalate**: never silently adjust cash to match
  expected. Always record the mismatch and the reason.

### P4. Reviewing a cash mismatch flag

- **When**: Review Queue shows `cash.close-mismatch`.
- **Action**:
  1. Open the flagged session; review every event in it.
  2. Match against staff's verbal explanation.
  3. If a missing event is identified (e.g. a sale not
     entered), have staff record a **correction event**
     (per [`../../spec/rebuild/event-schemas.md`](../../spec/rebuild/event-schemas.md))
     with `reason` documenting the explanation.
  4. Resolve the flag with `resolution = approve` and a note.
  5. If the discrepancy cannot be explained, resolve with
     `resolution = unresolved-loss` and a note. The number
     stands; the audit trail shows the decision.

### P5. Duplicate bill suspected

- **When**: staff reports a bill was created twice; or Review
  Queue shows `dedup.conflict`.
- **First check**: open History. Filter by the customer /
  amount / minute window.
- **Action**:
  1. If two distinct bill numbers exist with the same intent:
     void one with `reason = duplicate-of-bill-N`.
  2. If `dedup.conflict` is in Review Queue (same idempotency
     key, different payload): inspect both payloads. Decide
     which is the intended bill; void the other.
  3. Both decisions are events; the audit trail shows what
     happened.
- **Stop / escalate**: never delete bills. Always void with
  reason.

### P6. Staff made the wrong bill

- **When**: staff reports a wrong item / qty / rate / party.
- **First check**: time elapsed since the bill (rule from
  [`role-permission-matrix.md`](../../spec/rebuild/role-permission-matrix.md)):
  same cash session vs older.
- **Action**:
  1. If same cash session: staff can record a
     `bill_correction_recorded` themselves (UI gates this).
     A flag is raised; brother reviews per §P4.
  2. If older: only owner can correct. Owner opens the bill
     in History → Correct → confirms.
  3. Always include a `reason` (free text) on corrections.

### P7. Phone lost or stolen

- **When**: staff reports phone missing.
- **First check**: was the device online recently? (Owner can
  see "Last seen" in Admin → Users.)
- **Action**:
  1. Owner immediately revokes the user: Admin → Users → the
     staff → Status `suspended`. Token refresh fails on the
     lost device; no further writes accepted from it.
  2. If the lost device had unsynced events: they are lost.
     The next cash close will reveal the gap as a
     `reconciliation.cash-shortfall` flag.
  3. Provide a replacement device, sign in with the same user
     id; the device rebuilds cache from server events.
  4. If the device may have been compromised: also rotate the
     user's password.
- **Stop / escalate**: do not attempt to "recover" the lost
  data. The honest record is the server event log; whatever
  was on the lost device that never synced is gone.

### P8. App update failed

- **When**: staff reports the app will not open / shows a
  blocking "Update required" screen / install failed.
- **First check**: Settings → About → app version.
- **Action**:
  1. If `Update required` is shown but install link is broken:
     deliver the APK directly to the device (per the §Release
     process channel).
  2. If install starts but fails: clear the device's downloaded
     APK; retry. Confirm storage is not full.
  3. If the app crashes immediately on launch after update:
     **roll back** per §Release process §Rollback. The owner
     decides; the engineer executes.
- **Stop / escalate**: never leave the shop without a
  functioning app. If update can't complete and rollback isn't
  possible, fall back to manual paper bills (P1's manual
  path) until resolved.

### P9. Forbidden action attempt by staff

- **When**: notification "Staff attempted forbidden action N
  times" (per
  [`role-permission-matrix.md`](../../spec/rebuild/role-permission-matrix.md) §A
  rules).
- **First check**: Review Queue → the flagged event. The flag
  contains which action, how many times, in what window.
- **Action**:
  1. Talk to the staff. Possible causes: confusion about UI,
     accidental tap, intentional probing.
  2. If accidental: resolve flag with `note = ui-confusion`.
     Consider a UI tweak ticket.
  3. If intentional and benign (e.g. "I wanted to see if I
     could"): resolve with `note = explained-warned`.
  4. If intentional and concerning: revoke staff per §P7.
- **Stop / escalate**: do not ignore repeated escalation
  attempts. They are a real signal.

### P10. Firebase outage

- **When**: every device shows `Offline` despite being on
  Wi-Fi / mobile data; Firebase status page confirms.
- **Action**:
  1. Tell staff the app will continue to work offline. Bills,
     prints, cash close — all allowed.
  2. Do not attempt schema / role / settings changes during
     the outage (they are ❌ offline by design).
  3. When Firebase returns, watch the outbox drain (§P2 if it
     gets stuck).
- **Stop / escalate**: if outage exceeds 24 h, the engineer
  prepares a paper-bills-import procedure for the post-
  outage reconciliation.

### P11. Day close cannot complete

- **When**: staff cannot close the cash session — error
  message, missing button, infinite spinner.
- **First check**: Diagnostics → active session, outbox.
- **Action**:
  1. If outbox is non-empty, wait for drain.
  2. If a critical flag blocks close (e.g. `block` severity),
     resolve the flag first (owner-only).
  3. If the UI button is missing entirely, force-relaunch
     the app; the close button reappears if the session is
     still open.
  4. As a last resort: the owner can close the session
     remotely via Admin → Sessions.
- **Stop / escalate**: never leave a session open overnight if
  cash counts cannot be recorded — the session boundary is
  critical for tomorrow's projections. Record a mismatch
  close (§P3) rather than skip the close.

### P12. Reconciliation mismatch

- **When**: notification "Projection mismatch (R1–R4)" — the
  server's authoritative replay disagrees with the device's
  local projection.
- **First check**: Diagnostics → cache health on the affected
  device.
- **Action**:
  1. Brother / owner taps `Rebuild from server` on the
     affected projection. The cache is purged; events refold
     locally; numbers re-converge.
  2. If mismatch reappears within a day, escalate to the
     engineer — the bug is in the shared domain.
- **Stop / escalate**: never patch a projection by hand. The
  whole point of the architecture is reproducibility from
  events.

## Release process

Updating the app in production.

### When to release

- After-hours preferred. Default: after 9 PM local time, when
  the shop is closed.
- Never during a peak hour without an emergency reason.
- Never during a Firebase advisory window.

### Pre-release

1. PR is green per [`../../spec/rebuild/ci-contract.md`](../../spec/rebuild/ci-contract.md).
2. Release is tagged in source control with semver and a
   short release note.
3. Staging Firebase project has been dual-run for ≥ 24 h
   against the synthetic dataset.
4. If the release bumps `schemaVersion`: dual-run against a
   staging clone of prod events for ≥ 1 h with no rebuild
   errors.

### Release

1. Owner taps `Publish` (or the engineer does, with owner
   sign-off).
2. Backend rules / functions deploy first.
3. PWA cache busts; APK is uploaded to the configured
   channel.
4. `shopProfile.recommendedAppVersion` is bumped.
5. Smoke test on a real phone with a real printer: create one
   bill end-to-end. Confirm `Saved → Synced → Printed`.

### Post-release

1. Watch the Review Queue and Diagnostics for the first hour.
2. Watch Crashlytics for the first 24 h.
3. Send a short release note to brother: what changed, what
   to watch.

### Rollback

- A bad release can be rolled back **only** if the release did
  not bump `schemaVersion`. Schema bumps are one-way (per
  [`../../spec/rebuild/versioning-compatibility.md`](../../spec/rebuild/versioning-compatibility.md)).
- For non-schema rollback: redeploy the previous tag's
  artefacts; do not lower `shopProfile.minSupportedAppVersion`
  (clients on the new build keep working).
- For a schema-bumped release that is broken: **do not roll
  back**. Hotfix forward with a new release that adds
  compensating logic. This is intentional — the alternative
  silently desynchronises clients.

## Escalation table

| Situation | Who | How fast |
|---|---|---|
| Shop running, brother sees a flag | Brother triages | within day |
| Shop running, high-severity flag | Brother notifies owner | within 1 h |
| Shop running, can't print | Brother triages, fallback to manual | immediate |
| Shop running, can't bill | Owner notified; engineer notified | within 15 min |
| Cash mismatch | Brother triages, owner reviews | within day |
| Phone lost | Owner revokes, engineer optional | within 1 h |
| Firebase outage | Confirm via status page; wait | as long as needed (offline keeps working) |
| Schema-bumped bad release | Owner + engineer; hotfix-forward | within 4 h |
| Reconciliation mismatch | Owner rebuilds; engineer if recurs | within day |
| Suspected fraud | Owner only; do not act in app first | within 4 h |

## Contact list

- **Owner**: `TODO(owner)` — primary mobile + WhatsApp.
- **Brother / reviewer**: `TODO(owner)`.
- **Engineer / developer**: `TODO(owner)`.
- **Printer vendor**: `TODO(owner)` — model, contact, warranty
  expiry.
- **Phone vendor / repair**: `TODO(owner)`.
- **Firebase project owner email**: `TODO(owner)`.

The contact list is a `TODO(owner)` because it is shop-
specific and changes; the owner fills it in before pilot.

## Required tests / drills

- Restore drill — see [`backup-restore.md`](./backup-restore.md).
- Rollback drill — once per quarter the engineer rehearses a
  non-schema rollback against staging.
- Print-vendor failover drill — once per quarter the shop
  switches to the manual paper-bill fallback for 1 hour and
  verifies bill imports work.
- Phone-lost drill — once per quarter the owner revokes a
  staff user and confirms the device can no longer write,
  then re-enables.

## Open items

- `TODO(plan)` — confirm after-hours window with owner.
- `TODO(plan)` — confirm WhatsApp template (with engineer +
  owner) for the high-severity notification path.
- `TODO(plan)` — pick the APK distribution channel for v2.0
  (Play Store internal track? direct APK link?). Default per
  [`../../spec/rebuild/versioning-compatibility.md`](../../spec/rebuild/versioning-compatibility.md):
  direct APK with pinned signing cert.

## Recent changes

- _2026-06-15_ · file created. Daily / weekly / monthly
  steady-state checklists; 12 failure procedures (P1–P12)
  matched to spec failure modes; release process with
  rollback rules (no rollback through a schema bump);
  escalation table; contact list template; required
  quarterly drills.
