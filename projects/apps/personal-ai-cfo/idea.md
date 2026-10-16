# Personal AI CFO

> A personal financial intelligence app that unifies your whole financial life, projects your future position with explicit assumptions and deterministic calculations, tests goals and life events, and gives prioritized, trustworthy recommendations - read-only, privacy-first, and designed to extend to family finances later.

Full product spec: [spec/product-spec.md](./spec/product-spec.md).

## Problem

Personal finances are scattered across banks, EPF, NPS, investments, loans and insurance. Expense trackers and chatbots do not tell you where you stand, where you are heading, whether you can afford a goal, or what to do next.

## Target users

- **Primary**: an individual (India context) wanting one view of net worth, cash flow, goals and security.
- **Secondary**: families, joint owners and shared businesses (later versions, same foundations).
- **Anti-users**: people wanting trade execution, or generic AI financial advice.

## What success looks like

- Answers the five core questions (spec section 1) from the user's real records, explicit assumptions and calculated projections.
- No AI-invented numbers: calculations are deterministic (spec section 8).

## Constraints

- Read-only access to financial data; no money movement.
- Strong security and user ownership of financial data (spec section 9).
- Data model must support multi-owner extension without a rebuild (spec section 10).

## Non-goals

Not just an expense tracker, investment tracker or chatbot; no unverifiable AI-generated financial figures.

## Inspiration / prior art

Expense trackers, investment trackers and robo-advisors each cover a slice; this idea unifies them with a planning engine.

## Open questions

- [ ] Data-source strategy and import priority (spec section 7.1)?
- [ ] V1 scope boundary vs later versions (spec section 2)?
- [ ] Regulatory posture for recommendations?
