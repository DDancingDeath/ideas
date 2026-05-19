# Spec — AadhatManagement

This is the source of truth for what the app does.

## Reading order

1. **[`capabilities.md`](./capabilities.md)** — exhaustive feature inventory
   ("what the code does today"). Read this for breadth.
2. **[`page-specs/README.md`](./page-specs/README.md)** — explains the page
   spec contract (Purpose / Files / Calculations / Must NOT do / etc.).
3. **[`page-specs/00-auth.md`](./page-specs/00-auth.md) → `16-cash-management.md`**
   — page-by-page contracts. These are the canonical truth when behavior is
   in dispute.
4. **[`firestore-rules-design.md`](./firestore-rules-design.md)** — data
   model, collections, role-based authorization, and the **production**
   Firestore rules design (the current shipped rules are weaker — see
   `../plan/review-issues.md`).
5. **[`chat-design.md`](./chat-design.md)** — design for the AI assistant
   tab (page `15-chat.md` is the surface; this doc is the implementation
   design behind it).

## Glossary

- **Aadhat / Aadhat-i** (आढ़त) — Hindi for "commission / wholesale
  brokerage". The shop's traditional business name.
- **Khaata / Udhaar** — customer credit / outstanding balance.
- **Day close** — the end-of-day routine: count cash, reconcile drawer,
  archive the day.
- **Owner / Manager / Staff** — the three roles. Owner sees everything;
  manager has limited admin; staff can bill + lookup only.

## Notes for agents reading these docs

- Some links inside the per-page specs reference paths from the original
  source repo (e.g. `docs/CAPABILITIES.md`, `www/js/utils/...`). Mentally
  re-map:
  - `docs/CAPABILITIES.md` → `./capabilities.md`
  - `docs/REVIEW_ISSUES.md` → `../plan/review-issues.md`
  - `docs/PROD_FIRESTORE_RULES_DESIGN.md` → `./firestore-rules-design.md`
  - `docs/CHAT_DESIGN.md` → `./chat-design.md`
  - `www/js/...` → original implementation (not in this repo)
- The page-specs `Calculations / formulas` sections are the math truth. If
  a screen shows a different number, the screen is wrong.
- The page-specs `Must NOT do` sections are invariants — never violate them
  when implementing.

## Out of scope (deliberately)

- GST / e-invoicing.
- Multi-tenant / multi-branch.
- iOS.
- Desktop-only UX.
