# Box spec — Family

People come only from the household profile. Family adds ages and life
stages, events, child milestones, vaccinations and links to Finance education
goals. Settings: `family.*` in [configuration.md](../configuration.md#family).
Detailed parenting ideas: [parenting-companion](../../../parenting-companion/spec/README.md)
(this file wins on the hub contract).

## Calculations

| Calculation | Returns |
| --- | --- |
| Family summary | Each person's age (exact, or a range flagged *estimated* from a partial birth date or an age on a date), each child's life stage from the owner's stages, household and dependents (explicit flags only), next birthday (exact birth dates; 29 Feb → 28 Feb), next occurrence of each event, what is upcoming within `family.upcomingDays`, missing items |
| Milestones | Per child: achieved (with age at the date), in window now, upcoming within `family.milestoneLookaheadMonths`, not recorded yet |
| Child timeline | Per child: stage start dates, events, next birthday, linked Finance goals with the status Finance reported (`funded`, `short`, `unknown`) |
| Vaccinations | Per dose: due date = birth date + due age (needs an exact birth date); status `given`, `due`, `overdue` (after the dose's until-age, or after `family.vaccinationGraceDays` when the schedule has no window), `upcoming`, `scheduled`; next dose per person |
| Family facts | Facts for Ask: ages, stages, events, milestones, vaccinations, education links |

## Data model

| Document | Fields |
| --- | --- |
| Stages | `{source, stages[{stage_id, label, from_months (0–1560), until_months?}]}` — SAMPLE until saved |
| Events | `{event_id, title, kind, person_ids, date, recurs}`; `kind` ∈ anniversary, birthday, school_start, exam, college, medical, celebration, other; `recurs` ∈ yearly, once |
| Milestone catalogue | `{source, items[{milestone_id, title, domain, from_months, to_months (0–240)}]}`; `domain` ∈ motor, language, social, cognitive, other — SAMPLE until saved |
| Milestone records | `{record_id, person_id, date, milestone_id?, domain?}` |
| Vaccination schedules | per person `{person_id, source, doses[{dose_id, vaccine, due_age {value, unit}, until_age?}]}`; units days, weeks, months, years |
| Doses given | `{person_id, dose_id, date_given}` |
| Goal links | `family.goalLinks[]` |

## Rules

| Rule |
| --- |
| No built-in stages, milestone windows, schedules, windows or grace periods. |
| Milestone wording is neutral — achieved, in window, not recorded yet — never a judgement or a delay label. Disclaimer: *"Milestone windows are a general reference, not a test. Children develop at their own pace — check with your paediatrician; not medical advice."* |
| Vaccination dates come only from the schedule the owner entered or copied (a SAMPLE schedule stays marked *sample* until the owner verifies it). Disclaimer: *"Dates come from the schedule you entered. Follow your paediatrician and the official schedule; not medical advice."* |
| Education goals live in Finance; Family links a goal to a child and shows Finance's status. No finance maths in Family. |

## Birth date from a birth certificate

| Step | Behaviour |
| --- | --- |
| 1 | The Documents box classifies a source document as a birth certificate and reads the name and date of birth. |
| 2 | A draft "Set <person>'s birth date to <date> (precision: day)" appears in Family's review queue with the document and page; the person is matched by name only as a proposal. |
| 3 | The owner confirms the person and the date. Auto-apply never applies it. |
| 4 | The household profile is saved through the versioned save; birthdays, ages, stages and vaccination due dates recompute. |
