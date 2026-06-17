# Page spec: Review Queue (`review`) — new in rebuild

> **New page in v2.** Not present in the v1 page-specs. This is the
> primary surface for the brother / owner to monitor the shop. It
> turns the suspicion engine's flags into an actionable to-do list.

## Purpose

Give the monitoring user (brother / owner) one place to see
everything the app is unsure about — anomalies, possible duplicates,
cash mismatches, large discounts, negative-stock attempts, backdated
entries, sync issues, print failures — and to resolve each item with
one of `approve`, `dismiss`, or `correct`.

## Who can use it

- View: roles with `reviewQueue.read` permission. Default: `owner`.
  `TODO(spec)`: confirm whether `manager` can read.
- Resolve: roles with `reviewQueue.resolve` permission. Default:
  `owner`.
- Staff: cannot see this page.

## What the user sees (top → bottom)

1. **Header summary** — counts by severity (`high` / `medium` /
   `low`), counts unresolved vs resolved-today, last refresh time.
2. **Filter bar** — by severity, by rule id, by date range, by
   actor (which staff member's action raised the flag), by item /
   party.
3. **List of unresolved flags**, default sort: severity desc, then
   recency desc. Each row shows:
   - severity chip (color-coded)
   - rule id and one-line summary
   - the offending event in human form ("Retail bill #1234 for
     Ramesh on 14 Jun, ₹2,450 — discount 22% exceeds 10% limit")
   - timestamp and actor
   - quick actions: **Approve**, **Dismiss**, **Open bill**,
     **Correct**
4. **Resolved tab** — same shape, read-only, with the resolution
   and resolver shown.
5. **Diagnostics tab** — reconciliation status (R1–R4 in
   `invariants.md`): last replay run, any projection drift detected,
   audit gap count. Not per-flag, but a system health view.

## What the user can do

| Action | Effect | Writes |
|---|---|---|
| **Approve** | The flagged data is correct as-is. Records a `flag_resolved` event with `resolution = approve` | `flag_resolved` |
| **Dismiss** | False positive. Records `flag_resolved` with `resolution = dismiss`. (Repeated dismissals of the same rule may surface a tuning suggestion in Diagnostics.) | `flag_resolved` |
| **Open bill** | Navigates to the bill detail view; user can then file a void or correction; on save, that correction event is referenced from `flag_resolved` with `resolution = correct` | navigate; eventually `bill_correction_recorded` or `bill_voided` and `flag_resolved` |
| **Correct** | Shortcut: opens the bill in correction mode pre-filled with the engine's suggested fix (when the rule has one) | as above |
| **Bulk approve / dismiss** | Multi-select within one rule id. Audit row records the bulk action and references each `flagId`. | one `flag_resolved` event per flag |
| **Note** | Optional free-text per resolution | included in `flag_resolved.note` |
| **Tune rule** | Opens the rule's `shopProfile` setting (severity / threshold / enabled). Owner only. | `shop_profile_updated` |

## Calculations / formulas

- Counts: a fold over unresolved `flag_raised` events by severity.
- "Resolved today" = `flag_resolved` events with `resolvedAt`
  inside the shop's local-day window.
- "Last refresh time" = the latest of (most recent event seen,
  reconciliation job last-run timestamp).
- Sort order tiebreaker for equal severity: most recent
  `raisedAt` first.

No money math on this page — it surfaces the engine's outputs and
references the underlying events.

## Data sources

- `flag_raised` events (unresolved subset)
- `flag_resolved` events (for the Resolved tab)
- The original event referenced by each flag (read-only)
- Reconciliation job status (Diagnostics tab)
- `shopProfile.suspicion` (for the Tune rule action)

## Must NOT do

- Must NOT silently dismiss a flag without writing a
  `flag_resolved` event. Every disposition is auditable.
- Must NOT allow a staff role to see or resolve flags.
- Must NOT mutate the original flagged event. Corrections are
  separate events.
- Must NOT show a flag whose target event has been voided without
  also showing the void; the row should make clear the bill is
  already gone.
- Must NOT let a `block` rule become invisible (filtered or
  hidden) — `block`-severity flags exist only when an override
  attempt was made and always show in the Review Queue.

## Notification

`TODO(spec)`: how the brother is alerted to new `high`-severity
flags. Candidates: in-app badge, push notification (FCM via
Capacitor), email digest, WhatsApp message via a chosen integration.
Default for v2.0: in-app badge + a **daily digest** on the Today
page. The daily digest lists **every flag raised that day, grouped
by severity** (low / medium / high), unresolved ones highlighted — so
a flag that was "saved anyway" at the counter (e.g. an unusually low
rate) is still reviewed at day-close. How the flag also surfaces
**inline while the bill is being made** is in
[`suspicion-engine.md`](./suspicion-engine.md) §When and where a
flag surfaces.

## Example bug reports → what to change

- "I approved a flag and it came back" → check whether the engine
  is generating a new flag for a new event (correct behaviour) or
  re-firing for the same event after resolution (bug — engine must
  not raise for events that already have an unresolved flag of the
  same rule).
- "I can't see why this discount was flagged" → check the
  `context` field on the flag; if missing, the rule's emission
  code is incomplete.
- "The brother gets too many low flags" → tune `shopProfile`:
  demote rule, raise its threshold, or move it to digest-only.
- "Two people resolved the same flag at the same time" →
  storage adapter must reject the second `flag_resolved` (one
  flag, one resolution); double-resolve is a bug in the adapter.
