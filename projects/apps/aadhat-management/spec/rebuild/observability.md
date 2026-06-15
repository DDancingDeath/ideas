# Observability and supportability — rebuild

> What the system actively tells the owner and brother
> (notifications), what every running app exposes for debugging
> (supportability), and what telemetry is allowed. The contract
> that makes [`review-queue.md`](./review-queue.md),
> [`failure-modes.md`](./failure-modes.md), and the operations
> runbook actionable instead of decorative.

## Two surfaces

1. **Notifications** — things the system pushes to a human
   (banner, push, WhatsApp) so the owner / brother does not
   have to remember to check.
2. **Supportability** — things every running app exposes (IDs,
   versions, debug bundle) so when something goes wrong it can
   be triaged in minutes instead of hours.

The principle:

> If a problem can be silent for an hour, it can be silent for
> a week. Anything that affects business correctness must
> notify; anything that might cause a future support call must
> be debuggable in one tap.

## Notification catalogue

What pushes a signal to a human, by severity and channel.

| Trigger | Severity | Channel | Audience |
|---|---|---|---|
| `review_queue.flag_raised` with severity `high` or `block` | High | In-app badge + push + WhatsApp (configurable) | Brother, owner |
| `review_queue.flag_raised` with severity `medium` | Medium | In-app badge + push | Brother, owner |
| `review_queue.flag_raised` with severity `low` | Low | In-app badge | Brother, owner |
| Cash close completes with mismatch > `cash.mismatchPushThreshold` (default ₹100) | High | Push + in-app | Brother, owner |
| Outbox has events older than `obs.outboxStaleMinutes` (default 30 min) on any device | Medium | Push | Owner (about the device); shown in app on staff device |
| Print queue has > `obs.printQueueAlertCount` failures in last 24 h (default 3) | Medium | Push + in-app | Owner |
| Staff attempted an `❌` action (per [`role-permission-matrix.md`](./role-permission-matrix.md)) more than `auth.escalationWindowCount` times in `auth.escalationWindowMin` | High | Push + in-app | Owner |
| Projection mismatch detected by reconciliation (any `R1–R4`) | High | Push + in-app | Owner |
| Low stock for an item flagged as critical (per shop profile) | Low | In-app banner on next billing open | Staff, owner |
| Device offline more than `obs.deviceOfflineHours` (default 12 h) | Medium | Push | Owner |
| Schema-version mismatch with active client | High | Push + in-app | Owner |
| Backup job failure | High | Push + email (if configured) | Owner |
| Restore drill not run in the last `obs.restoreDrillIntervalDays` (default 30 days) | Low | In-app reminder | Owner |
| App crash (Crashlytics) | Medium | Email digest (daily) | Owner |
| Cold start regressed past budget on three consecutive launches | Low | In-app diagnostics card | Owner |
| Suspicion engine: deduplication conflict (same key, different payload) | High | Push + in-app | Owner |
| Suspicion engine: bill correction after cash close | High | Push + in-app | Owner |

### Channels

- **In-app** is always available; never depends on push
  delivery.
- **Push** uses Firebase Cloud Messaging; opt-in per user.
- **WhatsApp** is opt-in per shop; uses a templated message
  with a deep link back into the Review Queue (no PII in the
  message body beyond bill number and amount).
- **Email** is opt-in per user; primarily for owner digests.
- Push and WhatsApp are **augmentations**, not the source of
  truth. The same notification is always present in-app under
  the Review Queue with full context.

### Delivery rules

- Notifications are **idempotent**: the same `flag` does not
  push twice. Re-pushes happen only after the user has dismissed
  it and a new triggering event occurs.
- High-severity notifications are **not silenced** by per-user
  preferences — the owner always sees them in-app.
- Quiet hours (per shop profile) suppress push and WhatsApp for
  low/medium severity; high and block are always delivered.
- All notifications respect the **language** of the recipient
  (Hindi or English per their profile).

## Supportability — what every running app exposes

Every screen has a discoverable diagnostics path (long-press
on the app version badge, or Settings → Diagnostics):

