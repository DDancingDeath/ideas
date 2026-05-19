# Plan — winui-expert-teammate

## Status

**Pitched as an intern project.** No code. Existing brain components
(winui-expert KB, WinUI Code Review, winui-regression-reviewer) are
in production and are reused as services.

## Phased delivery

Each phase ships a usable slice. v1 (phase 1) has real users from day
1; subsequent phases extend the same teammate.

### Phase 1 — Identity + Q&A (Teams)

**Goal:** the bot exists as a Teams app, has a name, and answers
WinUI questions in 1:1 chat and on @mention in channels.

- Bot Framework app provisioned, manifest signed.
- Persona, avatar, name finalized.
- Calls winui-expert for Q&A; surfaces citations.
- Captures Q&A into persistent memory.
- Manual install per team.

**Acceptance:**

- Five WinUI engineers using it daily for a week.
- ≥ 80 % of Q&A responses rated useful in thumbs-up/down feedback.
- All responses cite sources.

### Phase 2 — PR review (GitHub/ADO)

**Goal:** add as PR reviewer; the bot posts architect-level review
comments.

- GitHub App + ADO service account provisioned.
- Webhook handlers for `pull_request` events.
- Calls WinUI Code Review and winui-regression-reviewer; posts
  comments with severity and rationale.
- Captures the PR thread into persistent memory.

**Acceptance:**

- Used on ≥ 20 real PRs.
- ≥ 60 % of bot comments accepted by authors (acted on or
  acknowledged); false-positive rate < 20 %.

### Phase 3 — Proactive notifications

**Goal:** rules engine fires pings into the right channel without
being asked.

- Rules config schema + 5 starter rules (regression on main,
  deprecated API in PR, KIR cleanup overdue, new bug in owned area,
  PR awaiting review > N days).
- Suppression windows + per-channel opt-out.

**Acceptance:**

- All five rules in production.
- Zero "noisy/wrong-channel" complaints in a one-week soak.

### Phase 4 — Investigation + work queue

**Goal:** accept assigned work (bug in ADO, ask in chat) with
acknowledgement, ETA, progress, and result.

- Work queue with lifecycle states (intake → ack → plan → progress
  → result → wrap-up).
- Visible queue surface (Teams Card or dashboard — choose).
- For ADO bugs: investigates, posts root-cause hypothesis with code
  and prior-fix citations.
- Daily/weekly status post.

**Acceptance:**

- Bot completes ≥ 10 assigned investigations in a sprint.
- Mean acknowledgement latency < 2 minutes from intake.
- Daily summary post in target channel for two weeks.

### Phase 5 — Mail + Agency surfaces

**Goal:** participate in Outlook threads and run as an Agency agent
— same brain, same memory.

- Service mailbox provisioned; Graph mail subscription + reply.
- Agency agent registered.
- **RAI review** required before this phase ships.

**Acceptance:**

- Added to ≥ 5 real mail threads with positive feedback.
- Same identity / memory / behaviour as Teams.
- RAI sign-off recorded.

### Phase 6 — PR drafting + QA assist _(stretch)_

**Goal:** for well-scoped issues, open a draft fix PR. Scaffold
tests. Flag coverage gaps.

- Reuse Copilot Coding Agent for the authoring step.
- Always **draft** PRs — never auto-merge.
- Coverage analysis on the touched files.
- **RAI review** required.

**Acceptance:**

- ≥ 5 draft PRs landed (merged by a human after review) in a
  sprint.
- Zero auto-merges, zero auto-closes.

## Risks

- **Identity sprawl** — surface-specific identities that drift from
  one persona. Mitigation: single canonical persona, federated
  identities, central router.
- **Memory rot** — incremental layer goes stale or contradictory to
  static KB. Mitigation: scheduled re-ingestion, conflict-resolution
  pass.
- **Throttling** — Graph + ADO have aggressive limits; persistent
  ingestion must use deltas + back-off.
- **RAI gates** — phases 5 and 6 will not ship without RAI sign-off;
  plan the work, don't surprise the reviewers.
- **Confused trust** — users assume the bot is authoritative. Always
  cite, always say "I don't know" rather than guessing.
- **Phase-1 stalling** — v1 is too small to feel different from
  existing CLI agents. Mitigation: ship phases 1 + 2 together if
  bandwidth allows.

## Dependencies

- winui-expert (KB + retrieval) — exists.
- WinUI Code Review — exists.
- winui-regression-reviewer — exists.
- Bot Framework provisioning path (internal).
- GitHub App / ADO service account provisioning path (internal).
- Internal Azure OpenAI endpoint.
- Graph API access for the bot's service mailbox (phase 5).
- Agency integration spec (phase 5).
- Copilot Coding Agent integration (phase 6).

## Known issues

(none yet — no code)
