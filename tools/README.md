# tools/

PowerShell scripts that automate the three repeatable workflows:

| Workflow         | Script             | Output                                                       |
| ---------------- | ------------------ | ------------------------------------------------------------ |
| Add an **idea**  | `add-idea.ps1`     | New folder under `projects/<kind>/<slug>/` in **this** repo, committed + pushed |
| Add a **skill**  | `add-skill.ps1`    | New GitHub repo (`DDancingDeath/skill-<slug>`) OR PR to the configured ADO skills repo |
| Add an **agent** | `add-agent.ps1`    | New GitHub repo (`DDancingDeath/agent-<slug>`) OR PR to the configured ADO agents repo |

Shared config: [`config.json`](./config.json). Edit the `TODO-...` placeholders
in the `ado.*` blocks **before** using `-Target ado` for the first time.

## Quick start

```powershell
# Add an idea (default kind = agents)
.\tools\add-idea.ps1 -Slug shop-floor-clock-in -Kind apps `
  -Title "Shop-floor clock-in" `
  -Pitch "A frictionless way for retail staff to clock in via a tablet."

# Add a personal skill, lives in a new private GitHub repo
.\tools\add-skill.ps1 -Slug ado-bug-triage -Target github `
  -Title "ADO bug triage" `
  -Description "Walks an ADO query and proposes dupe/triage/fix actions."

# Add an internal skill via a PR to the configured ADO repo
.\tools\add-skill.ps1 -Slug winui-perf-review -Target ado

# Add an agent
.\tools\add-agent.ps1 -Slug morning-brief -Target github
```

All scripts:

- Validate the slug (`^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$`).
- Are idempotent against existing target directories - fail fast if the
  destination already exists.
- Use the commit identity from `config.json -> git` and append the
  `Co-authored-by: Copilot` trailer.
- Support `-NoPush` so you can review before pushing / opening a PR.

## Prerequisites

- **PowerShell 5.1+** (Windows) or PowerShell 7+.
- **`gh` CLI** authenticated as `DDancingDeath` (`gh auth status`).
- **`git`** on PATH.
- For `-Target ado`: **`az` CLI** signed in (`az login`) with the
  `azure-devops` extension. The script installs the extension
  automatically on first ADO use.

## Customising the scaffold

- **Idea template** lives in [`../_templates/`](../_templates/). Five
  files (`project-readme.md`, `idea.md`, `spec.md`, `plan.md`,
  `build-prompt.md`).
- **Skill template** in [`../_templates/skill/`](../_templates/skill/).
- **Agent template** in [`../_templates/agent/`](../_templates/agent/).

Token substitution syntax in templates: `{{SLUG}}`, `{{TITLE}}`,
`{{DESCRIPTION}}`, `{{PITCH}}`, `{{KIND}}`, `{{DATE}}`, `{{TARGET}}`.

## When the user says "add an X"

Agents reading this repo: invoke the matching script directly. Do not
duplicate the scaffolding inline. The script enforces the convention.

See [`../CONVENTIONS.md`](../CONVENTIONS.md) for the full handoff
contract.
