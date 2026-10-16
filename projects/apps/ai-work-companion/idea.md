# AI Work Companion

> A personal intelligence layer that learns from the AI work you choose to record, recommends better models, agents, tools and techniques for it, and builds your expertise over time - local-first, evidence-based, and not another coding assistant or news feed.

Full product spec: [spec/product-spec.md](./spec/product-spec.md).

## Problem

The AI ecosystem changes faster than anyone can track. People who use AI daily cannot continuously find which new models, agents, frameworks and techniques matter to their own work, compare them with their current approach, and learn them while doing their actual job.

## Target users

- **Primary**: someone who actively uses AI in professional work and wants to stay effective as the ecosystem evolves.
- **Secondary**: teams wanting shared, policy-aware AI tooling guidance (later).
- **Anti-users**: people wanting an assistant that does the work for them, a news feed, or a course platform.

## What success looks like

- North star: validated improvements to the user's AI workflows per month, alongside growing understanding of the underlying technologies.
- Recommendation relevance, action rate, noise rate and personalization improvement as defined in spec section 14.
- Comfortable recommending nothing when there is no meaningful improvement.

## Constraints

- Local-first desktop application; sensitive data stays local by default.
- Capture only what the user chooses to record; external processing is opt-in and policy-aware.
- Recommendations must be grounded in current, verifiable evidence (vendor claims distinguished from independent evaluations).

## Non-goals

See spec section 13: no competing coding agent, no generic AI news aggregator, no continuous screen or keystroke recording, no automatic stack or model switching without approval, no rigid curriculum unrelated to real work.

## Inspiration / prior art

AI coding assistants, AI news aggregators and learning platforms each cover one part; this idea connects all three around the user's actual work.

## Open questions

- [ ] Which work sources to integrate first (spec section 12, phase 1)?
- [ ] Which discovery sources count as credible evidence (spec section 8)?
- [ ] Local vs opt-in cloud processing boundary for work capture.
