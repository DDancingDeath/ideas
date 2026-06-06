# Personal Agent v0 (Launch-App Spike)

> Weekend spike to prove the cross-device personal agent's wire end-to-end: type 'notepad' on the phone, notepad opens on a named Windows dev box. One command kind (launch-app), one device, one app allow-list config file. Shared-secret auth, in-memory storage, HTTP long-poll, Expo Go. ~500 LoC across phone + cloud backend + device agent. If it lives, graduates into Phase 1 of cross-device-personal-agent.

---

## The idea

Problem (1-2 paragraphs): what hurts today, for whom, and why nothing on
the market quite fits.

Target users: primary, secondary, and explicit anti-users.

What success looks like: concrete, measurable outcomes. "User X can do Y in
under Z seconds." Not "people love it".

Non-goals: things this deliberately does NOT do — the cheapest features to
cut up front.

---

## How it works

A short tour of the system. What the user sees, what runs behind it, the
two or three key data flows. Keep it conceptual — every detail lives in
`spec/`.

If there's an architecture diagram, drop the image into `assets/` and
embed it here:

```markdown
![Architecture](./assets/architecture.png)
```

---

## What it does today (and what's next)

Status: design / prototype / MVP / production.

Headline capabilities (bullets). Anything notably **out of scope today**
that may come later.

If there are measurable results (POC eval, performance numbers, user
metrics), put a small table here.

---

## Tech stack

One line per layer (frontend, backend, data, hosting, mobile, etc.). State
which choices are negotiable for a rebuild and which are part of the
contract (e.g. data shape).

---

## Reading order for an agent

1. `idea.md` — vision only (subset of the section above; deeper detail).
2. `spec/` — source of truth for **what to build**. Start at
   `spec/README.md` (it sets the reading order).
3. `plan/` — status, known issues, next steps. **Do not reintroduce**
   anything listed under known issues.
4. `prompts/build-from-spec.md` — paste this to a coding agent to build /
   rebuild the application.

## Layout

```
<slug>/
├── README.md           ← (this doc) the narrative entry point
├── idea.md             ← vision in detail
├── spec/               ← functional source of truth
├── plan/               ← roadmap + known issues
├── prompts/            ← ready-to-paste agent prompts
└── assets/             ← mockups, screenshots, diagrams
```

## Recent changes

- _2026-06-07_ · initial scaffold

