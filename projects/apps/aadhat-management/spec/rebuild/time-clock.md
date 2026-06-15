# Time and clock — rebuild

> Every event has two timestamps: `at` from the **server**
> (authoritative) and `clientAt` from the **device** (audit-
> only). Device clocks lie. The system handles that explicitly:
> backdated events flag, future-dated events are blocked,
> reports use the shop's timezone, and the shop "day" is the
> open cash session — not midnight.

## Why this doc exists

Two times appear on every event envelope (per
[`event-schemas.md`](./event-schemas.md)):

- `at` — the server timestamp, assigned at append.
- `clientAt` — the device timestamp at intent time, recorded for
  the audit trail.

[`invariants.md`](./invariants.md) T1 says event timestamps
that affect money or stock are server-assigned; T2 says
backdating beyond `shopProfile.backdateToleranceDays` raises a
flag. This file consolidates what that means in practice when
the device is offline, when its clock is wrong by hours, when
the shop's day boundary doesn't match midnight, and when a
report says "yesterday".

The principle:

> The server's clock is truth. The device's clock is evidence.
> The shop's clock is its open cash session.

## What each timestamp means

| Timestamp | Source | Authority | Used by |
|---|---|---|---|
| `at` | Server, at append | **Authoritative** | Ordering, reports, projections, all "when did X happen" reads |
| `clientAt` | Device, at intent | Audit-only | Skew detection, suspicion-engine inputs, debugging |
| `appendedAt` (storage adapter detail) | Storage, internal | Implementation detail | Adapter-internal; never reaches projections |

The application services receive `clientAt` from the UI; the
storage adapter overwrites or adds `at` at the moment of
append. The UI **never** reads `at` from anywhere but the
event itself after the server has acknowledged.

## Offline events

When the device is offline:

1. The event is created with `clientAt = device.now()` and
   queued in the outbox.
2. The UI shows it as `Saved` (per
   [`offline-sync.md`](./offline-sync.md) state vocabulary).
   The row's "when" displays `clientAt` with a small badge that
   it is local-only.
3. On reconnect, the server assigns `at` at acceptance.
4. The UI updates the row to show `at` (and the `Synced`
   badge), but **keeps the `clientAt`** visible in the bill
   detail / audit view so the staff can see "I rang this up at
   6:48 PM; the server logged it at 7:12 PM when the network
   came back".
