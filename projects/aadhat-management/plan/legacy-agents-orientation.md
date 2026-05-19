# AGENTS.md — Guide for AI agents working in this repo

> If you are an AI coding agent landing in this repository, **read this file
> before doing anything else**. It will save you (and the human) a lot of
> wasted turns.

---

## 1. What this repo is

This is the **staging clone** of `AadhatManagementApp` — a Hindi/English
wholesale-retail business app (Firebase + vanilla ES modules + Capacitor).

- **Source-of-truth prod repo**: `https://github.com/DDancingDeath/AadhatManagementApp`
- **This clone was forked** (manually, not via GitHub fork) at commit `bc2a434`.
- **Purpose**: a place to make and verify improvements **without any risk to
  production data**. Production users keep using the prod app while we work.

See `STAGING_README.md` (root) for the read-only safety model.

---

## 2. The unbreakable rules

1. **Never edit `D:\AadhatApp\AadhatManagementApp\` directly.** That's the
   prod working copy on this machine. Touch only `D:\AadhatApp\AadhatManagementApp-staging\`.
2. **Never write to prod Firestore from this clone.** Three layers of
   write-blocking are documented in `STAGING_README.md`. If you bypass any of
   them, you have made the clone unsafe.
3. **Never push this clone to the prod GitHub repo.** This is a *separate*
   repo (when it's pushed at all). Promotion to prod is a one-way
   `git cherry-pick` + `gh pr create` against the prod repo.
4. **Don't add a build step or framework.** No webpack, no Vite, no React. The
   prod app is plain `<script>` tags and `window.app` globals; staying
   compatible is required for cherry-picking.
5. **Don't rename files casually.** Inline `onclick="window.app.x.y()"`
   handlers and `template-loader.js` rely on stable file names.
6. **Always run `npm install --legacy-peer-deps`** until `p4-fix-canvas` is
   done — `canvas` peer-conflicts with `jest-environment-jsdom`.
7. **Never delete entries from `docs/REVIEW_ISSUES.md`.** Strike them through
   when fixed; keep the row.

---

## 3. Where to start reading

In order:

1. `STAGING_README.md` — what this clone is, what's safe.
2. `docs/PAGE_SPECS.md` — **the per-page contract.** When the owner says
   "page X is wrong", read the matching section here first. When you
   intentionally change behavior, update the matching section in the
   same PR.
3. `docs/CAPABILITIES.md` — descriptive ("what the code does today").
   Use this when you need to *understand* the existing app; use
   `PAGE_SPECS.md` when you need to *check* it against intent.
4. `docs/REVIEW_ISSUES.md` — the running checklist of everything that's broken.
5. The prod README (`README.md`, copied verbatim from prod) — original context.
6. `plan.md` (in the human's session folder, *not* in this repo) — current
   phase plan. Ask the human if you don't have it.

---

## 4. Codebase orientation (the bits you'll get wrong)

### Naming surprises

| You'd guess | Actual file |
|---|---|
| `expenses.js` | `www/js/modules/miscellaneous.js` |
| `printer.js` (modules) | `www/js/services/printer.js` |
| `wholesaleSalesHistory` | `AppState.salesHistory` (just "salesHistory" means **wholesale** here) |
| `retailSalesHistory` | `AppState.retailSalesHistory` (this one's normal) |
| `chat.js` | does not exist — the AI Assistant tab is wired but unimplemented |
| `bottom-nav.html` | doesn't exist — the "bottom" tabs are the bottom of the side nav in `navigation.html` |

### Conventions

- **All UI updates run inline `onclick` handlers** that call `window.app.*`. To expose a new module method to the UI, register it in `main.js`.
- **All Firestore access goes through `FirebaseService`** so collection names get the env prefix (`prod_`, `staging_`). Several existing modules bypass it — those are bugs (`docs/REVIEW_ISSUES.md` Section C/E).
- **Templates live in `www/templates/`**. They are loaded by `template-loader.js` on demand and inserted into the SPA shell.
- **Date strings**: bills mix ISO-8601 and `DD/MM/YYYY`. Use `Helpers.parseDate()` — never raw `new Date(string)`.
- **Money fields**: bills sometimes store `dueAmount` at top level *and* `payment.due` inside a nested object. Both can exist; both can drift. Read both, write both, treat the nested one as canonical when present.
- **State**: a single `AppState` object lives in `state.js`. Never invent a parallel cache.

### Things that look wrong but aren't

- The `xlsx` global pollution warning in tests is expected (SheetJS).
- `firebase` global is the compat-SDK style — modular SDK is intentionally not used.
- Many functions are async but don't await — that's a real bug, but documented; don't "fix" them silently.

---

## 5. Standard workflows

### "I want to fix a bug"

1. **First**, open `docs/PAGE_SPECS.md` and find the page section for
   the area being reported. The "Must NOT do" lines and "Example bug
   reports → what to change" lines are usually enough to locate the
   defect.
2. Find the row in `docs/REVIEW_ISSUES.md`. If it's not there, **add it
   first** (see "How to mark an item done" section in that file).
3. Make the change in `www/js/...`.
4. Run `npm test`. Baseline must stay green (103/103 at fork; 447 today).
5. If you added behaviour, add a Jest test for it.
6. Mark the issue row as done (`[x]`, strikethrough, fix-commit reference).
7. If the fix changes the page's intended behavior, also update the
   matching section in `docs/PAGE_SPECS.md` (strikethrough; never delete).
8. Commit with a message like `fix(stock): refresh current-stock pane after adjustment (REVIEW_ISSUES WALK-25) [PAGE_SPECS §7]`.
9. **Do not push to prod.** If the human wants to promote, they'll cherry-pick.

### "I want to add a new capability"

1. Update `docs/CAPABILITIES.md` in the same change — describe the new
   capability under the right module section.
2. Add new tabs by updating `navigation.html`, the template, and exposing the
   module via `main.js` `window.app.*`.
3. Re-test.

### "The human asked me to read the prod app before changing anything"

Use the prod working copy at `D:\AadhatApp\AadhatManagementApp\` for **reads
only**. Cross-reference into this clone using `Compare-Object` or a manual
diff. **Do not** open file editors against the prod path.

---

## 6. The Firestore safety model in one paragraph

This clone enforces read-only access to the shared Firebase project via three
independent layers: (1) a JS guard that monkey-patches Firestore writes to
throw, (2) a service worker that 403s every non-GET network call to Firebase
hosts, and (3) an additive Firestore rule on the prod project that denies
writes from a single dedicated `staging-readonly@aadhat.local` user. **Layers
1 and 2 are mandatory before any agent runs the clone against the live
project.** Layer 3 is mandatory before the clone is hosted publicly. If any
of these three is missing, stop and ask the human.

Implementation locations once Phase 1 lands:
- Layer 1: `www/js/firebase/read-only-guard.js` (loaded by `firebaseConfig.js`).
- Layer 2: `www/service-worker.js` (the `fetch` handler).
- Layer 3: lives in the prod repo / Firebase Console — *not* in this clone.

---

## 7. AI Assistant (`chat`) — design constraints

The user explicitly wants "a better AI chatbot". When you implement it
(Phase 4):

- **Do not** make a generic "let the LLM ramble" chat. The whole value is
  that the assistant knows the user's stock, sales, outstanding, and cash.
- Architect as: **intent router → structured query against AppState → LLM
  for natural-language summarisation only**. Cheap and fast for the common
  cases ("how much rice do I have?", "who owes me the most?"); LLM only for
  open-ended questions.
- The intent router can start as a tiny keyword/regex thing — no model
  needed. Add an LLM only when keyword routing genuinely fails.
- All Firestore reads must go through `FirebaseService` (no bypass).
- All UI updates must escape user-content (we have an open XSS issue,
  see `REVIEW_ISSUES.md` Section A).
- API keys for any LLM provider go in environment config + Firebase Functions
  config — **never** committed to the repo.

---

## 8. Commands you'll need

```powershell
# Install (always with the legacy flag until p4-fix-canvas)
cd D:\AadhatApp\AadhatManagementApp-staging
npm install --legacy-peer-deps

