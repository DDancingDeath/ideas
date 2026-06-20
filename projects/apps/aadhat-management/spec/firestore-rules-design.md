# Production Firestore Rules — Hardening Design

> **Status: DESIGN ONLY — DO NOT DEPLOY YET.**
> **Owner action required.** This document is a *proposal* for tightening
> the production `firestore.rules` file. Nothing in this design has been
> deployed. The current rules in `firestore.rules` are *unchanged* by
> this document. See §10 "Rollout Plan" for the safe deployment ladder.

## 0. Purpose & Scope

The current production rules (`firestore.rules` at the repo root, lines
1–175) collapse authorisation down to a single check:

```javascript
allow read, write: if isSignedIn();
```

This is correct *for a closed-trust deployment* — every authenticated
user is a trusted employee. But it has three real-world consequences:

1. **A leaked / stolen account = full data destruction**. Any signed-in
   user can `delete` every bill, every customer, every audit log, and
   then `update` the leftover bills to wrong amounts. The audit log
   they would normally leave can itself be deleted because
   `auditLogs/{logId}` allows `update, delete: if false` *only* —
   wait, that one is correct. But every other collection is open.

2. **Client bugs become data corruption**. A typo in
   `firestore-service.js` that writes `grandTotal: NaN` or
   `customerName: undefined` is silently accepted by the server.
   Reports break days later when nobody can correlate the bad row to
   the commit that introduced it.

3. **No defence-in-depth against the staging clone**. The staging
   read-only clone (Phase 1.5 of the master plan) leans on a *single*
   rule check (`isStagingReadOnly()`). If that check has a typo, the
   staging user can write to prod. We currently have no payload
   validation as a fallback.

This design proposes a **role-aware, schema-validating, audit-immutable**
ruleset that:

- Preserves day-to-day staff workflow (no clicks change).
- Quarantines destructive operations to the `owner` role.
- Validates payload shape on every financial write.
- Makes the staging-readonly rule the **third** layer of defence,
  not the only one.
- Is designed to be **rolled out in stages** (§10), each stage being
  individually reversible without a code deploy.

---

## 1. Current State (verbatim audit)

### Roles in use today

From `firestore.rules` line 11–17:

```javascript
function getUserRole() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
}
function isAdmin() {
  return isSignedIn() && getUserRole() == 'owner';
}
```

The `users` collection stores a `role` field. Code references in
`www/js/modules/admin.js`, `www/js/modules/users.js`, and
`www/js/auth/authentication.js` show three values in actual use:

- `'owner'` — full control (the founders of the business)
- `'staff'` — day-to-day cashier / data entry
- `'pending'` — newly-signed-up account, awaiting approval

The `pending` role is implicit — newly created `users/{uid}` docs may
have `status: 'pending'` and `role` either absent or `'staff'`. The
admin approval flow flips `status` to `'approved'`.

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

`dev_*` mirrors are all `read, write: if isSignedIn()` (lines 123–173).
The `dev_*` collections are intentionally permissive — they're the
testing surface — and out of scope for this hardening exercise.

### Things the current rules already get right
- `auditLogs` is genuinely append-only (`update, delete: if false`).
- `users` self-modify is correctly gated.
- The `dev_*` mirror exists.

### Things that are gaps
- **Every financial collection allows delete by any signed-in user.**
- **No payload validation anywhere.** A write of `{ grandTotal: -1e308 }`
  succeeds.
- **No timestamp integrity.** A user can backdate (or post-date) any
  bill by setting `createdAt` to whatever they want.
- **No tenant separation.** This is single-tenant by design today, but
  if a second business is ever onboarded, every write goes into the
  same collections.
- **`telemetry.update`** is permitted (line 114) — telemetry should be
  append-only too, otherwise the bug-tracker can be silently rewritten.

---

## 2. Goals (in priority order)

1. **No data loss from a single compromised credential.** Destructive
   ops (`delete`) on financial collections require the `owner` role.
2. **Schema validation on every financial write.** Money fields must be
   non-negative numbers; required fields must be present; server
   timestamps cannot be forged by the client.
3. **Append-only is enforced for both `auditLogs` AND `telemetry`.**
4. **Backwards-compatible with the existing client.** The current
   `staff` workflows must continue to work without code changes:
   create bills, edit items, run reports. *Edits* to past bills are
   allowed for staff (the app supports invoice corrections); only
   *deletes* require `owner`.
5. **Layered with the staging-readonly rule (Phase 1.5).** When that
   rule is added, it composes cleanly with this design — both checks
   apply, and either denial blocks the write.
