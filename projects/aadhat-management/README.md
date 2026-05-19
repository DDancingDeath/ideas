# AadhatManagement

A Hindi/English-bilingual business management app for a small wholesale/retail
operation (purchase + sales + stock + cash + outstanding + reporting), built
as a PWA with an Android wrapper.

- Live app repo: <https://github.com/DDancingDeath/AadhatManagementApp>
- Staging mirror (where these docs were authored): private
  `DDancingDeath/AadhatManagementApp-staging`
- Status: **in production**, used daily by the owner's family business.
  Spec is frozen-ish; refactor + security hardening pending (see
  [`plan/review-issues.md`](./plan/review-issues.md)).

## Read this folder in this order

1. **[`idea.md`](./idea.md)** — problem, users, north star.
2. **[`spec/README.md`](./spec/README.md)** — spec entry point + reading order.
3. **[`spec/page-specs/`](./spec/page-specs/)** — page-by-page contracts.
4. **[`spec/capabilities.md`](./spec/capabilities.md)** — what the code does
   today (descriptive).
5. **[`spec/firestore-rules-design.md`](./spec/firestore-rules-design.md)** —
   data model + authorization design.
6. **[`spec/chat-design.md`](./spec/chat-design.md)** — design for the in-app
   AI assistant feature.
7. **[`plan/review-issues.md`](./plan/review-issues.md)** — known defects.
   New work must not reintroduce these.
8. **[`plan/promotion.md`](./plan/promotion.md)** — staging→prod promotion
   protocol.
9. **[`plan/staging-smoke-checklist.md`](./plan/staging-smoke-checklist.md)**
   — manual smoke test before promotion.

## Build this app from the spec

Hand [`prompts/build-from-spec.md`](./prompts/build-from-spec.md) to a coding
agent.

## Tech stack (current implementation)

- **Frontend**: Vanilla ES6 modules
- **Data**: Firebase Firestore (compat SDK)
- **Auth**: Firebase Auth (email/password)
- **Mobile**: Capacitor 7.x (Android)
- **Hosting**: Firebase Hosting
- **Printing**: Bluetooth ESC/POS thermal printers via Capacitor BLE
- **Testing**: Jest + Babel
- **i18n**: Hindi + English, mostly via inline `Hindi / English` labels

A reimplementation does not need to use this stack — but the data shape
(Firestore collections, role model) **is** part of the spec.

## Notes on these docs

- The docs in `spec/` and `plan/` were authored against the staging repo's
  `docs/` folder. Some internal links inside them still reference the
  original repo paths (e.g. `docs/CAPABILITIES.md`, `www/js/...`). Treat
  those as historical pointers; the canonical location is now this folder.
- No screenshots or mocks have been added yet. Drop any UI mocks into
  [`assets/`](./assets/) and reference them from the relevant page-spec
  file.

## Recent changes

- _2026-05-19_ · Initial import of spec + plan docs from
  `AadhatManagementApp-staging/docs/`.
