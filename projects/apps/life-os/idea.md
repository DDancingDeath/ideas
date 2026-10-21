# Life OS — personal life hub

> One private app for an individual and their household where each life area is a box — Finance, Health, Career & Learning, Family, Notes & reminders, Reflection — and one Ask box answers any question by looking across all the boxes, with deterministic, traceable calculations behind every number. Local-first and free to host: a home server reached over a private network now; offline engines on every device with end-to-end encrypted sync next.

## Problem

Personal life admin is scattered. Money lives in bank apps and spreadsheets,
health in PDF lab reports, career plans in notes, family plans in someone's
head. The questions that matter cut across all of them — *"Can I afford a car
next year?"* depends on savings, loans, insurance cover, job stability and who
depends on you — but no single tool sees more than one area, and AI chat tools
answer with confident numbers nobody can trace.

The data involved is the most sensitive a person has (money, health, family),
so handing it to a cloud service is not acceptable either.

## Target users

- **Primary**: one individual managing their own life and household — money,
  health check-ups, career and learning, family plans — who wants one place
  and one question box for all of it.
- **Secondary**: household members whose data the primary user records (a
  spouse, children, parents), visible only through the primary user's devices.
- **Anti-users**: advisers managing many clients; anyone wanting social or
  shared features; anyone wanting the app to move money, trade, or diagnose.

## What success looks like

- The user asks a cross-area question (*"Can I take a 6-month career break?"*)
  and gets an answer within 3 seconds whose every number links to the
  calculation, inputs fingerprint and engine version that produced it.
- When an input is missing, the answer says exactly which field is missing
  and asks for it — it never fills in a default.
- The same inputs produce byte-identical results on every device.
- The app opens and answers with the network off.
- No server outside the user's own devices ever holds readable personal data.
- Running costs are zero (free tiers only, no billing account attached).
- A new box can be added without changing the hub or the Ask contract.

## Constraints

- **Local-first.** The user's own devices are the system of record; the
  network is optional.
- **Free hosting.** Free tiers only, no billing account; any relay is
  replaceable and sees ciphertext only.
- **Deterministic numbers.** Every figure comes from a tested, versioned
  calculation. AI may phrase or plan, never invent numbers.
- **Platforms.** Website, phone and desktop from one codebase where possible.
- **Privacy.** No analytics, no third-party scripts, no personal data in logs,
  issues or commits.
- **Non-diagnostic, non-advisory tone** for health; assumptions always shown
  for finance.

## Non-goals

- Moving money, trading, filing taxes or connecting with write access to any
  account.
- Diagnosing or treating medical conditions.
- Multi-tenant or shared use beyond one household.
- Social features, feeds, gamification.
- Replacing the per-area apps' depth on day one — boxes start narrow.

## Related ideas

Each box has (or will have) its own idea as the detailed source; this idea
defines the hub, the box contract and the Ask contract that tie them together.

| Box | Detailed idea |
| --- | --- |
| Finance | [personal-ai-cfo](../personal-ai-cfo/) |
| Family | [parenting-companion](../parenting-companion/) |
| Notes & reminders | [notes-reminders](../notes-reminders/) |
| Reflection | [reflective-friend](../reflective-friend/) |
| Career & Learning | — (this idea; child learning see [learning-companion](../learning-companion/)) |
| Health | — (this idea) |

## Inspiration / prior art

- Personal finance aggregators (net-worth trackers) — one area only.
- Health record apps — store reports, no cross-area reasoning.
- General AI assistants — cross-area, but untraceable numbers and cloud data.

## Open questions

- [ ] **App name** — "Life OS" is the working title.
- [ ] **AI provider for Ask** — none (deterministic templates only), a local
      model, or a cloud model with the user's own key.
- [ ] **iOS** — is a native iOS app needed, or is the installable website
      enough on iPhone?
- [ ] **Desktop shell** — installable website only, or a packaged desktop
      app (Electron / Tauri)?
- [ ] **Whose learning** — does "learning" mean the user's own (Career &
      Learning box) or a child's (Family box), or both?
