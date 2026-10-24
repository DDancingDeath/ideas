# Box contract — Life OS

Every box provides these members (data fields are snake_case; configuration keys are camelCase). Home, the reminders feed, nudges and Ask use
nothing else. Terms are defined in [glossary.md](glossary.md).

## Members

| Member | Required | Returns | Rules |
| --- | --- | --- | --- |
| `manifest` | yes | `{id, name, icon, tagline, status, kind, order, nav[]}` | `status` ∈ {`live`, `coming_soon`}. A `coming_soon` box shows on Home but contributes no facts, tools, recommendations or reminders. `kind` ∈ {`app`, `source`, `me`} ([apps-and-modes.md](apps-and-modes.md)). |
| `shared` | yes | `{reads[], writes[]}` shared entity types | The only shared facts the box reads or writes, always through the Knowledge Core API ([architecture.md](architecture.md#invariants), A1–A2). |
| `glance` | yes | `{headline {label, value, unit, format}, chip {label, tone}, lines[], missing_count, state, action, source}` | Built only from calculation outputs. `lines` ≤ 2. `format` ∈ {`inr`, `count`, `years`, `date`}. With no data: the box's welcome state and first action, never a zero. |
| `facts` | yes | list of [facts](#fact) | Every fact traceable to a calculation. |
| `tools` | yes | map name → tool | Each tool: JSON Schema of its inputs, a description, and the data-document paths it reads (the overridable inputs). |
| `recommendations` | yes | `[{id, domain, title, why, urgency, category, evidence, next_step, source_calc, rank_in_module}]` | `urgency` and `category` use the [glossary](glossary.md#hub-and-boxes) scales. A box never invents urgency: it maps only from its own engine's rules. |
| `missing` | yes | `[{id, domain, topic, impact, blocking, href}]` | One entry per data gap that affects a calculation, including every `required — no default` setting not yet set. |
| `reminders` | optional | `[{id, box, title, due, time?, kind, href, source_ref}]` | Dated due items for the cross-box feed ([nudges.md](nudges.md)). Due dates come only from the owner's data. |
| `review_queue` | optional | drafts awaiting review | For boxes that receive drafts from source documents, messages or the Documents box. |

## Fact

`{fact_id, domain, statement, value, unit, date, source, status, tags}` where
`source` = `{box, calculation, engine_version, inputs_sha256, ref, document?}`
and `document` = `{document_id, page?}` when the fact was read from a source
document. `fact_id` is stable for the same subject (e.g. `family.age.<person_id>`).

## Tool result

Running a tool with the stored data documents plus optional per-answer
overrides returns `{tool, status, result, inputs_sha256, engine_version, needs[], notes[]}`.

| `status` | Meaning | `result` | `needs` |
| --- | --- | --- | --- |
| `ok` | Calculated | present | empty |
| `needs_input` | A required input is missing | absent | exact input paths + a form spec for each |
| `invalid` | An input failed its schema | absent | empty; `notes` names every failing path |
| `not_configured` | The box has no data documents yet | absent | empty |

Overrides apply to that one run only and are never saved.

## Calculation envelope

Every engine calculation returns `{engine, engine_version, calculation,
conventions, inputs, inputs_sha256, outputs, warnings}`. `inputs` is the
canonical echo of the validated input; `inputs` + `engine_version` reproduce
the result. Validation reports **every** missing or invalid field at once with
its path; unknown fields are rejected; binary floating-point numbers are
rejected (decimals travel as strings).

## Priority order

*Top priorities across your life*, the life brief and Ask `suggestions` sort
by, in order:

1. `urgency` (glossary scale)
2. `category` (glossary scale)
3. box order `ranking.domainOrder`
4. the box's own `rank_in_module`

The same recommendation never appears twice on one screen.

## Box UI rules

| Rule |
| --- |
| A box's screens show engine strings and numbers only; no money, medical or date maths in the UI. |
| Every box has the same header (icon, title, tagline, section tabs), the same empty states and the same confirm dialog. |
| No inline styles or scripts, no external resources. |
| Every editable data document is saved through the [versioned save](cross-cutting.md#versioned-saves-and-conflicts). |
