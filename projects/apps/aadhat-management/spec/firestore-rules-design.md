# Production Firestore Rules — Hardening Design

> **v1 scope.** This document records the designed v1 Firestore ruleset. If it disagrees with `spec/rebuild/`, `spec/rebuild/` wins.
>
> **Status: DESIGN ONLY — DO NOT DEPLOY YET.** Owner action required. Current `firestore.rules` is unchanged. See §10 for rollout.

## 0. Purpose & Scope

Current production rules (`firestore.rules`, lines 1–175) reduce most authorization to:

```javascript
allow read, write: if isSignedIn();
```

This design adds role checks, schema validation, append-only audit/telemetry, and staged rollout. It preserves current staff workflows: create bills, edit items, run reports, and update past bills; only deletes become owner-only.


## 1. Current State (verbatim audit)

### Roles in use today

```javascript
function getUserRole() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
}
function isAdmin() {
  return isSignedIn() && getUserRole() == 'owner';
}
```

Roles referenced by `www/js/modules/admin.js`, `www/js/modules/users.js`, and `www/js/auth/authentication.js`:

- `'owner'` — full control.
- `'staff'` — cashier / data entry.
- `'pending'` — new account awaiting approval; may be implicit via `status: 'pending'` with missing/`'staff'` role.

### Current per-collection summary

| Collection | Read | Create | Update | Delete |
|---|---|---|---|---|
| `purchases` | signed-in | signed-in | signed-in | signed-in |
| `retailSales` | signed-in | signed-in | signed-in | signed-in |
| `wholesaleSales` | signed-in | signed-in | signed-in | signed-in |
| `items` | signed-in | signed-in | signed-in | signed-in |
| `expenses` | signed-in | signed-in | signed-in | signed-in |
| `stockAdjustments` | signed-in | signed-in | signed-in | signed-in |
| `withdrawals` | signed-in | signed-in | signed-in | signed-in |
| `cashManagement` | signed-in | signed-in | signed-in | signed-in |
| `cashSessions` | signed-in | signed-in | signed-in | signed-in |
| `settings` | signed-in | signed-in | signed-in | signed-in |
| `users` | signed-in | self only | self or `owner` | self or `owner` |
| `itemFrequency` | signed-in | signed-in | signed-in | signed-in |
| `notifications` | signed-in | signed-in | signed-in | signed-in |
| `autoSaves` | signed-in | signed-in | signed-in | signed-in |
| `drafts` | signed-in | signed-in | signed-in | signed-in |
| `auditLogs` | `owner` only | signed-in | **never** | **never** |
| `telemetry` | `owner` only | signed-in | signed-in | `owner` only |

`dev_*` mirrors are intentionally permissive: `read, write: if isSignedIn()` (lines 123–173). They are out of scope.

### Current gaps

- Financial collections allow signed-in deletes.
- No payload validation.
- No timestamp integrity.
- No tenant separation.
- `telemetry.update` is permitted.


## 2. Goals

1. Financial `delete` requires `owner`.
2. Financial writes validate schema, non-negative money fields, required fields, and server timestamps.
3. `auditLogs` and `telemetry` are append-only.
4. Existing approved staff can create/update business docs and run reports.
5. Phase 1.5 staging-readonly composes as an extra denial.
6. Roll out as small, revertible rule deploys.

### Explicit non-goals

- Real-time collaboration locking.
- Field-level read filtering.
- Compat SDK migration; see `STAGING_README.md`.


## 3. New role model

```javascript
// Existing - unchanged
function isSignedIn() { return request.auth != null; }
function getUserRole() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid))
         .data.get('role', 'staff');  // default to staff if field missing
}
function isOwner() { return isSignedIn() && getUserRole() == 'owner'; }

// New
function isStaff() { return isSignedIn() && getUserRole() in ['staff', 'owner']; }
function isApproved() {
  return isSignedIn() &&
    get(/databases/$(database)/documents/users/$(request.auth.uid))
      .data.get('status', 'pending') == 'approved';
}
```

Effects:

- `status != 'approved'`: may read only own `users` doc; cannot write business collections.
- `staff`: create/update business docs; delete only own draft/autosave.
- `owner`: only role allowed to delete financial docs.

Migration: seed `status: 'approved'` on existing users before activating these checks.


## 4. Payload validation rules

Exact helper and match code is in §12. This section is the implementation map.

