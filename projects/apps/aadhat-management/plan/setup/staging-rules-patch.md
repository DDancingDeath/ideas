# Additive `firestore.rules` patch — staging read-only user
#
# This is the **EXACT** patch the project owner applies to the
# **production** `firestore.rules` to enforce Layer 3 of the staging
# clone's three-layer write blocking. It is **not** deployed
# automatically by this repo (the staging clone has no deploy access
# to prod rules). The owner runs the deploy from the prod working
# copy.
#
# What it does
# ------------
# Adds one helper function — `isStagingReadOnly()` — and threads its
# negation through every existing `allow create / update / delete /
# write` rule so any matching write attempt by the dedicated staging
# user `staging-readonly@aadhat.local` is denied at the server. All
# other users (owner, manager, staff) are unaffected — the existing
# rules continue to evaluate exactly as they did before.
#
# Why this is safe
# ----------------
# * Strictly additive — no existing rule is removed or weakened.
# * Single-user scoped — checks `request.auth.token.email` against
#   one literal string. No prod user matches it.
# * Reads are never gated — the staging clone needs to read, and
#   every existing read rule is left untouched.
# * Worst case if the regex/email is wrong: the staging user can
#   write — but Layers 1 and 2 still block them at the client.
#
# Pre-deploy validation (REQUIRED)
# --------------------------------
# In the Firebase Console → Firestore → Rules → Rules Playground,
# evaluate at least these scenarios before clicking Publish:
#
#   1. uid=<owner_uid>, path=bills/{auto}, op=create     → ALLOW
#   2. uid=<staff_uid>, path=bills/{auto}, op=create     → ALLOW
#   3. uid=<staging_uid>, path=bills/{auto}, op=create   → DENY
#   4. uid=<staging_uid>, path=bills/{any}, op=get       → ALLOW
#   5. uid=<owner_uid>, path=users/<other>, op=update    → ALLOW (admin path)
#   6. uid=<staging_uid>, path=users/<self>, op=update   → DENY
#   7. uid=<owner_uid>, path=customers/{auto}, op=create → ALLOW
#   8. uid=<staging_uid>, path=customers/{auto}, op=create → DENY
#
# Deploy command (run from the **prod** repo working copy, NOT this clone)
# ------------------------------------------------------------------------
#   firebase deploy --only firestore:rules --project aadhat-management
#
# Verification (post-deploy)
# --------------------------
#   1. Owner logs in to live prod app, creates a test bill →  succeeds
#   2. Open https://aadhat-staging.web.app, auto-login as staging user,
#      open browser devtools, manually invoke the SDK to write to a
#      test doc → server returns `permission-denied`.
#   3. Reads on the staging site continue to work normally.
#
# Rollback
# --------
# If anything goes wrong, the entire `isStagingReadOnly()` helper and
# the `&& !isStagingReadOnly()` clauses can be removed in one revert
# commit. The prod project state is back to exactly the pre-patch
# behaviour.
#
# ============================================================
# DIFF — apply this to the prod repo's `firestore.rules` file
# ============================================================

# Add this helper near the top of the rules file, alongside the
# existing `isSignedIn()` / `getUserData()` / `isOwner()` etc:

#     // Staging clone uses one dedicated, throw-away Auth account
#     // (`staging-readonly@aadhat.local`). Every write rule below
#     // ANDs in `!isStagingReadOnly()` so that account is server-side
#     // read-only even if all client-side guards fail.
#     function isStagingReadOnly() {
#       return request.auth != null
#         && request.auth.token.email == 'staging-readonly@aadhat.local';
#     }

# Then for **every** rule in the file that currently looks like one of:

#     allow create: if isSignedIn();
#     allow update: if isSignedIn();
#     allow delete: if isOwner();
#     allow write : if isSignedIn();

# append `&& !isStagingReadOnly()`, e.g.:

#     allow create: if isSignedIn() && !isStagingReadOnly();
#     allow write:  if isSignedIn() && !isStagingReadOnly();

# Leave `allow read` / `allow get` / `allow list` rules **unchanged**.
# The staging clone needs to read.

# ============================================================
# Worked example — the `bills/{billId}` rule today
# ============================================================
# Before:
#     match /bills/{billId} {
#       allow read:  if isSignedIn();
#       allow write: if isSignedIn();
#     }
# After:
#     match /bills/{billId} {
#       allow read:  if isSignedIn();
#       allow write: if isSignedIn() && !isStagingReadOnly();
#     }

# Apply the same pattern to every collection block that has a
# write/create/update/delete rule:
#   - bills, billSequences, customers, items, expenses, payments,
#     paymentReceipts, transactions, employees, employeeWages,
#     employeeAdvances, salaryDisbursements, units, suppliers,
#     wholesaleSales, retailSales, financeEntries, dayClosures,
#     cashSnapshots, miscellaneous, settings, users, notifications,
#     auditLogs, telemetryEvents, bannedUsers, billCounters,
#     chatLlmQuotas, chatAuditLogs
# (Snapshot taken from the `firestore.rules` file in this repo
#  at commit time of this design doc.)


# ============================================================
# REAL PROD BUG DISCOVERED DURING STAGING WALKTHROUGH (2026-01-08)
# ============================================================
#
# While walking every tab on the live staging deploy as the
# staging-readonly user, the Finance tab logged:
#
#     Error loading custom finance accounts: FirebaseError:
#     Missing or insufficient permissions.
#
# The Finance module reads `users/{uid}/preferences/financeAccounts`
# (firestore-service.js#loadFinanceCustomAccounts). Prod's current
# `firestore.rules` only has a rule for `/users/{userId}` — there is
# NO match block for any subcollection underneath. Default-deny
# kicks in, so EVERY USER's "Custom Finance Accounts" feature is
# silently broken in production. The error is swallowed by the
# loader and the function returns `[]`, so users see "no custom
# accounts" with no indication their data isn't being loaded.
#
# This is independent of the staging clone — it's a pre-existing
# prod bug surfaced by staging walkthrough.
#
# FIX (separate from the staging-readonly patch — apply BOTH):
#
#     // The Finance module persists per-user custom-account
#     // configurations under each user's preferences subcollection.
#     // Without this rule, the feature is silently inaccessible.
#     match /users/{userId}/preferences/{prefId} {
#       allow read, write: if isSignedIn() && request.auth.uid == userId;
#     }
#
# Insert this block immediately AFTER the existing
# `match /users/{userId} { ... }` block (around line 84 of
# `firestore.rules`). Then add the `&& !isStagingReadOnly()`
# clause to its `write` allow as part of the staging patch above:
#
#     match /users/{userId}/preferences/{prefId} {
#       allow read:  if isSignedIn() && request.auth.uid == userId;
#       allow write: if isSignedIn() && request.auth.uid == userId
#                       && !isStagingReadOnly();
#     }
#
# Validation in Rules Playground:
#   - uid=A reads/writes /users/A/preferences/X      → ALLOW
#   - uid=A reads     /users/B/preferences/X         → DENY
#   - staging user writes /users/staging/prefs/X     → DENY
#     (Layer 3 staging block still applies)