# Run tests
npm test

# Test with coverage
npm run test:coverage

# Local serve (firebase serve under the hood)
npm start
```

Don't run `firebase deploy` from here unless you've confirmed the active
Firebase project is the staging one (`firebase use --add` to a staging alias
first; never deploy to prod from this clone).

---

## 9. When you should stop and ask the human

- The change you're about to make would touch the prod repo or prod Firestore.
- A test failure looks unrelated to your change.
- You can't tell whether a piece of state is the canonical one (e.g. `payment.due` vs `dueAmount`).
- You're about to add a new dependency.
- You're about to introduce a build step.
- The bug you found is in the read-only-guard / service worker / Firestore rule (these are safety-critical; a "fix" can silently make the clone unsafe).

---

## 10. Useful greps when you're lost

```powershell
# Find every place a Firestore collection is referenced raw (bypassing the wrapper)
grep -rnE "db\.collection\('(purchases|retailSales|wholesaleSales|expenses|items|users)'" www/

# Find every inline onclick in a template
grep -rn "onclick=" www/templates/

# Find every window.app.* usage in templates
grep -rnE "window\.app\.[a-zA-Z]+\.[a-zA-Z]+" www/templates/

# Find every showToast(..., 'error') (Issue WALK-24 — wrong arg type)
grep -rnE "showToast\([^,]+,\s*['\"](error|success|warning|info)['\"]\)" www/
```

---

## 11. If you're a human reading this

You are now an honorary agent. The same rules apply. Welcome aboard.
