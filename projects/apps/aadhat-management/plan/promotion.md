# Promotion workflow — staging clone → production

Once a fix has soaked in the staging clone (`AadhatManagementApp-staging`)
and is trusted, this document describes the one-way path to merge it
back into production (`AadhatManagementApp`).

## Principles

1. **One-way.** Production never pulls from staging. Staging never
   pulls from production. Specific commits are *cherry-picked* by a
   human reviewer.
2. **Single feature per PR.** Don't bundle unrelated fixes. Each PR
   to prod should map to exactly one logical change so it's easy to
   review and easy to revert.
3. **No staging-only files cross over.** The clone has files prod
   doesn't (and shouldn't) have:
   - `STAGING_README.md`
   - `www/js/firebase/read-only-guard.js`
   - `www/staging-config.example.js`
   - `www/css/staging-banner.css` (banner)
   - `docs/staging-smoke-checklist.md`
   - `docs/STAGING_RULES_PATCH.md`
   - `.firebaserc` `targets` mapping (prod doesn't have a staging site)
   - The staging-specific GitHub workflow YAMLs
   - Any modifications to `service-worker.js` that block writes
   - Any modifications to `firebaseConfig.js` that force read-only
   - Any modifications to `index.html` that load `read-only-guard.js`,
     `staging-banner.css`, or `staging-config.js`
   - Any modifications to `www/js/auth/authentication.js` that add
     `tryStagingAutoLogin()` (or main.js calls to it)
4. **Tests must pass on prod after the merge.** If the clone added
   tests, those tests should travel with the fix.
5. **No new external dependencies without a reason.** Anything in
   `package.json` should be justified in the PR description.

## Recommended workflow (cherry-pick by file path)

Most fixes touch a tight set of files (e.g., `www/js/modules/stock.js`
and its test). The cleanest way to bring them across is:

```powershell
# (one-time) clone the prod repo next to the staging clone
cd D:\AadhatApp
git clone https://github.com/DDancingDeath/AadhatManagementApp.git AadhatManagementApp-prod
cd AadhatManagementApp-prod
git checkout -b fix/<short-name>      # e.g. fix/walk-25-stock-zero-cost

# Copy the changed files from staging
$staging = "D:\AadhatApp\AadhatManagementApp-staging"
$prod    = "D:\AadhatApp\AadhatManagementApp-prod"
Copy-Item "$staging\www\js\modules\stock.js" "$prod\www\js\modules\stock.js" -Force
Copy-Item "$staging\www\js\__tests__\stock.test.js" "$prod\www\js\__tests__\stock.test.js" -Force

# Verify nothing else changed
git status
git diff --stat HEAD

# Run the prod test suite (it may differ — investigate any new failures)
npm install --legacy-peer-deps
npm test

# Commit and push
git add -A
git commit -m "fix(stock): zero-cost item stock report regression (cherry-picked from staging WALK-25)`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push -u origin fix/walk-25-stock-zero-cost

# Open the PR
gh pr create --base main --head fix/walk-25-stock-zero-cost --title "fix(stock): zero-cost stock report" --body "Cherry-picked from staging clone commit <sha>. See REVIEW_ISSUES.md item WALK-25 in the staging clone for full reasoning."
```

## Alternative — `git format-patch` / `git am`

For larger fixes that span many files and have a meaningful commit
history in staging, use patches:

```powershell
cd D:\AadhatApp\AadhatManagementApp-staging
# Pick the commit range you want to bring across:
git format-patch -1 <staging-commit-sha> -o D:\tmp\promotion\

cd D:\AadhatApp\AadhatManagementApp-prod
git checkout -b fix/<short-name>
# Drop staging-only files from the patch first:
# (open the .patch in an editor and delete chunks that touch
#  read-only-guard.js, staging-banner.css, the extra index.html lines, etc.)
git am D:\tmp\promotion\0001-*.patch

npm install --legacy-peer-deps
npm test
gh pr create --base main --head fix/<short-name> --title "..." --body "..."
```

## Forbidden — never do these

* Do NOT push a staging branch to the prod remote.
* Do NOT add the prod repo as a remote of the staging clone.
* Do NOT cherry-pick the read-only-guard or service-worker write
  blocks into prod — production needs to be able to write.
* Do NOT cherry-pick the auto-login wiring into prod.
* Do NOT cherry-pick `.firebaserc` `targets` changes into prod.
* Do NOT promote any change without first running the prod test
  suite locally and seeing it pass.

## Recommended first PR back to prod

Per the master plan (Phase 5, item `p5-first-pr-fix-prod-ci`), the
**first** PR back to prod should fix the prod CI. Today the prod
`firebase-hosting-merge.yml` runs `npm ci && npm run build`, but
the prod `package.json` has no `build` script, so the action fails
on every push. The staging clone's workflow uses `npm ci
--legacy-peer-deps` followed by `npm test` and skips `npm run build`
— that diff is the right shape to bring across.

## Tracking which staging commits have shipped

Maintain a running ledger in the staging repo at
`docs/PROMOTION_LEDGER.md` (created on first promotion):

```
| Staging SHA | Prod SHA   | PR #  | Description                | Date       |
|-------------|------------|-------|----------------------------|------------|
| 03d3459     | (pending)  | (na)  | CHAT-LLM-1 (LLM fallback)  | 2026-05-15 |
```

Update it every time a staging commit is promoted (or explicitly
dropped). This avoids the question "is this staging commit in prod
yet?" becoming archeology.
