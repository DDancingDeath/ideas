# Conventions

This file defines **the three repeatable workflows** for this knowledge
base. Each has a single canonical script in `tools/` — agents and
humans should both use it instead of redoing the work by hand.

| Workflow         | What it produces                                                             | Script                                |
| ---------------- | ---------------------------------------------------------------------------- | ------------------------------------- |
| Add an **idea**  | A new folder under `projects/<kind>/<slug>/` in **this** repo                | [`tools/add-idea.ps1`](./tools/add-idea.ps1)  |
| Add a **skill**  | A new GitHub repo (`DDancingDeath/skill-<slug>`) **or** a PR to ADO          | [`tools/add-skill.ps1`](./tools/add-skill.ps1) |
| Add an **agent** | A new GitHub repo (`DDancingDeath/agent-<slug>`) **or** a PR to ADO          | [`tools/add-agent.ps1`](./tools/add-agent.ps1) |

Targets are defined once in [`tools/config.json`](./tools/config.json):

- **GitHub** owner: `DDancingDeath`
- **ADO** organization / project: `os.developers` / `hik`
  - The exact ADO repo names are placeholders (`TODO-…`) — edit
    `tools/config.json` before the first `-Target ado` invocation.

---

## 1. Add an idea

An **idea** is a spec/plan folder living in this repo. Nothing gets
built or deployed from here — it's the input to a build job that
happens elsewhere.

```powershell
.\tools\add-idea.ps1 -Slug <slug> -Kind <apps|agents> -Title "<title>" `
                     -Pitch "<one-paragraph pitch>"
```

Output:

```
projects/<kind>/<slug>/
├── README.md      ← narrative entry point (template-driven)
├── idea.md        ← problem, users, success
├── spec/README.md
├── plan/README.md
├── prompts/build-from-spec.md
└── assets/.gitkeep
```

Then commits and pushes to `DDancingDeath/ideas` on `main`. The script
prints a TODO reminder to update the top-level `README.md` projects
table.

The template files in [`_templates/`](./_templates/) are the source of
truth for the narrative-README convention — see
[`AGENTS.md`](./AGENTS.md) for the project-folder reading order.

---

## 2. Add a skill

A **skill** is a Copilot CLI / agent-runtime plugin (a folder with a
`SKILL.md` manifest + supporting files). It lives in **its own repo**,
not in this knowledge base.

```powershell
# Public/personal - creates DDancingDeath/skill-<slug> (private repo by default)
.\tools\add-skill.ps1 -Slug <slug> -Target github -Title "<title>" -Description "<desc>"

# Internal Microsoft - PR to microsoft/OS.Developer/Hik under skills/<domain>/<slug>/
.\tools\add-skill.ps1 -Slug <slug> -Target ado -Domain <domain> -Title "<title>" -Description "<desc>"
```

Domains in the Hik repo today: `os`, `ado`, `winui`, `triage`, `docs`,
`meta`. Default if `-Domain` omitted: `meta`. New domains are allowed -
the script warns and reminds you to register the new domain in
`skills/README.md`.

Scaffold content comes from [`_templates/skill/`](./_templates/skill/).
The template uses the front-matter shape Hik expects:

```markdown
---
name: <skill-name>     # MUST equal the directory name
description: <1-3 sentences, lead with the verb for action skills>
---
```

### GitHub target

1. Creates `DDancingDeath/skill-<slug>` (private; topic
   `copilot-cli-skill`).
2. Clones to `D:\work\skill-<slug>`.
3. Scaffolds the skill files with token substitution.
4. Initial commit + push.

### ADO target (Hik repo)

1. Clones (or fast-forwards) `https://dev.azure.com/microsoft/OS.Developer/_git/Hik`
   into `D:\work\Hik`.
2. Creates branch `user/<alias>/skill-<slug>`.
3. Scaffolds under `skills/<domain>/<slug>/SKILL.md` (+ README.md).
4. Commits, pushes, opens a PR via `az repos pr create`.
5. **Reminds you to update `skills/README.md` catalog table** before
   merge - this is a Hik repo quality bar and the script does not
   auto-edit the catalog (the table format is opinionated).

---

## 3. Add an agent

An **agent** is a sub-agent configuration (system prompt + tool list +
model selection). Same shape and rules as a skill, but uses the
`agents.*` block in `config.json` and the
[`_templates/agent/`](./_templates/agent/) directory.

```powershell
.\tools\add-agent.ps1 -Slug <slug> -Target <github|ado> [-Domain <domain>]
```

For ADO target: lands at `agents/<domain>/<slug>/AGENT.md` in the Hik
repo. Domains today: `os`, `ado`, `winui`, `triage`, `meta`. Default
domain: `winui`. AGENT.md template includes the
`default-model: claude-opus-4.7-1m-internal`, `default-agent-type`, and
`default-mode` front-matter fields the Hik orchestrators expect.

### Targets at a glance

| Target | Where it lands | Repo URL |
| --- | --- | --- |
| `github` (skill) | New private repo `DDancingDeath/skill-<slug>` | `https://github.com/DDancingDeath/skill-<slug>` |
| `github` (agent) | New private repo `DDancingDeath/agent-<slug>` | `https://github.com/DDancingDeath/agent-<slug>` |
| `ado` (skill) | `skills/<domain>/<slug>/` in Hik | `https://dev.azure.com/microsoft/OS.Developer/_git/Hik` |
| `ado` (agent) | `agents/<domain>/<slug>/` in Hik | `https://dev.azure.com/microsoft/OS.Developer/_git/Hik` |

---

## Why scripts and not "just do it by hand"

- **Deterministic.** Every idea/skill/agent ships with the same files
  in the same shape — reviewers and downstream agents know what to
  expect.
- **Idempotent.** Re-running with the same slug fails fast instead of
  half-overwriting.
- **Single source of truth for the format.** The templates in
  `_templates/` are the convention; the scripts enforce it.
- **Agent-friendly.** When a user says *"add an idea X"* or *"add a
  skill Y"*, an agent reading this repo should invoke the matching
  script rather than re-inventing the scaffold each time.

---

## Editing the conventions

If the file shape changes (new file added to every project, template
field renamed, ADO repo name finalised):

1. Edit the relevant file in `_templates/` or `tools/config.json`.
2. Update [`tools/README.md`](./tools/README.md) usage examples if
   needed.
3. Backfill existing projects only if the change is mandatory; otherwise
   leave them and add to the "Recent changes" list in the affected
   README.
