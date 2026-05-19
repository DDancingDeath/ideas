# AadhatManagement

> A Hindi/English-bilingual business management app for a small
> wholesale/retail shop. One owner + a couple of staff run the day on a
> phone or tablet: billing, sales, stock, cash, outstanding (udhaar),
> reports. Bluetooth thermal printing. Works offline-tolerantly. In
> production since 2025 and used daily by the owner's family business.

- **Live code repo:** <https://github.com/DDancingDeath/AadhatManagementApp>
- **Staging mirror (private):** `DDancingDeath/AadhatManagementApp-staging`
  — these docs were authored there.
- **Status:** in production. Spec is essentially frozen; **security
  hardening + refactor pending** (see [`plan/review-issues.md`](./plan/review-issues.md)
  — XSS and Firestore-rule weaknesses are the priority backlog).

---

## The idea

Small wholesale/retail shops in India run on paper ledgers plus WhatsApp.
Real pains:

- **Stock is unknown until sale time.** Owner discovers shortages when a
  customer is already at the counter.
- **Outstanding (udhaar) is scattered.** Across notebooks, phone memory,
  and "I'll remember it."
- **Cash drawer mismatches** at end-of-day with no audit trail.
- **Generic ERPs are too expensive, English-only, and Windows-bound.** Not
  designed for a Hindi-first shop floor.
- **Family + staff need different slices** of the same data with
  different permissions — but most low-end POS apps have a single
  shared password.

AadhatManagement is the answer for *this* shop. Mobile-first, bilingual
labels everywhere (no separate locale toggle), three roles with real UI
gating (owner / manager / staff), live dashboards on Firestore
`onSnapshot` so the screen never lies. Anti-users: multi-branch chains,
GST-filing automation, anyone needing iOS or desktop-first.

Deeper detail: [`idea.md`](./idea.md).

---

## How it works

A single-page web app served from Firebase Hosting, wrapped with
Capacitor 7 to run on Android and access Bluetooth printers. Data lives
in Firebase Firestore; the app subscribes to seven `onSnapshot`
listeners so every screen recomputes when anything changes.

```
┌──────────────────────┐                  ┌──────────────────────┐
│  Android phone /     │  Capacitor 7     │  Bluetooth ESC/POS   │
│  tablet (or PWA in   │  ──────────────▶ │  thermal printer     │
│  browser)            │                  │  (Capacitor BLE)     │
└──────────┬───────────┘                  └──────────────────────┘
           │
           │  onSnapshot listeners (items, purchases, retail/wholesale
           │  sales, expenses, stockAdjustments, withdrawals,
           │  cashSessions)
           ▼
┌──────────────────────┐                  ┌──────────────────────┐
│  Firebase Firestore  │  Firebase Auth   │  3 roles:            │
│  9 collections,      │ ───────────────▶ │  owner / manager     │
│  `dev_`-prefix env   │                  │  / staff             │
│  switching           │                  │  (UI + design rules) │
└──────────────────────┘                  └──────────────────────┘
```

**One shared math helper.** Finance, Reports, and Analytics all delegate
to `PeriodMath` for every number on screen — date ranges, cash on hand,
stock value, outstanding, period revenue, payment split. If two of those
three pages disagree on the same number, the bug is in whichever caller
bypassed `PeriodMath`. (See [`spec/page-specs/README.md`](./spec/page-specs/README.md),
"Shared math".)

**Environment switching by collection prefix.** `?env=development` or
`localhost` auto-detection makes the app talk to `dev_purchases`,
`dev_retailSales`, etc. — same Firebase project, isolated data. Cheap,
effective, no second project to manage.

**Voice billing.** Tap-to-talk Hindi+English voice entry on the billing
page is live (v1, commit `56e230f`). V2 is in design — multi-item one-
breath bills, hands-free verification, wider Hindi number vocabulary —
see [`spec/voice-billing-v2.md`](./spec/voice-billing-v2.md).

---

## What it does today

Headline capabilities (full inventory in [`spec/capabilities.md`](./spec/capabilities.md)):

- **Billing** (retail + wholesale) with item lookup, weight chips, draft
  bills, ESC/POS print, voice entry.
- **Stock** — live computed from purchases − sales + adjustments; never
  stored, never stale.
- **Cash management** — sign-in / sign-out sessions, opening + closing
  count, drawer reconciliation, day close.
- **Outstanding** — per-customer/supplier ledger; payable and receivable
  in one view.
- **Reports + Analytics + Finance** — daily / weekly / monthly /
  custom; charts; CSV export.
- **Audit log** — owner-only 90-day immutable trail of every critical
  action.
- **Mobile polish** — haptics, pull-to-refresh, toasts; details in
  [`spec/mobile-enhancements.md`](./spec/mobile-enhancements.md).

**Pages at a glance** (17 page-specs total, full contracts in
[`spec/page-specs/`](./spec/page-specs/)):

| # | Page | Owner-only |
|---|---|---|
| 0 | Login / Register | — |
| 1 | Today | — |
| 2 | Billing | — |
| 3 | Wholesale Sales | — |
| 4 | Expenses | — |
| 5 | Items | — |
| 6 | History | — |
| 7 | Stocks | — |
| 8 | Outstanding | — |
| 9 | Finance | — |
| 10 | Reports | — |
| 11 | Analytics | — |
| 12 | Admin | **yes** |
| 13 | Diagnostics | **yes** |
| 14 | Settings | — |
| 15 | AI Assistant | — |
| 16 | Cash Management *(embedded in Today)* | — |

---

## Tech stack (current implementation)

