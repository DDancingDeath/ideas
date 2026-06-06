# Spec — parenting-companion

> **Placeholder.** Spec deferred until the platform (Flutter vs.
> React Native), data-storage model (local-first vs. cloud-first), and
> Indian fee-data source decisions are made — see open questions in
> [`../README.md`](../README.md) and [`../idea.md`](../idea.md).

## What the spec will need to cover

### Child profile
1. **Profile schema** — name, birthdate, sex (for growth-chart Z-scores),
   feeding / dietary notes, paediatrician contact, optional photo.
2. **Multi-child** — deferred to v2; design the schema with a
   `children[]` array now so the migration is cheap later.

### Growth tracking
3. **Measurement schema** — date, height, weight, head circumference,
   notes.
4. **Z-score / percentile computation** — against bundled WHO and IAP
   reference tables.
5. **Milestone catalogue** — motor / language / social / cognitive,
   age-banded with "typical onset" windows. Checkable, with parent
   notes per milestone.
6. **Visualisation** — line chart per metric overlaid on the standard
   curve; milestone timeline.

### Daily guidance
7. **Age-stage engine** — given today's age, surface the right diet,
   routine, sleep, and learning suggestions. Curated content keyed by
   age band.
8. **Screen-time / activity advice** — age-banded daily recommendations
   with the parent's actuals (optional input) for context.
9. **AI personalisation pass** — LLM over the child's profile +
   recent milestones to tune the suggestions and produce insights.

### Vaccination & health reminders
10. **Schedule data** — IAP / Mission Indradhanush default; per-child
    overrides for paediatrician-specific schedules.
11. **Reminder pipeline** — local notifications at T-7 days, T-1 day,
    T-0; "mark as done" + clinic note.
12. **Routine check-up cadence** — well-baby visits, dental, vision,
    age-appropriate intervals.

### Financial planning
13. **Goal schema** — target (MBBS, engineering, study abroad, school
    fees through grade 12), target year (computed from child's age),
    estimated current cost, inflation rate, ed-loan tolerance.
14. **Cost dataset** — bundled JSON of current Indian fees by goal type
    (school by board, undergrad by stream, post-grad by stream). Source
    + refresh strategy is an open question.
15. **Savings inputs** — current corpus by instrument, recurring SIPs
    by amount and expected return. Manual entry for v1.
16. **Gap analysis** — at today's plan, projected corpus at target year
    vs. projected cost at target year. Numeric gap + percentage.
17. **Scenario sliders** — what-if for SIP amount, expected return,
    inflation, goal year. Pure-function recompute.

### Habit building
18. **Habit catalogue** — reading, family activity, savings check-in,
    parent self-care.
19. **Reminders** — daily / weekly cadence; gentle nudge tone, not
    streak-shaming.

### AI parental insights
20. **Insight schema** — structured output: { kind, evidence, suggested
    action }. Kinds: *learning-gap*, *habit-drift*, *enrichment*,
    *financial-nudge*.
21. **Insight generation cadence** — on demand + weekly batch.
22. **Insight history** — every insight is saved with the snapshot of
    inputs that produced it, so the parent can audit later.

### Data input & customisation
23. **Quick-add UX** — measurement entry in under 15 seconds. Voice
    fallback (optional v2).
24. **Journaling** — text + photo entries, optionally tagged to a
    milestone or stage.

### Notifications
25. **Channels** — APNs (iOS) / FCM (Android); local fallbacks for
    when the device is offline.
26. **Quiet hours** — respect device DND; nothing before 7 am or
    after 9 pm by default.

### Privacy & storage
27. **On-device encrypted SQLite** — canonical store for profile,
    measurements, reminders, financial inputs.
28. **Optional cloud sync** — Azure Blob / OneDrive; opt-in per
    data type (profile + measurements separate from financial).
29. **Export / delete** — full export to JSON; full account delete.
30. **No third-party analytics** in v1.

## Out of scope

- Medical diagnosis / symptom checker.
- Direct integration with brokerages (Zerodha / Groww). Manual input
  only in v1.
- Social features (feed, comments, sharing).
- Multi-child profiles (v2).
- Multi-parent shared account (v2).
- General-purpose chatbot.
- Wearable ingestion (v2; schema hooks only in v1).
- Telemedicine / video consult.
