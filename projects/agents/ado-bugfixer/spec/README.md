# Spec — ado-bugfixer

> **Placeholder.** Spec deferred until the area-scope decision and the
> Copilot-Coding-Agent reuse decision are made.

## What the spec will need to cover

1. **ADO connectors** — bug query (WIQL), comment read/post, attachment
   download, linked PR read.
2. **Area allow-list** — config file with allowed area paths +
   sensitivity tags to skip. Enforced server-side, not just in UI.
3. **Classifier** — LLM prompt + heuristics for {dupe, user error,
   real bug, won't fix}. Dupe-detection precision is the priority
   metric.
4. **Investigation strategy** — for "real bug" items: find related
   code, prior fixes, prior bugs in the same area; produce either a
   draft PR or a root-cause note.
5. **PR draft path** — either invoke Copilot Coding Agent or do the
   authoring directly. Must run expert-review skills (memory-safety,
   concurrency, error-handling, performance, etc.) before surfacing
   the draft to me.
6. **Comment-on-bug policy** — voice, length, frequency, "do not
   spam the same bug" guardrails.
7. **Review UX** — CLI / TUI / Teams card surface that lets me approve,
   edit, or reject each suggested action.
8. **Telemetry** — local-only metrics: classification accuracy on my
   manual overrides, PR draft acceptance rate, dupe-detection
   precision.
9. **Audit log** — every read, every action, every skip — local file
   for compliance.

## Out of scope

- Auto-merge, auto-close.
- Org-wide deployment.
- Anonymous bot persona (must run under my identity in MVP).
