# Data governance — rebuild

> Read/export/delete/merge permissions, retention, personal data, and compliance boundaries. Dependent specs: [`role-permission-matrix.md`](./role-permission-matrix.md), [`audit log`](./projections.md#audit-log), and [`failure-modes.md`](./failure-modes.md) F20.

Human procedures live in [`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md). GST and e-invoicing are out of scope for v2.0 per [`scope-boundaries.md`](./scope-boundaries.md).

## Scope

1. Privacy and ownership.
2. Master data governance: items, parties, rates.
3. Legal/compliance records: bill numbering, retention, accountant export.

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

Business events are immutable. Corrections, voids, and adjustments are new events that reference the original.

## What personal data the app stores

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

- Produced on-device by voice billing; see [`spec/voice-billing-v2.md`](../voice-billing-v2.md).
- Raw recordings are not persisted by default.
- Transcripts are retained only when referenced by a created event; abandoned free-form transcripts are discarded.
- Retained transcript stores speaker user id, never raw audio. Owner can export or purge.

### Customer phone numbers

- Optional on every entry path.
- If entered, searchable on device and visible on printed bills.
- Every change is a `party_updated` event with `by`; export shows full history.

### Local encryption

- IndexedDB stores outbox rows and cached events.
- Android File-Based Encryption is assumed; no second encryption layer in v2.0.
- Forced upgrade and lost-phone flows are the theft defences.
- Future IndexedDB at-rest encryption remains open.

## Master data governance

### Duplicate item merge

- Owner-only; appends `item_merged`:
  ```
  { fromItemId, toItemId, by, at, schemaVersion, reason }
  ```
- Source item is archived, not deleted.
- Future reads reroute `fromItemId → toItemId` via items projection.
- Historical bill audit keeps `fromItemId`; projections fold as merged item.
- Stock-on-hand is summed; rate history is unioned.
- `R3`: post-merge stock = pre-merge sum-of-stock.

### Duplicate party merge

- Event type: `party_merged`; same shape as item merge.
- Outstanding balances are summed; bill history union-merged.
- `O3`: post-merge outstanding = pre-merge sum-of-outstanding.

### Rate change history

- Item rate changes are `item_rate_changed` events; see [`event-schemas.md`](./event-schemas.md).
- A bill at time T uses rate as of T; event payload captures the resolved rate.
- Rate-change events require `reason`; generic reasons are flagged by suspicion engine.
- Owner sees chronological rate set-points and transacted buy/sell trend in [`projections.md`](./projections.md#rate-history-per-item).

### Archived items / parties

- Hidden from picker UIs; retained in history, audit, and reports.
- Archived item cannot be used in a new sale or purchase.
- Owner-only views expose `Include archived`.
- Unarchiving is an event.

### Typo correction

- Item/party name typo: owner edit appends `item_updated` or `party_updated` with old and new value.
- In-flight bill keeps the name captured at bill creation.
- Re-rendered prints show current name only when explicitly reprinted.

### Hindi / English name changes

- Items and parties carry `nameHi` and `nameEn`.
- Either may be edited independently; audit records old and new values.
- Picker matches both fields.

## Retention

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

Audit log and event ledger are never thinned.

## When staff leaves

- Owner sets user status to `suspended`, optionally later `rejected`.
- Token refresh fails; writes from that device cease.
- User row remains for audit attribution.
- Unsynced events follow [`failure-modes.md`](./failure-modes.md) §F19 / F20.

## Lost or replaced device

- Owner revokes user or rotates credential via Admin.
- Fresh device sign-in can force-purge old device cache; cache rebuilds from events.
- Human runbook: [`../../plan/rebuild/operations-runbook.md`](../../plan/rebuild/operations-runbook.md) §Lost phone.

## Security and abuse prevention

- Firebase App Check is required in production for every Firebase client: reCAPTCHA v3 on web, Play Integrity on Android.
- App Check is enforced with strict Firestore rules; public web config possession cannot issue Firestore requests.

## Export

| Export | Format | Includes | Excludes |
|---|---|---|---|
| Bills (range) | CSV + JSON | Bill events, projections, references | Audit, internal flags |
| Stock snapshot | CSV | Current projection | Event log |
| Outstanding snapshot | CSV | Current projection | Event log |
| Reports (range) | CSV + PDF | Aggregated numbers | Per-row PII beyond names |
| Audit log (range) | CSV + JSON | Full event envelope | — |
| Full event ledger | JSON | Every event, every field | — |

Exports are owner-only, watermarked with shop name/date/exporting user, and append `data_exported` to the audit log.

## Bill numbering and legal posture

- Bill number is per-shop, monotonic-by-cash-session; format is in [`event-schemas.md`](./event-schemas.md) (`retail_sale_created` payload).
- Bill numbers are never reused after void; void references the original bill number.
- Offline-allocated numbers carry `offline-issued` until server-reconciled.
- Printed wording defaults to `Bill / बिल`; `Invoice` with `GSTIN: …` is configurable per shop profile.
- Until GSTIN is set, no invoice wording prints.
- Accountant export is CSV with all bills + payments for a period.
- No GST returns, e-invoicing, or e-way bills in v2.0.

## Validation gates

Applies to all writes against `items`, `parties`, and rates from owner UI, import tool, programmatic admin, and agent writes.

### Gate codes

Adapter results use `OK, SCHEMA_INVALID, INVARIANT_VIOLATION, PERMISSION_DENIED, REFERENCE_INVALID, IDEMPOTENCY_CONFLICT, BLOCKED_BY_RULE, OUT_OF_ORDER, UNAUTHORIZED`.

| Code | When |
|---|---|
| `SCHEMA_INVALID` | Empty required field, malformed type, value outside permitted range |
| `BLOCKED_BY_RULE` | Soft-uniqueness collision (duplicate item / party) when the caller has not explicitly chosen "create anyway" |
| `INVARIANT_VIOLATION` | Hard-uniqueness collision (impossible state) or post-merge reconciliation failure |
| `REFERENCE_INVALID` | Bill or purchase references an archived item; party reference does not exist |

`BLOCKED_BY_RULE` is resolved by merge/create-anyway/edit-existing. `SCHEMA_INVALID` fixes form input. `REFERENCE_INVALID` fixes the parent record.

### Items

| Rule | Code on violation | Notes |
|---|---|---|
| `nameEn` and `nameHi` together cannot both be empty (at least one must have a non-whitespace value) | `SCHEMA_INVALID` | UI shows: "Please enter at least one of English / Hindi name" |
| `unit` is one of the supported units (`kg`, `piece`) at create time | `SCHEMA_INVALID` | New units require a `domainVersion` bump |
| Rate is a positive integer in the unit's atomic representation (`paisePerKg` for weight, `paisePerPiece` for piece) | `SCHEMA_INVALID` | Zero rate is forbidden; free items use a discount |
| Rate is below `shopProfile.items.rateCeilingPaise` per [`configuration.md`](./configuration.md) | `BLOCKED_BY_RULE` | Owner can confirm-override; raises `rate-suspicious` low flag |
| Soft-uniqueness: no other non-archived item has the same `(unit, normalize(nameEn ∪ nameHi))` where normalize is lowercase + collapse whitespace + strip common punctuation | `BLOCKED_BY_RULE` | UI offers merge into existing, create anyway with `duplicate-item-confirmed` flag, or cancel |
| Cannot create a sale or purchase line referencing an `archived` item | `REFERENCE_INVALID` | UI shows: "Item is archived. Unarchive first." |
| Hard rule: every rate change appends an `item_rate_changed` event (cannot silently update the item row) | `BLOCKED_BY_RULE` | Owner UI always uses the event; programmatic updates skipping it are refused |
| Cannot delete an item ever (per ownership matrix) | `PERMISSION_DENIED` | Only `item_archived` |

### Parties (customers / suppliers)

| Rule | Code on violation | Notes |
|---|---|---|
| `name` cannot be empty | `SCHEMA_INVALID` | At least one of English / Hindi name |
| `phone` if provided is exactly 10 digits (Indian mobile format), no `+91`, no spaces | `SCHEMA_INVALID` | UI normalises to the 10-digit form before validation |
| Soft-uniqueness on phone: no other non-archived party has the same `phone` | `BLOCKED_BY_RULE` | UI offers merge, create-anyway with flag, or cancel |
| Soft-uniqueness on name when phone is absent: no other non-archived party has the same `normalize(name)` AND `type` (customer / supplier) | `BLOCKED_BY_RULE` | Same merge / create-anyway / cancel choice |
| Cannot create a bill referencing an `archived` party | `REFERENCE_INVALID` | |
| Settlement events reference a party id that exists | `REFERENCE_INVALID` | |

### Rates and rate-change history

| Rule | Code on violation | Notes |
|---|---|---|
| `item_rate_changed` carries a non-empty `reason` (free text) | `SCHEMA_INVALID` | Empty `reason` rejected; generic `reason` ("update", "change", "abc") triggers `rate-reason-generic` low flag and is accepted |
| Bill at time T uses the rate as of T, captured into the event payload | (architectural) | Domain helper enforces; tests assert later rate changes do not alter T's bill replay |
| Two rate changes within `shopProfile.items.rateChangeMinIntervalSec` on the same item raise a `rate-flapping` flag | (accepted) | Low severity; Review Queue shows the pattern |

### Merge contracts (cross-cutting)

| Rule | Code on violation | Notes |
|---|---|---|
| Only `owner` can merge (per ownership matrix) | `PERMISSION_DENIED` | |
| Merge `fromItemId == toItemId` is rejected | `SCHEMA_INVALID` | |
| Merging an archived item **into** a non-archived one is allowed; the reverse is rejected | `BLOCKED_BY_RULE` | Direction must be: archived → live |
| Post-merge stock sum equals pre-merge stock sum (`R3`) | `INVARIANT_VIOLATION` | Merge transaction is aborted; nothing is partially applied |
| Post-merge outstanding sum equals pre-merge outstanding sum (`O3`) | `INVARIANT_VIOLATION` | Same |
| Merge appends exactly one `item_merged` (or `party_merged`) event | (architectural) | No shadow updates of historical bill events; rerouting happens at projection time |

### Required tests

Gate-level tests complement [§Required tests](#required-tests):

- `item-empty-names-rejected` — both name fields empty → `SCHEMA_INVALID`.
- `item-zero-rate-rejected` — zero `paisePerKg` → `SCHEMA_INVALID`.
- `item-rate-above-ceiling-blocked` — over `shopProfile.items.rateCeilingPaise` → `BLOCKED_BY_RULE` + flag.
- `item-duplicate-soft-unique-blocked-suggest-merge` — case/whitespace-insensitive match.
- `item-create-anyway-records-flag` — caller opts past soft block; `duplicate-item-confirmed` flag present.
- `archived-item-in-bill-rejected` → `REFERENCE_INVALID`.
- `party-phone-not-10-digits-rejected` → `SCHEMA_INVALID`.
- `party-duplicate-phone-blocked-suggest-merge`.
- `rate-change-empty-reason-rejected` → `SCHEMA_INVALID`.
- `rate-change-generic-reason-flagged` — accepted, low flag.
- `rate-flapping-flagged` — two changes within `shopProfile.items.rateChangeMinIntervalSec` → flag.
- `merge-from-equals-to-rejected` → `SCHEMA_INVALID`.
- `merge-live-into-archived-rejected` → direction enforced.
- `merge-stock-sum-mismatch-aborts` → `INVARIANT_VIOLATION`, no partial state.

## Required tests

- `merge-items-projection-stable` — pre-merge stock sum = post-merge stock; rate history unioned; bill projections re-fold identically.
- `merge-parties-outstanding-stable` — pre-merge balance sum = post-merge balance.
- `archived-item-blocked-from-new-bill` — picker excludes it; service rejects it.
- `historical-bill-uses-rate-at-time` — bill total replays exactly after rate change.
- `revoked-user-cannot-write` — server refuses every write after revocation.
- `export-action-is-audit-event` — every export appends `data_exported`.
- `voice-transcript-not-persisted-when-no-event` — discarded on flow abandon.
- `retention-print-records-pruned-after-1-year` — background job follows retention table.

## Open items

- `TODO(spec, blocks: M0)` — Add IndexedDB at-rest encryption beyond OS-level FBE? **Default:** rely on FBE + device revocation for v2.0.
- `TODO(spec, blocks: M9)` — Define accountant export schema: column order, charset, date format? **Default:** UTF-8 CSV, ISO-8601 dates, amounts in rupees (₹) with two decimals.
- `TODO(spec, blocks: M2)` — Define exact merge UX: preview, side-by-side confirmation, undo window? **Default:** owner-only explicit preview screen; no undo because merge is an event.
- `TODO(spec, blocks: M0)` — Define telemetry purge cadence? **Default:** 90 days rolling, enforced by Firebase project setting.
