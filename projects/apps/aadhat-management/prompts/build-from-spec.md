# Build prompt — AadhatManagement

Paste this prompt to a coding agent (Copilot CLI, Cursor, Claude Code, etc.)
to (re)build AadhatManagement from the spec in this folder.

---

You are building **AadhatManagement**, a bilingual (Hindi/English) business
management app for a small wholesale/retail shop. The entire spec is in this
folder and its siblings. **Do not invent behavior; ask if unsure.**

## Step 1 — Load context (read in this order)

1. `../idea.md` — problem, users, success criteria.
2. `../spec/README.md` — spec orientation + glossary + path remapping notes.
3. `../spec/capabilities.md` — feature inventory.
4. `../spec/page-specs/README.md` — page-spec contract.
5. `../spec/page-specs/00-auth.md` through `16-cash-management.md` — one
   page at a time, in order. These are the canonical contracts. Pay
   special attention to:
   - **Purpose** (the invariant)
   - **Must NOT do** (hard constraints — never violate)
   - **Calculations / formulas** (math truth)
   - **Data sources** (which Firestore collections each page reads/writes)
6. `../spec/firestore-rules-design.md` — data model + authorization. **Use
   this for the rules, not the current shipped rules** (which are
   intentionally weaker for the live app — see review-issues).
7. `../spec/chat-design.md` — only if you're implementing the AI
   assistant tab.
8. `../plan/review-issues.md` — known defects in the current
   implementation. **Do not reintroduce any of these.**

## Step 2 — Confirm with the user

Before writing code, confirm:

- **Tech stack**: default is vanilla ES6 + Firebase Firestore + Capacitor 7
  for Android. Ask if the user wants to keep that stack or move to
  React/Lit/Svelte/etc. If unsure, stay with vanilla ES6 — the spec is
  written against it.
- **Scope of this build**: a from-scratch rebuild, or a refactor of the
  existing repo at <https://github.com/DDancingDeath/AadhatManagementApp>?
- **Target**: web PWA only, or PWA + Android via Capacitor?

## Step 3 — Generate code in a new location

- **Do not modify any file in this `projects/apps/aadhat-management/` folder.**
  This repo is docs-only.
- Generate the app in a separate directory (e.g.
  `D:\AadhatApp\AadhatManagementApp-rebuild` or a new GitHub repo).
- In the generated repo's README, link back to:
  - This folder (for the spec)
  - `../plan/review-issues.md` (for the known-issues backlog)

## Step 4 — Build order

Implement in this sequence; each step ships a runnable artifact:

1. **M0 — Scaffold**: project init, Firebase config, env switch
   (dev/prod via collection prefix), empty routing shell.
2. **M1 — Auth**: page `00-auth.md`. Login + register + role model.
3. **M2 — Master data**: page `05-items.md`. Item catalog with rates.
4. **M3 — Core transactions**: pages `02-billing.md` + `03-wholesale-sales.md`.
5. **M4 — Stock + History**: `07-stock.md`, `06-history.md`.
6. **M5 — Outstanding + Expenses**: `08-due.md`, `04-expenses.md`.
7. **M6 — Cash + Day close**: `16-cash-management.md`, `01-day.md`.
8. **M7 — Reports + Analytics**: `10-reports.md`, `11-analytics.md`,
   `09-finance.md`. Implement the shared math helper (`PeriodMath` in the
   page-specs README) once and route all three through it.
9. **M8 — Admin / Diagnostics / Settings**: owner-only pages.
10. **M9 — Chat assistant**: only after the rest is stable.
11. **M10 — Capacitor wrap + Bluetooth printing**.

## Quality bar

- Test suite passes; coverage for utilities ≥ 90%.
- No `innerHTML` interpolation of user-controlled data. Use `textContent`
  or an escaped builder. (See `plan/review-issues.md` — this was the
  biggest defect in the original implementation.)
- Firestore rules match `spec/firestore-rules-design.md`, **not** the
  weaker rules the live app currently ships.
- README has install + run in ≤ 3 commands.
- A `bun run` / `npm start` works from a clean clone.

## What to ask before you start

- Tech stack confirmation (see Step 2).
- Whether to reuse the existing Firebase project or create a new one.
- Whether i18n should stay as inline `Hindi / English` labels or move to a
  proper i18n file.
- Whether to keep the `dev_` collection-prefix env-switching scheme.

## What you must NOT do

- Don't post anything to <https://github.com/DDancingDeath/AadhatManagementApp>
  directly. That is the live production repo. All work goes in a new
  location until the owner explicitly says otherwise.
- Don't invent features that aren't in `spec/`. If something is missing,
  flag it as a `TODO(spec)` and stop.
- Don't relax the role-based authorization in `firestore-rules-design.md`
  for convenience. Staff/manager/owner separation is a hard requirement.
