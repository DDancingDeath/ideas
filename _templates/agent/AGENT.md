---
name: {{SLUG}}
description: {{DESCRIPTION}}
default-model: claude-opus-4.7-1m-internal
default-agent-type: general-purpose
default-mode: background
---

# {{TITLE}}

## When to dispatch

One paragraph describing when an orchestrator should hand work to this
agent. What makes a session "ripe" for it?

## Inputs

* `input-1` - description
* `input-2` - description

## System prompt (paste into `task(prompt=...)`)

```text
You are <role>. Your job is to <task>.

# Constraints
- ...

# Output
- ...
```

## Example invocation

```python
task(
  agent_type="general-purpose",
  model="claude-opus-4.7-1m-internal",
  mode="background",
  name="example-{{SLUG}}",
  description="Example dispatch of {{SLUG}}",
  prompt=<contents of the System prompt section above, with inputs substituted>,
)
```

## Known limitations

* ...

---

> Authoring notes (delete before PR):
> - `name` in front-matter MUST equal the parent directory name (`{{SLUG}}`).
> - Front-matter `default-*` fields are conventions used by the Hik repo
>   orchestrators - keep them unless you have a specific reason to override.
> - Update `agents/README.md` (catalog table) when adding this agent via PR.
