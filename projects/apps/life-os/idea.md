# Life OS — personal life hub

> **North star: a personal chief of staff that knows the owner's whole life
> from the owner's own records.** One private app for an individual and their
> household where each life area is a box — Finance, Health, Career & Learning,
> Family, Notes & reminders, Reflection, Documents, Conversations — and one Ask
> box answers any question by looking across all the boxes, with deterministic,
> traceable calculations behind every number. Local-first, end-to-end
> encrypted and free to host.

## North star pillars

1. **Absorbs everything the owner already has** — document folders re-scanned
   periodically, bank and investment statements, email, tax documents (ITR,
   Form 16, AIS), medical reports, certificates, personal chats.
2. **Understands them as connected facts with provenance** — a life graph of
   people, accounts, assets, policies, documents, dates and events; every fact
   cites its source document and page.
3. **Reasons across life areas** for any question.
4. **Nudges before it matters** — FD maturity, policy and passport expiry,
   missing expected statements, retests due, birthdays from birth
   certificates, tax savings, spending drift.
5. **Answers anything with evidence** — "What is my PAN?" gives the masked
   value and its source, revealed only after re-authentication; "How can I
   save?" draws on spending patterns and tax documents.
6. **Stays the owner's** — local-first, end-to-end encrypted, no action
   without confirmation, identifiers never sent to AI providers.

## Problem

Personal life admin is scattered. Money lives in bank apps and spreadsheets,
health in PDF lab reports, career plans in notes, family plans in someone's
head, commitments in chats. The questions that matter cut across all of them —
*"Can I afford a car next year?"* depends on savings, loans, insurance cover,
job stability and who depends on you — but no single tool sees more than one
area, and AI chat tools answer with confident numbers nobody can trace.

The data involved is the most sensitive a person has (money, health, family,
identity numbers, private messages), so handing it to a cloud service is not
acceptable either.

## Target users

- **Primary**: one individual managing their own life and household.
- **Secondary**: household members whose data the primary user records (a
  spouse, children, parents), visible only through the primary user's devices.
- **Anti-users**: advisers managing many clients; anyone wanting social or
  shared features; anyone wanting the app to move money, trade, diagnose, or
  process work data.

## What success looks like

- A cross-area question (*"Can I take a 6-month career break?"*) is answered
  within seconds; every number links to the calculation, inputs fingerprint
  and engine version that produced it; every fact names its source document.
- A missing input is asked for by name — never filled with a default.
- The same inputs produce identical results on every device.
- The app opens and answers with the network off.
- No server outside the owner's devices ever holds readable personal data.
- Running costs are zero (free tiers only, no billing account attached).
- The owner learns about an FD maturity, a policy or passport expiry or a
  missing statement before it matters, without asking.
- A new box can be added without changing the hub or the Ask contract.

## Constraints

- **Local-first.** The owner's devices are the system of record.
- **Free hosting.** Free tiers only; any relay is replaceable and sees
  ciphertext only.
- **Deterministic numbers.** AI may phrase or plan, never invent numbers.
- **Platforms.** Website, phone and desktop from one codebase where possible.
- **Privacy.** No analytics, no third-party scripts, no personal data in logs,
  issues or commits; identifiers masked; message text never sent to an AI
  provider without per-source consent.
- **Read-only sources.** No portal passwords, no scraping, no write access to
  any account; source documents are never modified.
- **No work data.** Employer mail, chats, Teams and work agents' data stay in
  sanctioned work tools.
- **Non-diagnostic, non-advisory tone** for health; assumptions always shown
  for finance; tax output is an estimate, not filing advice.

## Non-goals

- Moving money, trading, filing taxes, or write access to any account.
- Diagnosing or treating medical conditions.
- Multi-tenant or shared use beyond one household.
- Social features, feeds, gamification.
- Recording calls.

## Related ideas

| Box | Detailed idea |
| --- | --- |
| Finance | [personal-ai-cfo](../personal-ai-cfo/) |
| Family | [parenting-companion](../parenting-companion/) |
| Notes & reminders | [notes-reminders](../notes-reminders/) |
| Reflection | [reflective-friend](../reflective-friend/) |
| Career & Learning | — (this idea; child learning see [learning-companion](../learning-companion/)) |
| Health, Documents, Conversations | — (this idea) |

## Inspiration / prior art

- Personal finance aggregators — one area only.
- Health record apps — store reports, no cross-area reasoning.
- Document managers — store files, don't turn them into facts.
- General AI assistants — cross-area, but untraceable numbers and cloud data.

## Open questions

Each is tracked with a recommended default in
[`spec/README.md` § Open questions](./spec/README.md#open-questions).

- [ ] **App name** — "Life OS" is the working title.
- [ ] **AI provider for Ask** — none, a local model on the home-server PC, or a
      cloud model with masked facts only.
- [ ] **Life graph data model** and **proactive engine** design.
- [ ] **Whose learning** — the owner's (Career & Learning) or a child's (Family).
- [ ] **Account Aggregator via a regulated partner** — or stay with
      statements, alerts and public prices.
- [ ] **Cloud relay** for sync — the owner's home server only, or a free-tier
      Firebase project too.
- [ ] **iOS** and **desktop shell** — native apps or the installable website.
- [ ] **Conversations** — what the Android app may read; how commitments are
      detected; Telegram own-account.
