# Staging-clone smoke checklist

Run this end-to-end **once per significant change** to the read-only
guard, the service worker, or the auth flow. It takes ~10 minutes if
the page is already open. If you regress any of these, the staging
clone has lost a safety layer and we should not deploy.

## Setup
- [ ] `npm install --legacy-peer-deps` succeeds
- [ ] `npm test` passes (430+ tests across 22+ suites)
- [ ] If running locally: `npx http-server www -p 8080` (or `npm start`)
- [ ] If running deployed: open `https://aadhat-staging.web.app`

## Layer 1 — read-only-guard.js (client SDK monkey-patch)
Open the browser devtools console. The page should already be loaded
and the user signed in (auto-login if `staging-config.js` is present,
otherwise sign in manually as `staging-readonly@aadhat.local`).

- [ ] Console shows `[read-only-guard] Firestore writes are disabled`
      (or similar — the exact message lives in `read-only-guard.js`)
- [ ] Run in console:
      `await firebase.firestore().collection('test').add({foo:1})`
      → returns a fake doc ref, no Firestore network call, console
      logs the blocked write
- [ ] Run in console:
      `await firebase.firestore().doc('test/x').set({foo:1})`
      → same — blocked, no network call
- [ ] Run in console:
      `const b = firebase.firestore().batch(); b.set(firebase.firestore().doc('test/x'),{foo:1}); await b.commit();`
      → the batch is the stub batch, commit is a no-op, no network call

## Layer 2 — service-worker.js (transport-level fetch block)
Open devtools → Application → Service Workers. The SW for the staging
origin should be activated. Then:

- [ ] In console, run:
      `await fetch('https://firestore.googleapis.com/v1/projects/aadhat-management/databases/(default)/documents/test/x', {method: 'POST', body: '{}'})`
      → returns HTTP 403 (the SW's response)
- [ ] Same call with `method: 'GET'` → returns whatever Firestore
      returns (200 or 401, depending on auth state) — the SW does
      NOT block reads.
- [ ] In Application → Service Workers, click "Unregister" then
      reload. Re-run the POST test → request now reaches Firestore
      and Layer 3 should reject it.

## Layer 3 — additive Firestore rule (server-side)
Layer 3 only applies if the owner has deployed the
`isStagingReadOnly()` rule to the prod project. To verify:

- [ ] Sign in as the staging user.
- [ ] Disable Layer 1 (in devtools, set
      `window.READ_ONLY_GUARD_DISABLE = true` and reload)
      OR temporarily comment out the read-only-guard `<script>` tag
      in `index.html` and serve locally.
- [ ] Try a write: `await firebase.firestore().collection('test').add({foo:1})`
      → expected: rejected with `FirebaseError: Missing or insufficient
      permissions` (`permission-denied`).
- [ ] Re-enable the guard.

## Functional smoke (read paths must still work)
- [ ] Sign in completes within ~5s
- [ ] Items list loads from Firestore (Items tab)
- [ ] Bills list loads (Billing → History tab)
- [ ] Stock report renders (Stock tab)
- [ ] Reports → Sales last 30 days renders without errors
- [ ] AI Assistant tab opens; typing `help` returns the help message
- [ ] AI Assistant: typing `stock of <known item>` returns the
      current stock value (number)
- [ ] AI Assistant: typing `who owes me the most` returns at least
      the top customer with an amount in `₹X,XXX` Indian format

## Banner & UX
- [ ] Red banner reading something like "READ-ONLY STAGING CLONE — no
      writes will be saved" is visible at the top of the page on
      every tab
- [ ] Save / Submit buttons are visibly disabled (greyed) on at
      least: Add Item form, Add Customer form, Settings → Save
- [ ] Clicking a disabled button shows a toast like "Read-only mode"
      (or no-ops cleanly — both are acceptable)

## Failure protocol
If **any** of the Layer 1 / Layer 2 / Layer 3 checks fails:
1. Do **NOT** redeploy the staging site to a public URL.
2. File a bug in `docs/REVIEW_ISSUES.md` under a new section
   "Staging safety regression".
3. Revert the offending change and re-run this checklist.

## Last verified
- 2026-05-15 — local smoke OK after CHAT-LLM-1 commit (Layers 1/2
  only; Layer 3 not yet deployed by owner — pending Phase 1.5).
