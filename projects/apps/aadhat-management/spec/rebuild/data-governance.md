# Data governance — rebuild

> Who can read, export, delete, and merge each kind of data.
> What is kept and for how long. What customer / staff personal
> information the app stores. The compliance boundary the family
> shop operates within. The contracts that
> [`role-permission-matrix.md`](./role-permission-matrix.md),
> [`audit log`](./review-queue.md#audit), and
> [`failure-modes.md`](./failure-modes.md) F20 (lost phone) all
> depend on.

This file says **what the system permits and remembers**, not
how the human acts on it. The human procedures live in
[`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md).

## Scope

Three concerns nest here:

1. **Privacy and ownership** of data the app collects.
2. **Master data governance** — how items, parties, and rates
   evolve cleanly over time.
3. **Legal / compliance boundary** — what the app records that
   matters outside the shop (bill numbering, retention,
   accountant export).

GST and e-invoicing remain explicitly **out of scope** for v2.0
per [`scope-boundaries.md`](./scope-boundaries.md). This file
defines the contract the app **does** enforce.

## Ownership and access matrix

| Capability | staff | owner | engine / system | Notes |
|---|:-:|:-:|:-:|---|
| Read own-day data | ✅ | ✅ | ✅ | Per [`role-permission-matrix.md`](./role-permission-matrix.md) |
| Read all-time data | ❌ | ✅ | ✅ | |
| Export bills (CSV/JSON) | ❌ | ✅ | ✅ | See §Export |
| Export financial reports | ❌ | ✅ | ✅ | |
| Export audit log | ❌ | ✅ | ✅ | |
| Archive item / party | ❌ | ✅ | — | Soft-archive only |
| **Delete** business data | ❌ | ❌ | — | Forbidden; corrections are events |
| Merge duplicate items | ❌ | ✅ | — | See §Master data governance |
| Merge duplicate parties | ❌ | ✅ | — | |
| Change shop profile | ❌ | ✅ | — | Per role matrix |
| Reset projections | ❌ | ✅ | ✅ | Reproducible from events |
| Wipe a device | ❌ | ✅ | — | See §Lost or replaced device |
| Revoke a user | ❌ | ✅ | — | Server-enforced |

The deliberate `❌` for **delete** is the most important row.
**Business events are immutable.** Corrections, voids, and
adjustments are new events that reference the original. The
event log is the only honest history.

## What personal data the app stores

Minimised by design.

| Data | Stored where | Required? | Notes |
|---|---|---|---|
| Owner / staff name | Server | ✅ | For audit attribution |
| Owner / staff email | Server (Auth) | ✅ | For sign-in |
| Owner / staff phone | Server | Optional | Owner may store for runbook contact |
| Customer / supplier name | Server | ✅ | Required for bills and udhaar |
| Customer / supplier phone | Server | Optional | Useful for WhatsApp follow-up; never required for billing |
| Customer / supplier address | Server | Optional | Used on printed bill if entered |
| Voice transcripts | Local + server-redacted | Optional | See §Voice transcripts |
| Photos (item / cheque / receipt) | Server (Firebase Storage) | Optional | Out of scope for v2.0 |
| Device id | Server | ✅ | For audit + lost-phone revocation |
| App version | Server | ✅ | Per every write |
| Coarse location | Not stored | ❌ | Never collected |
| Biometric / payment details | Not stored | ❌ | Never collected |

### Voice transcripts

- Transcripts are produced on-device by the voice billing flow
  (per [`spec/voice-billing-v2.md`](../voice-billing-v2.md)).
- Recordings are **not** persisted by default. Transcripts are
  retained only when they are referenced by a created event;
  free-form transcripts that did not result in a bill are
  discarded.
- A retained transcript is stored alongside the event with the
  speaker's user id, never the raw audio. Owner can export or
  purge.

### Customer phone numbers

- Customer phone is **optional** on every entry path.
- If entered, it is searchable on the device and visible on
  printed bills.
- A `party_updated` event records every change with the
  `by` user; an exported audit trail shows the full history.

### Local encryption

- IndexedDB is treated as a sensitive store. Outbox rows and
  cached events live there.
- Device-level encryption (Android File-Based Encryption) is
  assumed; the app does not add a second encryption layer.
- The forced-upgrade screen and the lost-phone flow
  (§Lost or replaced device) are the primary defences in case
  of physical theft.
- A future at-rest encryption pass over IndexedDB is tracked as
  an open item; v2.0 relies on OS-level encryption plus device
  revocation.

## Master data governance

Items, parties, and unit rates accumulate over time. The
contract for keeping them clean.

### Duplicate item merge

- Triggered by owner action only.
- The merge creates an `item_merged` event:
  ```
  { fromItemId, toItemId, by, at, schemaVersion, reason }
  ```
- The source item is **archived**, not deleted. Future event
  reads transparently re-route `fromItemId → toItemId` via the
  items projection.
- Historical bill events that referenced `fromItemId` continue
  to show that id in audit; in projections they are folded as
  the merged item.
- Stock-on-hand is summed. Rate history is unioned.
- An `R3` reconciliation invariant asserts post-merge stock =
  pre-merge sum-of-stock.

### Duplicate party merge

- Same shape as item merge; event type `party_merged`.
- Outstanding balances are summed. Bill history union-merged.
- An `O3` reconciliation invariant asserts post-merge
  outstanding = pre-merge sum-of-outstanding.

### Rate change history

- Item rate changes are events (`item_rate_changed` per
  [`event-schemas.md`](./event-schemas.md)) — never silent
  edits.
- A bill at time T uses the **rate as of T**, not the current
  rate. The bill event captures the resolved rate in its
  payload so historical bills always re-fold to the same
  totals.
- Rate-change events have a mandatory `reason` (free text;
  flagged by suspicion engine if generic).

### Archived items / parties

- Archived rows are **hidden** from picker UIs but remain in
  history, audit, and reports.
- An archived item cannot be the subject of a new sale or
  purchase. The picker exposes an `Include archived` filter for
  owner-only views.
- Unarchiving is an event.

### Typo correction

- For an item / party name typo: owner edits via Admin; the
  service appends `item_updated` (or `party_updated`) with the
  old and new value in the payload.
- For an in-flight bill that already references the wrong name:
  the bill keeps the name as it was when the bill was created
  (point-in-time integrity). Re-rendered prints show the
  current name only if explicitly reprinted.

### Hindi / English name changes

- Items and parties carry both `nameHi` and `nameEn`.
- Either may be edited independently; the audit trail records
  both old and new values.
- Picker matches against both fields.

## Retention

How long each kind of data is kept.

| Data | Retention | Why |
|---|---|---|
| Event ledger (business) | Forever | The shop's only honest history |
| Audit log | Forever | Owner needs full history; small volume |
| Print attempt records | 1 year | Useful for debugging printer issues; large volume |
| Telemetry (Crashlytics / Analytics) | 90 days | Diagnostics window; nothing financial |
| Voice transcripts (retained) | Same as the event they back | Tied to event lifetime |
| Voice transcripts (free-form, unreferenced) | Not persisted | Privacy |
| Outbox (local) | 30 days max | Beyond that, surfaces a banner per [`offline-sync.md`](./offline-sync.md) |
| Cache (projections, item / party master) | Until invalidated by domain bump or event | Bounded by quota |
| Backups | 90 days rolling | See [`../../plan/rebuild/backup-restore.md`](../../plan/rebuild/backup-restore.md) |
| Deleted user records | Forever (status `rejected`, sign-in blocked) | Audit attribution needs the user to still exist |

The audit log and event ledger are **never** thinned. Storage
cost is trivial relative to the value of an honest history.

## When staff leaves

- Owner sets the user's status to `suspended` first (preserves
  identity for audit). Optionally, later, `rejected`.
- Token refresh fails on the staff's device; all writes from
  that device cease.
- Existing audit / event attribution is preserved — the user
  row stays, only their ability to sign in is removed.
- Any unsynced events on the staff's device follow
  [`failure-modes.md`](./failure-modes.md) §F19 / F20.

## Lost or replaced device

- Owner revokes the user (or rotates their credential) via
  Admin.
- Owner may also force-purge the **device's** cache via the
  next sign-in on a fresh device: cache is rebuilt from events;
  no shop data is permanently device-local.
- The runbook lives in
  [`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md)
  §Lost phone.

## Export

The owner can export:

| Export | Format | Includes | Excludes |
|---|---|---|---|
| Bills (range) | CSV + JSON | Bill events, projections, references | Audit, internal flags |
| Stock snapshot | CSV | Current projection | Event log |
| Outstanding snapshot | CSV | Current projection | Event log |
| Reports (range) | CSV + PDF | Aggregated numbers | Per-row PII beyond names |
| Audit log (range) | CSV + JSON | Full event envelope | — |
| Full event ledger | JSON | Every event, every field | — |

Exports are owner-only, watermarked with shop name, date, and
the exporting user; the export action is itself an event
(`data_exported`) in the audit log.

## Bill numbering and legal posture

- Each bill carries a human-readable bill number. Numbering
  is per-shop, monotonic-by-cash-session, with the format
  defined in [`event-schemas.md`](./event-schemas.md)
  (`retail_sale_created` payload).
- Bill numbers are **never** reused after a void; the voided
  bill keeps its number and a void event references it.
- Offline-allocated numbers (per the open item in
  [`offline-sync.md`](./offline-sync.md)) carry an `offline-
  issued` marker until server-reconciled.
- Printed bill wording defaults to "Bill / बिल"; "Invoice"
  wording with `GSTIN: …` is configurable per shop profile.
  Until a GSTIN is set, no invoice wording is printed.
- Accountant exports (CSV with all bills + payments for a
  period) are the supported integration point.
- No GST returns, no e-invoicing, no e-way bills in v2.0.

## Required tests

- `merge-items-projection-stable` — pre-merge stock sum =
  post-merge stock; rate history unioned; bill projections
  re-fold identically.
- `merge-parties-outstanding-stable` — pre-merge balance sum =
  post-merge balance.
- `archived-item-blocked-from-new-bill` — picker excludes it;
  service rejects it.
- `historical-bill-uses-rate-at-time` — bill total replays
  exactly even after a rate change.
- `revoked-user-cannot-write` — server refuses every write
  after revocation.
- `export-action-is-audit-event` — every export appends
  `data_exported`.
- `voice-transcript-not-persisted-when-no-event` — discarded
  on flow abandon.
- `retention-print-records-pruned-after-1-year` — background
  job removes per the retention table.

## Open items

- `TODO(spec)` — at-rest encryption for IndexedDB beyond OS-
  level FBE. Default v2.0: rely on FBE + device revocation.
- `TODO(spec)` — accountant export schema (column order,
  charset, date format). Default: UTF-8 CSV, ISO-8601 dates,
  amounts in rupees (₹) with two decimals.
- `TODO(spec)` — exact merge UX (preview, confirm with both
  candidates side by side, undo window). Default: owner-only
  with explicit preview screen; no undo (merge is an event).
- `TODO(spec)` — telemetry purge cadence. Default: 90 days
  rolling, enforced by Firebase project setting.

## Recent changes

- _2026-06-15_ · file created. Ownership / access matrix
  (delete is forbidden; corrections are events); minimised
  PII inventory with voice-transcript discard rule;
  master-data governance for merges, rate history, archive,
  typo correction, Hindi/English names; retention table;
  staff-leaves and lost-phone flows; export contract with
  audit-event coupling; bill-numbering and legal posture
  with GST out of scope; required tests.
