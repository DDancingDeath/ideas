# Page spec: Diagnostics (`diagnostics`) — owner-only

## Purpose
Owner-facing visibility into what the app is doing under the hood:
Firestore read/write counters, recent errors, audit log of admin
actions.

## Files
| Tab id | Template | Module(s) |
|---|---|---|
| `diagnostics` | `www/templates/diagnostics.html` | `www/js/modules/diagnostics.js` |

## Who can use it
**Owner + Admin only.**

## What the user sees
1. Telemetry counters (writes / reads / errors today).
2. Recent error list with stack traces.
3. Audit log table (who did what, when).
4. Clear / Refresh buttons.

## What the user can do
View, clear (with confirmation).

## Calculations / formulas

### Counters
```
writesToday = Σ telemetry.events where type='write' AND date=today
readsToday  = Σ telemetry.events where type='read'  AND date=today
errorsToday = Σ telemetry.events where type='error' AND date=today
```

### Error list
Sort `telemetry.events where type='error'` by timestamp desc, take 50.

### Audit log
```
displayed = auditLogs.sortBy(timestamp desc).take(100)
each row: { timestamp, user, action, target, before, after }
```

## Data sources
- `telemetry/` collection.
- `auditLogs/` collection.

## Must NOT do
- Must not surface raw secrets / tokens in error messages — sanitize
  before display.
- Must not delete audit logs without confirmation. Audit logs should
  be **append-only** for compliance — clearing is a soft-clear (filter
  client-side), not a Firestore delete.
- Must not write telemetry from this page itself (that would create a
  feedback loop on every refresh).

## Known issues
- ~~Syntax error broke the tab — fixed (STG-WALK-3).~~

## Example bug reports → what to change
- "Diagnostics tab is blank" → first check browser console for a JS
  error in `diagnostics.js` and confirm `getCollection('telemetry')`
  is using `FirebaseService` (not raw `firebase.firestore()`).
- "Audit log shows the same user for every action" → `recordedBy` is
  read from a stale `currentUser` snapshot; read from `auth.currentUser`
  at the moment of the audited action, not at module init.
