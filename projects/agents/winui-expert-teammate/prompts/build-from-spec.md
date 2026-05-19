# Build prompt — winui-expert-teammate

> This is the onboarding brief for the intern (or coding agent) who
> picks this project up. Read it in full, then `../README.md`,
> `../idea.md`, `../spec/README.md`, and `../plan/README.md` in that
> order before writing a single line of code.

---

## Mission

Build the **delivery layer** ("body + heartbeat") for the WinUI Expert
teammate. The brain — `winui-expert`, `WinUI Code Review`,
`winui-regression-reviewer` — is already in production. You are NOT
rewriting it. You are giving it identity, presence, memory, and
proactive behaviour across every surface the team already uses (Teams,
Outlook, GitHub/ADO, Agency).

## Non-negotiables

1. **One persona, many surfaces.** Same memory, same voice everywhere.
2. **Citations on every claim.** If the brain can't cite, the bot
   says "I don't know" instead.
3. **Internal LLM endpoint only.** Corp code, bug content, mail
   content never leave the internal Azure OpenAI boundary.
4. **No auto-merge, no auto-close, no silent action.** Every shipped
   change is human-gated until phase 6 — and even then PRs are
   drafts.
5. **Audit every outbound message** (prompt, retrieval set, response,
   recipient).
6. **Respect throttling** — Graph and ADO REST. Use deltas for
   ingestion.
7. **Responsible-AI review is gating** for phases 5 (mail) and 6
   (authoring). Don't ship without sign-off.

## How to start

1. Stand up the **Bot Framework Teams app** with the WinUIBot persona
   (name TBD with the sponsor). One canonical identity.
2. Wire **Q&A only** in phase 1 — `winui-expert` does the work; you
   just call it and surface the citations.
3. Capture every Q&A turn into the **persistent-memory incremental
   layer**.
4. Demo to 5 WinUI engineers. Get thumbs up/down. Tune.
5. Move to phase 2 (PR review) only when phase 1 is loved.

## Architecture rules

- Surface adapters normalise into a **single canonical work-intake
  event**. The router/work-queue is surface-agnostic.
- The **persistent-memory layer** reuses the winui-expert KB
  pipeline as the static base + an incremental layer for new
  conversations/reviews/commits.
- The **rules engine** is config-driven (YAML). New rules ship as
  config, not code.
- The **work queue** has a strict lifecycle: intake → ack → plan →
  progress → result → wrap-up. Every accepted task transitions
  through these states.

## Do NOT

- Rewrite winui-expert, WinUI Code Review, or winui-regression-
  reviewer. Call them as services.
- Build a public-facing bot. This is internal-only.
- Push corp content to public LLM endpoints.
- Ship phases 5 (mail) or 6 (authoring) without RAI sign-off.
- Auto-merge, auto-close, or silently take action.
- Become a general-purpose Microsoft bot — this is WinUI-team-scoped.

## When you're stuck

- Memory model unclear → talk to the winui-expert KB owners.
- Identity provisioning unclear → talk to the internal Bot Framework
  team.
- ADO/Graph throttling biting → use delta queries + back-off; never
  poll-spam.
- Trust / RAI unclear → escalate early; do not proceed past the gate.

## Definition of "done" per phase

See `../plan/README.md` — every phase has explicit acceptance
criteria. A phase isn't done until those are satisfied with real
users, not test users.