| Area | Exact names | Required checks |
|---|---|---|
| Bills | `purchases`, `wholesaleSales`, `retailSales`, `billPayloadValid()` | `d.size() <= 50`; keys `date`, `items`, `createdAt`; `date is string`; `items is list && size > 0 && size < 200`; `createdAt == request.time`; `grandTotal`, `amountPayable`, `total`, `payment.paid`, `payment.due` are numbers and `>= 0`. `read: isApproved`; `create/update: isStaff && isApproved && billPayloadValid`; `delete: isOwner && isApproved`. Client must use `serverTimestamp()` in `www/js/firebase/firestore-service.js` before §10 step 4. |
| Items | `items`, `itemPayloadValid()` | `d.size() <= 30`; key `name`; `name` string length `> 0` and `<= 200`; `hindiName` string; `purchaseRate` and `saleRate` numbers `>= 0`; `stockQty` number and may be negative if oversold. `read: isApproved`; `create/update: isStaff && isApproved && itemPayloadValid`; `delete: isOwner && isApproved`. |
| Expenses / withdrawals | `expenses`, `withdrawals`, `expensePayloadValid()` | `d.size() <= 20`; keys `amount`, `date`, `createdAt`; `amount is number && amount >= 0`; `date is string`; `createdAt == request.time`; `category` and `description` strings. |
| Cash sessions | `cashManagement`, `cashSessions`, `cashSessionPayloadValid()` | `d.size() <= 30`; key `createdAt`; `createdAt == request.time`; `openingBalance`, `closingBalance` numbers; `totalIn` and `totalOut` numbers `>= 0`. |
| Users | `users/{userId}` | `read` own doc or owner; `create` self only with role in `['staff', 'pending']` and status `pending`; `update` owner any doc, self only if `role` and `status` unchanged; `delete` owner only. |
| Preferences | `users/{userId}/preferences/{prefId}` | `read, write` only same user or owner. Used for v2 preferences including custom finance accounts. |
| Audit logs | `auditLogs` | Append-only. `create` requires `action`, `timestamp`, `userId`, `userId == request.auth.uid`, `timestamp == request.time`; `read` owner; `update/delete false`. |
| Telemetry | `telemetry` | Append-only gap fix. `create` signed-in; `read` owner; `update false`; `delete` owner. |
| Scratch / housekeeping | `drafts`, `autoSaves`, `notifications`, `itemFrequency`, `stockAdjustments` | Payloads stay flexible. `drafts` and `autoSaves` delete only by owner/user-owned doc. `notifications` delete owner only. `stockAdjustments` delete owner only. |
| Settings | `settings` | Global business config. `read` approved; `create/update/delete` owner. |


## 5. Composition with the staging-readonly rule

Phase 1.5 adds:

```javascript
function isStagingReadOnly() {
  return request.auth != null
    && request.auth.token.email == 'staging-readonly@aadhat.local';
}
```

Append `&& !isStagingReadOnly()` to every `create / update / delete`.

```text
ALLOW WRITE iff:
   isApproved
   AND isStaff or isOwner
   AND payloadValid
   AND !isStagingReadOnly
```

Any denial blocks the write. Phase 1.5 lands before role tightening.


## 6. Things this design does NOT do

- Field-level read filtering. Rules validate writes but do not redact read results.
- Cross-collection consistency, such as requiring an open cash session before a bill.
- Rate limiting; use App Check or Cloud Functions.
- Schema migration; existing rows remain readable until backfilled.


## 7. Test matrix

Firebase Rules Playground must verify all 26 cases before deploy.

| # | Auth | Status | Role | Op | Collection | Payload | Expected |
|---|---|---|---|---|---|---|---|
| 1 | none | — | — | read | purchases | — | DENY |
| 2 | yes | pending | staff | read | purchases | — | DENY |
| 3 | yes | approved | staff | read | purchases | — | ALLOW |
| 4 | yes | approved | staff | create | purchases | valid | ALLOW |
| 5 | yes | approved | staff | create | purchases | grandTotal: -1 | DENY |
| 6 | yes | approved | staff | create | purchases | createdAt forged | DENY |
| 7 | yes | approved | staff | update | purchases | valid | ALLOW |
| 8 | yes | approved | staff | delete | purchases | — | DENY |
| 9 | yes | approved | owner | delete | purchases | — | ALLOW |
| 10 | yes | approved | staff | create | items | valid | ALLOW |
| 11 | yes | approved | staff | create | items | name="" | DENY |
| 12 | yes | approved | staff | delete | items | — | DENY |
| 13 | yes | approved | owner | delete | items | — | ALLOW |
| 14 | yes | approved | staff | create | expenses | amount: NaN | DENY |
| 15 | yes | approved | staff | create | expenses | amount: -50 | DENY |
| 16 | yes | approved | staff | create | expenses | valid | ALLOW |
| 17 | yes | approved | staff | update | users/SELF | role unchanged | ALLOW |
| 18 | yes | approved | staff | update | users/SELF | role: 'owner' | DENY |
| 19 | yes | approved | staff | read | users/OTHER | — | DENY |
| 20 | yes | approved | owner | update | users/OTHER | role: 'owner' | ALLOW |
| 21 | yes | approved | owner | update | settings | valid | ALLOW |
| 22 | yes | approved | staff | update | settings | valid | DENY |
| 23 | yes | approved | staff | create | auditLogs | userId == self | ALLOW |
| 24 | yes | approved | staff | create | auditLogs | userId != self | DENY |
| 25 | yes | approved | staff | update | auditLogs | — | DENY |
| 26 | staging | approved | staff | create | purchases | valid | DENY |

