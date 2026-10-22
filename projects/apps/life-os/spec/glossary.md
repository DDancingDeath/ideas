# Glossary and vocabulary — Life OS

One name per concept. A second name for any of these is a spec bug. Finance
terms (inventory item, scenario, goal, §6.3 assessment states) are defined in
the [personal-ai-cfo spec](../../personal-ai-cfo/spec/README.md#glossary-and-vocabulary).

## People and data

| Term | Definition |
| --- | --- |
| **Owner** | The one person who signs in and owns all data. |
| **Household profile** | The people in the owner's household. Per person: `person_id`, label, relation (`self`, `spouse`, `child`, `parent`, `sibling`, `other`), birth date with `birth_date_precision` (`day`, `month`, `year`) or an age on a date, sex, `household_member`, `financially_dependent`, `co_owner`. Nothing is inferred. |
| **Dependent** | A person with `financially_dependent: true`. Never inferred from relation. |
| **Data document** | One stored JSON document of the owner's data (e.g. the household profile, a reviewed lab report). Addressed by a relative path. |
| **Source document** | A file the owner already has (PDF, image, spreadsheet, email) that data is read from. Never modified by the system. |
| **Version** | SHA-256 of a data document's bytes; `absent` before it exists. The one versioning scheme for saves, backups, bundles and sync. |
| **Bundle** | One file holding every data document with its SHA-256, for moving data between modes or devices. |
| **Sample** | Packaged synthetic data (role profiles, stages, prompts, rules) used only until the owner saves their own, and labelled *sample* wherever it appears. |
| **Illustrative** | An owner-side assumption document marked as not yet real; labelled *illustrative* wherever it is used. |
| **Today** | The local date defined in [cross-cutting.md § Dates](cross-cutting.md#dates-and-time-zone). |

## Hub and boxes

| Term | Definition |
| --- | --- |
| **Box** | One life area implementing the [box contract](box-contract.md). Status `live` or `coming_soon`. |
| **Glance** | A box's tile on Home. |
| **Fact** | A statement backed by a calculation output, with provenance ([box-contract.md § Fact](box-contract.md#fact)). |
| **Provenance** | Where a value came from: for a fact, the box, calculation, `engine_version`, `inputs_sha256` and the source document (and page) when there is one; for an observed value, its source and `observed_at`. |
| **Life graph** | The connected set of entities and facts with provenance edges ([life-graph.md](life-graph.md)). |
| **Tool** | A deterministic calculation a box exposes to Ask. |
| **Tool status** | `ok`, `needs_input`, `invalid`, `not_configured` ([box-contract.md § Tool result](box-contract.md#tool-result)). |
| **Engine version** | Version string of a calculation; changes whenever any output for the same input can change. |
| **`inputs_sha256`** | SHA-256 of the canonical JSON of a calculation's inputs (UTF-8, sorted keys, no whitespace, decimals as strings). |
| **Needs** | The missing inputs a tool reports: exact input paths plus a form spec for each. |
| **Missing item** | A data gap that affects a calculation, listed by a box's `missing`. |
| **Recommendation** | An undated, ranked suggestion from a box's calculations. |
| **Reminder** | A dated item in the cross-box reminders feed (an owner reminder or a box's due item). |
| **Nudge** | A reminder or recommendation emitted without being asked ([nudges.md](nudges.md)). "Nudge" names the origin; it is always delivered as a reminder or a recommendation. |
| **Urgency** | `critical` > `high` > `medium` > `low` > `unrated`. The single severity scale. |
| **Category** | Ranking category of a recommendation: `lab_critical` > `protection` > `liquidity` > `health_followup` > `debt` > `data` > `optimisation` > `growth`. |
| **Draft** | Values read from a source document or message, awaiting review. A draft never changes data until applied. |
| **Review queue** | A box's list of drafts. |
| **Apply** | The owner's confirmation that copies a draft's chosen rows into data documents through the normal validated, versioned save. |
| **Auto-apply** | A per-source or per-rule owner opt-in that applies matching drafts without a per-draft confirmation. Off until the owner turns it on. |
| **Observation** | A value with its `source` and `observed_at`, read from a source document, message or price file. |
| **Stale** | A value or price whose age exceeds the owner's limit for it. |

## Ask

| Term | Definition |
| --- | --- |
| **Intent** | A class of question with a fixed tool plan across boxes. |
| **Entity** | A value parsed from the question (amount, duration, timing, person, age, percentage, health test, role, item). |
| **Aspect** | One box's part in an answer: `used`, `missing_data` or `not_relevant`. |
| **Thread** | A sequence of Ask questions sharing context. |
| **Life brief** | *Your week*: the cross-box summary on Home and for "what should I focus on" questions ([ask.md § Life brief](ask.md#life-brief)). |
| **Refusal** | An answer to an out-of-scope question: what Ask cannot do, then what it can do from the owner's data. |

## Security and sync

| Term | Definition |
| --- | --- |
| **Session** | A signed-in device on the home server, with an expiry and a scope. |
| **Session scope** | `app` (the app's cookie) or `sync` (relay calls only). A sync session is never accepted as an app session. |
| **Vault** | The owner's encryption setup: data key, keyring, passphrase and recovery key. |
| **Data key** | The random key that encrypts everything leaving a device. Exists only in memory while unlocked. |
| **Passphrase** | The owner's secret that unlocks the vault. Separate from the sign-in password. |
| **Recovery key** | A random key shown once, which also unlocks the vault. |
| **Keyring** | The vault's public record: KDF parameters and the data key wrapped by the passphrase and by the recovery key. Contains no secret. |
| **Relay** | A store of opaque encrypted blobs used for sync. Sees ciphertext only. |
| **Conflict copy** | The losing side of a concurrent edit, kept as its own data document until the owner resolves it. |
| **Identity fact** | A government or account identifier (PAN, Aadhaar, passport number…) held in the [identity vault](identity-vault.md). |
| **Reveal** | Showing an identity fact unmasked, after re-authentication. |

## Conversations

| Term | Definition |
| --- | --- |
| **Conversation source** | One imported chat export, the phone's message/call metadata, or the owner's voice-notes folder, each with its own retention and AI consent. |
| **Contact** | A person seen in a conversation source; linked to a household-profile person only when the owner confirms. |
| **Commitment** | A promise found in a message ("I'll send it tomorrow"), proposed as a draft reminder. |
| **Work bridge entry** | A short note the owner writes in their own words about a work commitment that affects personal life. Never content copied from a work system. |

## Tax

| Term | Definition |
| --- | --- |
| **Assessment year (AY)** | The Indian tax year in which a financial year's income is assessed; AY *YYYY–YY* covers FY *(YYYY−1)–(YYYY−2000)*. |
| **Tax rule set** | A versioned data file of official rules for one AY with source links and effective dates ([boxes/finance.md § Tax report](boxes/finance.md#tax-report)). |
| **Verified rule set** | A tax rule set the owner has marked as checked against its official sources. |
