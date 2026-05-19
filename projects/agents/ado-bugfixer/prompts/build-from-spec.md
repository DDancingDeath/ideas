# Build prompt — ado-bugfixer

> ⚠️ **Do not hand this to an agent yet.** Resolve the open decisions
> in `../README.md` first (area scope; reuse of Copilot Coding Agent;
> comment voice; cadence; tribal-knowledge layer).

---

You are building **ado-bugfixer**, a personal-scope agentic
bot-fixer for ADO. Read `../README.md` and `../idea.md` end-to-end
before doing anything. The agent must:

1. Run only against the **area allow-list** the user configures.
2. Default to **read-only**; PR drafting and bug-commenting are
   per-action consent.
3. **Never auto-merge, never auto-close.**
4. Use the internal Azure OpenAI endpoint. Corp code stays in corp
   services.
5. Run the existing expert-review skills (memory-safety, concurrency,
   error-handling, performance, etc.) on every draft PR before
   surfacing it.

Generate code in a separate directory or repo. Do not modify this
`projects/agents/ado-bugfixer/` folder.

Quality bar:

- Dupe-detection precision ≥ 90 % on manual-labelled holdouts.
- All draft PRs pass internal lint + at least one expert-review skill
  scan with zero high-severity findings before they reach the user's
  review queue.
- All actions written to a local audit log.

Do NOT:

- Run on areas not on the allow-list.
- Auto-merge or auto-close.
- Spam the same bug with multiple comments.
- Expose corp bug content to any non-internal LLM endpoint.