Row 26 covers Phase 1.5 staging-readonly. It lands first chronologically.


## 8. Migration cost / breaking changes

### Client code required before §10 step 4

1. Use `firebase.firestore.FieldValue.serverTimestamp()` for all `createdAt` fields:
   - `firestore-service.js` create methods (purchases, sales, items, expenses, withdrawals, etc.)
   - `cash-management.js` session open/close
   - `auditLogs` writes
   - `telemetry` writes
2. Coerce `payment.due` and `payment.paid` to numbers before deploy:
   ```javascript
   db.collection('purchases').get().then(snap => snap.docs.forEach(d => {
     const data = d.data();
     const fix = {};
     if (typeof data?.payment?.paid === 'string') fix['payment.paid'] = Number(data.payment.paid) || 0;
     if (typeof data?.payment?.due === 'string') fix['payment.due'] = Number(data.payment.due) || 0;
     if (Object.keys(fix).length) d.ref.update(fix);
   }));
   ```
3. Seed `status: 'approved'` on every existing `users` doc before §10 step 3.

### No client changes required for

- Owner-only delete.
- `users` self-edit restriction.
- Telemetry append-only, because telemetry writes are creates only.


## 9. Observability

Permission denials appear in Firebase Console → Firestore → Usage. Expect a small spike after deploy as validators catch bad client payloads.

Optional future runbook item: `firestore-deny-monitor.html`, showing the last 24h of permission-denied counts by collection from a GCP Cloud Logging sink. Not in scope.


## 10. Rollout plan (safe ladder)

Each step is a separate `firebase deploy --only firestore:rules`. Stop and revert on production breakage.

| Step | What | Risk | Rollback |
|---|---|---|---|
| 0 | Backfill: every `users` doc gets `status: 'approved'` if missing | Owner-run script, no rules touched | n/a |
| 1 | Backfill: bill `payment.paid` / `payment.due` coerced to numbers | Owner-run script, no rules touched | n/a |
| 2 | Deploy: client code changed to use `serverTimestamp()` for `createdAt` everywhere | Standard PR + deploy | git revert |
| 3 | Deploy: add `isApproved()` and `isStaff()` helpers + payload validators **but keep all `allow` rules unchanged** | Validator code lands but isn't yet *used* | revert rules deploy |
| 4 | Deploy: switch business collections from `allow read, write: if isSignedIn()` to `allow read: if isApproved(); allow create, update: if isStaff() && isApproved() && payloadValid(); allow delete: if isOwner() && isApproved()`. **One collection at a time** — start with `expenses` (low volume) to validate, then `items`, then bills | Per-collection regression possible | revert rules deploy (cuts back to old wide-open rule for that one collection) |
| 5 | Deploy: tighten `users` (no self role/status edits) | Could lock out a malformed admin script | revert rules deploy |
| 6 | Deploy: tighten `settings` to owner-only writes | Configure tab breaks for staff (intended) | revert rules deploy |
| 7 | Deploy: telemetry append-only (`update: if false`) | Telemetry retry logic might fail silently | revert rules deploy |
| 8 | Deploy: auditLogs payload validator (writer == userId) | Same | revert rules deploy |
| 9 | Validate: Rules Playground all 26 rows from §7 | n/a | n/a |
| 10 | One-week soak. Monitor permission-denied error rate. | n/a | n/a |

Phase 1.5 staging-readonly lands separately before step 3.


## 11. Open questions for the owner

