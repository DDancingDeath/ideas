# Spec — inbox-triage

> **Placeholder.** Full spec deferred until the open decisions in
> [`../README.md`](../README.md) (surface, runtime, LLM endpoint) are
> resolved.

## What the spec will need to cover (when written)

1. **Source connectors** — exact Graph endpoints, ADO REST endpoints,
   delta-token handling, throttling backoff strategy.
2. **Auth flow** — MSAL Public Client setup, AAD app registration scopes
   (`Mail.Read`, `Chat.Read`, `ChannelMessage.Read.All`, ADO `vso.work`,
   `vso.code`), token cache in Windows Credential Manager.
3. **Inbox entry schema** — the unified shape; what fields are required
   vs optional; how dedupe across sources works (e.g. a PR linked from
   a mail must collapse to one entry).
4. **Ranking model** — feature list (age, my_role, sender importance,
   keywords, due dates), LLM prompt for urgency score, fallback when
   LLM is unavailable.
5. **Draft generation** — per-source prompts (mail reply, PR comment,
   bug triage note), tone settings, length cap, "no draft" classifier
   for items where a draft makes no sense (FYI mails, etc.).
6. **Surface** — the chosen UI (Teams card / CLI / Electron) with
   wireframes in `../assets/`.
7. **Scheduler** — exact cadence, work-hours definition, focus-time
   integration, OOF awareness, manual trigger.
8. **Telemetry** — local-only metrics (precision/recall of ranking,
   draft acceptance rate) so we can tune.
9. **Privacy + compliance** — explicit confirmation that no corp data
   leaves the device; data retention; per-source opt-out.

## Reference (internal Microsoft)

- Graph API docs: https://learn.microsoft.com/graph/
- ADO REST docs: https://learn.microsoft.com/rest/api/azure/devops/
- Azure OpenAI internal endpoints: search internal docs.

## Out of scope (deliberately)

- Multi-user / multi-tenant.
- Auto-sending / auto-approving anything.
- Voice — see `notes-reminders`.