5. Projections recompute using `at`. The shop's "today"
   becomes whatever cash session was open at `at`, not at
   `clientAt` — see [§Shop day](#shop-day) below.

If `at − clientAt` exceeds a sync-delay threshold
(`shopProfile.time.maxSyncDelayMin`, default 1440 minutes = 24
hours), the device raises a `sync-delay-suspicious` flag at
ingest. The event is still accepted.

## Clock skew handling

Skew is `clientAt − at` (positive = device is ahead, negative =
device is behind).

| Skew window | Behaviour |
|---|---|
| `\|skew\| ≤ shopProfile.time.toleranceMin` (default 5 min) | Accepted silently; no flag |
| `shopProfile.time.toleranceMin < \|skew\| ≤ shopProfile.time.toleranceMin × 6` (default 30 min) | Accepted; `clock-skew-warning` low-severity flag raised; device-diagnostics view shows the skew |
| `\|skew\| > shopProfile.time.toleranceMin × 6` (default 30 min) | **Backdated** events (positive skew on a clientAt < at) → see [§Backdated](#backdated-events); **future-dated** events (clientAt > at by more than the window) → see [§Future-dated](#future-dated-events) |

On every successful sync, the device records the observed skew
and uses an exponential-moving-average to detect drift. A
sustained drift above 1 minute / day raises
`device-clock-drift` (medium severity); the operations runbook
walks the owner through enabling NTP on the staff phone.

## Backdated events

An event with `clientAt < (at − shopProfile.backdateToleranceDays)`
is **accepted but flagged**:

- `flag_raised(rule: 'backdated', severity: 'high')`
- The Review Queue surfaces the bill with both timestamps.
- Brother decides whether the bill is legitimate (e.g. "phone
  was dead all morning, I billed it at noon") or fraudulent
  (e.g. "staff backdated to a previous cash session").
- A `bill_voided` or `bill_correction_recorded` follows the
  normal flow; the original event stays in the ledger.

`backdateToleranceDays` defaults to 1 (today and yesterday).

## Future-dated events

An event with `clientAt > (at + shopProfile.time.maxFutureMin)`
(default 60 minutes) is **blocked at the adapter** with
`BLOCKED_BY_RULE`:

- The UI shows: "Your phone's clock is set to the future. Fix
  the date / time and try again."
- The intent is preserved in a local "rejected drafts" view so
  the staff doesn't lose the work.
- A `clock-future-block` flag is raised so the brother sees a
  staff phone with a broken clock.

The rationale is that a future-dated bill in the ledger silently
breaks "today" calculations and report periods; rejecting it is
safer than flagging it.

## Shop day

The shop's day is bounded by the **open cash session**, not by
calendar midnight. This is pinned in
[`../../plan/rebuild/decisions.md`](../../plan/rebuild/decisions.md)
row 9. The contract:

- "Today" on every screen means "the currently-open cash
  session". If no session is open, it falls back to the
  calendar day in the shop's timezone.
- Period-end on reports uses the **last closed session's
  close time**, not midnight, unless the period is explicitly
  set to "calendar days" by the user.
- A bill rung up at 1:05 AM after a session that opened at
  9:00 AM yesterday is part of **yesterday's** day for cash
  reconciliation, even though it crossed midnight.
- A new session that opens at 9:00 AM today starts today's
  cash day; bills before that (and after last night's close)
  fall in a `no-session` bucket and raise a `bill-outside-
  session` low-severity flag.

The cash session boundary is what `R4` (Today == Finance ==
Reports) tests against — the assertion is "all three views
agree on what 'today' means", not "all three views agree on
midnight".

## Reports use shop timezone

- Every report carries the shop's timezone (`shopProfile.timezone`,
  default `Asia/Kolkata`) in its header.
- The device's timezone is **never** used for report period
  boundaries. A staff phone set to `Asia/Dubai` does not shift
  the report.
- The owner can override the timezone in shop profile; doing so
  raises a `shop-timezone-changed` audit event and re-renders
  cached report projections.
- Times in a report are always shown in shop time; the row
  detail view shows both shop time and the original `clientAt`
  for traceability.

## Display rules

| Surface | Time shown | Notes |
|---|---|---|
| History row | `at` in shop timezone | Default short format: `6:48 PM, today` / `Mon 4:12 PM` / `12 Jun, 6:48 PM` |
| Bill detail | `at` and `clientAt` (if they differ) | Helps explain offline gap |
| Audit log | `at` and `clientAt` and `by` | Always both timestamps |
| Reports | Period boundaries in shop timezone | Header carries the timezone name |
| Today dashboard | "Session opened at HH:MM" | Anchors the user to the session boundary |
| Cash close form | Session opened `at`; "now is" current shop time | |

The 12 / 24 hour display preference is `shopProfile.locale.timeFormat`,
default 12-hour. Choosing 24-hour is a per-shop config; the
underlying timestamps are unchanged.

## What the storage adapter enforces

The adapter is the line of truth for time:

1. Overwrites `at` on every append. Client-provided `at` is
   refused; client-provided `clientAt` is required.
2. Refuses events where `clientAt − at > shopProfile.time.maxFutureMin`
   with `BLOCKED_BY_RULE`.
3. Accepts (with `OK`) events where `at − clientAt >
   shopProfile.backdateToleranceDays`, **and** appends a
   `flag_raised(rule: 'backdated')` in the same transaction.
4. Records the observed skew in the device's diagnostics
   snapshot.
5. Stamps event ordering via a monotonically increasing `seq`
   that is independent of `at` (per
   [`offline-sync.md`](./offline-sync.md) §Conflict handling
   "Out-of-order replay"). Two events with the same `at` keep
   their relative order via `seq`.

These adapter behaviours are part of `security` and
`integration` CI jobs (per
[`ci-contract.md`](./ci-contract.md)).

## Tests this spec requires

- `clientAt-preserved-after-sync` — offline bill keeps its
  original `clientAt` after server `at` is assigned.
- `skew-within-tolerance-no-flag` — 3-minute skew, no flag.
- `skew-warning-band` — 10-minute skew, warning flag, accepted.
- `backdate-out-of-tolerance-flagged-but-accepted` — bill
  dated 3 days ago, accepted, high-severity flag.
- `future-date-blocked` — bill dated 2 hours from now,
  refused, no event in ledger, draft preserved.
- `session-day-not-midnight` — bill at 00:45 with session
  still open from 09:00 yesterday belongs to yesterday's day.
- `no-session-bucket` — bill rung up between sessions raises
  `bill-outside-session` flag.
- `report-timezone-shop-not-device` — staff phone in
  `Asia/Dubai`; report still uses `Asia/Kolkata`.
- `drift-ema-detected` — sustained 70 s / day drift over a
  week raises `device-clock-drift`.
- `at-ordering-monotonic-by-seq` — two events with identical
  `at` keep stable order via `seq`.

## Open items

- `TODO(spec)` — should the staff UI render `clientAt` or `at`
  on the History row when they differ? Default: `at`, with the
  `clientAt` shown in the detail.
- `TODO(spec)` — the no-session bucket — should it block
  bills entirely, or just flag? Default: flag (staff may need
  to ring up a bill before opening the session).
- `TODO(spec)` — auto-suggest opening a session if first bill
  of the day lacks one. Default: yes, with one-tap "Open
  session" inline.

## Recent changes

- _2026-06-16_ · file created. Two-timestamp model
  (`at` authoritative, `clientAt` audit-only); offline
  preservation rule; clock-skew tolerance bands; backdated
  events accepted-with-flag; future-dated events blocked;
  shop day = open cash session per decisions row 9; reports
  always in shop timezone; storage-adapter responsibilities;
  required tests.