6. **Designed for incremental rollout.** Each new check goes in as a
   *separate* deploy so any regression can be reverted in <60 seconds
   without a code change.

### Explicit non-goals
- Real-time collaboration locking (out of scope; single-store app).
- Field-level read filtering (out of scope; everyone needs everything
  they read today).
- Migrating off the compat SDK (orthogonal — see `STAGING_README.md`).

---

## 3. New role model

We keep the current three-value role enum. We add **two helper
functions** that classify writes by intent:

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

Three behavioural changes follow:

- `pending` users (`status != 'approved'`) **cannot write** to any
  business collection. They can only read their own `users` doc and
  await admin approval. (Today, a freshly self-signed-up user can
  immediately write bills — a quiet vulnerability.)
- `staff` users can **create and update** any business doc, but **cannot
  delete** anything except their own draft / autosave.
- `owner` is the only role that can `delete` from financial collections.

Migration: any existing `users` doc without `status` is treated as
`'pending'` *only after* the rule deploy. To avoid breaking everyone
overnight, the rollout (§10) seeds `status: 'approved'` on every
existing `users` doc *before* the new rule is activated.

---

## 4. Payload validation rules

Per-collection schema. Every rule below is intersected with the
existing role check; both must pass.

### 4.1 `purchases` and `wholesaleSales` and `retailSales`
```javascript
function billPayloadValid() {
  let d = request.resource.data;
  return d.size() <= 50  // sanity bound — bills shouldn't have 100+ fields
    && d.keys().hasAll(['date', 'items', 'createdAt'])
    && d.date is string
    && d.items is list && d.items.size() > 0 && d.items.size() < 200
    && d.createdAt == request.time   // server timestamp, not client-chosen
    && (d.get('grandTotal', 0) is number) && d.get('grandTotal', 0) >= 0
    && (d.get('amountPayable', 0) is number) && d.get('amountPayable', 0) >= 0
    && (d.get('total', 0) is number) && d.get('total', 0) >= 0
    && (d.get('payment', {}).get('paid', 0) is number)
    && d.get('payment', {}).get('paid', 0) >= 0
    && (d.get('payment', {}).get('due', 0) is number)
    && d.get('payment', {}).get('due', 0) >= 0;
}

match /purchases/{id} {
  allow read: if isApproved();
  allow create: if isStaff() && isApproved() && billPayloadValid();
  allow update: if isStaff() && isApproved() && billPayloadValid();
  allow delete: if isOwner() && isApproved();
}
```

`request.time` is the server-stamped time on the request; any client
attempt to set `createdAt` to a different value fails the rule.
**Existing client code must be updated to use `serverTimestamp()` for
`createdAt`.** This is a one-line change in
`www/js/firebase/firestore-service.js` per write site. `BATCH-N` already
audits these sites — that code change is paired with this rule deploy in
§10 step 4.

### 4.2 `items`
```javascript
function itemPayloadValid() {
  let d = request.resource.data;
  return d.size() <= 30
    && d.keys().hasAll(['name'])
    && d.name is string && d.name.size() > 0 && d.name.size() <= 200
    && (d.get('hindiName', '') is string)
    && (d.get('purchaseRate', 0) is number) && d.get('purchaseRate', 0) >= 0
    && (d.get('saleRate', 0) is number) && d.get('saleRate', 0) >= 0
    && (d.get('stockQty', 0) is number);  // can be negative if oversold
}

match /items/{id} {
  allow read: if isApproved();
  allow create, update: if isStaff() && isApproved() && itemPayloadValid();
  allow delete: if isOwner() && isApproved();
}
```

### 4.3 `expenses` and `withdrawals`
Same shape as bills, simpler payload:
```javascript
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
```

### 4.4 `cashManagement` and `cashSessions`
```javascript
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
```

### 4.5 `users` (tighten)

- `update` of one's own doc may not modify `role` or `status` (only
  `owner` can change those). Otherwise, a junior staff member could
  promote themselves to owner.
- `read` of others' docs becomes owner-only. Staff can still read their
  own doc (needed by the role lookup helper).

```javascript
match /users/{userId} {
  allow read: if isSignedIn() && (request.auth.uid == userId || isOwner());
  allow create: if isSignedIn() && request.auth.uid == userId
    && request.resource.data.get('role', 'staff') in ['staff', 'pending']
    && request.resource.data.get('status', 'pending') == 'pending';
  allow update: if isSignedIn() && (
    // owners can change anything
    isOwner()
    // self-edits cannot escalate role/status
    || (request.auth.uid == userId
        && request.resource.data.role == resource.data.role
        && request.resource.data.status == resource.data.status)
  );
  allow delete: if isOwner();
}
```

