# AadhatManagementApp — Staging (Read-Only Mirror)

> ⚠️ **This is the read-only staging mirror of the production app.**
> It connects to the same Firebase project (`aadhat-management`) as
> production and reads live data, but **all write operations are
> blocked by three independent layers**. Use this repo to safely
> develop and validate improvements before promoting them to prod.

## Source provenance

This repo was initialised by a one-time copy of the production repo at:

- **Upstream**: https://github.com/DDancingDeath/AadhatManagementApp
- **Source commit SHA**: `bc2a434` (main, copied 2026-05-09)
- **Excluded from copy**: `node_modules/`, `.git/`, `android/`,
  `coverage/`, `*.log`

This is **not** a GitHub fork — the two repos are independent. We
intentionally avoid the upstream link so the clone can diverge without
constant merge conflicts.

## Three-layer write blocking

| Layer | Where | What it does |
|------:|-------|--------------|
| 1 | `www/js/firebase/read-only-guard.js` | Monkey-patches every Firestore SDK write method (add, set, update, delete, batch, runTransaction) into a logged no-op |
| 2 | `www/service-worker.js` (fetch handler) | Returns HTTP 403 for any non-GET request to `firestore.googleapis.com` / `firebase.googleapis.com` / `firebaseio.com` |
| 3 | Production `firestore.rules` (additive) | An additive `isStagingReadOnly()` rule denies writes from the dedicated `staging-readonly@aadhat.local` user only |

Any one layer is sufficient to block all writes. All three must fail
simultaneously for prod data to be at risk.

## Quick start (developer / agent)

```powershell
cd D:\AadhatApp\AadhatManagementApp-staging
npm install --legacy-peer-deps   # (--legacy-peer-deps to be removed once canvas dep is dropped)
npm test                         # Should pass 436+ tests
npm start                        # Serves at http://localhost:8080
```

Without `www/staging-config.js`, the local clone behaves exactly like
prod's login screen — sign in with any prod account to read live
data. Writes are still blocked by Layers 1 + 2 even when signed in
as a normal prod user.

## One-shot owner setup

To create the GitHub repo, the staging-readonly Firebase user, the
staging hosting site, the additive Firestore rule, and the prod-CI
fix PR — all from one script — the project owner runs:

```powershell
# Edit `tools/owner-bootstrap.ps1`, set $StagingPassword to a
# strong random password (line ~52), then:
cd D:\AadhatApp\AadhatManagementApp-staging
.\tools\owner-bootstrap.ps1
```

The script is idempotent (safe to re-run if any step fails). It
walks through TWO browser OAuth flows (GitHub + Firebase) at the
start, then runs unattended. See the script header for the full
list of steps it performs.

When in staging mode (auto-login wired by `www/staging-config.js`),
the app:
- Auto-signs-in as `staging-readonly@aadhat.local`
- Shows a red banner across the top
- Blocks every write at three independent layers

## Promotion to production

This is a **one-way** flow. Fixes are validated here, then cherry-
picked into a feature branch on the prod repo and submitted as a PR.

1. Identify the commit SHA in this repo to promote
2. In a working copy of the prod repo, create a feature branch
3. `git cherry-pick <sha>`
4. `gh pr create` with a link back to the staging URL where the fix
   was validated
5. Production CI deploys after merge

The clone repo stays alive permanently as the safety mirror — further
iteration always happens here first.
