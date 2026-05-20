# Plan — inbox-triage

## Status

**Early-stage idea capture.** No code, no AAD app registration, no
chosen surface. The idea is captured; design decisions are pending.

## Next steps (in order)

1. **Try Clawpilot first.** Request access at `aka.ms/clawpilot-request`.
   Configure Heartbeat (Teams + Outlook polling) + a "morning triage"
   Workflow + a Skill that encodes the ranking logic this project
   describes. If that covers it, this project ships as a Clawpilot
   config + a Skill prompt — not a from-scratch agent. Decide *now*
   whether the remaining gap justifies new code.
2. **Audit other internal tools.** Before writing anything, also search:
   - Copilot for M365 Priority Inbox + Chat
   - MyHub
   - Internal hackathon repos via internal GitHub search for
     "inbox triage", "PR digest", "ADO bug digest"
   - Internal MCP server registry
   Goal: confirm this isn't ~70 % built already.
3. **Resolve open decisions** (see `../README.md` → "Open decisions").
4. **AAD app registration** in the personal-use AAD app pattern
   internal docs describe. Get Graph + ADO scopes approved.
5. **Walking skeleton:** pull *only* PRs assigned to me + unread Teams
   @mentions into a local SQLite. No LLM yet. CLI table output.
6. **Add the LLM triage pass** for ranking + a one-line "why this
   matters" per item. Still no draft generation.
7. **Add draft generation** for PR review comments (lowest-risk
   draft — going into a comment box, not a sent mail).
8. **Add mail + bug sources.**
9. **Pick and build the surface** (Teams card / CLI / Electron).
10. **Tune.** Iterate on prompt + features based on observed ranking
    quality.

## Risks

- **Conditional Access** may block tokens from anything not delivered
  by an approved internal channel. Mitigate by piloting on the work
  laptop with a personal-use AAD app, not a third-party-looking one.
- **Graph throttling** with naive polling. Delta queries from day 1.
- **LLM drift** — ranking quality may shift between Azure OpenAI model
  versions. Pin the deployment and review on every model upgrade.
- **Scope creep** — calendar / docs / SharePoint will all feel
  tempting after MVP. Hold the line until ranking + drafts work well
  on the four sources.

## Known issues

(none yet — no code)