Per-user preferences are an explicit subcollection because v2 syncs
preferences that v1 kept in localStorage only, including custom finance
accounts:

```javascript
match /users/{userId}/preferences/{prefId} {
  allow read, write: if isSignedIn()
    && (request.auth.uid == userId || isOwner());
}
```

### 4.6 `auditLogs` (already correct, document the invariant)
No change. `update, delete: if false` is the right answer.
Recommend adding a payload validator anyway:
```javascript
match /auditLogs/{logId} {
  allow create: if isSignedIn()
    && request.resource.data.keys().hasAll(['action', 'timestamp', 'userId'])
    && request.resource.data.userId == request.auth.uid
    && request.resource.data.timestamp == request.time;
  allow read: if isOwner();
  allow update, delete: if false;
}
```
Stronger because we now also enforce that the `userId` field on the log
matches the writer (so users can't impersonate someone else in the log).

### 4.7 `telemetry` (gap fix)
Today telemetry allows `update`, which lets clients silently rewrite
historical bug reports. Change to append-only:
```javascript
match /telemetry/{docId} {
  allow create: if isSignedIn();
  allow read: if isOwner();
  allow update: if false;          // CHANGED from `if isSignedIn()`
  allow delete: if isOwner();
}
```

### 4.8 Lightly-validated collections (`drafts`, `autoSaves`, `notifications`, `itemFrequency`, `stockAdjustments`)

These are scratch / housekeeping data — payload validation is
low-value and risks breaking the client. Keep `read, write: if isStaff() && isApproved()`. Drop the `delete`-by-anyone surface area:

```javascript
match /drafts/{docId} {
  allow read, create, update: if isStaff() && isApproved();
  allow delete: if isStaff() && isApproved()
    && resource.data.get('userId', '') == request.auth.uid;
}
```
Same for `autoSaves`. For `notifications`, allow all signed-in writes
(since notifications cross users by design), but only `owner` can
delete:
```javascript
match /notifications/{notificationId} {
  allow read, create, update: if isApproved();
  allow delete: if isOwner();
}
```

### 4.9 `settings`

`settings` is global business config (printer settings, GST rates, etc.).
It's edited by the admin in the Configure tab — there's no reason a
junior staff member should be able to overwrite the GST rate or the
printer config:

```javascript
match /settings/{settingId} {
  allow read: if isApproved();
  allow create, update: if isOwner();
  allow delete: if isOwner();
}
```

---

## 5. Composition with the staging-readonly rule

Phase 1.5 introduces:
```javascript
function isStagingReadOnly() {
  return request.auth != null
    && request.auth.token.email == 'staging-readonly@aadhat.local';
}
```

This composes with the rules above by appending `&& !isStagingReadOnly()`
to every `create / update / delete` in the file. It is a final-line
check — the *most restrictive* — and stays unchanged by this design.

The composition is explicitly defence-in-depth:

```
ALLOW WRITE iff:
   isApproved (status check)
   AND isStaff or isOwner (role check, depending on op)
   AND payloadValid (shape check)
   AND !isStagingReadOnly (identity blocklist)
```

Any one denial blocks the write. The rule deploy order in §10 ensures
the staging-readonly rule (Phase 1.5) lands *before* the role tightening
(this document) so we always have a backstop while iterating.

---

## 6. Things this design does NOT do

- **Field-level access control on reads.** Rules can validate write
  payloads but don't filter what gets returned on a read. A staff
  member can still query the entire `users` collection (modulo §4.5)
  and see everyone's document. If we ever need to hide one staff
  member's salary from another, we need data partitioning, not rules.
- **Cross-collection consistency.** Rules can't enforce "you can only
  create a bill if there's a corresponding cash session open." That's
  an application-level invariant.
- **Rate limiting.** Rules can't say "no more than 100 writes per
  minute per user." App Check or Cloud Functions are the answers there.
- **Schema migration.** Existing rows that don't match the new schema
  remain readable (rules only check writes). If we want to enforce
  the schema retroactively, we need a one-time backfill script.

---

## 7. Test matrix

The Firebase Rules Playground (Console → Firestore → Rules → Playground)
must verify each row before deploy. **All 26 cases must match the
"Expected" column.** This matrix is the definition-of-done for §10
step 5.

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

The staging-readonly rule (Phase 1.5) is row 26. It's listed last
because it lands first chronologically (Phase 1.5 before this design's
deploy).

---

## 8. Migration cost / breaking changes

### Client code changes required *before* §10 step 4 deploys
1. **All `createdAt` fields must be `firebase.firestore.FieldValue.serverTimestamp()`** instead of client `Date.now()` or new `Date().toISOString()`. Audit sites:
   - `firestore-service.js` create methods (purchases, sales, items, expenses, withdrawals, etc.)
   - `cash-management.js` session open/close
   - `auditLogs` writes (already mostly server timestamp)
   - `telemetry` writes
2. **`payment.due` and `payment.paid` must be numbers**, not strings. Some legacy code stores them as strings. One-time backfill:
   ```javascript
   db.collection('purchases').get().then(snap => snap.docs.forEach(d => {
     const data = d.data();
     const fix = {};
     if (typeof data?.payment?.paid === 'string') fix['payment.paid'] = Number(data.payment.paid) || 0;
     if (typeof data?.payment?.due === 'string') fix['payment.due'] = Number(data.payment.due) || 0;
     if (Object.keys(fix).length) d.ref.update(fix);
   }));
   ```
   Run this from a one-shot admin console as `owner` *before* §10 step 4.
3. **Every existing `users` doc must have `status: 'approved'`** before §10 step 3 (role tightening). One-shot backfill, owner-run.

### No client changes required for
- The `delete` restriction. The existing app rarely deletes; only the
  Admin → Audit "purge" flow does, and only owners use that.
- The `users` self-edit restriction. The Profile screen doesn't expose
  role / status fields.
- Telemetry append-only. Telemetry writes are creates only.

---

## 9. Observability

Every denial in production lands in the Firebase Console → Firestore →
Usage tab as a "Permission denied" error. Currently we have ~0 of
those (rules are too loose to deny anything). After deploy we should
expect a small spike from the validator catching legitimate edge cases
the existing client code does sloppily — that's a feature, not a bug.

Recommendation: add a `firestore-deny-monitor.html` admin page that
renders the last 24h of permission-denied counts grouped by collection.
Build that page on top of an existing GCP Cloud Logging sink.
**Not in scope** of this design but referenced for the runbook.

---

## 10. Rollout plan (the safe ladder)

Each step is a *separate* `firebase deploy --only firestore:rules`. Each
step is independently revertible. **Stop at any step that breaks
production**; the previous step remains active.

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

The staging-readonly rule (Phase 1.5) is independent of this ladder
and lands separately *before* step 3, so it's the safety net while we
iterate the role tightening.

---

## 11. Open questions for the owner

1. **Should `staff` be able to update past bills, or only same-day?**
   This document allows updates indefinitely (matches current behaviour).
   If we want to lock historical edits, add `&& resource.data.createdAt
   > timestamp.value(now() - duration.value(1, 'd'))` to the update
   rule.
2. **Are there other accounts in production today besides `owner` and
   `staff`?** If so, the role enum needs widening before §10 step 3.
3. **Do we want to hide bill totals from non-`owner` staff?** That's a
   field-level read filter — out of scope here, but if the answer is
   "yes" we need to redesign the data layer (separate `billTotals`
   collection, owner-only).
4. **Cost ceiling on the `get(/users/...)` lookup inside every
   rule call.** Each `getUserRole()` invocation costs one read. With
   ~50 staff users active during peak and ~100 writes/minute, that's
   ~6000 extra reads per minute. Stays well under the free tier, but
   if traffic 100×s we should cache the role on the auth token via a
   Cloud Function `setCustomUserClaims({role, status})`. **Listed as
   future work.**
5. **Should the staging-readonly rule expand to also block reads of
   `users` and `auditLogs`?** Currently it only blocks writes. If
   staging staff shouldn't see real audit history, add
   `allow read: if !isStagingReadOnly()` to those two collections.

---

## 12. Appendix — full proposed `firestore.rules`

> Reproduced for reference. **Not a deploy artefact** — for diff /
> review only. Compose with the Phase 1.5 staging-readonly rule before
> shipping.

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

---

## 13. Summary

**Today**: one rule everywhere — "is signed in?" — with no payload check
and no role gating. One leaked password destroys the business.

**Proposed**: signed-in + approved + correct role + valid payload, with
the staging-readonly identity blocked as a final layer. Eight separate
deploy steps, each individually revertible. Owner-only manual deploys.

**Not deployed by this commit.** Deploying is a Phase 5 (post-staging-
proven) decision that requires owner action in the Firebase Console
plus the prerequisite client code changes from §8.
