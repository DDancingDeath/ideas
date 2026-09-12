# Spec — AadhatManagement

This is the source of truth for what the app does.

> **Two specs in one folder.** The page-specs and the v1 design docs
> describe the **live production app** (what runs in the family shop
> today). The new [`rebuild/`](./rebuild/) subtree captures the
> **v2 rebuild** the owner is now scoping — same business, free to
> change layout / tech / data shape where it improves correctness or
> testability. When the two disagree, the rebuild subtree wins for v2
> work; for the live app, the page-specs win.

## Three reading tracks

The spec is written for three audiences asking different questions. Read
your own; read another's whenever you need to — nothing is hidden.

| Track | Who | What to read | Why |
|---|---|---|---|
| **Owner** | Deciding what to build | [`rebuild/scope-boundaries.md`](./rebuild/scope-boundaries.md), [`rebuild/suspicion-engine.md`](./rebuild/suspicion-engine.md), [`rebuild/role-permission-matrix.md`](./rebuild/role-permission-matrix.md), [`rebuild/analytics.md`](./rebuild/analytics.md), plus [`../idea.md`](../idea.md), [`../plan/rebuild/decisions.md`](../plan/rebuild/decisions.md), [`../plan/rebuild/roadmap.md`](../plan/rebuild/roadmap.md) | What the app promises the shop, what it catches when something goes wrong, and who may do what |
| **Engineer** | Judging the design | [`rebuild/README.md`](./rebuild/README.md), [`rebuild/worked-example.md`](./rebuild/worked-example.md), [`rebuild/invariants.md`](./rebuild/invariants.md), [`rebuild/architecture.md`](./rebuild/architecture.md), [`rebuild/event-ledger.md`](./rebuild/event-ledger.md) | Whether the event model, layering and invariants actually hold |
| **Agent** | Building it | Everything. Start at [`rebuild/README.md`](./rebuild/README.md) and follow its order | Payload shapes, permission cells, thresholds and fixtures are needed to implement, and are noise for a human |

Exact file lists and line counts: [`READING-TRACKS.md`](../READING-TRACKS.md).

## Reading order — v1 (live app)

| # | Doc | What it gives you |
|---|---|---|
| 1 | [`capabilities.md`](./capabilities.md) | Exhaustive feature inventory of what the code does today. Read for breadth |
| 2 | [`page-specs/README.md`](./page-specs/README.md) | The page-spec contract (Purpose / Files / Calculations / Must NOT do) and the `PeriodMath` shared-math table |
| 3 | [`page-specs/00-auth.md`](./page-specs/00-auth.md) → [`16-cash-management.md`](./page-specs/16-cash-management.md) | Page-by-page contracts. Canonical when live-app behaviour is disputed |
| 4 | [`firestore-rules-design.md`](./firestore-rules-design.md) | Data model, collections, and the **designed** role-based rules (shipped rules are weaker — see [`../plan/review-issues.md`](../plan/review-issues.md)) |
| 5 | [`chat-design.md`](./chat-design.md) | Implementation design behind the AI assistant tab (`15-chat.md` is the surface) |
| 6 | [`voice-billing-v2.md`](./voice-billing-v2.md) | Design for v2 of tap-to-talk voice billing on `02-billing.md`. V1 is live |

## Reading order — v2 (rebuild)

Held in one place: **[`rebuild/README.md`](./rebuild/README.md)** — 36 docs
in four groups (Foundations · Data and lifecycle · Correctness, monitoring
and access · Quality, performance, definition of done), each with a one-line
statement of what it settles. That index is the only v2 reading order; this
file does not repeat it.

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
- iOS in v2.0. (iOS is a v2.1 **stretch target** documented in
  [`rebuild/platform-compatibility.md`](./rebuild/platform-compatibility.md)
  §iOS posture, gated on a real-device printer verification or
  a Wi-Fi printer path.)
- Desktop-only UX.