| Surface | Value |
|---|---|
| App version | semver, build number, commit short SHA |
| Device id | stable per install; visible on every screen footer in diagnostics mode |
| Current shop id | `shop-1` for the family shop |
| Signed-in user | name, role, id, last token refresh |
| Network status | online / offline, last `online` event |
| Outbox depth | pending count, oldest event's age |
| Last successful sync | timestamp + count of events confirmed |
| Last failed sync | timestamp + reason if any |
| Print queue depth | pending count, oldest job's age, last failure |
| Active scenario / fixture in test builds | name; absent in production |
| Schema version | of the running client |
| Domain version | of the running client |
| Cache health | each projection's name, last update, size |
| Active draft (if any) | bill draft id and last save time |
| Trace id | per UI action that wrote an event; visible to expand in the History row |

### Action ids and trace ids

- Every user action that produces an event carries a
  `clientActionId` (see [`idempotency.md`](./idempotency.md)).
- The `clientActionId` is the **trace id** for that action: it
  threads through the bill row, the print job, the audit
  entry, the projection update, and any flag.
- Every History row shows its trace id on tap. Tapping it
  copies to clipboard for inclusion in a support report.

### "Send debug report" flow

- One tap from Diagnostics produces a downloadable JSON bundle
  containing:
  - app, schema, domain versions
  - signed-in user id (not PII beyond user id)
  - device id, OS / browser, screen size
  - last 24 h of in-app diagnostic events (network up/down,
    outbox events, print events, errors)
  - last 100 trace ids
  - cache health snapshot
  - the active draft snapshot (if any)
- The bundle **never** contains: customer/supplier names,
  phone numbers, transcripts, free-form notes, raw bill totals.
  It contains references (ids and event types) only.
- The bundle is shareable via standard share-sheet (WhatsApp,
  Drive, email).
- Generating the bundle appends a `support.debug-bundle-
  generated` audit event so its release is itself recorded.

### Crash reporting

- Crashlytics is enabled per
  [`decisions.md`](../../plan/rebuild/decisions.md) row 7.
- Stack traces are uploaded with app version and device id.
  PII is **never** in a stack trace by construction (no PII in
  error messages — see Forbidden patterns).
- Owner sees a daily email digest if crashes occurred.

### Analytics

- Firebase Analytics is enabled per the same decision row.
- Allowed events: `screen_view`, `action_started`,
  `action_succeeded`, `action_failed`, `flag_raised`,
  `print_attempted`, `outbox_drained`. All keyed by anonymised
  user id and the trace id; no PII.
- Forbidden events: anything carrying customer names, item
  names with prices, raw amounts, or voice transcripts.

## Forbidden patterns

- A toast that says "Something went wrong" with no trace id
  the user can show the owner.
- A push notification that contains a customer's name or
  phone number.
- A debug bundle that includes customer phone numbers, bill
  amounts, or voice transcripts.
- A silent failure that is only visible after manual log
  inspection.
- A notification path that depends on FCM / WhatsApp being up;
  the in-app surface must always carry the same signal.
- A "monitoring page" that the brother has to remember to open
  — the system pushes high-severity items.

## Required tests

- `notification-idempotent` — same flag does not push twice.
- `notification-high-severity-bypasses-quiet-hours` —
  delivered even during configured quiet window.
- `debug-bundle-contains-no-pii` — assert by schema that no
  PII keys are present.
- `diagnostics-shows-current-state` — Playwright opens
  Diagnostics, asserts app/schema/domain versions, outbox
  depth, network status.
- `trace-id-threads-through-action` — same id present on bill
  event, audit row, print event, flag, projection update.
- `crashlytics-payload-no-pii` — assert error messages contain
  no PII fields.

## Open items

- `TODO(spec)` — exact WhatsApp template wording (per language)
  and the configured template id with Meta. Owner to provide;
  defaults to in-app + push only until then.
- `TODO(spec)` — push preference defaults. Recommended:
  high + block opt-in by default; medium opt-in; low off.
- `TODO(spec)` — debug bundle retention server-side if the
  owner uploads one. Default: 30 days then auto-deleted.

## Recent changes

- _2026-06-15_ · file created. Notification catalogue with
  severity / channel / audience; channels (in-app always, push
  / WhatsApp / email opt-in); idempotent delivery with
  high-severity bypass; supportability surface (app / device /
  user / network / outbox / queues / cache); trace ids;
  one-tap debug bundle with PII-exclusion contract;
  Crashlytics / Analytics PII boundary; required tests.
