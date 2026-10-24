# Context retrieval policy — Life OS

An app does not read the owner's whole life. It asks the intelligence layer
for context with a purpose; the app's **context policy** decides what it
receives, at which level of detail, and every grant is recorded. Invariant A5
of [architecture.md](architecture.md#invariants). Terms:
[glossary.md](glossary.md).

## Policy document

One policy per app id and one for the coordinator (`coordinator`). Stored as
the owner's configuration `context.policies.<appId>`
([configuration.md](configuration.md#apps-sources-and-context)).

| Field | Type | Rule |
| --- | --- | --- |
| `app_id` | app id or `coordinator` | One policy per id |
| `purposes[]` | strings | Every request names one purpose from this list; a request with another purpose is denied |
| `own_domain` | box id + level | The app's own box; level `detail` |
| `grants[]` | `{domain, entity_types[], level, purpose, sensitivity_ceiling}` | The only cross-domain reads allowed; anything not granted is denied |
| `min_review_state` | review state | The least-reviewed state treated as fact; see [Retrieval rules](#retrieval-rules) |
| `max_age_days` | map entity type → days | Older facts are returned labelled *stale* |
| `clarify_when[]` | subset of `missing`, `conflict`, `stale` | The answer asks the owner instead of assuming in these cases |

The version of a policy is the SHA-256 of its document, as for every data
document.

## Levels

| Level | The app receives | Example (Finance asking Health) |
| --- | --- | --- |
| `none` | Nothing | — |
| `existence` | That a fact of the granted type exists, with its date when it has one | "Possible significant upcoming medical expense" |
| `summary` | Labels, counts, dates and statuses; no values from domain records | "2 results outside the lab's range in the last report" |
| `detail` | Values with provenance | The result values and their report and page |

## Sensitivity classes

| Class | Covers |
| --- | --- |
| `normal` | Organisations, public prices, document types |
| `personal` | People, household, accounts, assets, liabilities, policies, goals, events, commitments, note metadata, career facts |
| `sensitive` | Health records, identity facts, journal content, message content |

A grant's `sensitivity_ceiling` is the most sensitive class it may return;
facts above it are withheld. Identity values are never returned by context
retrieval at any level — only masked references, and only through the
[identity vault](identity-vault.md)'s Reveal.

## Retrieval rules

| # | Rule |
| --- | --- |
| C1 | Default deny: an app receives its own domain at `detail` and nothing from another domain unless a grant lists that domain, entity type and purpose. |
| C2 | Minimum necessary: the lowest level that answers the purpose is returned, never above the grant's level. |
| C3 | Relevance first, then reliability (review state: `owner_entered` and `verified` before `draft`), then currency (`observed_at`, newest first). |
| C4 | `draft` facts below `min_review_state` and every `ai_interpretation` are returned only labelled as such, never as facts and never as calculation inputs. |
| C5 | Stale, conflicting or missing context is labelled; in the cases listed in `clarify_when` the answer is `needs_input`, never a guess. |
| C6 | Every assumption an answer relies on is listed in the answer. |
| C7 | Every grant is appended to the **context audit log**: `{at, app_id, purpose, question_id?, fact ids, level, policy_version}`. The log never holds a fact's value. The owner can read it per app ("what each app saw"). |
| C8 | The audit log is a data document: encrypted with the vault, synced end-to-end encrypted, never sent to an AI provider. |
| C9 | Ask inside an app uses that app's policy; Ask from the coordinator uses the `coordinator` policy. An answer lists which domains it used and at which level. |
| C10 | Context sent to an AI provider is additionally limited by `ask.share.<boxId>` and `ask.share.questionText` ([ask.md § AI provider](ask.md#ai-provider)). |

## Default grants

Used, labelled *sample*, until the owner saves a policy of their own.

| `app_id` | Domain | Entity types | Level | Purpose | Ceiling |
| --- | --- | --- | --- | --- | --- |
| every app | `me` | person, household | `summary` | addressing people | `personal` |
| `finance` | `health` | event | `existence` | affordability, protection review | `sensitive` |
| `finance` | `family` | person, event, goal | `summary` | goal planning | `personal` |
| `finance` | `career` | organisation, event | `summary` | income stability | `personal` |
| `health` | `family` | person, event | `summary` | retests and check-ups for household members | `personal` |
| `family` | `finance` | goal | `summary` | education and family goals | `personal` |
| `family` | `health` | event | `existence` | vaccinations and check-ups due | `sensitive` |
| `career` | `finance` | goal | `existence` | learning budget | `personal` |
| `notes` | every domain | event, commitment | `summary` | reminders and links | `personal` |
| `reflection` | — | — | — | — | — |
| `coordinator` | every domain | every type | `summary` (`detail` for the domain a question names) | today, life brief, cross-domain questions | `sensitive` |

The open question on these defaults is in
[README.md § Open questions](README.md#open-questions).
