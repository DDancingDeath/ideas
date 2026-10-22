# Nudges and the reminders feed — Life OS

A **nudge** is a reminder or recommendation the system raises without being
asked. Every nudge is delivered through the cross-box reminders feed (dated)
or the box's recommendations (undated) — there is no third channel. The engine
that evaluates nudges is an open question ([README.md § Open questions](README.md#open-questions)).

## Reminders feed

| Rule |
| --- |
| One feed collects every box's `reminders` and the owner's own reminders, sorted into overdue, today, upcoming (within `reminders.upcomingDays`), later, snoozed, undated and done. |
| Done and snooze on another box's item apply to that occurrence only. Snooze hides an item until a local date-time. |
| Home shows a *Coming up* card; the life brief includes the same window. |
| In-app notifications while the app is open are off until `reminders.notifications.enabled` and `reminders.notifications.intervalMinutes` are set and the device allows them; they show the reminder's title only. |
| A calendar feed (see [privacy-security.md § Calendar feed](privacy-security.md#calendar-feed)) delivers reminders to the owner's calendar app. |
| Background push when the app is closed carries no personal content (e.g. "You have 3 reminders"). |

## Nudge catalogue

Every trigger uses only the owner's data and settings. A nudge whose input is
missing does not fire; the gap is listed under `missing` instead.

| Nudge | Box | Trigger | Delivered as |
| --- | --- | --- | --- |
| Owner reminder | Notes | its due date / repeat rule | reminder |
| Retest due | Health | last result date + `health.cadences[].everyDays`; tests in `health.checkupPlan` not yet done | reminder |
| Policy renewal | Finance | policy end date | reminder |
| FD maturity | Finance | the deposit's maturity date | reminder ([finance § FD maturity](boxes/finance.md#fd-maturity)) |
| Snapshot day | Finance | `reminders.financeSnapshotDayOfMonth` | reminder |
| Document expiry (passport, licence, policy) | Documents / identity vault | expiry date read from the document and confirmed | reminder |
| Expected document missing | Documents | `documents.expected[]` cadence + grace passed without a matching document | reminder |
| Birthday / anniversary | Family | event or exact birth date (incl. one confirmed from a birth certificate, [family](boxes/family.md#birth-date-from-a-birth-certificate)) | reminder |
| Vaccination due | Family | the owner's schedule and doses given | reminder |
| Learning session | Career | the learning plan's next session | reminder |
| Review period | Reflection | `reflection.reviewCadences` | reminder |
| Commitment | Conversations | a confirmed commitment draft | reminder |
| Relationship | Conversations | no contact with a person for longer than the owner's per-person interval | reminder |
| Spending drift | Finance | [finance § Spending insights](boxes/finance.md#spending-insights) | recommendation |
| Tax saving | Finance | [finance § Tax report](boxes/finance.md#tax-report) | recommendation |
| Stale data | Finance | value or price older than the owner's limit | recommendation (`data`) |

## Rules

| # | Rule |
| --- | --- |
| N1 | A nudge never writes data; any write it suggests opens a confirmation form. |
| N2 | A nudge cites its trigger facts (with provenance) and links to where to act. |
| N3 | The same subject produces one nudge; repeats update it rather than adding another. |
| N4 | Dates follow [cross-cutting.md § Dates](cross-cutting.md#dates-and-time-zone). |