| Layer | Choice | Negotiable? |
|---|---|---|
| Frontend | Vanilla ES6 modules | Yes — Lit/Svelte plausible |
| Data | Firebase Firestore (compat SDK) | **No — data shape is part of the spec** |
| Auth | Firebase Auth (email/password) | Yes |
| Mobile | Capacitor 7.x (Android) | Yes |
| Hosting | Firebase Hosting | Yes |
| Printing | Bluetooth ESC/POS via Capacitor BLE | **No — required** |
| Testing | Jest + Babel | Yes |
| i18n | Inline `Hindi / English` labels | Yes |

**The Firestore collection shape and the three-role model are part of
the spec** — see [`spec/firestore-rules-design.md`](./spec/firestore-rules-design.md).
The shipped Firestore rules are intentionally weaker than that design
while the app stabilizes; new work must move toward the design, not away
from it.

---

## Known issues (do not reintroduce)

Full list: [`plan/review-issues.md`](./plan/review-issues.md). The
priority ones:

- **Stored XSS** — 144 + `innerHTML` interpolations of user-controlled
  data across 19 files; only 5 are escaped. Worst sink:
  `diagnostics.js:328` (`<strong>${log.userName}</strong>`) which gives
  staff → owner privilege escalation via audit log injection.
- **Firestore rules are too permissive** — `allow read, write: if
  isSignedIn()` on financial collections means a staff user with the
  API can bypass UI role checks and write anywhere. The shipped rules
  vs. the designed rules diverge; see
  [`spec/firestore-rules-design.md`](./spec/firestore-rules-design.md).
- **Audit-log cleanup is dead code** — `auditLogs` has `allow update,
  delete: if false` but cleanup batches try to delete; fails silently
  every owner login.
- **CI is broken** — workflows run `npm ci && npm run build` but there
  is no `build` script and `npm ci` fails on `canvas` peer dep.
- **Service worker install fails** — STATIC_ASSETS lists files that no
  longer exist; `cache.addAll` is atomic, so offline support doesn't
  work despite README claiming it does.

---

## Reading order for an agent

1. **[`idea.md`](./idea.md)** — vision in detail.
2. **[`spec/README.md`](./spec/README.md)** — spec entry point + glossary
   + path-remapping notes.
3. **[`spec/capabilities.md`](./spec/capabilities.md)** — exhaustive
   feature inventory.
4. **[`spec/page-specs/README.md`](./spec/page-specs/README.md)** —
   per-page contract template + page index + the `PeriodMath` table.
5. **[`spec/page-specs/`](./spec/page-specs/)** (00-auth → 16-cash) —
   one file per screen.
6. **[`spec/firestore-rules-design.md`](./spec/firestore-rules-design.md)**
   — data model + authorization (the **designed** rules, not the
   shipped ones).
7. **[`spec/chat-design.md`](./spec/chat-design.md)** — AI assistant tab.
8. **[`spec/voice-billing-v2.md`](./spec/voice-billing-v2.md)** — voice
   billing v2 design.
9. **[`spec/mobile-enhancements.md`](./spec/mobile-enhancements.md)** —
   mobile polish (haptics, toasts, pull-to-refresh).
10. **[`plan/review-issues.md`](./plan/review-issues.md)** — known
    defects. Do not reintroduce.
11. **[`plan/promotion.md`](./plan/promotion.md)** — staging → prod
    protocol.
12. **[`plan/staging-smoke-checklist.md`](./plan/staging-smoke-checklist.md)**
    — manual smoke test.
13. **[`plan/legacy-agents-orientation.md`](./plan/legacy-agents-orientation.md)**
    — the original `AGENTS.md` from the live repo (safety rules and
    operational workflow for code work, not spec work).
14. **[`plan/setup/`](./plan/setup/)** — environment setup, Bluetooth
    printer config, Firebase project setup, staging mode docs. Read
    these when you actually start building or deploying.
15. **[`prompts/build-from-spec.md`](./prompts/build-from-spec.md)** —
    paste-ready prompt to (re)build the app.

## Layout

```
aadhat-management/
├── README.md                       ← (this doc) narrative entry point
├── idea.md                         ← vision in detail
├── spec/
│   ├── README.md
│   ├── capabilities.md
│   ├── chat-design.md
│   ├── firestore-rules-design.md
│   ├── mobile-enhancements.md
│   ├── voice-billing-v2.md
│   └── page-specs/                 ← 17 per-page contracts + README
├── plan/
│   ├── review-issues.md
│   ├── promotion.md
│   ├── staging-smoke-checklist.md
│   ├── legacy-agents-orientation.md
│   └── setup/                      ← env, printer, firebase, staging
├── prompts/
│   └── build-from-spec.md
└── assets/                         ← mockups / screenshots / diagrams
```

## Notes on these docs

- The docs in `spec/` and `plan/` were authored against the staging
  repo's `docs/` folder. Some internal links inside them still
  reference the original repo paths (e.g. `docs/CAPABILITIES.md`,
  `www/js/...`). Treat those as historical pointers; the canonical
  location is now this folder. The spec/README has a full re-map table.

## Recent changes

- _2026-05-20_ · Brought in remaining docs from the staging mirror:
  `MOBILE_ENHANCEMENTS.md` → `spec/mobile-enhancements.md`; root-level
  `AGENTS.md` → `plan/legacy-agents-orientation.md`; setup notes
  (Bluetooth printer, environment, Firebase, staging-readme,
  staging-rules-patch) → `plan/setup/`. README rewritten as the
  narrative entry point.
- _2026-05-20_ · Added `spec/voice-billing-v2.md` — v2 design doc
  imported from the staging mirror's working tree (was uncommitted
  there).
- _2026-05-19_ · Initial import of spec + plan docs from
  `AadhatManagementApp-staging/docs/`.
