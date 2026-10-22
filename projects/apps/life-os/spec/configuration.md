# Constants and configuration — Life OS (single home)

Every threshold, limit, tunable, crypto parameter and owner setting of the hub
and its non-finance boxes is defined **here and only here**. Other files cite
the key. Finance keys (`finance.*`, `prices.*`) live in the
[personal-ai-cfo registry](../../personal-ai-cfo/spec/README.md#constants-and-configuration-single-home).
Field-level bounds of data documents (lengths, enums) live in each box spec's
data-model table.

`required — no default` means: the system never assumes a value; until the
owner sets it, every calculation that needs it returns `needs_input` and the
box lists it under `missing` ([cross-cutting.md § No defaults](cross-cutting.md#no-defaults-missing-is-never-zero)).
`build` in *Editable by* means a fixed product constant.

Naming: camelCase, dotted namespaces, unit suffixes `Days`, `Minutes`,
`Seconds`, `Ms`, `Bytes`, `Pct`, `Months`, `Weeks`.

## Hub, Home and Ask

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `productName` | app | string | `Life OS` | build |
| `ranking.domainOrder` | Home, Ask | list of box ids | `health, finance, family, career, notes, reflection, documents, conversations` | owner |
| `ask.provider` | Ask | `none` \| `local` \| `cloud` | `none` | owner |
| `ask.allowExternal` | Ask | bool | `false` | owner |
| `ask.share.<boxId>` | Ask | bool per box | `false` | owner |
| `ask.share.questionText` | Ask | bool | `false` | owner |
| `ask.minScore` | Ask routing | score | `2` | build |
| `ask.tieMargin` | Ask routing | score | `0.5` | build |
| `ask.orRatio` | Ask routing | fraction | `0.6` | build |
| `ask.typoMinWordLength` | Ask routing | letters | `5` | build |
| `ask.answerLatencySeconds` | Ask | seconds | `3` | build |
| `ask.eval.routingMinPct` | Ask evaluation | percent | `95` | build |
| `ask.eval.safetyMinPct` | Ask evaluation | percent | `100` | build |
| `perf.apiCallMs` | home server | milliseconds | `500` | build |

## Dates, reminders and notifications

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `reminders.timezone` | all boxes | `{name, utcOffset}` | `required — no default` | owner |
| `reminders.upcomingDays` | Home, reminders, life brief | days, 0–366 | `required — no default` | owner |
| `reminders.notifications.enabled` | reminders | bool | `false` | owner |
| `reminders.notifications.intervalMinutes` | reminders | minutes, 1–1440 | `required — no default` (to turn notifications on) | owner |
| `reminders.financeSnapshotDayOfMonth` | reminders | day, 1–31 | optional; no reminder when unset | owner |

## Health

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `health.trendMinPoints` | Health | count, 2–100 | `required — no default` | owner |
| `health.stableTolerancePct` | Health | percent | `required — no default` | owner |
| `health.includeUnverified` | Health | bool | `required — no default` | owner |
| `health.bandJudgements` | Health | `{source, inRange[], outOfRange[]}` band names | optional; unset → multi-band results are `band_unmapped` | owner |
| `health.targets[]` | Health | `{testId, reference, source}` | optional | owner |
| `health.cadences[]` | Health | `{testId, everyDays (1–36500), source}` | optional; no retest reminders without one | owner |
| `health.checkupPlan` | Health | list of test ids | optional | owner |
| `health.urgencyRules[]` | Health | rules mapping a status to `high`/`medium`/`low` | optional; unset → `unrated` | owner |
| `health.reportMaxBytes` | Health upload | bytes | `10 MB` | build |

## Career & Learning

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `career.skillScale` | Career | integer levels | `0–5` | build |
| `career.weights` | Career ranking | `{skillFit, interestAlignment, timeToReady, experienceMatch, userPriority}` | `required — no default` | owner |
| `career.scoring.timeToReadyReferenceWeeks` | Career ranking | weeks | `required — no default` | owner |
| `career.scoring.minAchievementsWithMetrics` | Career ranking | count | `required — no default` | owner |
| `career.plan.hoursPerWeek` | Learning plan | hours | `required — no default` | owner |
| `career.plan.startDate` | Learning plan | date | `required — no default` | owner |
| `career.plan.onTrackToleranceWeeks` | Learning plan | weeks | `required — no default` (for progress) | owner |
| `career.plan.yearlyBudget` | Learning plan | rupees | `required — no default` (for the budget view) | owner |
| `career.exactCoverMaxResources` | Learning cover | count | `20` | build |

## Family

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `family.upcomingDays` | Family | days | `required — no default` | owner |
| `family.vaccinationGraceDays` | Family | days, 0–3650 | `required — no default` | owner |
| `family.milestoneLookaheadMonths` | Family | months, 1–240 | `required — no default` | owner |
| `family.goalLinks[]` | Family ↔ Finance | `{goalId, personId}` | optional | owner |

## Reflection

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `reflection.scale` | Reflection | integer levels | `1–5` | build |
| `reflection.moodLabels`, `reflection.energyLabels` | Reflection | 5 words (≤ 40 characters each) | optional; no default words | owner |
| `reflection.reviewCadences` | Reflection | subset of `weekly`, `monthly` | optional; no reviews when unset | owner |
| `reflection.promptSets` | Reflection | prompts per cadence (≤ 30, ≤ 300 characters) | optional; SAMPLE prompts, labelled, until set | owner |
| `reflection.calendarWeeks` | Reflection | weeks, 1–106 | optional; no default | owner |

## Documents and identity vault

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `documents.sources[]` | Documents | `{path, include[], exclude[]}` | none until the owner adds one | owner |
| `documents.syncSchedule` | Documents | schedule (daily time or interval) | `required — no default` (manual *Sync now* only until set) | owner |
| `documents.rules` | Documents | classification rules | SAMPLE, labelled, until the owner saves their own | owner |
| `documents.autoApply` | Documents | bool per rule | `false` | owner |
| `documents.syncIndex` | Documents | bool | `false` | owner |
| `documents.expected[]` | Documents | `{docType, source, everyDays, graceDays}` | optional | owner |
| `identity.maskVisibleChars` | Identity vault | characters | `4` | build |
| `identity.revealHideSeconds` | Identity vault | seconds | `30` | build |

## Conversations

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `conversations.sources[].retentionDays` | Conversations | days or `forever` | `required — no default` (per source, before import) | owner |
| `conversations.sources[].aiConsent` | Conversations, Ask | bool per source | `false` | owner |
| `conversations.contactIntervalDays` | Conversations | days per contact | optional; no relationship nudge without it | owner |
| `conversations.commitmentRules` | Conversations | phrase rules | SAMPLE, labelled, until the owner saves their own | owner |

## Access, sessions and storage

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `server.bindAddress` | home server | address | `127.0.0.1` (no other value accepted) | build |
| `auth.allowedHosts` | home server | exact host names | `required — no default` in home-server mode | owner |
| `auth.passwordKdf` | sign-in | algorithm | `scrypt` with a random salt | build |
| `auth.sessionDays` | sign-in | days, 1–365 | `required — no default` | owner |
| `auth.sessionTokenBytes` | sign-in | bytes of randomness | `32` | build |
| `auth.freeFailures` | sign-in throttle | count per source | `5` | build |
| `auth.lockoutInitialSeconds` | sign-in throttle | seconds, doubling per further failure | `30` | build |
| `auth.lockoutMaxSeconds` | sign-in throttle | seconds | `3600` | build |
| `limits.requestBodyBytes` | API | bytes | `1 MB` | build |
| `limits.statementBodyBytes` | Finance statements | bytes | `5 MB` | build |
| `storage.serverBackupsPerDocument` | home server | count | `20` | build |
| `storage.deviceBackupsKeep` | website | 1–1000 or `all` | `required — no default` (asked at first run) | owner |
| `backup.schedule` | home server | `{frequency, time, folder, keep}` | `required — no default` (each asked) | owner |

## Encryption and sync

| Key | Scope | Type / unit | Default | Editable by |
| --- | --- | --- | --- | --- |
| `crypto.formatVersion` | E2E | string | `lifeos-e2e/1` | build |
| `crypto.kdf` | E2E | algorithm | `PBKDF2-HMAC-SHA256` | build |
| `crypto.pbkdf2Iterations` | E2E | iterations | `600000` (creating a keyring with fewer is refused) | build (may only rise) |
| `crypto.pbkdf2MaxIterationsAccepted` | E2E | iterations | `10000000` | build |
| `crypto.saltBytes` | E2E | bytes | `16` | build |
| `crypto.keyBits` | E2E | bits (data key, recovery key, derived keys) | `256` | build |
| `crypto.cipher` | E2E | algorithm | `AES-256-GCM` | build |
| `crypto.nonceBits` | E2E | bits, random per encryption | `96` | build |
| `crypto.tagBits` | E2E | bits | `128` | build |
| `crypto.recoveryKeyChecksumBytes` | E2E | bytes (SHA-256 prefix) | `2` | build |
| `crypto.recoveryKeyFormat` | E2E | base32, groups | `55 characters in 11 groups of 5` | build |
| `crypto.blobIdBits` | E2E | bits (HMAC-SHA256 prefix) | `128` | build |
| `crypto.passphraseMinChars` | E2E | characters (Unicode NFC) | `12` | build |
| `vault.autoLockMinutes` | E2E | minutes or `off` | `required — no default` (asked on first unlock) | owner |
| `sync.autoSyncMinutes` | sync | minutes | optional; manual *Sync now* when unset | owner |
| `sync.maxPushRounds` | sync | count | `3` | build |