1. **Should `staff` be able to update past bills, or only same-day?** Current default: updates indefinitely. Same-day alternative adds `&& resource.data.createdAt > timestamp.value(now() - duration.value(1, 'd'))`.
2. **Are there production roles besides `owner` and `staff`?** Widen enum before §10 step 3 if yes.
3. **Hide bill totals from non-`owner` staff?** Requires data-layer redesign, not rules.
4. **Cost ceiling on `get(/users/...)`:** ~50 staff × ~100 writes/minute = ~6000 extra reads/minute. If traffic 100×s, cache role/status in custom claims via Cloud Function `setCustomUserClaims({role, status})`.
5. **Should staging-readonly also block reads of `users` and `auditLogs`?** If yes, add `allow read: if !isStagingReadOnly()` to those collections.


## 12. Appendix — full proposed `firestore.rules`

> Review reference only. Compose with Phase 1.5 staging-readonly before shipping.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // -- Helpers ------------------------------------------------------
    function isSignedIn() { return request.auth != null; }
    function userDoc() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    function getUserRole() { return userDoc().get('role', 'staff'); }
    function getUserStatus() { return userDoc().get('status', 'pending'); }
    function isOwner() { return isSignedIn() && getUserRole() == 'owner'; }
    function isStaff() { return isSignedIn() && getUserRole() in ['staff', 'owner']; }
    function isApproved() { return isSignedIn() && getUserStatus() == 'approved'; }

    function billPayloadValid() {
      let d = request.resource.data;
      return d.size() <= 50
        && d.keys().hasAll(['date', 'items', 'createdAt'])
        && d.date is string
        && d.items is list && d.items.size() > 0 && d.items.size() < 200
        && d.createdAt == request.time
        && (d.get('grandTotal', 0) is number) && d.get('grandTotal', 0) >= 0
        && (d.get('amountPayable', 0) is number) && d.get('amountPayable', 0) >= 0
        && (d.get('total', 0) is number) && d.get('total', 0) >= 0
        && (d.get('payment', {}).get('paid', 0) is number)
        && d.get('payment', {}).get('paid', 0) >= 0
        && (d.get('payment', {}).get('due', 0) is number)
        && d.get('payment', {}).get('due', 0) >= 0;
    }
    function itemPayloadValid() {
      let d = request.resource.data;
      return d.size() <= 30
        && d.keys().hasAll(['name'])
        && d.name is string && d.name.size() > 0 && d.name.size() <= 200
        && (d.get('hindiName', '') is string)
        && (d.get('purchaseRate', 0) is number) && d.get('purchaseRate', 0) >= 0
        && (d.get('saleRate', 0) is number) && d.get('saleRate', 0) >= 0
        && (d.get('stockQty', 0) is number);
    }
    function expensePayloadValid() {
      let d = request.resource.data;
      return d.size() <= 20
        && d.keys().hasAll(['amount', 'date', 'createdAt'])
        && d.amount is number && d.amount >= 0
        && d.date is string
        && d.createdAt == request.time
        && (d.get('category', '') is string)
        && (d.get('description', '') is string);
    }
    function cashSessionPayloadValid() {
      let d = request.resource.data;
      return d.size() <= 30
        && d.keys().hasAll(['createdAt'])
        && d.createdAt == request.time
        && (d.get('openingBalance', 0) is number)
        && (d.get('closingBalance', 0) is number)
        && (d.get('totalIn', 0) is number) && d.get('totalIn', 0) >= 0
        && (d.get('totalOut', 0) is number) && d.get('totalOut', 0) >= 0;
    }

    // -- Phase 1.5 staging-readonly backstop --------------------------
    function isStagingReadOnly() {
      return request.auth != null
        && request.auth.token.email == 'staging-readonly@aadhat.local';
    }

    // -- Bills --------------------------------------------------------
    match /purchases/{id} {
      allow read: if isApproved();
      allow create: if isStaff() && isApproved() && billPayloadValid() && !isStagingReadOnly();
      allow update: if isStaff() && isApproved() && billPayloadValid() && !isStagingReadOnly();
      allow delete: if isOwner() && isApproved() && !isStagingReadOnly();
    }
    match /retailSales/{id} {
      allow read: if isApproved();
      allow create: if isStaff() && isApproved() && billPayloadValid() && !isStagingReadOnly();
      allow update: if isStaff() && isApproved() && billPayloadValid() && !isStagingReadOnly();
      allow delete: if isOwner() && isApproved() && !isStagingReadOnly();
    }
    match /wholesaleSales/{id} {
      allow read: if isApproved();
      allow create: if isStaff() && isApproved() && billPayloadValid() && !isStagingReadOnly();
      allow update: if isStaff() && isApproved() && billPayloadValid() && !isStagingReadOnly();
      allow delete: if isOwner() && isApproved() && !isStagingReadOnly();
    }

    // -- Items --------------------------------------------------------
    match /items/{id} {
      allow read: if isApproved();
      allow create, update: if isStaff() && isApproved() && itemPayloadValid() && !isStagingReadOnly();
      allow delete: if isOwner() && isApproved() && !isStagingReadOnly();
    }

    // -- Expenses + withdrawals --------------------------------------
    match /expenses/{id} {
      allow read: if isApproved();
      allow create, update: if isStaff() && isApproved() && expensePayloadValid() && !isStagingReadOnly();
      allow delete: if isOwner() && isApproved() && !isStagingReadOnly();
    }
    match /withdrawals/{id} {
      allow read: if isApproved();
      allow create, update: if isStaff() && isApproved() && expensePayloadValid() && !isStagingReadOnly();
      allow delete: if isOwner() && isApproved() && !isStagingReadOnly();
    }

    // -- Cash sessions ----------------------------------------------
    match /cashManagement/{id} {
      allow read: if isApproved();
      allow create, update: if isStaff() && isApproved() && cashSessionPayloadValid() && !isStagingReadOnly();
      allow delete: if isOwner() && isApproved() && !isStagingReadOnly();
    }
    match /cashSessions/{id} {
      allow read: if isApproved();
      allow create, update: if isStaff() && isApproved() && cashSessionPayloadValid() && !isStagingReadOnly();
      allow delete: if isOwner() && isApproved() && !isStagingReadOnly();
    }

    // -- Stock adjustments + drafts + autoSaves + itemFrequency -----
    match /stockAdjustments/{id} {
      allow read: if isApproved();
      allow create, update: if isStaff() && isApproved() && !isStagingReadOnly();
      allow delete: if isOwner() && isApproved() && !isStagingReadOnly();
    }
    match /drafts/{id} {
      allow read, create, update: if isStaff() && isApproved() && !isStagingReadOnly();
      allow delete: if isStaff() && isApproved() && !isStagingReadOnly()
        && resource.data.get('userId', '') == request.auth.uid;
    }
    match /autoSaves/{id} {
      allow read, create, update: if isStaff() && isApproved() && !isStagingReadOnly();
      allow delete: if isStaff() && isApproved() && !isStagingReadOnly()
        && resource.data.get('userId', '') == request.auth.uid;
    }
    match /itemFrequency/{id} {
      allow read, create, update: if isApproved() && !isStagingReadOnly();
      allow delete: if isOwner() && !isStagingReadOnly();
    }

    // -- Settings ----------------------------------------------------
    match /settings/{id} {
      allow read: if isApproved();
      allow create, update, delete: if isOwner() && !isStagingReadOnly();
    }

    // -- Notifications ----------------------------------------------
    match /notifications/{id} {
      allow read, create, update: if isApproved() && !isStagingReadOnly();
      allow delete: if isOwner() && !isStagingReadOnly();
    }

    // -- Users -------------------------------------------------------
    match /users/{userId} {
      allow read: if isSignedIn() && (request.auth.uid == userId || isOwner());
      allow create: if isSignedIn() && request.auth.uid == userId
        && request.resource.data.get('role', 'staff') in ['staff', 'pending']
        && request.resource.data.get('status', 'pending') == 'pending'
        && !isStagingReadOnly();
      allow update: if isSignedIn() && !isStagingReadOnly() && (
        isOwner()
        || (request.auth.uid == userId
            && request.resource.data.role == resource.data.role
            && request.resource.data.status == resource.data.status)
      );
      allow delete: if isOwner() && !isStagingReadOnly();

      match /preferences/{prefId} {
        allow read: if isSignedIn() && (request.auth.uid == userId || isOwner());
        allow write: if isSignedIn() && !isStagingReadOnly()
          && (request.auth.uid == userId || isOwner());
      }
    }

    // -- Audit logs (append-only) -----------------------------------
    match /auditLogs/{logId} {
      allow create: if isSignedIn()
        && request.resource.data.keys().hasAll(['action', 'timestamp', 'userId'])
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.timestamp == request.time;
      allow read: if isOwner();
      allow update, delete: if false;
    }

    // -- Telemetry (append-only) ------------------------------------
    match /telemetry/{id} {
      allow create: if isSignedIn();
      allow read: if isOwner();
      allow update: if false;
      allow delete: if isOwner();
    }

    // -- Dev mirrors (unchanged — explicitly permissive) ------------
    // ... existing dev_* rules from current firestore.rules lines 123-173 ...
  }
}
```


## 13. Summary

Proposed v1 design: signed-in + approved + role + valid payload; staging-readonly blocks writes as final layer. Deploy only after §8 prerequisites and owner approval.
