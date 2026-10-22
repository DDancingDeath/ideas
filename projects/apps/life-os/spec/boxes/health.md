# Box spec — Health

Health turns the owner's (and household members') lab reports into a reviewed
history and factual prompts. It never diagnoses. Settings: `health.*` in
[configuration.md](../configuration.md#health).

## Flow

| Step | Behaviour |
| --- | --- |
| Upload | One or more report PDFs (≤ `health.reportMaxBytes`), or pasted text. |
| Extract | A **draft** report: date, lab, patient sex/age if printed, result rows (test, value, qualifier `=`/`<`/`<=`/`>`/`>=`, unit, the printed reference as text and parsed, the lab's flag), each `verified: false` with a confidence, issues and the raw line. Rows wrapped over two lines are joined conservatively and marked (one confidence step lower). Lines that look like results but match no catalogue test are listed, with ranked candidates when the name is incomplete. |
| Scanned PDF | Refused for text extraction; the owner may choose on-device OCR (offline) — every OCR row is at most medium confidence and needs review — or type results into an empty table. |
| Review | The owner compares each row with the PDF, fixes or removes rows, maps unknown lines with a catalogue picker, ticks *Verified* (per row or all). Extraction never marks anything verified. |
| Save | The reviewed report is saved; an existing report id is refused (edit instead). |

## Judgement

| Rule |
| --- |
| A value is judged **only** against the reference printed on its own report (in that report's unit) or a target the owner entered in `health.targets[]` (with its required source). Neither → `no_reference`. No clinical range exists in the product. |
| The test catalogue holds only names, aliases, canonical units and exact unit factors. |
| Multi-band references (e.g. Desirable / Borderline / High) report the band name verbatim and are judged only through `health.bandJudgements` (band names compared ignoring case, punctuation and spacing). A band not in the mapping → `band_unmapped`. A SAMPLE mapping may be copied; while its source is `sample` every summary warns. |
| Sex-specific references use the profile's sex, else `needs_profile_sex`. |
| `<x` is the interval `[0, x)`; a bound-straddling `<`/`>` result is `indeterminate`. |
| Values convert to the catalogue's canonical unit with exact factors. The one formula is HbA1c IFCC (mmol/mol) → NGSP (%) = 0.09148 × IFCC + 2.152; the reference stays in the report's own unit. eAG is never computed. |
| Unverified rows are excluded unless `health.includeUnverified` is true. |
| A trend is shown only over the last `health.trendMinPoints` exact values; a change within `health.stableTolerancePct` is "stable". |

| Status | Meaning |
| --- | --- |
| `within_range` | Inside the printed interval, the same qualitative wording (or a synonym), or a band mapped in range |
| `above_range` / `below_range` | Wholly above / below the printed interval |
| `outside_range` | Qualitative opposite, or a band mapped out of range |
| `band_unmapped` | In a printed band not in the owner's mapping (not judged) |
| `outside_bands` | Outside every printed band (not judged) |
| `indeterminate` | Straddles a bound, or bands mapped both ways |
| `needs_profile_sex` | Sex-specific reference, no sex in the profile |
| `text_mismatch_unjudged` | Different wording that is neither a synonym nor an opposite |
| `reference_unparsed` | The reference text is not an interval (kept verbatim) |
| `no_reference` | No printed reference and no target |
| `not_comparable` | A text result against a numeric reference, or a unit without an exact conversion for a target |

Qualitative synonym groups: *absent* = negative, nil, absent, not detected,
none detected, non detected, undetected, not present, not seen, none seen;
*present* = positive, present, detected; *trace*; *non-reactive* vs
*reactive*; *normal* vs *abnormal*.

## Prompts and urgency

| Prompt kind | Fires when |
| --- | --- |
| `lab_critical` | The lab printed a critical/panic flag |
| `persistent_out_of_range` | ≥ 2 consecutive reports out of range |
| `out_of_range_latest` | Latest value out of range |
| `outside_target` | Outside an owner target |
| `worsening_trend` | Trend moving away from range |
| `lab_flagged` | The lab flagged high/low |
| `overdue_retest` | A cadence's due date has passed |
| `missing_planned_test` | A test in `health.checkupPlan` not yet done |

| Rule |
| --- |
| Urgency `critical` (category `lab_critical`) only from the lab's critical flag; `high`/`medium`/`low` only from `health.urgencyRules`; otherwise `unrated`. Other prompts have category `health_followup`. |
| Retest reminders come only from `health.cadences` and `health.checkupPlan`; there are no built-in cadences. |

## Medical safety

| Rule |
| --- |
| No diagnosis, no medication or dosage advice, no clinical thresholds. Anything out of range points to a doctor. |
| Every prompt and health answer carries the disclaimer: *"Not medical advice. Discuss results with a qualified doctor."* |
| Reports are processed on the device; the extraction makes no network calls. |

## Settings screen

The three required settings start empty (placeholders only) and show who set
each value; targets, cadences, check-up plan, urgency rules and band names are
optional; validation errors appear next to the field.
